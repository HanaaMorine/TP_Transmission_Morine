function b = qpsk_demod(r, mapping)
% demodulateur QPSK : decision sur le signe de chaque voie, puis demapping
% r       : symboles recus (complexes)
% mapping : 'gray' (par defaut) ou 'naturel'
% b       : bits decides, vecteur ligne [b0 b1 b0 b1 ...]
if nargin < 2, mapping = 'gray'; end
iNeg = real(r(:)).' < 0;             % voie I negative
qNeg = imag(r(:)).' < 0;             % voie Q negative
% Gray    : b0 = (Q < 0), b1 = (I < 0)            -> voies independantes
% naturel : b0 = (Q < 0), b1 = (I < 0) xor b0
b0 = double(qNeg);
if strcmp(mapping, 'gray')
    b1 = double(iNeg);
else
    b1 = double(xor(iNeg, qNeg));
end
b = reshape([b0; b1], 1, []);
end
