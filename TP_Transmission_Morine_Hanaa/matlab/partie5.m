%% PARTIE 5 - Modulation QPSK (bande de base equivalente)
% symboles exp(j k pi/4), k = 1, 3, 5, 7, energie par symbole Es = 1
% le bruit est complexe, de variance N0/2 sur chaque voie
% Le modele Simulink correspondant est construit par creer_chaine_qpsk.m
Parametres;
close all;
Q  = @(x) 0.5 * erfc(x / sqrt(2));
Es = 1;                 % energie par symbole
Eb = Es / 2;            % 2 bits par symbole
avec_simulink = ~exist('OCTAVE_VERSION', 'builtin') && exist('sim', 'file') > 0;

%% Question 1 : mapping de Gray
fprintf('\n--- Question 1 : mapping de Gray ---\n');
couples = [0 0; 0 1; 1 1; 1 0];
for i = 1:4
    s = qpsk_mod(couples(i, :), 'gray');
    fprintf('[%d %d] -> k = %d : I = %+.3f, Q = %+.3f\n', couples(i, :), ...
        round(mod(angle(s), 2*pi) / (pi/4)), real(s), imag(s));
end
fprintf('Es = %g -> Eb = Es/2 = %g\n', Es, Eb);

%% Question 2 : validation sans bruit
b = double(rand(1, 1e4) < 0.5);
for mp = {'gray', 'naturel'}
    bd = qpsk_demod(qpsk_mod(b, mp{1}), mp{1});
    fprintf('Sans bruit, mapping %s : erreurs = %d\n', mp{1}, sum(bd ~= b));
end

%% Question 3 : constellations recues pour Eb/N0 = 0, 5 et 10 dB
figure('Position', [100 100 900 330]);
liste = [0 5 10];
for i = 1:3
    N0 = Eb / 10^(liste(i) / 10);
    s  = qpsk_mod(double(rand(1, 2000) < 0.5), 'gray');
    r  = s + sqrt(N0/2) * (randn(size(s)) + 1j * randn(size(s)));
    subplot(1, 3, i);
    plot(real(r), imag(r), '.', 'MarkerSize', 4); hold on;
    plot(real(exp(1j*(1:2:7)*pi/4)), imag(exp(1j*(1:2:7)*pi/4)), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
    plot([-2.5 2.5], [0 0], 'k-'); plot([0 0], [-2.5 2.5], 'k-');
    axis([-2.5 2.5 -2.5 2.5]); axis square; grid on;
    xlabel('I'); ylabel('Q');
    title(sprintf('E_b/N_0 = %d dB', liste(i)));
end

%% Questions 4 et 5 : TEB QPSK (Gray et naturel) compare a la chaine binaire
EbN0dB_vec = 0:9;
TEB_gray = zeros(size(EbN0dB_vec));
TEB_nat  = zeros(size(EbN0dB_vec));
Nb = zeros(size(EbN0dB_vec));
for i = 1:numel(EbN0dB_vec)
    N0 = Eb / 10^(EbN0dB_vec(i) / 10);
    q  = Q(sqrt(2 * 10^(EbN0dB_vec(i) / 10)));
    N  = 2 * ceil(min(4e6, max(2e5, 300 / q)) / 2);   % nombre pair de bits
    Nb(i) = N;
    if avec_simulink
        % --- modele Simulink ---
        if ~exist('chaine_qpsk.slx', 'file'), creer_chaine_qpsk; end
        sigma2_qpsk = N0 / 2;                          % variance par voie
        N = min(N, 1e6); Nb(i) = N;                    % limite la duree de simulation
        for mp = 0:1                                   % 0 = Gray, 1 = naturel
            mapping_naturel = mp;
            out = sim('chaine_qpsk', 'StopTime', num2str(N - 1));
            be = double(out.bits_emis(:)); br = double(out.bits_recus(:));
            d  = trouver_retard(be(1:2000), br(1:2000), 10);
            t  = mean(be(1:end-d) ~= br(1+d:end));
            if mp == 0, TEB_gray(i) = t; else, TEB_nat(i) = t; end
        end
    else
        % --- simulation Matlab ---
        e_g = 0; e_n = 0; reste = N;
        while reste > 0
            n = min(reste, 2e5);
            b = double(rand(1, n) < 0.5);
            bruit = sqrt(N0/2) * (randn(1, n/2) + 1j * randn(1, n/2));
            e_g = e_g + sum(qpsk_demod(qpsk_mod(b, 'gray')    + bruit, 'gray')    ~= b);
            e_n = e_n + sum(qpsk_demod(qpsk_mod(b, 'naturel') + bruit, 'naturel') ~= b);
            reste = reste - n;
        end
        TEB_gray(i) = e_g / N;
        TEB_nat(i)  = e_n / N;
    end
    fprintf('Eb/N0 = %d dB : TEB Gray = %.2e, naturel = %.2e (%d bits)\n', ...
        EbN0dB_vec(i), TEB_gray(i), TEB_nat(i), N);
end

xdB = linspace(0, 10, 300);
qth = Q(sqrt(2 * 10.^(xdB / 10)));         % erreur sur une voie
TEB_gray_th = qth;                          % = TEB de la chaine binaire de la partie 3
TEB_nat_th  = qth .* (3 - 2 * qth) / 2;     % mapping naturel (voir rapport)

figure;
semilogy(xdB, TEB_gray_th, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_vec, TEB_gray, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(xdB, TEB_nat_th, 'r-', 'LineWidth', 1.5);
semilogy(EbN0dB_vec, TEB_nat, 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('QPSK : mapping de Gray et mapping naturel');
legend('Gray : theorie Q(sqrt(2E_b/N_0)) = binaire', 'Gray : simulation', ...
       'naturel : theorie q(3-2q)/2', 'naturel : simulation', 'Location', 'southwest');
fprintf('Rapport TEB naturel / Gray a 9 dB : %.2f (theorie -> 1,5)\n', TEB_nat(end) / TEB_gray(end));

%% Question 6 : QPSK + code de Hamming
% un mot-code fait 7 bits (impair) : on groupe 2 mots = 14 bits = 7 symboles
% (Buffer de 14, periode symbole = 2 Tc = 8 Tb / 7) : pas de bit de bourrage
[G, H] = hamming_matrices();
TEB_qh = zeros(size(EbN0dB_vec));
for i = 1:numel(EbN0dB_vec)
    x  = 10^(EbN0dB_vec(i) / 10);
    Ec = Es / 2;                      % energie par bit code (2 bits codes par symbole)
    Eb_info = Ec * 7 / 4;             % energie par bit d'information
    N0 = Eb_info / x;
    N  = 8 * ceil(Nb(i) / 8);         % multiple de 8 bits utiles = 2 mots
    err = 0; reste = N;
    while reste > 0
        n = min(reste, 8 * 25000);
        b = double(rand(1, n) < 0.5);
        c = hamming_code(b, G);                         % 14 bits codes pour 8 bits utiles
        r = qpsk_mod(c, 'gray');
        r = r + sqrt(N0/2) * (randn(size(r)) + 1j * randn(size(r)));
        bd = hamming_decode(qpsk_demod(r, 'gray'), H);
        err = err + sum(bd ~= b);
        reste = reste - n;
    end
    TEB_qh(i) = err / N;
    fprintf('Eb/N0 = %d dB : TEB QPSK + Hamming = %.2e\n', EbN0dB_vec(i), TEB_qh(i));
end

% comparaison avec la partie 4 (BPSK + Hamming) si les resultats existent
figure;
semilogy(xdB, TEB_gray_th, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_vec, TEB_qh, 'rs-', 'MarkerSize', 7, 'LineWidth', 1.5);
if exist('resultats_partie4.mat', 'file')
    R4 = load('resultats_partie4.mat');
    semilogy(R4.EbN0dB_vec, R4.TEB_c, 'kx--', 'MarkerSize', 8, 'LineWidth', 1.2);
    legend('sans codage (theorie)', 'QPSK + Hamming (simulation)', 'binaire + Hamming (partie 4)', 'Location', 'southwest');
else
    legend('sans codage (theorie)', 'QPSK + Hamming (simulation)', 'Location', 'southwest');
end
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('QPSK avec code de Hamming C(7,4)');

save('resultats_partie5.mat', 'EbN0dB_vec', 'TEB_gray', 'TEB_nat', 'TEB_qh', 'Nb');
