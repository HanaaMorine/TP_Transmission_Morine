%% Construction du modele Simulink chaine_hamming.slx (partie 4, question 10)
% Chaine de la partie 3 avec codage de Hamming C(7,4) :
%  source (1 bit / Tb) -> regroupement par 4 (Tapped Delay + Rate Transition 4Tb)
%  -> codeur (sous-systeme) -> mise en serie a Tc = 4Tb/7 (compteur + Multiport Switch)
%  -> emetteur +/- A sqrt(4/7), L echantillons par bit code -> canal gaussien
%  -> detecteur optimal (integrateur + echantillonneur + seuil)
%  -> regroupement par 7 -> decodeur par syndrome (sous-systeme) -> mise en serie a Tb
% Variables utilisees (script Parametres) : Tb, A, L, graine, sigma2, dec_mot
if ~exist('Tb', 'var'), Parametres; end
if ~exist('dec_mot', 'var'), dec_mot = 0; end
mdl = 'chaine_hamming';
sl_nouveau(mdl, 'Tb*4/(7*L)');          % pas fondamental = Tc / L
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

% ===== regroupement des bits par 4 (role du bloc Buffer) =====
sl_bloc(mdl, 'simulink/Discrete/Tapped Delay', 'Groupe4', 260, y0 + 30, ...
    'vinit', '0', 'samptime', 'Tb', 'NumDelays', '4', 'DelayOrder', 'Oldest');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'Vers4Tb', 340, y0 + 30, 'OutPortSampleTime', '4*Tb');
sl_fil(mdl, 'EnDouble/1', 'Groupe4/1');
sl_fil(mdl, 'Groupe4/1', 'Vers4Tb/1');

% ===== codeur =====
sl_codeur_hamming(mdl, 'Codeur Hamming', 420, y0 + 20);
sl_fil(mdl, 'Vers4Tb/1', 'Codeur Hamming/1');

% ===== mise en serie des 7 bits codes a Tc = 4Tb/7 (role du bloc Unbuffer) =====
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'VersTc', 580, y0 + 30, 'OutPortSampleTime', '4*Tb/7');
sl_bloc(mdl, 'simulink/Signal Routing/Demux', 'Demux7', 660, y0 + 10, 'Outputs', '7');
set_param([mdl '/Demux7'], 'Position', [660 y0-20 670 y0+140]);
sl_bloc(mdl, 'simulink/Sources/Counter Limited', 'Compteur7', 660, y0 + 180, 'uplimit', '6', 'tsamp', '4*Tb/7');
sl_bloc(mdl, 'simulink/Signal Routing/Multiport Switch', 'Serie7', 740, y0, ...
    'Inputs', '7', 'DataPortOrder', 'Zero-based contiguous');
set_param([mdl '/Serie7'], 'Position', [740 y0-20 790 y0+200]);
sl_fil(mdl, 'Codeur Hamming/1', 'VersTc/1');
sl_fil(mdl, 'VersTc/1', 'Demux7/1');
sl_fil(mdl, 'Compteur7/1', 'Serie7/1');
for k = 1:7
    sl_fil(mdl, sprintf('Demux7/%d', k), sprintf('Serie7/%d', k + 1));
end

% ===== emetteur : bit code -> +/- A sqrt(4/7), L echantillons par bit code =====
sl_bloc(mdl, 'simulink/Math Operations/Gain', 'Gain', 840, y0 + 70, 'Gain', '2*A*sqrt(4/7)');
sl_bloc(mdl, 'simulink/Math Operations/Bias', 'Bias', 910, y0 + 70, 'Bias', '-A*sqrt(4/7)');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'VersTe', 980, y0 + 70, 'OutPortSampleTime', '4*Tb/(7*L)');
sl_fil(mdl, 'Serie7/1', 'Gain/1');
sl_fil(mdl, 'Gain/1', 'Bias/1');
sl_fil(mdl, 'Bias/1', 'VersTe/1');

% ===== canal gaussien =====
sl_bloc(mdl, 'simulink/Sources/Random Number', 'Bruit', 980, y0 + 170, ...
    'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine+2', 'SampleTime', '4*Tb/(7*L)');
sl_bloc(mdl, 'simulink/Math Operations/Sum', 'Canal', 1060, y0 + 80, 'Inputs', '++');
sl_fil(mdl, 'VersTe/1', 'Canal/1');
sl_fil(mdl, 'Bruit/1', 'Canal/2');

% ===== detecteur optimal (comme dans chaine_gauss) =====
sl_bloc(mdl, 'simulink/Discrete/Unit Delay', 'Retard1', 1130, y0 + 80, 'SampleTime', '-1');
sl_bloc(mdl, 'simulink/Discrete/Discrete FIR Filter', 'Integrateur', 1200, y0 + 80, 'Coefficients', 'ones(1,L)/L');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'Echantillonneur', 1270, y0 + 80, 'OutPortSampleTime', '4*Tb/7');
sl_bloc(mdl, 'simulink/Logic and Bit Operations/Compare To Zero', 'Decision', 1340, y0 + 80, 'relop', '>');
sl_bloc(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'EnDouble2', 1410, y0 + 80, 'OutDataTypeStr', 'double');
sl_fil(mdl, 'Canal/1', 'Retard1/1');
sl_fil(mdl, 'Retard1/1', 'Integrateur/1');
sl_fil(mdl, 'Integrateur/1', 'Echantillonneur/1');
sl_fil(mdl, 'Echantillonneur/1', 'Decision/1');
sl_fil(mdl, 'Decision/1', 'EnDouble2/1');

% ===== regroupement des bits recus par 7 (alignement reglable par dec_mot) =====
sl_bloc(mdl, 'simulink/Discrete/Delay', 'Alignement', 140, y0 + 330, ...
    'DelayLength', 'dec_mot + 1', 'SampleTime', '-1');
sl_bloc(mdl, 'simulink/Discrete/Tapped Delay', 'Groupe7', 230, y0 + 330, ...
    'vinit', '0', 'samptime', '4*Tb/7', 'NumDelays', '7', 'DelayOrder', 'Oldest');
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'Vers4Tb_rx', 320, y0 + 330, 'OutPortSampleTime', '4*Tb');
sl_fil(mdl, 'EnDouble2/1', 'Alignement/1');
sl_fil(mdl, 'Alignement/1', 'Groupe7/1');
sl_fil(mdl, 'Groupe7/1', 'Vers4Tb_rx/1');

% ===== decodeur =====
sl_decodeur_hamming(mdl, 'Decodeur Hamming', 400, y0 + 320);
sl_fil(mdl, 'Vers4Tb_rx/1', 'Decodeur Hamming/1');

% ===== mise en serie des 4 bits decodes a Tb =====
sl_bloc(mdl, 'simulink/Signal Attributes/Rate Transition', 'VersTb', 560, y0 + 330, 'OutPortSampleTime', 'Tb');
sl_bloc(mdl, 'simulink/Signal Routing/Demux', 'Demux4', 640, y0 + 310, 'Outputs', '4');
set_param([mdl '/Demux4'], 'Position', [640 y0+300 650 y0+400]);
sl_bloc(mdl, 'simulink/Sources/Counter Limited', 'Compteur4', 640, y0 + 430, 'uplimit', '3', 'tsamp', 'Tb');
sl_bloc(mdl, 'simulink/Signal Routing/Multiport Switch', 'Serie4', 720, y0 + 310, ...
    'Inputs', '4', 'DataPortOrder', 'Zero-based contiguous');
set_param([mdl '/Serie4'], 'Position', [720 y0+300 770 y0+460]);
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'BitsRecus', 830, y0 + 360, 'VariableName', 'bits_recus', 'SaveFormat', 'Array');
sl_fil(mdl, 'Decodeur Hamming/1', 'VersTb/1');
sl_fil(mdl, 'VersTb/1', 'Demux4/1');
sl_fil(mdl, 'Compteur4/1', 'Serie4/1');
for k = 1:4
    sl_fil(mdl, sprintf('Demux4/%d', k), sprintf('Serie4/%d', k + 1));
end
sl_fil(mdl, 'Serie4/1', 'BitsRecus/1');

save_system(mdl);
open_system(mdl);
fprintf('Modele %s cree.\n', mdl);
