function completer_chaine_gauss(mdl)
% Ajoute au modele chaine_gauss la voie "sans integration" (question 12) :
%   sortie du canal -> Delay de L/2 echantillons -> echantillonnage a Tb
%   -> decision (> 0) -> To Workspace 'bits_recus_1ech'
% Ne fait rien si la voie existe deja.
if ~isempty(find_system(mdl, 'SearchDepth', 1, 'Name', 'BitsRecus1ech'))
    return
end

% le bloc Delay (z^-4) a deja ete pose a la main
dly = [mdl '/Delay'];
set_param(dly, 'DelayLength', 'L/2');
pos = get_param(dly, 'Position');
dx  = 90;

% on relie le canal (bloc Sum) au Delay s'il n'est pas encore branche
lh = get_param(dly, 'LineHandles');
if lh.Inport(1) == -1
    add_line(mdl, 'Sum/1', 'Delay/1', 'autorouting', 'on');
end

add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Echant1ech'], ...
    'OutPortSampleTime', 'Tb', 'Position', pos + [dx 0 dx 0]);
add_block('simulink/Logic and Bit Operations/Compare To Zero', [mdl '/Decision1ech'], ...
    'relop', '>', 'Position', pos + [2*dx 0 2*dx 0]);
add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/Double1ech'], ...
    'OutDataTypeStr', 'double', 'Position', pos + [3*dx 0 3*dx+20 0]);
add_block('simulink/Sinks/To Workspace', [mdl '/BitsRecus1ech'], ...
    'VariableName', 'bits_recus_1ech', 'SaveFormat', 'Array', ...
    'Position', pos + [4*dx+40 0 4*dx+100 0]);

add_line(mdl, 'Delay/1', 'Echant1ech/1', 'autorouting', 'on');
add_line(mdl, 'Echant1ech/1', 'Decision1ech/1', 'autorouting', 'on');
add_line(mdl, 'Decision1ech/1', 'Double1ech/1', 'autorouting', 'on');
add_line(mdl, 'Double1ech/1', 'BitsRecus1ech/1', 'autorouting', 'on');
save_system(mdl);
fprintf('Voie sans integration ajoutee au modele %s.\n', mdl);
end
