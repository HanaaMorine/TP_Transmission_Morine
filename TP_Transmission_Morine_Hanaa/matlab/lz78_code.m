function [indices, lettres] = lz78_code(x, M)
% codeur LZ78
% x = suite de symboles (numeros de 1 a M)
% M = taille de l'alphabet
% indices(k), lettres(k) = le k-ieme couple (phrase connue, symbole ajoute)

dico = containers.Map('KeyType', 'double', 'ValueType', 'double');  % dictionnaire
nb = 0;   % nombre de phrases dans le dictionnaire

indices = zeros(1, numel(x));
lettres = zeros(1, numel(x));
np = 0;   % nombre de couples envoyes
n = 0;    % phrase en cours (0 = phrase vide)

for i = 1:numel(x)
    s = x(i);
    cle = n * (M + 1) + s;   % un numero unique pour "phrase n + symbole s"
    if isKey(dico, cle)
        n = dico(cle);       % deja vu : on continue la phrase
    else
        % nouveau : on envoie le couple (n, s)
        np = np + 1;
        indices(np) = n;
        lettres(np) = s;
        % on ajoute la nouvelle phrase au dictionnaire
        nb = nb + 1;
        dico(cle) = nb;
        n = 0;               % on repart de la phrase vide
    end
end

% si le message se termine au milieu d'une phrase deja connue
if n > 0
    np = np + 1;
    indices(np) = n;
    lettres(np) = 0;         % 0 = pas de symbole ajoute
end

indices = indices(1:np);     % on enleve les cases vides
lettres = lettres(1:np);
end