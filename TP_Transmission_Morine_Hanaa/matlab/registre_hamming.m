function [r, etats] = registre_hamming(m)
% calcul de la redondance avec le registre a decalage (division par g(x))
% m = [m0 m1 m2 m3] ; les bits entrent poids fort d'abord : m3, m2, m1, m0
% a chaque coup d'horloge, avec f = m_entree xor s2 :
%    s2 <- s1,  s1 <- s0 xor f,  s0 <- f
% r     = [r0 r1 r2] (contenu du registre apres 4 coups d'horloge)
% etats = table des etats : [entree f s0 s1 s2] apres chaque coup

s = [0 0 0];                  % s0 s1 s2 au depart
etats = zeros(4, 5);
entrees = m(end:-1:1);        % m3, m2, m1, m0
for k = 1:4
    f = xor(entrees(k), s(3));
    s = [f, xor(s(1), f), s(2)];   % nouvelles valeurs de s0, s1, s2
    etats(k, :) = [entrees(k) f s];
end
r = s;
end
