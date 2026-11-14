function d = trouver_retard(be, br, dmax)
% cherche le retard (en bits) entre les bits emis be et les bits recus br
% on essaie les decalages 0..dmax et on garde celui qui donne le moins d'erreurs
if nargin < 3, dmax = 10; end
be = be(:); br = br(:);
n = min(numel(be), numel(br));
be = be(1:n); br = br(1:n);
err = inf(1, dmax + 1);
for k = 0:dmax
    err(k+1) = sum(be(1:end-k) ~= br(1+k:end));
end
[~, i] = min(err);
d = i - 1;
end
