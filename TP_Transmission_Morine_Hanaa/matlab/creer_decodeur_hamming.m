%% Construction du modele Simulink decodeur_hamming.slx (partie 4, question 6)
% Banc de test du decodeur par syndrome realise en logique combinatoire :
%   From Workspace (variable entree_dec = [temps, mot de 7 bits])
%   -> sous-systeme "Decodeur Hamming" -> To Workspace 'messages_dec'
if ~exist('Tb', 'var'), Parametres; end
if ~exist('entree_dec', 'var')
    entree_dec = [0, 1 0 1 1 1 0 0];   % un mot-code de test
end
mdl = 'decodeur_hamming';
sl_nouveau(mdl, 'Tb');

sl_bloc(mdl, 'simulink/Sources/From Workspace', 'Mots', 30, 50, ...
    'VariableName', 'entree_dec', 'SampleTime', 'Tb', ...
    'OutputAfterFinalValue', 'Holding final value');
sl_decodeur_hamming(mdl, 'Decodeur Hamming', 160, 40);
sl_fil(mdl, 'Mots/1', 'Decodeur Hamming/1');
sl_bloc(mdl, 'simulink/Sinks/To Workspace', 'Messages', 340, 50, ...
    'VariableName', 'messages_dec', 'SaveFormat', 'Array');
sl_fil(mdl, 'Decodeur Hamming/1', 'Messages/1');

save_system(mdl);
open_system(mdl);
fprintf('Modele %s cree.\n', mdl);
