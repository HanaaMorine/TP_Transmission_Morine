function sl_nouveau(mdl, pas)
% cree un modele Simulink vide (en ecrasant l'ancien) avec un solveur
% a pas fixe discret, comme demande dans le sujet (section 1.2)
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', pas, 'StopTime', '100');
end
