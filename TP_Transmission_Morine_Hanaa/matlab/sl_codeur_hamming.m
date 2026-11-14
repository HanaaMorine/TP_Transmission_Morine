function sl_codeur_hamming(mdl, nom, x, y)
% Cree dans le modele mdl un sous-systeme "nom" : codeur de Hamming systematique
%   entree : message de 4 bits [m0 m1 m2 m3] (vecteur)
%   sortie : mot-code de 7 bits [m0 m1 m2 m3 r0 r1 r2] (vecteur, double)
% r_j = XOR des m_i tels que P(i,j) = 1 (equations de parite, sans produit matriciel)
[~, ~, P] = hamming_matrices();
sub = [mdl '/' nom];
add_block('built-in/Subsystem', sub, 'Position', [x y x+110 y+60]);
sl_bloc(sub, 'simulink/Sources/In1', 'message', 20, 150);
sl_bloc(sub, 'simulink/Signal Routing/Demux', 'Demux', 100, 100, 'Outputs', '4');
set_param([sub '/Demux'], 'Position', [100 40 110 280]);
sl_fil(sub, 'message/1', 'Demux/1');
sl_bloc(sub, 'simulink/Signal Routing/Mux', 'Mux', 450, 100, 'Inputs', '7');
set_param([sub '/Mux'], 'Position', [450 30 460 330]);
for i = 1:4
    sl_fil(sub, sprintf('Demux/%d', i), sprintf('Mux/%d', i));   % partie message
end
for j = 1:3
    idx = find(P(:, j));
    nomR = sprintf('r%d', j - 1);
    sl_bloc(sub, 'simulink/Logic and Bit Operations/Logical Operator', nomR, 220, 180 + 60*(j-1), ...
        'Operator', 'XOR', 'Inputs', num2str(numel(idx)));
    for k = 1:numel(idx)
        sl_fil(sub, sprintf('Demux/%d', idx(k)), sprintf('%s/%d', nomR, k));
    end
    nomD = ['d' nomR];
    sl_bloc(sub, 'simulink/Signal Attributes/Data Type Conversion', nomD, 330, 180 + 60*(j-1), ...
        'OutDataTypeStr', 'double');
    sl_fil(sub, [nomR '/1'], [nomD '/1']);
    sl_fil(sub, [nomD '/1'], sprintf('Mux/%d', 4 + j));
end
sl_bloc(sub, 'simulink/Sinks/Out1', 'mot_code', 530, 160);
sl_fil(sub, 'Mux/1', 'mot_code/1');
end
