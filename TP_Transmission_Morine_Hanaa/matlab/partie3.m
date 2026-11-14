%% PARTIE 3 - Chaine de transmission de base
Parametres;
close all;

%% Questions 1 et 2 : canal binaire symetrique (CBS)

N = 1e5;   % nombre de bits a envoyer

% on lance le modele Simulink pendant N bits
% (le temps va de 0 a N-1 donc on a N bits)
out = sim('canal_cbs', 'StopTime', num2str(N - 1));

% on recupere les bits
be = double(out.bits_emis);    % bits emis
br = double(out.bits_recus);   % bits recus

% on compte les erreurs
nerr = sum(be ~= br);          % nombre de bits differents
TEB  = nerr / numel(be);       % taux d'erreur binaire

% intervalle de confiance a 95 %
IC = 1.96 * sqrt(TEB * (1 - TEB) / numel(be));

fprintf('\n--- Canal binaire symetrique ---\n');
fprintf('Nombre de bits    = %d\n', numel(be));
fprintf('Nombre d''erreurs  = %d\n', nerr);
fprintf('pe theorique      = %.4f\n', pe);
fprintf('TEB mesure        = %.4f\n', TEB);
fprintf('Intervalle 95 %%   = [%.4f ; %.4f]\n', TEB - IC, TEB + IC);

%% Question 3 : capacite du canal binaire symetrique

C = 1 - entropie_binaire(pe);   % capacite de mon canal
R = 4/7;                        % rendement du code de Hamming

fprintf('\n--- Capacite du CBS ---\n');
fprintf('Capacite de mon canal C = %.4f bit par bit emis\n', C);
fprintf('Rendement Hamming R = %.4f\n', R);
if R < C
    fprintf('R < C : une transmission fiable est possible (Shannon)\n');
else
    fprintf('R >= C : une transmission fiable est impossible\n');
end
fprintf('Capacite pour pe = 0.5 : C = %.4f\n', 1 - entropie_binaire(0.5));

% courbe C(pe)
pp = linspace(0, 1, 501);
figure;
plot(pp, 1 - entropie_binaire(pp), 'LineWidth', 1.5); hold on;
plot(pe, C, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);   % mon canal
yline(R, 'k--', 'R = 4/7 (Hamming)');
grid on;
xlabel('p_e (probabilite d''erreur)');
ylabel('C (bit par bit emis)');
title('Capacite du canal binaire symetrique');
legend('C(p_e) = 1 - H(p_e)', sprintf('mon canal : p_e = %.2f', pe), 'Location', 'north');

%% Question 4 : densites du canal a bruit uniforme

% r = x + bruit, x = -A (bit 0) ou +A (bit 1), bruit uniforme sur [-a, a]
r = linspace(-3, 3, 2001);
f0 = (r >= -A - a & r <= -A + a) / (2*a);   % densite de r si bit 0
f1 = (r >=  A - a & r <=  A + a) / (2*a);   % densite de r si bit 1

fprintf('\n--- Canal a bruit uniforme ---\n');
fprintf('a = %.2f, A = %.2f\n', a, A);
fprintf('Zone de recouvrement = [%.2f ; %.2f]\n', A - a, a - A);
fprintf('Hauteur des densites = 1/(2a) = %.4f\n', 1/(2*a));
if p1 < 0.5
    s_opt = a - A;     % on donne la zone de recouvrement au bit 0
else
    s_opt = A - a;     % on la donne au bit 1
end
fprintf('Seuil optimal (p1 = %.2f) = %.2f\n', p1, s_opt);

% figure
figure;
plot(r, f0, 'b', 'LineWidth', 1.5); hold on;
plot(r, f1, 'r', 'LineWidth', 1.5);
xline(s_opt, 'k--', sprintf('seuil optimal s = %.2f', s_opt));
% on colorie la zone de recouvrement
zone = (r >= A - a) & (r <= a - A);
area(r(zone), f0(zone), 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
grid on;
ylim([0 0.6]);
xlabel('r (valeur recue)');
ylabel('densite de probabilite');
title(sprintf('Canal a bruit uniforme (A = %g, a = %.2f)', A, a));
legend('f(r|0)', 'f(r|1)', 'seuil optimal', 'zone de recouvrement', 'Location', 'northwest');


%% Question 5 : probabilite d'erreur du canal uniforme selon le seuil

% proba de se tromper pour chaque bit (on borne entre 0 et 1)
P0err = @(s) min(max((a - A - s) / (2*a), 0), 1);   % bit 0 decide 1
P1err = @(s) min(max((s - A + a) / (2*a), 0), 1);   % bit 1 decide 0
Pe_unif = @(s) p0 * P0err(s) + p1 * P1err(s);       % proba d'erreur totale

fprintf('\n--- Proba d''erreur du canal uniforme ---\n');
fprintf('Pe(s = 0)    = %.4f\n', Pe_unif(0));
fprintf('Pe(s = %.2f) = %.4f  (seuil optimal)\n', s_opt, Pe_unif(s_opt));

% courbe Pe(s)
s = linspace(-3, 3, 1001);
figure;
plot(s, Pe_unif(s), 'b', 'LineWidth', 1.5); hold on;
plot(s_opt, Pe_unif(s_opt), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
grid on;
xlabel('seuil s');
ylabel('P_e(s)');
title('Probabilite d''erreur du canal uniforme selon le seuil');
legend('P_e(s) theorique', 'seuil optimal', 'Location', 'north');

%% Question 6 : TEB simule du canal uniforme pour plusieurs seuils

Nu = 1e5;                          % nombre de bits
bu = source(Nu, p1);               % bits de la source (p1 = 0.39)
xu = A * (2*bu - 1);               % bit 0 -> -A, bit 1 -> +A
nu = a * (2*rand(1, Nu) - 1);      % bruit uniforme entre -a et +a
ru = xu + nu;                      % signal recu

seuils = sort([-3:0.1:3, s_opt]);  % les seuils a tester (+ le seuil optimal)
TEBu = zeros(size(seuils));
for i = 1:numel(seuils)
    bdec = ru > seuils(i);                  % decision : 1 si r > seuil
    TEBu(i) = mean(bdec ~= bu);             % proportion d'erreurs
end

% meilleur seuil mesure
[TEBmin, imin] = min(TEBu);
fprintf('\n--- Simulation canal uniforme (%d bits) ---\n', Nu);
fprintf('TEB mesure pour s = 0    : %.4f (theorie %.4f)\n', TEBu(seuils == 0), Pe_unif(0));
fprintf('TEB mesure pour s = %.2f : %.4f (theorie %.4f)\n', s_opt, TEBu(seuils == s_opt), Pe_unif(s_opt));
fprintf('Meilleur seuil mesure    : s = %.2f (TEB = %.4f)\n', seuils(imin), TEBmin);

% on ajoute les points mesures sur la courbe de la question 5
figure;
plot(s, Pe_unif(s), 'b', 'LineWidth', 1.5); hold on;
plot(seuils, TEBu, 'rx', 'MarkerSize', 7, 'LineWidth', 1.2);
plot(s_opt, Pe_unif(s_opt), 'ko', 'MarkerSize', 9, 'LineWidth', 1.5);
grid on;
xlabel('seuil s');
ylabel('TEB');
title('Canal uniforme : TEB theorique et simule');
legend('P_e(s) theorique', 'TEB simule (10^5 bits)', 'seuil optimal', 'Location', 'north');

%% Question 7 : canal gaussien, seuil optimal et proba d'erreur theorique

Q = @(x) 0.5 * erfc(x / sqrt(2));                 % fonction Q
s_gauss = sigma^2 / (2*A) * log(p0 / p1);         % seuil optimal
Pe_gauss = @(s) p0 * Q((s + A) / sigma) + p1 * Q((A - s) / sigma);

fprintf('\n--- Canal gaussien (sigma = %.2f) ---\n', sigma);
fprintf('Seuil optimal s* = %.4f\n', s_gauss);
fprintf('Pe theorique (s = 0)  = %.4f\n', Pe_gauss(0));
fprintf('Pe theorique (s = s*) = %.4f\n', Pe_gauss(s_gauss));

%% Question 8 : TEB simule du canal gaussien selon le seuil

Ng = 1e5;                          % nombre de bits
bg = source(Ng, p1);               % bits de la source
xg = A * (2*bg - 1);               % bit 0 -> -A, bit 1 -> +A
rg = xg + sigma * randn(1, Ng);    % on ajoute le bruit gaussien

seuils_g = sort([-1.5:0.05:1.5, s_gauss]);   % seuils a tester
TEBg = zeros(size(seuils_g));
for i = 1:numel(seuils_g)
    TEBg(i) = mean((rg > seuils_g(i)) ~= bg);   % proportion d'erreurs
end

[TEBgmin, igmin] = min(TEBg);
fprintf('TEB mesure (s = 0)  = %.4f\n', TEBg(seuils_g == 0));
fprintf('TEB mesure (s = s*) = %.4f\n', TEBg(seuils_g == s_gauss));
fprintf('Meilleur seuil mesure : s = %.2f (TEB = %.4f)\n', seuils_g(igmin), TEBgmin);
fprintf('Gain du seuil optimal / s = 0 : %.1f %%\n', ...
    100 * (1 - Pe_gauss(s_gauss) / Pe_gauss(0)));

% figure
sg = linspace(-1.5, 1.5, 501);
figure;
plot(sg, Pe_gauss(sg), 'b', 'LineWidth', 1.5); hold on;
plot(seuils_g, TEBg, 'rx', 'MarkerSize', 7, 'LineWidth', 1.2);
plot(s_gauss, Pe_gauss(s_gauss), 'ko', 'MarkerSize', 9, 'LineWidth', 1.5);
xline(0, 'k:');
grid on;
xlabel('seuil s');
ylabel('TEB');
title(sprintf('Canal gaussien (\\sigma = %.2f) : TEB selon le seuil', sigma));
legend('P_e(s) theorique', 'TEB simule (10^5 bits)', 'seuil optimal s^*', 's = 0', 'Location', 'north');

%% Question 10 : chaine avec L echantillons par bit et detecteur optimal

% --- test 1 : sans bruit, pour verifier et trouver le retard ---
sigma2 = 0;                                       % pas de bruit
out = sim('chaine_gauss', 'StopTime', '9999');    % 10000 bits
be = double(out.bits_emis(:));    % bits emis
br = double(out.bits_recus(:));   % bits recus

% on essaie plusieurs retards, on garde celui qui donne 0 erreur
err = zeros(1, 6);
for d = 0:5
    err(d+1) = sum(be(1:end-d) ~= br(1+d:end));
end
[~, i] = min(err);
retard = i - 1;
fprintf('\n--- Chaine gaussienne (L = %d) ---\n', L);
fprintf('Sans bruit : retard = %d bit(s), erreurs = %d\n', retard, err(i));

% --- test 2 : avec bruit, Eb/N0 = 5 dB ---
EbN0dB = 5;
N0 = Eb / 10^(EbN0dB/10);        % densite du bruit
sigma2 = N0 * L / (2*Tb);        % variance par echantillon
out = sim('chaine_gauss', 'StopTime', '99999');   % 100000 bits
be = double(out.bits_emis(:));
br = double(out.bits_recus(:));
be = be(1:end-retard);           % on compense le retard
br = br(1+retard:end);

TEB10 = mean(be ~= br);                           % TEB mesure
IC10  = 1.96 * sqrt(TEB10 * (1 - TEB10) / numel(be));
TEBth = Q(sqrt(2 * Eb / N0));                     % TEB theorique

fprintf('Eb/N0 = %d dB, variance par echantillon = %.4f\n', EbN0dB, sigma2);
fprintf('TEB mesure    = %.5f  [%.5f ; %.5f]\n', TEB10, TEB10 - IC10, TEB10 + IC10);
fprintf('TEB theorique = %.5f\n', TEBth);