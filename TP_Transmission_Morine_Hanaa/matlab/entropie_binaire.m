function H = entropie_binaire(p)
% entropie d'une source binaire
% p = proba d'avoir un 1
% H = quantite d'info moyenne par bit (en bits)

q = 1 - p;   % proba d'avoir un 0

% formule de l'entropie vue en cours
H = -p .* log2(p) - q .* log2(q);

% si p = 0 ou p = 1, matlab donne NaN a cause de log2(0)
% mais la source est alors toujours pareille donc H = 0
H(p == 0 | p == 1) = 0;
end