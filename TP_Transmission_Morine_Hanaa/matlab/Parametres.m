%% Script de parametres du TP chaine de transmission
% A lancer avant chaque partie du TP.
% Toutes les valeurs utilisees dans le TP sont definies ici.

clear; clc;   % on efface les anciennes variables et la console

% parametres_perso tire des valeurs au hasard (c = rand(1))
% donc on les tire une seule fois et on les sauvegarde
% pour garder les memes valeurs pendant tout le TP
if exist('mes_parametres.mat', 'file')
    load('mes_parametres.mat', 'P');          % on relit mes valeurs
else
    P = parametres_perso('MORINE HANAA');     % premier tirage
    save('mes_parametres.mat', 'P');          % on les garde
end

% valeurs utilisees dans les parties 2 et 3
p1 = P.p1;      % proba d'avoir un bit a 1
p0 = 1 - p1;    % proba d'avoir un bit a 0

% valeurs pour la chaine de transmission
Tb = 1;         % duree d'un bit, on la prend comme reference
A  = P.A;       % amplitude du signal (bit 0 -> -A, bit 1 -> +A)
L  = P.L;       % nombre d'echantillons par bit

% graine pour que les tirages aleatoires soient toujours les memes
% (round car avec rand la graine n'est plus forcement un entier)
graine = round(P.graine);
rng(graine);

% valeurs pour la partie 3 (canaux)
pe    = P.pe_cbs;    % proba d'erreur du canal binaire symetrique
a     = P.a_unif;    % bruit uniforme entre -a et +a
sigma = P.sigma;     % ecart-type du bruit gaussien

% partie 3 (Q10 et suite) : chaine avec L echantillons par bit
EbN0dB = 5;                       % rapport Eb/N0 en dB
Eb     = A^2 * Tb;                % energie par bit
N0     = Eb / 10^(EbN0dB/10);     % densite du bruit
sigma2 = N0 * L / (2*Tb);         % variance du bruit par echantillon
seuil  = 0;                       % seuil de decision (bits equiprobables)

% affichage de mes parametres pour verifier
disp(P)