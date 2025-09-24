% -------- Build per-file frequency axes --------
faxes = cell(1,N);
for i = 1:N
    faxes{i} = linspace(0, fsArr(i)/2, halfN(i));
end

% -------- Choose a common frequency grid (log-spaced) --------
loHz_use = max([loHz, 20]);                % avoid 0 Hz on log axis
hiHz_use = min([hiHz, min(fsArr)/2]);      % within Nyquist of all files
f_common = logspace(log10(loHz_use), log10(hiHz_use), 2048);

% -------- Interpolate all FRs onto the common grid --------
FR_interp = zeros(N, numel(f_common));
for i = 1:N
    xi = faxes{i}; yi = FR{i};
    pos = xi > 0;
    FR_interp(i,:) = interp1(xi(pos), yi(pos), f_common, 'linear', 'extrap');
end

% -------- Prepare absolute (ref) and relative (others) responses --------
isDB = true;  % set false if impulseToDB returns linear magnitude

% Mask for plot band
mask_common = (f_common >= loHz & f_common <= hiHz);
fc = f_common(mask_common);

% A) Absolute 0° (or whichever index is refIdx), normalized in-band
if isDB
    Y_ref_abs = FR_interp(refIdx, mask_common);
else
    % If FR is linear, convert to dB first for plotting absolute
    Y_ref_abs = 20*log10(abs(FR_interp(refIdx, mask_common)));
end
Y_ref_abs = Y_ref_abs - max(Y_ref_abs);  % normalize ref trace

% B) Relative of all others to refIdx (in dB), each normalized in-band
Y_rel = zeros(N-1, numel(fc));
other_labels = cell(1, N-1);
row = 1;
for i = 1:N
    if i == refIdx, continue; end
    if isDB
        Yi = FR_interp(i, :) - FR_interp(refIdx, :);      % dB subtraction
    else
        eps_reg = 1e-6 * max(abs(FR_interp(refIdx, :)));
        linRel  = FR_interp(i, :) ./ (FR_interp(refIdx, :) + eps_reg);
        Yi      = 20*log10(abs(linRel));                  % convert to dB
    end
    yi = Yi(mask_common);
    yi = yi - max(yi);                                    % normalize this trace
    Y_rel(row, :) = yi;
    other_labels{row} = labels{i};
    row = row + 1;
end

% -------- Overlay plot (ref absolute + others relative) --------
% -------- Overlay plot (ref absolute + others relative) --------
figure('Color','w'); hold on
semilogx(fc, Y_ref_abs, 'LineWidth', 1.3);                 % ref absolute
for k = 1:size(Y_rel,1)
    semilogx(fc, Y_rel(k,:), 'LineWidth', 1.3);            % others relative
end
grid on
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB, normalized)');

% Build legend labels as a cell array of char vectors
legends = cell(1, size(Y_rel,1)+1);
legends{1} = sprintf('%s (abs)', labels{refIdx});
for k = 1:size(Y_rel,1)
    legends{k+1} = sprintf('%s (rel)', other_labels{k});
end
legend(legends, 'Location','best');

title(sprintf('%s absolute; others relative to %s  —  %d–%d Hz', ...
    labels{refIdx}, labels{refIdx}, loHz, hiHz));

% Ref absolute panel
nexttile;
semilogx(fc, Y_ref_abs, 'LineWidth', 1.3); grid on
title(sprintf('%s (absolute)', labels{refIdx}));
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB, normalized)');

% Others relative panels (order preserved)
row = 1;
for i = 1:N
    if i == refIdx, continue; end
    nexttile;
    semilogx(fc, Y_rel(row,:), 'LineWidth', 1.3); grid on
    title(sprintf('%s (relative to %s)', labels{i}, labels{refIdx}));
    xlabel('Frequency (Hz)'); ylabel('Magnitude (dB, normalized)');
    row = row + 1;
end
