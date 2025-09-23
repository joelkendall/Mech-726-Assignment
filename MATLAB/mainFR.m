[lectureIR, fs] = audioread("./../Recordings/Lecture theater/Lecture Theater Sep 20 2m-48k.wav");
[lectureBackIR, fs2] = audioread("./../Recordings/Lecture theater/Lecture Theater Sep 20 back 2m-48k.wav");
[loudspeakerIR, fs3] = audioread("./../Recordings/Lab/Aug 22-48k.wav");

[frontLectureFR, half1] = impulseToDB(lectureIR);
[backLectureFR, half2] = impulseToDB(lectureBackIR);
[loudspeakerFR, half3] = impulseToDB(loudspeakerIR);

eps_reg = 1e-3 * max(abs(loudspeakerFR));
lectureFrontRemovedFR = (frontLectureFR ./ (loudspeakerFR + eps_reg));
lectureBackRemovedFR = (backLectureFR ./ (loudspeakerFR + eps_reg));

f = linspace(0, fs/2, half1);
f2 = linspace(0, fs2/2, half2);

mask = (f >= 100 & f <= 10000); %100 Hz – 10 kHz
f_plot = f(mask);
lectureDBPlot = lectureFrontRemovedFR(mask);
f2_plot = f2(mask);
lectureBackDBPlot = lectureBackRemovedFR(mask);

lectureBackDBPlot = lectureBackDBPlot - max(lectureBackDBPlot);
lectureDBPlot = lectureDBPlot - max(lectureDBPlot);

figure('Color','w');

subplot(1, 2, 1)
semilogx(f_plot, lectureDBPlot, 'LineWidth', 1.3);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB normalised to 0dB peak)');
title('Room FR (100 Hz – 10 kHz) - Position 1 (Close to walls)');


subplot(1, 2, 2)
semilogx(f2_plot, lectureBackDBPlot, 'LineWidth', 1.3);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB normalised to 0dB peak)');
title('Room FR (100 Hz – 10 kHz) - Position 2 (Middle of Room)');




