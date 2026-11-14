function [G, H, P, restes] = hamming_matrices()
% matrices du code de Hamming C(7,4) cyclique, g(x) = 1 + x + x^3
% forme systematique : c = [m0 m1 m2 m3 | r0 r1 r2], r(x) = x^3 m(x) mod g(x)
% les polynomes sont ecrits par puissances croissantes : [a0 a1 a2 ...]

g = [1 1 0 1];          % g(x) = 1 + x + x^3
restes = zeros(4, 3);   % reste pour chaque message de poids 1

for i = 0:3
    % message de poids 1 : m(x) = x^i, donc x^3 m(x) = x^(i+3)
    num = zeros(1, i + 4);
    num(end) = 1;
    restes(i+1, :) = reste_mod2(num, g);
end

P = restes;                  % ligne i = reste de x^3 * x^(i-1)
G = [eye(4) P];              % matrice generatrice systematique
H = [P' eye(3)];             % matrice de controle
end

function r = reste_mod2(num, g)
% reste de la division de num(x) par g(x), coefficients modulo 2
dg = numel(g) - 1;           % degre de g
num = mod(num, 2);
for k = numel(num):-1:dg+1   % on elimine les termes de degre >= dg
    if num(k) == 1
        num(k-dg:k) = mod(num(k-dg:k) + g, 2);
    end
end
r = num(1:dg);
end
