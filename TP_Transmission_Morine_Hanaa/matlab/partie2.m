%% PARTIE 2 - Codage de source
% Lancer d'abord le script Parametres
Parametres;
close all;   % on ferme les anciennes figures

%% Question 2 : verification de la source et entropie

% --- a) frequence des 1 sur 10^5 bits ---
N = 1e5;                     % nombre de bits
b = source(N, p1);           % on genere les bits avec ma source
f1 = mean(b);                % proportion de 1 (moyenne des bits)

% intervalle de confiance a 95 % (formule de l'annexe du sujet)
IC = 1.96 * sqrt(f1 * (1 - f1) / N);

fprintf('Proba theorique p1      = %.4f\n', p1);
fprintf('Frequence mesuree des 1 = %.4f\n', f1);
fprintf('Intervalle de confiance = [%.4f ; %.4f]\n', f1 - IC, f1 + IC);

% --- b) entropie de ma source ---
H = entropie_binaire(p1);
fprintf('Entropie de la source H(p1) = %.4f bit/symbole\n', H);

% courbe H(p) pour p entre 0 et 1
p = linspace(0, 1, 501);
figure;
plot(p, entropie_binaire(p), 'LineWidth', 1.5); hold on;
plot(p1, H, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);  % ma source
grid on;
xlabel('p = P(bit = 1)');
ylabel('H(p) (bit/symbole)');
title('Entropie d''une source binaire');
legend('H(p)', sprintf('ma source : p_1 = %.2f', p1), 'Location', 'south');

% --- c) debit d'information ---
Db = 1;                      % la source emet 1 bit par seconde
Di = H * Db;                 % debit d'information
fprintf('Debit d''information = %.4f bit/s\n', Di);


%% Question 3 : entropie d'un texte

% mon livre (nettoye avec le script nettoyer_livre)
fichier = 'livre_propre.txt';
fprintf('\nTexte : Le tour du monde en quatre-vingts jours, Jules Verne\n');

texte = fileread(fichier, 'Encoding', 'UTF-8');   % on lit le texte
Nc = numel(texte);                                % nombre de caracteres
fprintf('Fichier : %s\n', fichier);
fprintf('Nombre de caracteres = %d\n', Nc);

% entropie du texte
[Ht, symb, pt] = entropie_empirique(double(texte));
M = numel(symb);   % nombre de caracteres differents
fprintf('Taille de l''alphabet = %d\n', M);
fprintf('Entropie du texte = %.4f bit/caractere\n', Ht);

% code de longueur fixe
nfixe = ceil(log2(M));   % bits necessaires pour M caracteres
fprintf('Code de longueur fixe = %d bits/caractere\n', nfixe);

% redondance par rapport a 8 bits par caractere
red8 = 1 - Ht / 8;
fprintf('Redondance par rapport a 8 bits = %.1f %%\n', 100 * red8);

% --- graphique des caracteres les plus frequents ---
[pt_tri, ordre] = sort(pt, 'descend');   % du plus frequent au moins frequent
symb_tri = symb(ordre);
K = min(20, M);   % on garde les 20 premiers

% on donne un nom aux caracteres invisibles
noms = cell(1, K);
for i = 1:K
    c = symb_tri(i);
    if c == 32
        noms{i} = 'esp';   % espace
    elseif c == 10
        noms{i} = '\n';    % retour a la ligne
    elseif c == 13
        noms{i} = '\r';    % retour chariot
    else
        noms{i} = char(c); % lettre normale
    end
end

% trace
figure;
bar(100 * pt_tri(1:K));
set(gca, 'XTick', 1:K, 'XTickLabel', noms, 'TickLabelInterpreter', 'none');
grid on;
xlabel('caractere');
ylabel('frequence (%)');
title(sprintf('Les %d caracteres les plus frequents du livre', K));



%% Question 4 : code de Huffman et validation

pex = [0.4 0.2 0.2 0.1 0.1];   % probas du sujet
cex = huffman_code(pex);        % on construit le code

% on affiche le code
fprintf('\nCode de Huffman de l''exemple :\n');
for i = 1:numel(pex)
    fprintf('  symbole %d  (p = %.1f)  ->  %s\n', i, pex(i), cex{i});
end

lg = cellfun(@length, cex);     % longueur des mots

% test 1 : code prefixe ?
prefixe = true;
for i = 1:numel(cex)
    for j = 1:numel(cex)
        % le mot i est il le debut du mot j ?
        if i ~= j && strncmp(cex{j}, cex{i}, lg(i))
            prefixe = false;
        end
    end
end
fprintf('Code prefixe : %d (1 = oui)\n', prefixe);

% test 2 : somme de Kraft
kraft = sum(2 .^ (-lg));
fprintf('Somme de Kraft = %.4f\n', kraft);

% test 3 : longueur moyenne
Lmoy = sum(pex(:) .* lg);
fprintf('Longueur moyenne = %.2f bits (attendu 2,2)\n', Lmoy);

% entropie pour comparer
Hex = -sum(pex .* log2(pex));
fprintf('Entropie = %.4f bits\n', Hex);

% comparaison avec la fonction de matlab (si elle existe)
if exist('huffmandict', 'file')
    [~, Lmat] = huffmandict(1:5, pex);
    fprintf('Longueur moyenne avec huffmandict = %.2f bits\n', Lmat);
else
    fprintf('Communications Toolbox pas disponible\n');
end


%% Question 5 : code de Huffman du livre

% on reprend le livre de la question 3
% symb = les caracteres, pt = leurs probas, Ht = entropie

code_txt = huffman_code(pt);             % code de Huffman du livre
lg_txt = cellfun(@length, code_txt);     % longueur de chaque mot

% longueur moyenne et efficacite
Lmoy_txt = sum(pt .* lg_txt);
eff = Ht / Lmoy_txt;
fprintf('\nLongueur moyenne Huffman = %.4f bits/caractere\n', Lmoy_txt);
fprintf('Efficacite H/L = %.4f\n', eff);

% verification H <= L < H+1
ok = (Ht <= Lmoy_txt) && (Lmoy_txt < Ht + 1);
fprintf('H <= L < H+1 : %d (1 = oui)\n', ok);

% --- codeur ---
[~, idx] = ismember(double(texte), symb);   % numero de chaque caractere
bits = [code_txt{idx}];                     % on colle tous les mots
fprintf('Nombre de bits apres codage = %d\n', numel(bits));

% --- decodeur ---
idx_dec = huffman_decode(bits, code_txt);   % on retrouve les numeros
texte_dec = char(symb(idx_dec))';           % on retrouve les caracteres

% on verifie que le texte est le meme
fprintf('Texte retrouve sans erreur : %d (1 = oui)\n', isequal(texte_dec, texte));

% --- taux de compression ---
bits_8 = 8 * Nc;             % taille avec 8 bits par caractere
bits_fixe = nfixe * Nc;      % taille avec le code fixe (7 bits)
fprintf('Taille 8 bits/car      = %d bits\n', bits_8);
fprintf('Taille code fixe       = %d bits\n', bits_fixe);
fprintf('Taille Huffman         = %d bits\n', numel(bits));
fprintf('Taux de compression / 8 bits     = %.1f %%\n', 100 * (1 - numel(bits) / bits_8));
fprintf('Taux de compression / code fixe  = %.1f %%\n', 100 * (1 - numel(bits) / bits_fixe));


%% Question 6 : cout de la table de codage

% pour chaque caractere on envoie :
%  - le caractere (16 bits pour avoir aussi les accents)
%  - la longueur de son mot
%  - le mot lui-meme
bits_car  = 16;                                % bits pour un caractere
bits_long = ceil(log2(max(lg_txt) + 1));       % bits pour la longueur
table = M * (bits_car + bits_long) + sum(lg_txt);   % cout total

fprintf('\nCout de la table = %d bits\n', table);
fprintf('Part de la table pour mon livre = %.3f %%\n', 100 * table / numel(bits));

% longueur de texte pour que la table fasse moins de 1 %
Nmin = table / (0.01 * Lmoy_txt);
fprintf('Table negligeable (< 1 %%) a partir de %.0f caracteres\n', Nmin);

% --- courbe : bits par caractere en comptant la table ---
Nvec = logspace(1, 7, 200);              % longueurs de texte de 10 a 10^7
Ltot = Lmoy_txt + table ./ Nvec;         % cout moyen par caractere avec la table

figure;
semilogx(Nvec, Ltot, 'LineWidth', 1.5); hold on;
yline(Lmoy_txt, 'r--', 'Huffman sans table');
yline(8, 'k:', '8 bits/car');
xline(Nc, 'g-', 'mon livre');
grid on;
ylim([0 20]);
xlabel('nombre de caracteres du texte');
ylabel('bits par caractere');
title('Cout de Huffman en comptant la table');


%% Question 7 : extension de la source (blocs de k bits)

p1e = P.p1_ext;              % ma source tres desequilibree
He  = entropie_binaire(p1e); % son entropie
fprintf('\np1_ext = %.2f   entropie = %.4f bit\n', p1e, He);

kmax = 10;
Lth  = zeros(1, kmax);   % longueur moyenne par bit (calcul)
Lmes = zeros(1, kmax);   % longueur moyenne par bit (mesure)

Nb = 1e5;                     % bits de source pour verifier
bsrc = source(Nb, p1e);       % on genere les bits

for k = 1:kmax
    % tous les paquets possibles de k bits (un paquet par ligne)
    blocs = dec2bin(0:2^k-1) - '0';
    w = sum(blocs, 2);                        % nombre de 1 dans chaque paquet
    pk = p1e.^w .* (1-p1e).^(k-w);            % proba de chaque paquet

    ck = huffman_code(pk);                    % code de Huffman des paquets
    lk = cellfun(@length, ck);                % longueur des mots
    Lth(k) = sum(pk .* lk) / k;               % longueur moyenne par bit de source

    % verification : on code vraiment les bits
    Nk = floor(Nb / k) * k;                   % on garde un multiple de k
    paquets = reshape(bsrc(1:Nk), k, []);     % on coupe en paquets de k bits
    num = 2.^(k-1:-1:0) * paquets + 1;        % numero de chaque paquet
    bits_k = [ck{num}];                       % on code
    Lmes(k) = numel(bits_k) / Nk;             % bits par bit de source

    fprintf('k = %2d   L/k calcule = %.4f   L/k mesure = %.4f\n', k, Lth(k), Lmes(k));
end

% --- figure ---
kk = 1:kmax;
figure;
plot(kk, Lth, 'bo-', 'LineWidth', 1.5); hold on;
plot(kk, Lmes, 'rx', 'MarkerSize', 10, 'LineWidth', 1.5);
plot(kk, He * ones(1, kmax), 'k--', 'LineWidth', 1.2);
plot(kk, He + 1 ./ kk, 'g-.', 'LineWidth', 1.2);
grid on;
xlabel('k (taille des paquets)');
ylabel('bits par bit de source');
title(sprintf('Extension de la source (p_1 = %.2f)', p1e));
legend('L_k/k calcule', 'L_k/k mesure (10^5 bits)', 'entropie H', 'borne H + 1/k');

%% Question 8 : sources avec memoire et compresseurs

% on compare le livre complet et ses 5000 premiers caracteres
textes   = {texte, texte(1:5000)};
noms     = {'livre complet', '5000 premiers car.'};
fichiers = {'q8_complet.txt', 'q8_debut.txt'};

R = zeros(2, 5);   % resultats en bits par caractere

for t = 1:2
    x = double(textes{t});   % le texte en nombres
    n = numel(x);            % nombre de caracteres

    % entropie d'ordre 0 (lettres seules)
    [H0, ~, pp] = entropie_empirique(x);

    % code de longueur fixe
    nf = ceil(log2(numel(pp)));

    % Huffman lettre par lettre
    cc = huffman_code(pp);
    Lh = sum(pp .* cellfun(@length, cc));

    % entropie des paires de lettres qui se suivent
    paires = x(1:end-1) * 1e5 + x(2:end);   % un numero unique par paire
    H2 = entropie_empirique(paires) / 2;    % divise par 2 : par caractere

    % gzip : on ecrit le texte dans un fichier puis on le compresse
    fid = fopen(fichiers{t}, 'w', 'n', 'UTF-8');
    fprintf(fid, '%s', textes{t});
    fclose(fid);
    gzip(fichiers{t});                       % cree le fichier .gz
    info = dir([fichiers{t} '.gz']);         % on lit sa taille
    Lgz = 8 * info.bytes / n;                % bits par caractere

    R(t, :) = [nf H0 Lh H2 Lgz];

    % affichage
    fprintf('\n--- %s (%d caracteres) ---\n', noms{t}, n);
    fprintf('Code fixe         = %.3f bits/car\n', nf);
    fprintf('Entropie ordre 0  = %.3f bits/car\n', H0);
    fprintf('Huffman           = %.3f bits/car\n', Lh);
    fprintf('H(X1X2)/2         = %.3f bits/car\n', H2);
    fprintf('gzip              = %.3f bits/car\n', Lgz);
end

% --- figure de comparaison ---
figure;
bar(R');
set(gca, 'XTickLabel', {'code fixe', 'H ordre 0', 'Huffman', 'H(X1X2)/2', 'gzip'});
grid on;
ylabel('bits par caractere');
legend(noms);
title('Comparaison des methodes de compression');

%% Question 9 : les bits en sortie de Huffman

% --- bits du livre compresse par Huffman (question 5) ---
bh = bits - '0';                     % on passe de '0'/'1' a 0/1
f1h = mean(bh);                      % proportion de 1

% entropie des paires de bits (00, 01, 10, 11)
nn = floor(numel(bh) / 2) * 2;       % nombre pair de bits
paires_h = 2 * bh(1:2:nn) + bh(2:2:nn);   % numero de chaque paire (0 a 3)
H2h = entropie_empirique(paires_h) / 2;   % par bit

fprintf('\n--- Bits en sortie de Huffman ---\n');
fprintf('Proportion de 1        = %.4f\n', f1h);
fprintf('Entropie des paires /2 = %.4f bit par bit\n', H2h);

% --- pour comparer : bits du livre NON compresse (8 bits par octet) ---
octets = unicode2native(texte, 'UTF-8');          % le livre en octets
b8 = dec2bin(octets, 8)' - '0';                   % chaque octet en 8 bits
b8 = b8(:)';                                      % une seule ligne de bits
f1_8 = mean(b8);

nn8 = floor(numel(b8) / 2) * 2;
paires_8 = 2 * b8(1:2:nn8) + b8(2:2:nn8);
H2_8 = entropie_empirique(paires_8) / 2;

fprintf('\n--- Bits du livre non compresse (8 bits) ---\n');
fprintf('Proportion de 1        = %.4f\n', f1_8);
fprintf('Entropie des paires /2 = %.4f bit par bit\n', H2_8);