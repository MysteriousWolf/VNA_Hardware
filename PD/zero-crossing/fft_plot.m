function []=fft_plot(y,Fs)
% y = input data;
% Fs= sampling freq.

L=length(y);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
semilogx(f,20*log10(2*abs(Y(1:NFFT/2+1))))
% semilogx(f,abs(Y(1:NFFT/2+1)))
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
grid;
