clc;
clear;

% Load IRs into string arrays (so [] works)
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

distances = [0.5, 1, 2, 3];

clarity1 = zeros(length(fileNames), 2);
clarity2 = zeros(length(staffFilenames), 2);

for i = 1:length(fileNames)
    [ir, fs] = audioread(fileNames(i));   % note () indexing for string array
    clarity1(i,:) = [distances(i), compute_C50(ir, fs)];
end

for i = 1:length(staffFilenames)
    [ir, fs] = audioread(staffFilenames(i));
    clarity2(i,:) = [distances(i), compute_C50(ir, fs)];
end

[h, fs] = audioread(fileNames(1));
if size(h,2)>1, h=mean(h,2); end
plot((0:numel(h)-1)/fs, 20*log10(abs(hilbert(h))));

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

% ---------- helpers ----------
function C50 = compute_C50(ir, fs)
    if size(ir,2) > 1, ir = mean(ir,2); end
    i0 = detect_onset_largest_peak(ir);
    ir = ir(i0:end);
    m = max(abs(ir)); if m > 0, ir = ir./m; end
    e = ir.^2;

    tailN = round(0.2*fs);
    if numel(e) > tailN
        nP = mean(e(end-tailN+1:end));
        e = max(e - nP, 0);
    end

    cutoffSample = round(0.050 * fs);
    lateEnd = min(numel(e), round(1.5*fs));

    earlyEnergy = sum(e(1:min(cutoffSample, numel(e))));
    lateEnergy  = sum(e(min(cutoffSample+1, numel(e)):lateEnd));

    C50 = 10*log10((earlyEnergy + eps) / (lateEnergy + eps));
end

function i0 = detect_onset_first_arrival(x)
    N = max(3, round(0.001*fs));
    env = sqrt(movmean(x.^2, N));
    preN = min(numel(env), round(0.050*fs));
    pre = env(1:preN);
    mu = median(pre);
    madv = median(abs(pre - mu)) + eps;
    thr = mu + 8*madv;
    idx = find(env > thr, 1, 'first');
    if isempty(idx), idx = 1; end
    i0 = max(1, idx - round(0.0005*fs));
end
function i0 = detect_onset_largest_peak(x)
    % Anchor to the absolute largest peak in the IR
    [~, i0] = max(abs(x));
    i0 = max(1, i0 - 10);   % back off 10 samples to catch onset
end
