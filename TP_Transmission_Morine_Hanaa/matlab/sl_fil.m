function sl_fil(mdl, de, vers)
% relie deux ports : de = 'Bloc/1' (sortie), vers = 'Bloc/2' (entree)
add_line(mdl, de, vers, 'autorouting', 'on');
end
