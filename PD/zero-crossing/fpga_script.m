clc
clear all
close all

f_samp = 60.94e6; % do 65 Msps (nek primer ure, ki je na ICE40 izvedljiva s 60 MHz kristalom)
bit_samp = 12; % 12 bit ADC

f_ref = 10e6; % 10 MHz signal
five_periods = 5/f_ref;

test_gain = 1/10; % 10 dB dampening
test_phase = 11/180*pi; % phase shift

% simulation with 100 samples per period
%f_sim = f_samp;
f_sim = 160*f_samp;

% minimum sample size
mss_mult = 6;
min_mem_size = 65*20;%lcm(f_ref/1e6, f_samp/1e6);
mem_size_n = ceil(log2(min_mem_size)) + mss_mult;
mem_size = 2^mem_size_n;
min_sample_time = mem_size/f_samp;

% Generate signals for processing
%out = sim("dataflow.slx");
out.ref = int16( ( sin(2*pi*f_ref*(0:1/f_samp:(mem_size-1)/f_samp))/2 + 0.5 )*2^bit_samp );
out.test = int16( ( sin(2*pi*f_ref*(0:1/f_samp:(mem_size-1)/f_samp) + test_phase)/2 + 0.5 )*2^bit_samp );

%sin_synth = sin(linspace(0, 2*pi, mem_size));
%cos_synth = cos(linspace(0, 2*pi, mem_size));

% FPGA section
sin_synth = int16( ( sin(2*pi*f_ref*(0:1/f_samp:(mem_size-1)/f_samp))/2 + 0.5 )*2^bit_samp );
cos_synth = int16( ( cos(2*pi*f_ref*(0:1/f_samp:(mem_size-1)/f_samp))/2 + 0.5 )*2^bit_samp );
sinsat_synth = bitget(sin_synth, bit_samp);
cossat_synth = bitget(cos_synth, bit_samp);
%sin_synth = sin(2*pi*f_ref*(0:1/f_samp:mem_size/f_samp));
%cos_synth = cos(2*pi*f_ref*(0:1/f_samp:mem_size/f_samp));
%sinsat_synth = sin_synth >= 0;
%cossat_synth = cos_synth >= 0;

% Accumulators
ref_i_ac = 0;
ref_q_ac = 0;

test_i_ac = 0;
test_q_ac = 0;

% Testing vectors
ref_i_arr = zeros(1,mem_size,'uint32');
ref_q_arr = zeros(1,mem_size,'uint32');
test_i_arr = zeros(1,mem_size,'uint32');
test_q_arr = zeros(1,mem_size,'uint32');
ref_lim_arr = zeros(1,mem_size,'uint32');
test_lim_arr = zeros(1,mem_size,'uint32');

% Amplitude variables
ref_amp = 0;
test_amp = 0;

for n = 1:mem_size
    % Take the samples
    ref_s = out.ref(n);
    test_s = out.test(n);

    % Get MSB (effectively saturating the signal)
    ref_sig = bitget(ref_s, bit_samp);
    test_sig = bitget(test_s, bit_samp);

    % Debug values, not for FPGA
    ref_lim_arr(n) = ref_sig;
    test_lim_arr(n) = test_sig;
    % End debug
    
    % Mix the signals
    %ref_imix = ref_sig - sinsat_synth(n);
    %ref_qmix = ref_sig - cossat_synth(n);
    %test_imix = test_sig - sinsat_synth(n);
    %test_qmix = test_sig - cossat_synth(n);

    ref_imix = xor(ref_sig, sinsat_synth(n));
    ref_qmix = xor(ref_sig, cossat_synth(n));
    test_imix = xor(test_sig, sinsat_synth(n));
    test_qmix = xor(test_sig, cossat_synth(n));
    
    % Debug values, not for FPGA
    ref_i_arr(n) = ref_imix;
    ref_q_arr(n) = ref_qmix;
    test_i_arr(n) = test_imix;
    test_q_arr(n) = test_qmix;
    % End debug
    
    % Get max signal value for amplitude
    if ref_s > ref_amp
        ref_amp = ref_s;
    end

    if test_s > test_amp
        test_amp = test_s;
    end
    
    % accumulate values
    ref_i_ac = ref_i_ac + ref_imix;
    ref_q_ac = ref_q_ac + ref_qmix;

    test_i_ac = test_i_ac + test_imix;
    test_q_ac = test_q_ac + test_qmix;
end

% vsakih mem_size ciklov se izvede izračun končnih vrednosti
% phase
%ref_i = bitshift(ref_i_ac*10000, -mem_size_n);
%ref_q = bitshift(ref_q_ac*10000, -mem_size_n);
%test_i = bitshift(test_i_ac*10000, -mem_size_n);
%test_q = bitshift(test_q_ac*10000, -mem_size_n);
ref_i = ref_i_ac;%-mem_size/2;
ref_q = ref_q_ac;%-mem_size/2;
test_i = test_i_ac;%-mem_size/2;
test_q = test_q_ac;%-mem_size/2;

if ref_q_ac < mem_size/2
    ph_ref_s = 180*ref_i_ac/mem_size;
else
    ph_ref_s = -180*ref_i_ac/mem_size;
end

if test_q_ac < mem_size/2
    ph_test_s = 180*test_i_ac/mem_size;
else
    ph_test_s = -180*test_i_ac/mem_size;
end

ph_ref_s
ph_test_s
ph_dif = wrapTo360(ph_test_s-ph_ref_s)


%ref_phase = mean(ref_lim)
perioda = 4;
period_n = 2;
perioda_len = 130;
minx=perioda*perioda_len;
maxx=(perioda + period_n)*perioda_len;

%{
% Primerjava spektrov generiranega signala in "vzorčenega"
figure(10)
fft_plot(ref_lim_arr, f_samp)
figure(20)
fft_plot(sinsat_synth, f_samp)

% -------------------------- SIN --------------------------
f1 = figure(1);
f1.Name = "Sin";
subplot(3, 1, 1)
plot(out.ref)
hold on
bar(ref_lim_arr*2^bit_samp)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Referenca")
xlim([minx, maxx])

subplot(3, 1, 2)
plot((sin_synth + 1)/2)
hold on
bar(sinsat_synth)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Sinteza")
xlim([minx, maxx])

subplot(3, 1, 3)
bar(ref_i_arr)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Razlika Faze")
xlim([minx, maxx])

% -------------------------- COS --------------------------
f2 = figure(2);
f2.Name = "Cos";
subplot(3, 1, 1)
plot(out.ref)
hold on
bar(ref_lim_arr*2^bit_samp)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Referenca")
xlim([minx, maxx])

subplot(3, 1, 2)
plot((cos_synth + 1)/2)
hold on
bar(cossat_synth)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Sinteza")
xlim([minx, maxx])

subplot(3, 1, 3)
bar(ref_q_arr)
hold on
xline(0:perioda_len:(floor(mem_size/perioda_len)*perioda_len), "-r")
title("Razlika Faze")
xlim([minx, maxx])
%}