clc
clear all
close all
format long;

fdesired = 8000000000; % 8 GHz

f_ref = 60000000;
r_div = 1;
mod = 2097151;
n_frac = 1;
n_int = 0;
vco_double_frequency = 2;

freq_rf1 = (f_ref / r_div) * vco_double_frequency * (n_int + n_frac/mod);
freq_rf2 = 2 * freq_rf1

freq_rf1_ghz = freq_rf1 / 1000000000;
freq_rf2_ghz = freq_rf1_ghz * 2