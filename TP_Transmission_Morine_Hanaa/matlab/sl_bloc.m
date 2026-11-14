function h = sl_bloc(mdl, lib, nom, x, y, varargin)
% ajoute un bloc Simulink a la position (x, y) et regle ses parametres
% exemple : sl_bloc('modele', 'simulink/Math Operations/Gain', 'G1', 100, 50, 'Gain', '2')
h = add_block(lib, [mdl '/' nom], 'Position', [x y x+50 y+34]);
if ~isempty(varargin)
    set_param(h, varargin{:});
end
end
