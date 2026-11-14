%% PARTIE 3 - Question 12 : TEB en fonction de Eb/N0 (avec et sans integration)
% Deux facons de lancer ce script :
%   mode = 'simulink' : la simulation est faite par le modele chaine_gauss.slx
%                       (a lancer sur un PC avec Matlab/Simulink)
%   mode = 'matlab'   : meme chaine simulee directement en Matlab
%                       (sert de reference, marche aussi sous Octave)
Parametres;
close all;

mode = 'simulink';                 % 'simulink' ou 'matlab'
if exist('OCTAVE_VERSION', 'builtin'), mode = 'matlab'; end   % pas de Simulink sous Octave

Q = @(x) 0.5 * erfc(x / sqrt(2));  % fonction Q
EbN0dB_vec = 0:9;                  % Eb/N0 de 0 a 9 dB
Eb = A^2 * Tb;                     % energie par bit

%% Preparation du modele Simulink (voie "un seul echantillon")
if strcmp(mode, 'simulink')
    mdl = 'chaine_gauss';
    load_system(mdl);
    completer_chaine_gauss(mdl);   % ajoute la voie sans integration si elle manque

    % retard de chaque voie : on simule sans bruit et on cherche le decalage sans erreur
    sigma2 = 0;
    out = sim(mdl, 'StopTime', '999');
    be  = double(out.bits_emis(:));
    retard_int = trouver_retard(be, double(out.bits_recus(:)));
    retard_1   = trouver_retard(be, double(out.bits_recus_1ech(:)));
    fprintf('Retard voie avec integration : %d bit(s)\n', retard_int);
    fprintf('Retard voie sans integration : %d bit(s)\n', retard_1);
end

%% Boucle sur Eb/N0
TEB_int = zeros(size(EbN0dB_vec));    % avec integrateur
TEB_1   = zeros(size(EbN0dB_vec));    % un seul echantillon au milieu du bit
Nbits   = zeros(size(EbN0dB_vec));

for i = 1:numel(EbN0dB_vec)
    N0     = Eb / 10^(EbN0dB_vec(i)/10);    % densite du bruit
    sigma2 = N0 * L / (2*Tb);               % variance par echantillon

    % nombre de bits : au moins ~200 erreurs attendues (entre 1e5 et 2e6 bits)
    Pth = Q(sqrt(2*Eb/N0));
    N = min(2e6, max(1e5, ceil(200 / Pth)));
    Nbits(i) = N;

    if strcmp(mode, 'simulink')
        out = sim(mdl, 'StopTime', num2str(N - 1));
        be = double(out.bits_emis(:));
        b1 = double(out.bits_recus(:));
        b2 = double(out.bits_recus_1ech(:));
        TEB_int(i) = mean(be(1:end-retard_int) ~= b1(1+retard_int:end));
        TEB_1(i)   = mean(be(1:end-retard_1)   ~= b2(1+retard_1:end));
    else
        % meme chaine en Matlab, par paquets de 1e5 bits pour la memoire
        err_int = 0; err_1 = 0; reste = N;
        while reste > 0
            n  = min(reste, 1e5);
            b  = double(rand(1, n) < 0.5);                 % source equiprobable
            x  = A * (2*b - 1);                            % -A / +A
            s  = repmat(x, L, 1);                          % L echantillons par bit (une colonne = un bit)
            r  = s + sqrt(sigma2) * randn(L, n);           % canal gaussien
            z  = mean(r, 1);                               % integrateur (moyenne sur le bit)
            z1 = r(L/2 + 1, :);                            % un seul echantillon au milieu du bit
            err_int = err_int + sum((z  > seuil) ~= b);
            err_1   = err_1   + sum((z1 > seuil) ~= b);
            reste = reste - n;
        end
        TEB_int(i) = err_int / N;
        TEB_1(i)   = err_1 / N;
    end
    fprintf('Eb/N0 = %d dB : TEB integ = %.2e   TEB 1 ech = %.2e   (%d bits)\n', ...
        EbN0dB_vec(i), TEB_int(i), TEB_1(i), N);
end

%% Courbes theoriques
x_fin    = linspace(0, 9, 200);
TEB_th   = Q(sqrt(2 * 10.^(x_fin/10)));          % avec integrateur : Q(sqrt(2Eb/N0))
TEB_th_1 = Q(sqrt(2 * 10.^(x_fin/10) / L));      % un echantillon : SNR divise par L

figure;
semilogy(x_fin, TEB_th, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_vec, TEB_int, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x_fin, TEB_th_1, 'r-', 'LineWidth', 1.5);
semilogy(EbN0dB_vec, TEB_1, 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('TEB');
title(sprintf('Chaine gaussienne (L = %d) : avec et sans integration', L));
legend('theorie Q(sqrt(2E_b/N_0))', 'simulation avec integrateur', ...
       'theorie Q(sqrt(2E_b/(L N_0)))', 'simulation 1 echantillon', 'Location', 'southwest');
ylim([1e-6 1]);

% ecart entre les deux voies
fprintf('\nEcart theorique entre les deux voies : 10 log10(L) = %.1f dB\n', 10*log10(L));
save('resultats_partie3_q12.mat', 'EbN0dB_vec', 'TEB_int', 'TEB_1', 'Nbits', 'mode');
