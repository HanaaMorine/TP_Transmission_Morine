function sortie = huffman_decode(bits, code)
% decodeur de Huffman
% bits = suite de '0' et '1'
% code{i} = mot du symbole i
% sortie = numeros des symboles retrouves

% --- 1) on construit l'arbre a partir des mots ---
fils = [0 0];   % fils(noeud,1) = branche 0, fils(noeud,2) = branche 1
feuille = 0;    % feuille(noeud) = numero du symbole (0 si pas une feuille)
nb = 1;         % nombre de noeuds (le noeud 1 est la racine)

for s = 1:numel(code)
    n = 1;   % on part de la racine
    for b = code{s}
        k = (b == '1') + 1;   % 1 pour '0', 2 pour '1'
        if fils(n, k) == 0    % la branche n'existe pas : on la cree
            nb = nb + 1;
            fils(nb, :) = [0 0];
            feuille(nb) = 0;
            fils(n, k) = nb;
        end
        n = fils(n, k);   % on descend
    end
    feuille(n) = s;   % au bout du mot : c'est le symbole s
end

% --- 2) on lit les bits un par un ---
sortie = zeros(1, numel(bits));
m = 0;   % nombre de symboles trouves
n = 1;   % on part de la racine
for i = 1:numel(bits)
    n = fils(n, (bits(i) == '1') + 1);   % on suit la branche
    if feuille(n) > 0                    % on est sur une feuille
        m = m + 1;
        sortie(m) = feuille(n);          % on note le symbole
        n = 1;                           % on repart de la racine
    end
end
sortie = sortie(1:m);   % on enleve les cases vides
end