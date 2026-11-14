function h = rrc_coeffs(alpha, L, span)
% coefficients du filtre en racine de cosinus sureleve (RRC)
% alpha : facteur de retombee (roll-off), L : echantillons par symbole,
% span  : longueur en symboles (N = span*L + 1 coefficients)
% le filtre est normalise a energie unite : sum(h.^2) = 1
% (avec le filtre adapte, l'echantillon au bon instant vaut le symbole emis)
T = 1;                                  % duree symbole (reference)
t = (-span*L/2 : span*L/2) / L * T;     % instants des echantillons
h = zeros(size(t));
for k = 1:numel(t)
    tk = t(k);
    if abs(tk) < 1e-12
        % limite en t = 0
        h(k) = (1/sqrt(T)) * (1 - alpha + 4*alpha/pi);
    elseif abs(abs(tk) - T/(4*alpha)) < 1e-12
        % limite en t = +/- T/(4 alpha) (denominateur nul)
        h(k) = alpha/sqrt(2*T) * ((1 + 2/pi) * sin(pi/(4*alpha)) + (1 - 2/pi) * cos(pi/(4*alpha)));
    else
        num = sin(pi*tk/T*(1 - alpha)) + 4*alpha*tk/T .* cos(pi*tk/T*(1 + alpha));
        den = pi*tk/T .* (1 - (4*alpha*tk/T).^2);
        h(k) = (1/sqrt(T)) * num / den;
    end
end
h = h / sqrt(sum(h.^2));                % energie unite
end
