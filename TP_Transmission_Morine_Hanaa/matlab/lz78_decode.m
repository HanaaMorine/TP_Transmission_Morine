function x = lz78_decode(indices, lettres)
% decodeur LZ78
% on reconstruit les phrases une par une

np = numel(indices);
phrases = cell(1, np);   % phrases{k} = la k-ieme phrase du dictionnaire

for k = 1:np
    % la phrase connue
    if indices(k) == 0
        base = [];
    else
        base = phrases{indices(k)};
    end
    % on ajoute le symbole (sauf si 0)
    if lettres(k) > 0
        phrases{k} = [base lettres(k)];
    else
        phrases{k} = base;
    end
end

x = [phrases{:}];   % on colle toutes les phrases
end