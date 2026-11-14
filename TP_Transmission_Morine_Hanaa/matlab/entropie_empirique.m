function [H, symboles, proba] = entropie_empirique(x)
% calcule l'entropie d'une suite de symboles
% H = entropie (bits par symbole)
% symboles = les symboles differents
% proba = la proba de chaque symbole

x = x(:);   % on met tout en colonne

% on trouve les symboles differents
[symboles, ~, idx] = unique(x);

compte = accumarray(idx, 1);   % on compte chaque symbole
proba  = compte / numel(x);    % on divise par le total

H = -sum(proba .* log2(proba));   % formule de l'entropie
end