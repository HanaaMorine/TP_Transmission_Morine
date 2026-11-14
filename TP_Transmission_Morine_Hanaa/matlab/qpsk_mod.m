function s = qpsk_mod(b, mapping)
% modulateur QPSK en bande de base equivalente, energie par symbole Es = 1
% b       : bits (longueur paire), regroupes par deux [b0 b1]
% mapping : 'gray' (par defaut) ou 'naturel'
% s       : symboles complexes exp(j k pi/4), k = 1, 3, 5, 7
%
% Gray    : 00 -> k=1, 01 -> k=3, 11 -> k=5, 10 -> k=7
% naturel : 00 -> k=1, 01 -> k=3, 10 -> k=5, 11 -> k=7
if nargin < 2, mapping = 'gray'; end
B  = reshape(b(:), 2, []);           % une colonne = un couple [b0; b1]
b0 = B(1, :);  b1 = B(2, :);
if strcmp(mapping, 'gray')
    k = 1 + 2 * (2 * b0 + xor(b0, b1));   % 00->1, 01->3, 11->5, 10->7
else
    k = 1 + 2 * (2 * b0 + b1);            % 00->1, 01->3, 10->5, 11->7
end
s = exp(1j * k * pi / 4);
end
