function [outputDB, nyquist] = impulseToDB(inputIR)
%impulseToDB 
%   outputs the dB for the input IR in the freq. domain
N = length(inputIR);
FR = fft(inputIR, N);

%halving the Fr
half = floor(N/2) + 1;
halvedFR = FR(1:half);

%converting to dB
outputDB = 20*log10(abs(halvedFR));
outputDB = outputDB - max(outputDB);

nyquist = half;

end