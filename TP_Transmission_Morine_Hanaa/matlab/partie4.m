%% PARTIE 4 - Codage de canal : code de Hamming C(7,4)
% g(x) = 1 + x + x^3, forme systematique c = [m0 m1 m2 m3 | r0 r1 r2]
% Les questions 5, 6 et 10 utilisent aussi des modeles Simulink
% (voir creer_codeur_registre.m, creer_decodeur_hamming.m, creer_chaine_hamming.m).
Parametres;
close all;
Q = @(x) 0.5 * erfc(x / sqrt(2));   % fonction Q
avec_simulink = ~exist('OCTAVE_VERSION', 'builtin') && exist('sim', 'file') > 0;

%% Question 1 : restes, matrices G et H, verification G*H' = 0
[G, H, P, restes] = hamming_matrices();

fprintf('\n--- Question 1 : restes x^3 m(x) mod g(x) ---\n');
for i = 0:3
    fprintf('m(x) = x^%d  ->  reste [r0 r1 r2] = [%d %d %d]\n', i, restes(i+1, :));
end
disp('G = [I4 | P] ='); disp(G);
disp('H = [P'' | I3] ='); disp(H);
GHt = mod(G * H.', 2);
fprintf('G*H'' mod 2 = 0 : %d (1 = oui)\n', all(GHt(:) == 0));

%% Question 2 : colonnes de H, distance minimale
cols = H.' * [1; 2; 4];                      % numero de chaque colonne
fprintf('\n--- Question 2 ---\n');
fprintf('Colonnes de H non nulles : %d, distinctes : %d\n', all(cols > 0), numel(unique(cols)) == 7);

% distance minimale = plus petit poids non nul des 16 mots-codes
tous_m = dec2bin(0:15) - '0';                % les 16 messages (une ligne chacun)
tous_m = tous_m(:, end:-1:1);                % ordre [m0 m1 m2 m3]
tous_c = hamming_code(tous_m, G);
poids  = sum(tous_c, 2);
dmin   = min(poids(poids > 0));
fprintf('Distance minimale dmin = %d -> detecte %d erreurs, corrige %d erreur\n', ...
    dmin, dmin - 1, floor((dmin - 1) / 2));

%% Question 3 : validation du codeur et du decodeur (fonctions Matlab)
fprintf('\n--- Question 3 : validation ---\n');
[m_dec, nc] = hamming_decode(tous_c, H);
fprintf('Sans erreur : 16 messages retrouves : %d, corrections : %d\n', isequal(m_dec, tous_m), nc);

ok = true;
for j = 1:7                                  % une erreur a la position j
    r = tous_c;
    r(:, j) = 1 - r(:, j);
    [m_dec, nc, s] = hamming_decode(r, H);
    ok_j = isequal(m_dec, tous_m) && nc == 16;
    ok = ok && ok_j;
    fprintf('Erreur en position %d : syndrome [%d %d %d], 16 messages corriges : %d\n', ...
        j, s(1, :), ok_j);
end
fprintf('Toutes les erreurs simples sont corrigees : %d\n', ok);

%% Question 5 : registre a decalage (table des etats) et comparaison avec le codeur matriciel
fprintf('\n--- Question 5 : registre a decalage ---\n');
m_ex = [1 0 1 1];                            % m = [m0 m1 m2 m3]
[r_ex, etats] = registre_hamming(m_ex);
fprintf('Message m = [%d %d %d %d], entree poids fort d''abord\n', m_ex);
fprintf(' coup | entree | f | s0 s1 s2\n');
fprintf('   0  |   -    | - |  0  0  0\n');
for k = 1:4
    fprintf('   %d  |   %d    | %d |  %d  %d  %d\n', k, etats(k, :));
end
c_ex = hamming_code(m_ex, G);                % mot-code du codeur matriciel
fprintf('Redondance registre [%d %d %d], codeur matriciel [%d %d %d]\n', r_ex, c_ex(5:7));

identique = true;
for k = 1:16
    r_reg = registre_hamming(tous_m(k, :));
    identique = identique && isequal([tous_m(k, :) r_reg], tous_c(k, :));
end
fprintf('Registre = codeur matriciel pour les 16 messages : %d\n', identique);

if avec_simulink
    % verification du modele Simulink du registre (construit par creer_codeur_registre)
    seq_registre = reshape(tous_m(:, end:-1:1).', 1, []);   % les 16 messages, poids fort d'abord
    if ~exist('codeur_registre.slx', 'file'), creer_codeur_registre; end
    out = sim('codeur_registre', 'StopTime', num2str(numel(seq_registre) - 1));
    s_reg = double(out.etats_reg);                    % s0 s1 s2 apres chaque bit
    r_sim = s_reg(4:4:end, :);                        % contenu apres le 4e bit de chaque message
    fprintf('Modele Simulink du registre = codeur matriciel : %d\n', ...
        isequal(r_sim(1:16, :), tous_c(:, 5:7)));
end

%% Question 6 : decodeur Simulink (logique combinatoire)
if avec_simulink
    if ~exist('decodeur_hamming.slx', 'file'), creer_decodeur_hamming; end
    % mots de test : les 16 mots-codes, sans erreur puis avec 1 erreur a chaque position
    mots = tous_c;
    for j = 1:7
        r = tous_c; r(:, j) = 1 - r(:, j);
        mots = [mots; r];
    end
    attendus = repmat(tous_m, 8, 1);
    entree_dec = [(0:size(mots, 1) - 1).', mots];     % [temps, mot] pour From Workspace
    out = sim('decodeur_hamming', 'StopTime', num2str(size(mots, 1) - 1));
    m_sim = double(out.messages_dec);
    fprintf('Decodeur Simulink : %d mots sur %d decodes correctement\n', ...
        sum(all(m_sim(1:size(mots, 1), :) == attendus, 2)), size(mots, 1));
end

%% Questions 7 a 9 : performances theoriques
fprintf('\n--- Questions 7 a 9 ---\n');
EbN0dB_ex = 5;
x = 10^(EbN0dB_ex / 10);
p0 = Q(sqrt(2 * x));                 % erreur sur un bit sans codage
p  = Q(sqrt(2 * 4/7 * x));           % erreur sur un bit code (Ec = 4/7 Eb)
P_bloc_nc = (1 - p0)^4;              % bloc de 4 bits juste sans codage
P_bloc_c  = (1 - p)^7 + 7 * p * (1 - p)^6;   % mot juste apres correction (0 ou 1 erreur)
fprintf('A Eb/N0 = %d dB : p0 = %.4e (non code), p = %.4e (bit code)\n', EbN0dB_ex, p0, p);
fprintf('Bloc de 4 bits juste : sans codage %.6f, avec codage %.6f\n', P_bloc_nc, P_bloc_c);

%% Question 10 : TEB sans et avec codage, de 0 a 9 dB
EbN0dB_vec = 0:9;
Eb = A^2 * Tb;
Tc = 4 * Tb / 7;                     % duree d'un bit code (pour le cadencement Simulink)
Ac = A * sqrt(4/7);                  % amplitude d'un bit code : Ec = 4/7 Eb (meme Eb par bit utile)
% Comme dans le sujet, on garde L echantillons par bit code et la meme variance
% par echantillon sigma2 = N0 L / (2 Tb) : seule l'amplitude change. Apres
% l'integrateur, z = +/- A sqrt(4/7) + bruit de variance N0/2, donc
% p = Q( sqrt(2 * 4/7 * Eb/N0) ).

TEB_nc = zeros(size(EbN0dB_vec));    % sans codage
TEB_c  = zeros(size(EbN0dB_vec));    % avec codage
Nb     = zeros(size(EbN0dB_vec));

for i = 1:numel(EbN0dB_vec)
    N0 = Eb / 10^(EbN0dB_vec(i) / 10);
    xx = 10^(EbN0dB_vec(i) / 10);
    pp = Q(sqrt(2 * 4/7 * xx));
    Pb_approx = sum((2:7)/7 .* arrayfun(@(j) nchoosek(7, j), 2:7) .* pp.^(2:7) .* (1 - pp).^(7 - (2:7)));
    N = 4 * ceil(min(4e6, max(2e5, 300 / Pb_approx)) / 4);   % multiple de 4, assez d'erreurs
    Nb(i) = N;

    if avec_simulink
        % --- simulation par le modele Simulink de la chaine codee ---
        if ~exist('chaine_hamming.slx', 'file'), creer_chaine_hamming; end
        if ~exist('dec_mot_ok', 'var')
            % reglage une seule fois, sans bruit : decalage qui aligne les mots
            % de 7 bits a la reception (dec_mot) et retard global en bits (retard_h)
            sigma2 = 0;
            for dec_mot = 0:6
                out = sim('chaine_hamming', 'StopTime', '399');
                be = double(out.bits_emis(:)); br = double(out.bits_recus(:));
                retard_h = trouver_retard(be, br, 40);
                if sum(be(1:end-retard_h) ~= br(1+retard_h:end)) == 0, break; end
            end
            dec_mot_ok = dec_mot;
            fprintf('Chaine Hamming Simulink : dec_mot = %d, retard = %d bits\n', dec_mot, retard_h);
        end
        dec_mot = dec_mot_ok;
        sigma2 = N0 * L / (2 * Tb);                   % variance par echantillon
        N = min(N, 1e6);                              % limite la duree de simulation
        Nb(i) = N;
        out = sim('chaine_hamming', 'StopTime', num2str(N - 1));
        be = double(out.bits_emis(:));
        br = double(out.bits_recus(:));
        TEB_c(i) = mean(be(1:end-retard_h) ~= br(1+retard_h:end));
    else
        % --- meme chaine simulee en Matlab (L echantillons par bit code) ---
        err = 0; reste = N;
        while reste > 0
            n  = min(reste, 4 * 25000);
            b  = double(rand(1, n) < 0.5);            % bits d'information
            c  = hamming_code(b, G);                  % bits codes (7 pour 4)
            xc = Ac * (2 * c - 1);                    % +/- A sqrt(4/7)
            sigma2 = N0 * L / (2 * Tb);               % variance par echantillon
            rr = repmat(xc, L, 1) + sqrt(sigma2) * randn(L, numel(xc));
            z  = mean(rr, 1);                         % integrateur
            c_dec = double(z > 0);                    % decision
            b_dec = hamming_decode(c_dec, H);         % correction par syndrome
            err = err + sum(b_dec ~= b);
            reste = reste - n;
        end
        TEB_c(i) = err / N;
    end

    % chaine non codee (partie 3), meme methode
    err = 0; reste = N;
    while reste > 0
        n  = min(reste, 1e5);
        b  = double(rand(1, n) < 0.5);
        sigma2 = N0 * L / (2 * Tb);
        rr = repmat(A * (2 * b - 1), L, 1) + sqrt(sigma2) * randn(L, n);
        err = err + sum((mean(rr, 1) > 0) ~= b);
        reste = reste - n;
    end
    TEB_nc(i) = err / N;

    fprintf('Eb/N0 = %d dB : TEB sans codage = %.2e, avec codage = %.2e (%d bits)\n', ...
        EbN0dB_vec(i), TEB_nc(i), TEB_c(i), N);
end

% courbes theoriques
xdB = linspace(-2, 10, 400);
xl  = 10.^(xdB / 10);
TEB_nc_th = Q(sqrt(2 * xl));
pth = Q(sqrt(2 * 4/7 * xl));
TEB_c_th  = zeros(size(xl));   % approximation du sujet : j erreurs -> j bits faux
TEB_c_th2 = zeros(size(xl));   % plus realiste : le decodeur ajoute 1 erreur (j+1 bits faux)
for j = 2:7
    TEB_c_th  = TEB_c_th  + j/7 * nchoosek(7, j) * pth.^j .* (1 - pth).^(7 - j);
    TEB_c_th2 = TEB_c_th2 + min(j+1, 7)/7 * nchoosek(7, j) * pth.^j .* (1 - pth).^(7 - j);
end

R = 4/7;
lim_R   = 10 * log10((2^(2*R) - 1) / (2*R));   % limite de Shannon pour R = 4/7
lim_abs = 10 * log10(log(2));                  % limite absolue ln 2

figure;
semilogy(xdB, TEB_nc_th, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_vec, TEB_nc, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(xdB, TEB_c_th, 'r-', 'LineWidth', 1.5);
semilogy(xdB, TEB_c_th2, 'r--', 'LineWidth', 1.2);
semilogy(EbN0dB_vec, TEB_c, 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy([lim_R lim_R], [1e-7 1], 'k--', 'LineWidth', 1.2);
semilogy([lim_abs lim_abs], [1e-7 1], 'k:', 'LineWidth', 1.2);
grid on;
xlim([-2 10]); ylim([1e-7 1]);
xlabel('E_b/N_0 (dB)');
ylabel('TEB');
title('TEB sans et avec code de Hamming C(7,4)');
legend('sans codage : theorie', 'sans codage : simulation', ...
       'Hamming : approx. du sujet (j/7)', 'Hamming : approx. (j+1)/7', 'Hamming : simulation', ...
       sprintf('limite de Shannon R = 4/7 (%.2f dB)', lim_R), ...
       sprintf('limite absolue ln 2 (%.2f dB)', lim_abs), 'Location', 'southwest');

fprintf('\nLimite de Shannon pour R = 4/7 : %.2f dB\n', lim_R);
fprintf('Limite absolue ln 2 : %.2f dB\n', lim_abs);

%% Question 11 : seuil d'interet du codage et gain a TEB = 1e-4
fprintf('\n--- Question 11 ---\n');
% a partir des courbes theoriques (approximation du sujet puis approximation (j+1)/7)
courbes = {TEB_c_th, TEB_c_th2};
noms = {'approx. j/7', 'approx. (j+1)/7'};
for q = 1:2
    dd = log10(courbes{q}) - log10(TEB_nc_th);
    k = find(dd(1:end-1) > 0 & dd(2:end) <= 0, 1);
    x_croise = interp1(dd(k:k+1), xdB(k:k+1), 0);
    x_nc_4 = interp1(log10(TEB_nc_th), xdB, -4);
    x_c_4  = interp1(log10(courbes{q}), xdB, -4);
    fprintf('%s : codage avantageux au-dela de %.2f dB ; TEB = 1e-4 : %.2f dB -> %.2f dB, gain %.2f dB\n', ...
        noms{q}, x_croise, x_nc_4, x_c_4, x_nc_4 - x_c_4);
end
% a partir des points simules (interpolation en echelle log)
dd = log10(TEB_c) - log10(TEB_nc);
k = find(dd(1:end-1) > 0 & dd(2:end) <= 0, 1);
x_croise_sim = interp1(dd(k:k+1), EbN0dB_vec(k:k+1), 0);
x_nc_4_sim = interp1(log10(TEB_nc), EbN0dB_vec, -4);
x_c_4_sim  = interp1(log10(TEB_c),  EbN0dB_vec, -4);
fprintf('simulation : codage avantageux au-dela de %.2f dB ; TEB = 1e-4 : %.2f dB -> %.2f dB, gain %.2f dB\n', ...
    x_croise_sim, x_nc_4_sim, x_c_4_sim, x_nc_4_sim - x_c_4_sim);
fprintf('Ecart a la limite de Shannon (R = 4/7) a TEB = 1e-4 : %.2f dB\n', x_c_4_sim - lim_R);

%% Question 12 : latence et debit
fprintf('\n--- Question 12 ---\n');
fprintf('Debit sur le canal = 7/4 du debit utile (+%.0f %%)\n', 100 * (7/4 - 1));
fprintf('Latence minimale : codeur 4 Tb (attendre les 4 bits), decodeur 7 Tc = 4 Tb (attendre le mot)\n');

save('resultats_partie4.mat', 'EbN0dB_vec', 'TEB_nc', 'TEB_c', 'Nb', 'x_croise_sim', 'x_nc_4_sim', 'x_c_4_sim', 'lim_R', 'lim_abs');
