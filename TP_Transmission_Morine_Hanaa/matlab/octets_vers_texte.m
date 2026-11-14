function txt = octets_vers_texte(oct)
% transforme des octets (codage UTF-8) en texte affichable
% les octets abimes par les erreurs de transmission deviennent '?'
oct = uint8(oct(:).');
try
    txt = native2unicode(oct, 'UTF-8');
catch
    % sequence UTF-8 invalide (Octave refuse) : on decode a la main
    txt = '';
    k = 1;
    while k <= numel(oct)
        o = double(oct(k));
        if o >= 32 && o < 127 || o == 10
            txt(end+1) = char(o); k = k + 1;                     % caractere ASCII
        elseif o >= 194 && o <= 223 && k < numel(oct) && bitand(double(oct(k+1)), 192) == 128
            try
                txt = [txt native2unicode(oct(k:k+1), 'UTF-8')];  % lettre accentuee (2 octets)
            catch
                txt(end+1) = '?';
            end
            k = k + 2;
        else
            txt(end+1) = '?'; k = k + 1;                         % octet abime
        end
    end
end
end
