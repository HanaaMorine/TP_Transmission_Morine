function code = huffman_code(p)
% code de Huffman
% p = les probas
% code{i} = le mot binaire du symbole i

n = numel(p);
code = repmat({''}, n, 1);   % mots vides au depart

% si un seul symbole on lui donne '0'
if n == 1
    code{1} = '0';
    return
end

paquets = num2cell(1:n);   % un paquet par symbole
proba = p(:)';             % proba de chaque paquet

while numel(proba) > 1
    % on trie les paquets (plus petite proba en premier)
    [proba, ordre] = sort(proba);
    paquets = paquets(ordre);

    % 1er paquet : on ajoute 0 devant
    for s = paquets{1}
        code{s} = ['0' code{s}];
    end

    % 2eme paquet : on ajoute 1 devant
    for s = paquets{2}
        code{s} = ['1' code{s}];
    end

    % on regroupe les 2 paquets
    paquets = [{[paquets{1} paquets{2}]}, paquets(3:end)];
    proba   = [proba(1) + proba(2), proba(3:end)];
end
end