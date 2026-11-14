%% PARTIE 6 - Filtre de mise en forme et filtre adapte (approfondissement)
% QPSK (Gray), L echantillons par symbole, filtres a energie unite :
% a l'instant optimal, sans bruit ni IES, l'echantillon vaut le symbole emis.
% Les filtres sont realises comme dans un bloc Discrete FIR Filter (fonction filter).
Parametres;
close all;
Q  = @(x) 0.5 * erfc(x / sqrt(2));
Es = 1; Eb = Es / 2;                 % QPSK : 2 bits par symbole
span = 10;                           % troncature : 10 symboles, N = 10 L + 1
alpha = P.alpha;                     % mon roll-off (0,35)
EbN0dB_vec = 0:9;

h_porte = ones(1, L) / sqrt(L);      % filtre porte d'energie unite
h_rrc   = rrc_coeffs(alpha, L, span);

%% Question 1 : filtre porte = detecteur optimal de la partie 3
% porte (emission) * porte (reception) puis echantillonnage a la fin du symbole
% = moyenne des L echantillons du symbole = integrateur + echantillonneur
fprintf('\n--- Question 1 : filtre porte ---\n');
b = double(rand(1, 2e4) < 0.5);
bd = chaine_mise_en_forme(b, h_porte, L, 0);
fprintf('Sans bruit, filtre porte : erreurs = %d\n', sum(bd ~= b));

%% Question 2 : coefficients du filtre RRC et valeurs limites
fprintf('\n--- Question 2 : filtre RRC (alpha = %.2f, N = %d coefficients) ---\n', alpha, numel(h_rrc));
h0   = 1 - alpha + 4*alpha/pi;                                            % h(0) * sqrt(T)
hlim = alpha/sqrt(2) * ((1 + 2/pi)*sin(pi/(4*alpha)) + (1 - 2/pi)*cos(pi/(4*alpha)));
fprintf('h(0) = (1 - a + 4a/pi)/sqrt(T) = %.4f\n', h0);
fprintf('h(+/- T/(4a)) = a/sqrt(2T) [(1+2/pi) sin(pi/4a) + (1-2/pi) cos(pi/4a)] = %.4f\n', hlim);
fprintf('Energie du filtre = %.4f, symetrique : %d\n', sum(h_rrc.^2), max(abs(h_rrc - fliplr(h_rrc))) < 1e-12);
bd = chaine_mise_en_forme(b, h_rrc, L, 0);
fprintf('Sans bruit, filtre RRC : erreurs = %d\n', sum(bd ~= b));

%% Question 3 : h et h*h, annulation aux multiples de T
g = conv(h_rrc, h_rrc);              % cosinus sureleve (tronque)
tg = (-(numel(g)-1)/2 : (numel(g)-1)/2) / L;
th = (-(numel(h_rrc)-1)/2 : (numel(h_rrc)-1)/2) / L;
kT = (numel(g)+1)/2 + (-span:span)*L;     % indices des instants kT
gk = g(kT);
hk = h_rrc((numel(h_rrc)+1)/2 + (-span/2:span/2)*L);
fprintf('\n--- Question 3 ---\n');
fprintf('h*h en 0 : %.4f ; max |h*h(kT)|, k ~= 0 : %.2e\n', max(gk), max(abs(gk(abs(gk) < 0.5))));
fprintf('h seul : max |h(kT)|, k ~= 0 : %.3f (ne s''annule pas)\n', max(abs(hk(abs(hk) < max(hk)))) * sqrt(L));

figure('Position', [100 100 900 360]);
subplot(1, 2, 1);
plot(th, h_rrc * sqrt(L), 'b-', 'LineWidth', 1.5); hold on;
plot(th(1:L:end), h_rrc(1:L:end) * sqrt(L), 'ro', 'MarkerSize', 5);
grid on; xlim([-5 5]);
xlabel('t / T'); ylabel('h(t) \surd T');
title(sprintf('Filtre RRC h (\\alpha = %.2f)', alpha));
subplot(1, 2, 2);
plot(tg, g, 'b-', 'LineWidth', 1.5); hold on;
plot(tg(kT), gk, 'ro', 'MarkerSize', 5);
grid on; xlim([-5 5]);
xlabel('t / T'); ylabel('h*h(t)');
title('h * h : cosinus sureleve');

%% Question 4 : densites spectrales de puissance (porte et RRC)
Ns = 2e4;
s  = qpsk_mod(double(rand(1, 2*Ns) < 0.5), 'gray');
x  = zeros(1, Ns*L); x(1:L:end) = s;
Nfft = 1024;
w = 0.5 - 0.5*cos(2*pi*(0:Nfft-1)/Nfft);          % fenetre de Hann
f = (-Nfft/2 : Nfft/2 - 1) / Nfft * L;            % frequence normalisee f*T
noms_f = {'porte', 'RRC'};
filtres = {h_porte, h_rrc};
DSP = zeros(2, Nfft);
B99 = zeros(1, 2);
B40 = zeros(1, 2);
for q = 1:2
    xe = filter(filtres{q}, 1, x);
    nseg = floor(numel(xe) / Nfft);
    acc = zeros(1, Nfft);
    for k = 1:nseg
        seg = xe((k-1)*Nfft + (1:Nfft)) .* w;
        acc = acc + abs(fftshift(fft(seg))).^2;
    end
    DSP(q, :) = acc / nseg;
    DSP(q, :) = DSP(q, :) / max(DSP(q, :));
    % bande occupee a 99 % de la puissance (bilaterale -> on donne la moitie)
    p = cumsum(DSP(q, :)) / sum(DSP(q, :));
    B99(q) = (f(find(p >= 0.995, 1)) - f(find(p >= 0.005, 1))) / 2;
    % frequence la plus haute ou la DSP depasse encore -40 dB
    B40(q) = max(abs(f(DSP(q, :) > 1e-4)));
end
fprintf('\n--- Question 4 ---\n');
fprintf('Bande a 99 %% : porte %.2f / T, RRC %.3f / T (theorie (1+a)/2T = %.3f / T)\n', ...
    B99(1), B99(2), (1 + alpha) / 2);
fprintf('Bande a -40 dB : porte %.2f / T (limite du calcul : L/2T), RRC %.3f / T\n', B40(1), B40(2));

figure;
plot(f, 10*log10(DSP(1, :) + 1e-12), 'r-', 'LineWidth', 1.2); hold on;
plot(f, 10*log10(DSP(2, :) + 1e-12), 'b-', 'LineWidth', 1.5);
plot([1 1] * (1 + alpha)/2, [-80 5], 'k--');
plot(-[1 1] * (1 + alpha)/2, [-80 5], 'k--');
grid on; xlim([-3 3]); ylim([-70 5]);
xlabel('f T'); ylabel('DSP normalisee (dB)');
title('Densite spectrale du signal emis');
legend('porte', sprintf('RRC \\alpha = %.2f', alpha), '\pm(1+\alpha)/2T', 'Location', 'south');

%% Question 5 : TEB avec porte et RRC, diagramme de l'oeil, constellation
TEB_porte = zeros(size(EbN0dB_vec));
TEB_rrc   = zeros(size(EbN0dB_vec));
for i = 1:numel(EbN0dB_vec)
    N0 = Eb / 10^(EbN0dB_vec(i)/10);
    q  = Q(sqrt(2 * 10^(EbN0dB_vec(i)/10)));
    N  = 2 * ceil(min(1e6, max(1e5, 200 / q)) / 2);
    e1 = 0; e2 = 0; reste = N;
    while reste > 0
        n = min(reste, 1e5);
        b = double(rand(1, n) < 0.5);
        e1 = e1 + sum(chaine_mise_en_forme(b, h_porte, L, N0) ~= b);
        e2 = e2 + sum(chaine_mise_en_forme(b, h_rrc,   L, N0) ~= b);
        reste = reste - n;
    end
    TEB_porte(i) = e1 / N;
    TEB_rrc(i)   = e2 / N;
    fprintf('Eb/N0 = %d dB : TEB porte = %.2e, RRC = %.2e (%d bits)\n', EbN0dB_vec(i), TEB_porte(i), TEB_rrc(i), N);
end
xdB = linspace(0, 10, 200);
figure;
semilogy(xdB, Q(sqrt(2 * 10.^(xdB/10))), 'k-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_vec, TEB_porte, 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(EbN0dB_vec, TEB_rrc, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('QPSK avec filtres de mise en forme');
legend('theorie Q(sqrt(2E_b/N_0))', 'porte (simulation)', sprintf('RRC \\alpha = %.2f (simulation)', alpha), 'Location', 'southwest');

% diagramme de l'oeil (voie I, sans bruit) et constellation a 10 dB
b = double(rand(1, 2000) < 0.5);
[~, ~, y, D] = chaine_mise_en_forme(b, h_rrc, L, 0);
N0 = Eb / 10^(10/10);
[~, z10] = chaine_mise_en_forme(b, h_rrc, L, N0);
figure('Position', [100 100 900 360]);
subplot(1, 2, 1);
tt = (-L : L) / L;                                % deux symboles autour de l'instant optimal
for k = 20:400
    c = D + 1 + k*L;
    plot(tt, real(y(c - L : c + L)), 'b-'); hold on;
end
plot([0 0], [-1.5 1.5], 'r--');
grid on; xlabel('t / T (0 = instant optimal)'); ylabel('voie I');
title(sprintf('Diagramme de l''oeil, RRC \\alpha = %.2f', alpha));
subplot(1, 2, 2);
plot(real(z10), imag(z10), '.', 'MarkerSize', 4); hold on;
plot(real(exp(1j*(1:2:7)*pi/4)), imag(exp(1j*(1:2:7)*pi/4)), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
axis([-1.5 1.5 -1.5 1.5]); axis square; grid on;
xlabel('I'); ylabel('Q'); title('Constellation, E_b/N_0 = 10 dB');

%% Question 6 : decalage de l'instant d'echantillonnage de T/4
fprintf('\n--- Question 6 : decalage T/4 ---\n');
alphas6 = [0.22 1];
EbN0_6 = 6;
N0 = Eb / 10^(EbN0_6/10);
TEB6 = zeros(2, 2);
figure('Position', [100 100 900 360]);
for q = 1:2
    hq = rrc_coeffs(alphas6(q), L, span);
    N = 4e5; e0 = 0; e4 = 0;
    for r = 1:4
        b = double(rand(1, N/4) < 0.5);
        e0 = e0 + sum(chaine_mise_en_forme(b, hq, L, N0, 1, 0) ~= b);
        e4 = e4 + sum(chaine_mise_en_forme(b, hq, L, N0, 1, L/4) ~= b);
    end
    TEB6(q, :) = [e0 e4] / N;
    fprintf('alpha = %.2f, Eb/N0 = %d dB : TEB instant optimal = %.2e, decale de T/4 = %.2e\n', ...
        alphas6(q), EbN0_6, TEB6(q, 1), TEB6(q, 2));
    % oeil sans bruit
    b = double(rand(1, 2000) < 0.5);
    [~, ~, y, D] = chaine_mise_en_forme(b, hq, L, 0);
    subplot(1, 2, q);
    for k = 20:400
        c = D + 1 + k*L;
        plot(tt, real(y(c - L : c + L)), 'b-'); hold on;
    end
    plot([0 0], [-1.5 1.5], 'r--'); plot([1 1]/4, [-1.5 1.5], 'k-', 'LineWidth', 1.5);
    grid on; xlabel('t / T'); ylabel('voie I');
    title(sprintf('Oeil, \\alpha = %.2f (trait noir : T/4)', alphas6(q)));
end
th_q = Q(sqrt(2 * 10^(EbN0_6/10)));
fprintf('TEB theorique a %d dB : %.2e\n', EbN0_6, th_q);

save('resultats_partie6.mat', 'EbN0dB_vec', 'TEB_porte', 'TEB_rrc', 'B99', 'TEB6');
