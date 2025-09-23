freqBands = [250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000];

EDT_values = NaN(length(freqBands), 1);
T20_values = NaN(length(freqBands), 1);

for i = 1:length(freqBands)
    [B, A] = oct3dsgn(freqBands(i), fs, 3); 
    filteredIR = filter(B, A, lectureIR);

    h2 = filteredIR.^2;
    EDC = flipud(cumsum(flipud(h2)));
    EDC = EDC / max(EDC);
    EDC_dB = 10*log10(EDC);
    t = (0:length(filteredIR)-1)/fs;

    fprintf('\n[%d Hz] EDC Range: %.1f dB to %.1f dB\n', ...
        freqBands(i), max(EDC_dB), min(EDC_dB));

    % ---- EDT ----
    mask_EDT = (EDC_dB <= 0) & (EDC_dB >= -10);
    t_EDT = t(mask_EDT); 
    y_EDT = EDC_dB(mask_EDT);

    % Force column vectors
    t_EDT = t_EDT(:);
    y_EDT = y_EDT(:);

    if length(t_EDT) > 5
        X_EDT = [t_EDT ones(size(t_EDT))];
        B_EDT = X_EDT \ y_EDT;
        slope_EDT = B_EDT(1);
        if slope_EDT < 0
            EDT_values(i) = -60 / slope_EDT;
        end
    else
        fprintf('  Skipping EDT — not enough points\n');
    end

    % ---- T20 ----
    mask_T20 = (EDC_dB <= -5) & (EDC_dB >= -25);
    t_T20 = t(mask_T20); 
    y_T20 = EDC_dB(mask_T20);

    % Force column vectors
    t_T20 = t_T20(:);
    y_T20 = y_T20(:);

    if length(t_T20) > 5
        X_T20 = [t_T20 ones(size(t_T20))];
        B_T20 = X_T20 \ y_T20;
        slope_T20 = B_T20(1);
        if slope_T20 < 0
            T20_values(i) = -60 / slope_T20;
        end
    else
        fprintf('  Skipping T20 — not enough points\n');
    end
end

% Plot results
figure;
semilogx(freqBands, EDT_values, '-o', 'LineWidth', 1.5); hold on;
semilogx(freqBands, T20_values, '-x', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Reverberation Time (s)');
title('EDT and T20 per 1/3-Octave Band');
legend('EDT', 'T20');
grid on;
