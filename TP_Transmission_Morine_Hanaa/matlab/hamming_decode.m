function [m, ncorr, s] = hamming_decode(r, H)
% decodeur de Hamming par syndrome
% r     : bits recus (vecteur de longueur multiple de 7, ou une ligne par mot)
% m     : messages decodes (4 bits par mot, meme forme que r)
% ncorr : nombre de mots ou une correction a ete faite
% s     : syndromes (une ligne par mot)
if nargin < 2, [~, H] = hamming_matrices(); end
vecteur = isvector(r);
if vecteur
    R = reshape(r(:), 7, []).';     % on decoupe en mots de 7 bits (une ligne = un mot)
else
    R = r;                          % deja une ligne par mot
end

s = mod(R * H.', 2);                % syndrome de chaque mot (3 bits)

% le syndrome d'une erreur en position j est la colonne j de H
% numero du syndrome : s0 + 2 s1 + 4 s2 (entre 0 et 7)
num_s   = s * [1; 2; 4];
num_col = H.' * [1; 2; 4];          % numero de chaque colonne de H
pos = zeros(8, 1);                  % pos(num+1) = position de l'erreur
pos(num_col + 1) = 1:7;

p = pos(num_s + 1);                 % position a corriger (0 = pas d'erreur)
idx = find(p > 0);
R(sub2ind(size(R), idx, p(idx))) = 1 - R(sub2ind(size(R), idx, p(idx)));   % on inverse le bit faux
ncorr = numel(idx);

M = R(:, 1:4);                      % le message est en tete du mot (code systematique)
if vecteur
    m = reshape(M.', 1, []);
else
    m = M;
end
end
