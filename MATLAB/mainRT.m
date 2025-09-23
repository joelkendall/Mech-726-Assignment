clc; clear;

%% ===== Setup =====
addpath('filterbanks');   % contains oct3dsgn.m

% Load IRs for Positions A & B (mono)
[irA, fsA] = audioread("./../Recordings/Lecture theater/Lecture Theater Sep 20 2m-48k.wav");
[irB, fsB] = audioread("./../Recordings/Lecture theater/Lecture Theater Sep 20 back 2m-48k.wav");
assert(fsA==fsB, 'Sample rates must match'); fs = fsA;
irA = mean(irA,2); irB = mean(irB,2);

% 1/3-octave centres: 250–4000 Hz
bands = [250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000];

% (Optional) trim to direct sound to improve SNR before EDC
irA = trim_to_direct(irA);
irB = trim_to_direct(irB);

%% ===== Compute bandwise EDT & T20 using oct3dsgn + filter =====
[EDT_A, T20_A, R2_EDT_A, R2_T20_A] = rt_bands_oct3(irA, fs, bands);
[EDT_B, T20_B, R2_EDT_B, R2_T20_B] = rt_bands_oct3(irB, fs, bands);

%% ===== Plot: EDT & T20 vs frequency (both positions on one graph) =====
figure;
semilogx(bands, EDT_A, '-o', 'LineWidth', 1.6); hold on;
semilogx(bands, T20_A, '-x', 'LineWidth', 1.6);
semilogx(bands, EDT_B, '--o', 'LineWidth', 1.6);
semilogx(bands, T20_B, '--x', 'LineWidth', 1.6);
grid on; xlim([250 4000]);
xlabel('Centre frequency (Hz)'); ylabel('Reverberation time (s)');
title('EDT & T20 per 1/3-octave band (Positions A & B)');
legend('A: EDT','A: T20','B: EDT','B: T20','Location','best');

%% ===== (Optional) sanity check: show filter response for a band =====
%{
fc = 1000;
[B,A] = oct3dsgn(fc, fs, 3);       % N=3 per manual’s suggestion
fvtool(B, A, 'Fs', fs);            % inspect magnitude and poles/zeros
%}

%% ================= Helper functions =================
function x = trim_to_direct(x)
    % keep a handful of samples before the absolute-peak (direct sound)
    [~,i0] = max(abs(x)); i0 = max(1, i0-10);
    x = x(i0:end);
end

function [EDT, T20, R2_EDT, R2_T20] = rt_bands_oct3(h, fs, fcs)
    N = numel(fcs);
    EDT = nan(N,1);  T20 = nan(N,1);
    R2_EDT = nan(N,1); R2_T20 = nan(N,1);

    for k = 1:N
        fc = fcs(k);

        % 1/3-oct band filter (per manual): B,A = oct3dsgn(fc,Fs,N); y = filter(B,A,x)
        [B,A] = oct3dsgn(fc, fs, 3);          % start with order N=3 (manual)
        y = filter(B, A, h);                  % use filter(), per slides

        % Schroeder EDC (manual Section "EDC Calculation")
        e   = y.^2;
        EDC = flipud(cumsum(flipud(e)));      % backward integration
        EDC = EDC ./ max(EDC + eps);          % normalise to 0 dB at start
        EDCdB = 10*log10(EDC + eps);
        t = (0:numel(y)-1).'/fs;

        % --- EDT: 0 to -10 dB, extrapolate to -60 dB
        [m1,b1,mask1,ok1] = linear_fit_db(t, EDCdB, [0 -10]);
        if ok1 && m1 < 0
            EDT(k)   = -60 / m1;
            R2_EDT(k)= rsq(EDCdB(mask1), m1*t(mask1)+b1);
        end

        % --- T20: -5 to -25 dB, extrapolate to -60 dB
        [m2,b2,mask2,ok2] = linear_fit_db(t, EDCdB, [-5 -25]);
        if ok2 && m2 < 0
            T20(k)    = -60 / m2;            % = 3 * (-20/m2)
            R2_T20(k) = rsq(EDCdB(mask2), m2*t(mask2)+b2);
        end
    end
end

function [m,b,mask,ok] = linear_fit_db(t, ydb, range_dB)
    hi = max(range_dB); lo = min(range_dB);
    mask = (ydb <= hi + 1e-12) & (ydb >= lo - 1e-12);
    tt = t(mask); yy = ydb(mask);
    ok = numel(tt) >= 8;
    if ok
        X = [tt, ones(size(tt))];       % slides: prepare X, Y then B = X\Y
        B = X \ yy;                     % least squares (backslash)
        m = B(1); b = B(2);
    else
        m = NaN; b = NaN;
    end
end

function R2 = rsq(y, yhat)
    ybar = mean(y);
    SSres = sum((y - yhat).^2);
    SStot = sum((y - ybar).^2);
    R2 = max(0, 1 - SSres/max(eps,SStot));   % manual shows R^2 formula
end
