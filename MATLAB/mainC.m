clc;
clear;

% Load IRs into a cell array
fileNames = [ ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 back 0.5m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 back 1m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 back 2m-48k.wav", ...
    "./../Recordings/Lecture theater/Lecture Theater Sep 20 back 3m-48k.wav"];

staffFilenames = [ ...
    "./../Recordings/Staff room/staff room 0.5m loc 2-48k.wav", ...
    "./../Recordings/Staff room/staff room 1m loc 2-48k.wav", ...
    "./../Recordings/Staff room/staff room 2m loc 2-48k.wav", ...
    "./../Recordings/Staff room/staff room 33m loc 2-48k.wav"];

clarity1 = zeros(length(fileNames), 2);
clarity2 = zeros(length(staffFilenames), 2);

distances = [0.5, 1, 2, 3]; 

for i = 1:length(fileNames)
    [ir, fs] = audioread(fileNames{i});
    ir = trim_to_direct(ir);

    ir2 = ir.^2;
    
    cutoffSample = round(0.05 * fs); 
    
    earlyEnergy = sum(ir2(1:cutoffSample));
    lateEnergy  = sum(ir2(cutoffSample+1:end));
    
    C50 = 10*log10(earlyEnergy / lateEnergy);
    
    clarity1(i,:) = [distances(i), C50];
end

for i = 1:length(staffFilenames)
    [ir, fs] = audioread(staffFilenames{i});
    ir = trim_to_direct(ir);

    ir2 = ir.^2;
    
    cutoffSample = round(0.05 * fs); 
    
    earlyEnergy = sum(ir2(1:cutoffSample));
    lateEnergy  = sum(ir2(cutoffSample+1:end));
    
    C50 = 10*log10(earlyEnergy / lateEnergy);
    
    clarity2(i,:) = [distances(i), C50];
end

figure;
subplot(1, 2, 1)
plot(clarity1(:,1), clarity1(:,2), '-x', 'LineWidth', 1.3);
grid on;
xlabel('Distance between speaker and microphone (m)');
ylabel('Clarity C_{50} (dB)');
title('C_{50} with distance - Lecture Theatre');

subplot(1, 2, 2)
plot(clarity2(:,1), clarity2(:,2), '-x', 'LineWidth', 1.3);
grid on;
xlabel('Distance between speaker and microphone (m)');
ylabel('Clarity C_{50} (dB)');
title('C_{50} with distance - Staff Room');

function x = trim_to_direct(x)
    % keep a handful of samples before the absolute-peak (direct sound)
    [~,i0] = max(abs(x)); i0 = max(1, i0-10);
    x = x(i0:end);
end
