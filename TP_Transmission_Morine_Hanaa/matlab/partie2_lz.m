%% PARTIE 2.5 - Lempel-Ziv (complement)
Parametres;
close all;

%% Question 10 : validation sur l'exemple du sujet

ex = 'ABAABABAABAB';
alpha = 'AB';                       % l'alphabet
[~, xex] = ismember(ex, alpha);     % A -> 1, B -> 2

[ind, let] = lz78_code(xex, 2);

% affichage des couples
fprintf('Couples LZ78 de %s :\n', ex);
for k = 1:numel(ind)
    fprintf('(%d,%c) ', ind(k), alpha(let(k)));
end
fprintf('\n');

% decodage et verification
xdec = lz78_decode(ind, let);
fprintf('Decode : %s   identique : %d (1 = oui)\n', alpha(xdec), isequal(xdec, xex));

%% Question 11 : nombre de bits par symbole

% cout du message : le i-eme couple coute ceil(log2(i)) + ceil(log2(M)) bits
cout = @(np, M) sum(ceil(log2(1:np))) + np * ceil(log2(M));

% --- sur le livre ---
texte = fileread('livre_propre.txt', 'Encoding', 'UTF-8');
symb = unique(double(texte));       % alphabet du livre
M = numel(symb);

morceaux = {texte, texte(1:5000)};
noms = {'livre complet', '5000 premiers car.'};
for t = 1:2
    [~, x] = ismember(double(morceaux{t}), symb);   % caracteres -> numeros
    [ind, let] = lz78_code(x, M);
    ok = isequal(lz78_decode(ind, let), x);          % verification
    bps = cout(numel(ind), M) / numel(x);            % bits par caractere
    fprintf('\n%s : %d couples, %.3f bits/car, decodage ok : %d\n', ...
        noms{t}, numel(ind), bps, ok);
end

% --- sur la source binaire tres desequilibree ---
p1e = P.p1_ext;
He = entropie_binaire(p1e);
Ns = [1e3 3e3 1e4 3e4 1e5 3e5 1e6];   % longueurs des messages
bps_bin = zeros(size(Ns));

fprintf('\nSource binaire p1 = %.2f (entropie %.4f)\n', p1e, He);
for j = 1:numel(Ns)
    xb = source(Ns(j), p1e) + 1;            % bits 0/1 -> symboles 1/2
    [ind, let] = lz78_code(xb, 2);
    bps_bin(j) = cout(numel(ind), 2) / Ns(j);
    fprintf('N = %7d : %.4f bit/bit\n', Ns(j), bps_bin(j));
end

% figure
figure;
semilogx(Ns, bps_bin, 'bo-', 'LineWidth', 1.5); hold on;
yline(He, 'r--', 'entropie H');
yline(1, 'k:', 'sans compression');
grid on;
xlabel('longueur du message (bits)');
ylabel('bits par bit de source');
title(sprintf('LZ78 sur la source binaire (p_1 = %.2f)', p1e));
legend('LZ78', 'Location', 'northeast');