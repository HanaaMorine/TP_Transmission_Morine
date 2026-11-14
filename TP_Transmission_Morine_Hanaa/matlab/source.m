function b = source(N, p1)
% Fonction qui genere N bits aleatoires (0 ou 1)
% avec une probabilite p1 d'avoir un 1 et 1-p1 d'avoir un 0.
%
% Principe : on tire un nombre au hasard entre 0 et 1.
% S'il est plus petit que p1 on met un 1, sinon un 0.
% Comme le tirage est uniforme, on a bien un 1 avec la proba p1.

u = rand(1, N);       % N nombres au hasard entre 0 et 1
b = double(u < p1);   % 1 si u < p1, 0 sinon (double pour avoir des nombres)

end