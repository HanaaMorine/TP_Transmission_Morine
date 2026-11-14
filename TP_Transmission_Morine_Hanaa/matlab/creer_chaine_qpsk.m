%% Construction du modele Simulink chaine_qpsk.slx (partie 5)
% QPSK en bande de base equivalente, Es = 1 (voies I et Q traitees separement)
%  source (1 bit / Tb) -> couples de bits (Tapped Delay + Rate Transition 2Tb)
%  -> mapping (Gray si mapping_naturel = 0, naturel si = 1)
%  -> I, Q = +/- 1/sqrt(2) -> bruit gaussien de variance N0/2 par voie
%  -> decision sur le signe de chaque voie -> demapping -> mise en serie a Tb
% Mapping : b0 donne le signe de Q, b1 (xor b0 en naturel) donne le signe de I
%   Gray    : 00 -> k=1, 01 -> k=3, 11 -> k=5, 10 -> k=7
%   naturel : 00 -> k=1, 01 -> k=3, 10 -> k=5, 11 -> k=7
% Variables : Tb, graine, sigma2_qpsk (= N0/2), mapping_naturel (0 ou 1)
if ~exist('Tb', 'var'), Parametres; end
if ~exist('sigma2_qpsk', 'var'), sigma2_qpsk = 0; end
if ~exist('mapping_naturel', 'var'), mapping_naturel = 0; end
mdl = 'chaine_qpsk';
sl_nouveau(mdl, 'Tb');
y0 = 60;

% ===== source =====
sl_bloc(mdl, 'simulink/Sources/Uniform Random Number', 'Hasard', 20, y0, ...
    'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
sl_bloc(mdl, 'simulink/Sources/Constant', 'Proba', 20, y0 + 70, 'Value', '0.5', 'SampleTime', 'Tb');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Relational Operator', 'Comparaison', 100, y0 + 30, 'Operator', '<');
sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'EnDouble', 170, y0 + 30, 'OutDataTypeStr', 'double');
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'BitsEmis', 260, y0 - 50, 'VariableName', 'bits_emis', 'SaveFormat', 'Array');
sl_fil(mdl, 'Hasard/1', 'Comparaison/1');
sl_fil(mdl, 'Proba/1', 'Comparaison/2');
sl_fil(mdl, 'Comparaison/1', 'EnDouble/1');
sl_fil(mdl, 'EnDouble/1', 'BitsEmis/1');

% ===== couples de bits [b0 b1] (role du bloc Buffer de taille 2) =====
sl_bloc(mdl, 'simulink/Discrete/Tapped Delay', 'Groupe2', 260, y0 + 30, ...
    'vinit', '0', 'samptime', 'Tb', 'NumDelays', '2', 'DelayOrder', 'Oldest');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'Vers2Tb', 340, y0 + 30, 'OutPortSampleTime', '2*Tb');
sl_bloc(mdl, 'simulink/Signal Routing/Demux', 'Demux2', 420, y0 + 20, 'Outputs', '2');
sl_fil(mdl, 'EnDouble/1', 'Groupe2/1');
sl_fil(mdl, 'Groupe2/1', 'Vers2Tb/1');
sl_fil(mdl, 'Vers2Tb/1', 'Demux2/1');

% ===== modulateur (mapping) =====
sl_bloc(mdl, 'simulink/Sources/Constant', 'Naturel', 420, y0 + 130, ...
    'Value', 'mapping_naturel', 'SampleTime', '2*Tb');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'ET_tx', 500, y0 + 110, 'Operator', 'AND', 'Inputs', '2');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'sI_tx', 580, y0 + 60, 'Operator', 'XOR', 'Inputs', '2');
sl_fil(mdl, 'Naturel/1', 'ET_tx/1');
sl_fil(mdl, 'Demux2/1', 'ET_tx/2');
sl_fil(mdl, 'Demux2/2', 'sI_tx/1');
sl_fil(mdl, 'ET_tx/1', 'sI_tx/2');
% signe -> amplitude : 0 -> +1/sqrt(2), 1 -> -1/sqrt(2)
noms = {'I', 'Q'};
for v = 1:2
    sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', ['D' noms{v}], 660, y0 + 20 + 120*(v-1), 'OutDataTypeStr', 'double');
    sl_bloc(mdl, 'simulink/Math Operations/Gain', ['G' noms{v}], 730, y0 + 20 + 120*(v-1), 'Gain', '-2/sqrt(2)');
    sl_bloc(mdl, 'simulink/Math Operations/Bias', ['B' noms{v}], 800, y0 + 20 + 120*(v-1), 'Bias', '1/sqrt(2)');
    sl_fil(mdl, ['D' noms{v} '/1'], ['G' noms{v} '/1']);
    sl_fil(mdl, ['G' noms{v} '/1'], ['B' noms{v} '/1']);
    % canal : bruit gaussien de variance N0/2 sur chaque voie
    sl_bloc(mdl, 'simulink/Sources/Random Number', ['Bruit' noms{v}], 800, y0 + 80 + 120*(v-1), ...
        'Mean', '0', 'Variance', 'sigma2_qpsk', 'Seed', sprintf('graine+%d', v + 1), 'SampleTime', '2*Tb');
    sl_bloc(mdl, 'simulink/Math Operations/Sum', ['Canal' noms{v}], 880, y0 + 30 + 120*(v-1), 'Inputs', '++');
    sl_fil(mdl, ['B' noms{v} '/1'], ['Canal' noms{v} '/1']);
    sl_fil(mdl, ['Bruit' noms{v} '/1'], ['Canal' noms{v} '/2']);
    % decision sur le signe
    sl_bloc(mdl, 'simulink/Logic and Bit Operations/Compare To Zero', ['Neg' noms{v}], 960, y0 + 30 + 120*(v-1), 'relop', '<');
    sl_fil(mdl, ['Canal' noms{v} '/1'], ['Neg' noms{v} '/1']);
end
sl_fil(mdl, 'sI_tx/1', 'DI/1');
sl_fil(mdl, 'Demux2/1', 'DQ/1');

% symboles recus (pour la constellation)
sl_bloc(mdl, 'simulink/Signal Routing/Mux', 'MuxIQ', 960, y0 + 300, 'Inputs', '2');
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'Symboles', 1040, y0 + 300, 'VariableName', 'symb_recus', 'SaveFormat', 'Array');
sl_fil(mdl, 'CanalI/1', 'MuxIQ/1');
sl_fil(mdl, 'CanalQ/1', 'MuxIQ/2');
sl_fil(mdl, 'MuxIQ/1', 'Symboles/1');

% ===== demodulateur (demapping) : b0 = (Q < 0), b1 = (I < 0) xor (naturel et b0) =====
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'ET_rx', 1040, y0 + 170, 'Operator', 'AND', 'Inputs', '2');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Logical Operator', 'b1_rx', 1110, y0 + 40, 'Operator', 'XOR', 'Inputs', '2');
sl_fil(mdl, 'Naturel/1', 'ET_rx/1');
sl_fil(mdl, 'NegQ/1', 'ET_rx/2');
sl_fil(mdl, 'NegI/1', 'b1_rx/1');
sl_fil(mdl, 'ET_rx/1', 'b1_rx/2');
sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'Db0', 1180, y0 + 150, 'OutDataTypeStr', 'double');
sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'Db1', 1180, y0 + 40, 'OutDataTypeStr', 'double');
sl_fil(mdl, 'NegQ/1', 'Db0/1');
sl_fil(mdl, 'b1_rx/1', 'Db1/1');

% ===== mise en serie a Tb (role du bloc Unbuffer) =====
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'VersTb_b0', 1250, y0 + 150, 'OutPortSampleTime', 'Tb');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'VersTb_b1', 1250, y0 + 40, 'OutPortSampleTime', 'Tb');
sl_bloc(mdl, 'simulink/Sources/Counter Limited', 'Compteur2', 1250, y0 + 240, 'uplimit', '1', 'tsamp', 'Tb');
sl_bloc(mdl, 'simulink/Signal Routing/Multiport Switch', 'Serie2', 1330, y0 + 80, ...
    'Inputs', '2', 'DataPortOrder', 'Zero-based contiguous');
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'BitsRecus', 1410, y0 + 90, 'VariableName', 'bits_recus', 'SaveFormat', 'Array');
sl_fil(mdl, 'Db0/1', 'VersTb_b0/1');
sl_fil(mdl, 'Db1/1', 'VersTb_b1/1');
sl_fil(mdl, 'Compteur2/1', 'Serie2/1');
sl_fil(mdl, 'VersTb_b0/1', 'Serie2/2');     % compteur = 0 -> b0
sl_fil(mdl, 'VersTb_b1/1', 'Serie2/3');     % compteur = 1 -> b1
sl_fil(mdl, 'Serie2/1', 'BitsRecus/1');

save_system(mdl);
open_system(mdl);
fprintf('Modele %s cree.\n', mdl);
