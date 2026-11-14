function c = hamming_code(m, G)
% codeur de Hamming (produit matriciel modulo 2)
% m : - soit un vecteur de bits (longueur multiple de 4)
%       -> c est un vecteur ligne de bits codes (7 bits par message)
%     - soit une matrice a 4 colonnes (une ligne = un message [m0 m1 m2 m3])
%       -> c est une matrice a 7 colonnes (une ligne = un mot-code)
if nargin < 2, G = hamming_matrices(); end
if isvector(m)
    M = reshape(m(:), 4, []).';   % on decoupe en messages de 4 bits
    C = mod(M * G, 2);            % mots-codes
    c = reshape(C.', 1, []);      % on remet bout a bout
else
    c = mod(m * G, 2);
end
end
