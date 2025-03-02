clc;
clear;
close all;

% Parametri simulacije
f_samp = 60.94e6; % Vzorcev na sekundo
bit_samp = 12; % Ločljivost ADC-ja
f_ref = 10e6; % Referenčna frekvenca signala

% Trajanje simulacije in vzorčenje
mem_size = ceil(2^nextpow2(f_samp / f_ref)); % Za celo število period
time = (0:mem_size-1) / f_samp; % Časovni vektor

% Generacija referenčnega signala (12-bitni ADC)
ref_signal = int16((sin(2*pi*f_ref*time) + 1) * (2^(bit_samp-1)-1));

% Generacija testnega signala z faznim zamikom
test_phase_deg = 0:5:360; % Testni fazni zamiki (°)
test_phase_rad = deg2rad(test_phase_deg); % Pretvorba v radiane
errors = zeros(size(test_phase_deg)); % Za shranjevanje napak

for idx = 1:length(test_phase_deg)
    % Testni signal z zamikom
    test_signal = int16((sin(2*pi*f_ref*time + test_phase_rad(idx)) + 1) * (2^(bit_samp-1)-1));
    
    % Zero-crossing detekcija za referenčni signal
    ref_zero_crossings = find(diff(ref_signal > 2^(bit_samp-1)) ~= 0);
    test_zero_crossings = find(diff(test_signal > 2^(bit_samp-1)) ~= 0);
    
    % Izračun faznega zamika na osnovi časovnih razlik
    if length(ref_zero_crossings) >= 2 && length(test_zero_crossings) >= 2
        ref_period = mean(diff(ref_zero_crossings)) / f_samp; % Povprečna perioda
        time_shift = (test_zero_crossings(1) - ref_zero_crossings(1)) / f_samp; % Časovni zamik
        phase_shift = mod(time_shift / ref_period * 360, 360); % Faza v stopinjah
    else
        phase_shift = NaN; % Če ni dovolj prehodov
    end
    
    % Shranjevanje napake
    errors(idx) = mod(phase_shift - test_phase_deg(idx) + 180, 360) - 180; % Napaka
end

% Vizualizacija napake
figure;
plot(test_phase_deg, errors, '-o');
title('Napaka faznega zamika');
xlabel('Testni fazni zamik (°)');
ylabel('Napaka (°)');
grid on;

disp('Simulacija zaključena.');
