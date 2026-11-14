%% PARTIE 7 - Complement : canal a deux trajets (echo)
% h_c(t) = delta(t) + beta * delta(t - tau), tau multiple de la duree symbole T
% chaine : QPSK (Gray) + filtre RRC a l'emission + canal + bruit + filtre adapte
Parametres;
close all;
Q  = @(x) 0.5 * erfc(x / sqrt(2));
Es = 1; Eb = Es / 2;
span  = 10;
alpha = P.alpha;                      % 0,35
beta  = P.beta;                       % amplitude de l'echo (0,23)
tau   = P.retard_trajet;              % retard de l'echo en symboles (2)
h  = rrc_coeffs(alpha, L, span);
hc = [1, zeros(1, tau*L - 1), beta];  % reponse du canal en echantillons
EbN0dB_vec = 0:9;
fprintf('Echo : beta = %.2f, tau = %d T\n', beta, tau);

%% Question 1 : diagramme de l'oeil et TEB avec l'echo
% reponse globale echantillonnee aux instants kT : h*hc*h
gtot = conv(conv(h, hc), h);
c0   = numel(h);                                  % indice de l'instant 0 (retard N-1)
gk   = gtot(c0 + (0:2*tau) * L);
fprintf('Reponse globale aux instants kT, k = 0..%d : %s\n', 2*tau, mat2str(round(gk*1000)/1000));
fprintf('-> la valeur %.2f en k = %d : le critere de Nyquist n''est plus verifie\n', beta, tau);

TEB_ideal = zeros(size(EbN0dB_vec));
TEB_echo  = zeros(size(EbN0dB_vec));
for i = 1:numel(EbN0dB_vec)
    N0 = Eb / 10^(EbN0dB_vec(i)/10);
    N  = 4e5;
    e1 = 0; e2 = 0;
    for r = 1:4
        b = double(rand(1, N/4) < 0.5);
        e1 = e1 + sum(chaine_mise_en_forme(b, h, L, N0, 1)  ~= b);
        e2 = e2 + sum(chaine_mise_en_forme(b, h, L, N0, hc) ~= b);
    end
    TEB_ideal(i) = e1 / N;
    TEB_echo(i)  = e2 / N;
    fprintf('Eb/N0 = %d dB : TEB canal ideal = %.2e, avec echo = %.2e\n', EbN0dB_vec(i), TEB_ideal(i), TEB_echo(i));
end

% TEB theorique avec echo : sur chaque voie, z = a + beta * a' + bruit,
% a' = symbole emis tau symboles plus tot (+/- 1/sqrt(2), equiprobable)
xdB = linspace(0, 10, 200);
sig = sqrt(Eb ./ 10.^(xdB/10) / 2);               % ecart-type du bruit par voie (N0/2)
a   = 1/sqrt(2);
TEB_echo_th = 0.5 * (Q(a*(1 + beta) ./ sig) + Q(a*(1 - beta) ./ sig));

figure('Position', [100 100 900 360]);
subplot(1, 2, 1);
b = double(rand(1, 2000) < 0.5);
[~, ~, y, D] = chaine_mise_en_forme(b, h, L, 0, hc);
tt = (-L : L) / L;
for k = 20:400
    c = D + 1 + k*L;
    plot(tt, real(y(c - L : c + L)), 'b-'); hold on;
end
plot([0 0], [-1.5 1.5], 'r--');
grid on; xlabel('t / T'); ylabel('voie I');
title(sprintf('Oeil avec echo (\\beta = %.2f, \\tau = %dT)', beta, tau));
subplot(1, 2, 2);
semilogy(xdB, Q(sqrt(2 * 10.^(xdB/10))), 'k-', 'LineWidth', 1.5); hold on;
semilogy(xdB, TEB_echo_th, 'r-', 'LineWidth', 1.5);
semilogy(EbN0dB_vec, TEB_ideal, 'ko', 'MarkerSize', 6, 'LineWidth', 1.2);
semilogy(EbN0dB_vec, TEB_echo, 'rs', 'MarkerSize', 6, 'LineWidth', 1.2);
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('TEB avec et sans echo');
legend('sans echo (theorie)', 'avec echo (theorie)', 'sans echo (simu.)', 'avec echo (simu.)', 'Location', 'southwest');

%% Question 3 : transmission d'un texte (chaine complete, canal ideal)
% caracteres -> octets -> bits -> [Hamming] -> QPSK + RRC -> canal -> ... -> texte recu
fid = fopen('texte_fr.txt', 'r');
octets = fread(fid, 600, 'uint8=>double').';      % debut du texte (600 octets UTF-8)
fclose(fid);
bits = reshape(dec2bin(octets, 8).' - '0', 1, []);
[G, H] = hamming_matrices();
fprintf('\n--- Question 3 : texte de %d octets (%d bits) ---\n', numel(octets), numel(bits));
textes = struct('EbN0', {}, 'code', {}, 'TEB', {}, 'texte', {});
for EbN0dB = [3 6]
    N0 = Eb / 10^(EbN0dB/10);
    for avec_code = [0 1]
        if avec_code
            c = hamming_code(bits, G);
            if mod(numel(c), 2), c = [c 0]; end              % nombre pair pour la QPSK
            cd_ = chaine_mise_en_forme(c, h, L, N0 * 7/4);   % meme Eb par bit utile : Ec = 4/7 Eb
            br = hamming_decode(cd_(1:7*numel(bits)/4), H);
        else
            br = chaine_mise_en_forme(bits, h, L, N0);
        end
        teb = mean(br ~= bits);
        oct = bin2dec(char(reshape(br, 8, []).' + '0')).';
        txt = octets_vers_texte(oct);
        textes(end+1) = struct('EbN0', EbN0dB, 'code', avec_code, 'TEB', teb, 'texte', txt);
        noms_code = {'sans codage', 'avec Hamming'};
        fprintf('\nEb/N0 = %d dB, %s : TEB = %.4f\n', EbN0dB, noms_code{avec_code + 1}, teb);
        fprintf('%s\n', txt(1:min(160, numel(txt))));
    end
end
save('resultats_partie7.mat', 'EbN0dB_vec', 'TEB_ideal', 'TEB_echo', 'gk', 'textes');

