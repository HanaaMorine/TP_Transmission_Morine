function P = parametres_perso(nom)
%PARAMETRES_PERSO  Param�tres personnels du TP � cha�ne de transmission �.
%   P = parametres_perso('DUPONT Jean') rend une structure dont les champs
%   sont d�termin�s par le nom de l'�tudiant (deux �tudiants n'ont pas les
%   m�mes valeurs). Le nom doit �tre �crit comme sur la liste d'appel.
%
%   Champs : p1, p1_ext, pe_cbs, A, a_unif, sigma, L, alpha, beta,
%            retard_trajet (en dur�es symbole), graine.

n = upper(strtrim(nom));
c =rand(1);
graine = mod(sum(c .* (1:numel(c)) * 31) + 7 * numel(c), 2^31 - 1);
s = RandStream('mt19937ar', 'Seed', graine);
u = @(a, b) a + (b - a) * rand(s);

P.nom           = n;
P.p1            = round(u(0.15, 0.40) * 100) / 100;   % P(bit = 1), parties 2 et 3
P.pe_cbs        = round(u(0.02, 0.15) * 1000) / 1000; % canal binaire sym�trique
P.A             = 1;                                  % amplitude
P.a_unif        = round(u(1.2, 2.0) * 100) / 100;     % bruit uniforme sur [-a, a]
P.sigma         = round(u(0.5, 0.9) * 100) / 100;     % bruit gaussien (partie 3)
Ls              = [4 8 16];
P.L             = Ls(randi(s, 3));                    % �chantillons par bit
alphas          = [0.22 0.25 0.35];
P.alpha         = alphas(randi(s, 3));                % roll-off du filtre RRC
P.beta          = round(u(0.2, 0.5) * 100) / 100;     % amplitude de l'�cho
P.retard_trajet = randi(s, 2);                        % retard de l'�cho (symboles)
P.graine        = mod(graine, 1e6);
P.p1_ext        = round(u(0.05, 0.15) * 100) / 100;   % source tr�s d�s�quilibr�e
end
