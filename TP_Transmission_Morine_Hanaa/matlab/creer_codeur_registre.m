%% Construction du modele Simulink codeur_registre.slx (partie 4, question 5)
% Calcul de la redondance r(x) = x^3 m(x) mod g(x), g(x) = 1 + x + x^3,
% avec un registre a decalage de 3 bascules (blocs Unit Delay), des portes XOR
% et des interrupteurs (Switch), sans produit matriciel ni division de polynomes.
% Les bits du message entrent poids fort d'abord (m3, m2, m1, m0), un bit par Tb.
% A chaque coup d'horloge, avec f = m_entree xor s2 :
%    s2 <- s1,  s1 <- s0 xor f,  s0 <- f
% Les Switch remettent le registre a zero au debut de chaque message
% (compteur = 0) : ils remplacent l'etat precedent par 0.
% Sortie (To Workspace 'etats_reg') : [s0 s1 s2] apres chaque bit ;
% apres le 4e bit d'un message, on lit (r0, r1, r2).
if ~exist('Tb', 'var'), Parametres; end
if ~exist('seq_registre', 'var')
    seq_registre = [1 1 0 1];   % m = [1 0 1 1] entre poids fort d'abord
end
mdl = 'codeur_registre';
sl_nouveau(mdl, 'Tb');

% entree : suite de bits (variable seq_registre) et compteur de position dans le message
sl_bloc(mdl, 'simulink/Sources/Repeating Sequence Stair', 'Message', 30, 40, ...
    'OutValues', 'seq_registre', 'tsamp', 'Tb');
sl_bloc(mdl, 'simulink/Sources/Counter Limited', 'Compteur', 30, 300, ...
    'uplimit', '3', 'tsamp', 'Tb');
sl_bloc(mdl, 'simulink/Sources/Constant', 'Zero', 30, 380, ...
    'Value', '0', 'OutDataTypeStr', 'boolean', 'SampleTime', 'Tb');

% les 3 bascules D (Unit Delay) et leurs interrupteurs de remise a zero
for k = 0:2
    sl_bloc(mdl, 'simulink/Discrete/Unit Delay', sprintf('S%d', k), 520, 120 + 90*k, ...
        'InitialCondition', '0', 'SampleTime', 'Tb');
    set_param([mdl sprintf('/S%d', k)], 'Orientation', 'left');
    sl_bloc(mdl, 'simulink/Signal Routing/Switch', sprintf('RAZ%d', k), 200, 120 + 90*k, ...
        'Criteria', 'u2 > Threshold', 'Threshold', '0');
    sl_fil(mdl, sprintf('S%d/1', k), sprintf('RAZ%d/1', k));
    sl_fil(mdl, 'Compteur/1', sprintf('RAZ%d/2', k));
    sl_fil(mdl, 'Zero/1', sprintf('RAZ%d/3', k));
end

% f = m xor s2 ; nouvelles valeurs : s0 = f, s1 = s0 xor f, s2 = s1
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'XOR_f', 330, 40, ...
    'Operator', 'XOR', 'Inputs', '2');
sl_fil(mdl, 'Message/1', 'XOR_f/1');
sl_fil(mdl, 'RAZ2/1', 'XOR_f/2');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'XOR_s1', 330, 150, ...
    'Operator', 'XOR', 'Inputs', '2');
sl_fil(mdl, 'RAZ0/1', 'XOR_s1/1');
sl_fil(mdl, 'XOR_f/1', 'XOR_s1/2');
sl_fil(mdl, 'XOR_f/1', 'S0/1');
sl_fil(mdl, 'XOR_s1/1', 'S1/1');
sl_fil(mdl, 'RAZ1/1', 'S2/1');

% sortie : etat du registre apres chaque bit
sl_bloc(mdl, 'simulink/Signal Routing/Mux', 'Mux', 650, 40, 'Inputs', '3');
sl_fil(mdl, 'XOR_f/1', 'Mux/1');
sl_fil(mdl, 'XOR_s1/1', 'Mux/2');
sl_fil(mdl, 'RAZ1/1', 'Mux/3');
sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'EnDouble', 730, 40, ...
    'OutDataTypeStr', 'double');
sl_fil(mdl, 'Mux/1', 'EnDouble/1');
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'Etats', 830, 40, ...
    'VariableName', 'etats_reg', 'SaveFormat', 'Array');
sl_fil(mdl, 'EnDouble/1', 'Etats/1');
sl_bloc(mdl, 'simulink/Sinks/Scope', 'Scope', 830, 120);
sl_fil(mdl, 'EnDouble/1', 'Scope/1');

save_system(mdl);
open_system(mdl);
fprintf('Modele %s cree.\n', mdl);
