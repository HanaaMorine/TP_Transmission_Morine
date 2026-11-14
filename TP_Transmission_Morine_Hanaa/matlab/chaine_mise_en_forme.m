function [bd, z, y, D] = chaine_mise_en_forme(b, h, L, N0, hc, dec)
% chaine QPSK (mapping de Gray) avec filtre de mise en forme et filtre adapte
%   b   : bits emis (nombre pair)
%   h   : filtre de mise en forme (energie unite), le filtre adapte est h(-t) = h (symetrique)
%   L   : echantillons par symbole
%   N0  : densite du bruit (variance N0/2 par voie et par echantillon)
%   hc  : reponse du canal en echantillons (1 = canal ideal, sinon echo)
%   dec : decalage de l'instant d'echantillonnage, en echantillons (0 = instant optimal)
% sorties : bd = bits decides, z = echantillons de decision, y = signal apres filtre adapte,
%           D = retard total des deux filtres (N - 1 echantillons = span symboles)
if nargin < 5, hc = 1; end
if nargin < 6, dec = 0; end
s  = qpsk_mod(b, 'gray');                 % symboles complexes, Es = 1
Ns = numel(s);
D  = numel(h) - 1;                        % retard des deux filtres (causaux)
x  = zeros(1, Ns*L + D + L);              % un symbole tous les L echantillons, puis des zeros
x(1:L:Ns*L) = s;
xe = filter(h, 1, x);                     % filtre de mise en forme (emission)
xc = filter(hc, 1, xe);                   % canal (ideal ou a echo)
n  = sqrt(N0/2) * (randn(size(xc)) + 1j * randn(size(xc)));
y  = filter(h, 1, xc + n);                % filtre adapte (reception)
idx = D + 1 + (0:Ns-1)*L + dec;           % instants d'echantillonnage (retard compense)
z  = y(idx);
bd = qpsk_demod(z, 'gray');
end
