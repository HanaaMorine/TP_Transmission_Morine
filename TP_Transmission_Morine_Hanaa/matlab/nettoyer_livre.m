%% Nettoyage du livre telecharge sur Gutenberg
% on enleve le texte en anglais au debut et la licence a la fin

texte = fileread('livre.txt', 'Encoding', 'UTF-8');   % on lit le livre

debut = strfind(texte, '*** START OF');   % ligne avant le vrai texte
fin   = strfind(texte, '*** END OF');     % ligne apres le vrai texte

% on saute jusqu'a la fin de la ligne START
saut = find(texte(debut(1):end) == newline, 1);

% on garde seulement le livre
texte = texte(debut(1) + saut : fin(1) - 1);
texte = strtrim(texte);   % on enleve les lignes vides au debut et a la fin

% on enregistre le livre propre dans un nouveau fichier
fid = fopen('livre_propre.txt', 'w', 'n', 'UTF-8');
fprintf(fid, '%s', texte);
fclose(fid);

fprintf('Livre nettoye : %d caracteres\n', numel(texte));