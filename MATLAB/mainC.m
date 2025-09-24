clc;
clear;

% Load IRs into a cell array
fileNames = [ ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 0.5m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 1m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 2m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 3m-48k.wav"];

clarity = zeros(length(fileNames), 2);

distances = [0.5, 1, 2, 3]; 

for i = 1:length(fileNames)
    [ir, fs] = audioread(fileNames{i});

    ir2 = ir.^2;
    
    cutoffSample = round(0.05 * fs); 
    
    earlyEnergy = sum(ir2(1:cutoffSample));
    lateEnergy  = sum(ir2(cutoffSample+1:end));
    
    C50 = 10*log10(earlyEnergy / lateEnergy);
    
    clarity(i,:) = [distances(i), C50];
end

figure;
plot(clarity(:,1), clarity(:,2), 'LineWidth', 1.3);
grid on;
xlabel('Distance between speaker and microphone (m)');
ylabel('Clarity C_{50} (dB)');
title('C_{50} with distance - Lecture Theatre');

function x = trim_to_direct(x)
    % keep a handful of samples before the absolute-peak (direct sound)
    [~,i0] = max(abs(x)); i0 = max(1, i0-10);
    x = x(i0:end);
end
