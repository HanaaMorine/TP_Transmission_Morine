function sl_decodeur_hamming(mdl, nom, x, y)
% Cree dans le modele mdl un sous-systeme "nom" qui decode un mot de Hamming :
%   entree : mot recu de 7 bits [r0 ... r6] (vecteur)
%   sortie : message corrige de 4 bits [m0 m1 m2 m3] (vecteur, double)
% Realisation en logique combinatoire (pas de produit matriciel) :
%   syndrome s_j = XOR des r_i tels que H(j,i) = 1
%   erreur sur le bit i  e_i = ET des s_j (ou NON s_j) selon la colonne i de H
%   bit corrige          m_i = r_i XOR e_i
[~, H] = hamming_matrices();
sub = [mdl '/' nom];
add_block('built-in/Subsystem', sub, 'Position', [x y x+110 y+60]);
sl_bloc(sub, 'simulink/Sources/In1', 'mot_recu', 20, 200);
sl_bloc(sub, 'simulink/Signal Routing/Demux', 'Demux', 100, 180, 'Outputs', '7');
set_param([sub '/Demux'], 'Position', [100 40 110 360]);
sl_fil(sub, 'mot_recu/1', 'Demux/1');

% --- syndrome : 3 portes XOR ---
for j = 1:3
    idx = find(H(j, :));
    nomS = sprintf('s%d', j - 1);
    sl_bloc(sub, 'simulink/Logic and Bit Operations/Logical Operator', nomS, 220, 60 + 110*(j-1), ...
        'Operator', 'XOR', 'Inputs', num2str(numel(idx)));
    for k = 1:numel(idx)
        sl_fil(sub, sprintf('Demux/%d', idx(k)), sprintf('%s/%d', nomS, k));
    end
    % NON s_j (utile pour reconnaitre les colonnes de H)
    sl_bloc(sub, 'simulink/Logic and Bit Operations/Logical Operator', ['non_' nomS], 320, 90 + 110*(j-1), ...
        'Operator', 'NOT', 'Inputs', '1');
    sl_fil(sub, [nomS '/1'], ['non_' nomS '/1']);
end

% --- detection de l'erreur et correction pour les 4 bits du message ---
sl_bloc(sub, 'simulink/Signal Routing/Mux', 'Mux', 720, 150, 'Inputs', '4');
set_param([sub '/Mux'], 'Position', [720 60 730 340]);
for i = 1:4
    nomE = sprintf('e%d', i - 1);
    sl_bloc(sub, 'simulink/Logic and Bit Operations/Logical Operator', nomE, 440, 40 + 80*(i-1), ...
        'Operator', 'AND', 'Inputs', '3');
    for j = 1:3
        if H(j, i) == 1
            sl_fil(sub, sprintf('s%d/1', j - 1), sprintf('%s/%d', nomE, j));
        else
            sl_fil(sub, sprintf('non_s%d/1', j - 1), sprintf('%s/%d', nomE, j));
        end
    end
    nomM = sprintf('m%d', i - 1);
    sl_bloc(sub, 'simulink/Logic and Bit Operations/Logical Operator', nomM, 540, 40 + 80*(i-1), ...
        'Operator', 'XOR', 'Inputs', '2');
    sl_fil(sub, sprintf('Demux/%d', i), [nomM '/1']);
    sl_fil(sub, [nomE '/1'], [nomM '/2']);
    nomD = sprintf('d%d', i - 1);
    sl_bloc(sub, 'simulink/Signal Attributes/Data Type Conversion', nomD, 630, 40 + 80*(i-1), ...
        'OutDataTypeStr', 'double');
    sl_fil(sub, [nomM '/1'], [nomD '/1']);
    sl_fil(sub, [nomD '/1'], sprintf('Mux/%d', i));
end
sl_bloc(sub, 'simulink/Sinks/Out1', 'message', 800, 200);
sl_fil(sub, 'Mux/1', 'message/1');
end
