%% Import data from text file
% Script for importing data from the following text file:
%
%    filename: /home/tom/Desktop/working_dir/magnicoms/data/nrz/nrz_900hz_ps_all/Raw Data.csv
%
% Auto-generated by MATLAB on 08-May-2021 21:10:34
clear;
%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Times", "MagneticFieldxT", "MagneticFieldyT", "MagneticFieldzT", "AbsolutefieldT"];
opts.VariableTypes = ["double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
RawData = readtable("/home/tom/Desktop/working_dir/magnicoms/data/nrz/nrz_900hz_ps_all/Raw Data.csv", opts);

% Clear temporary variables
clear opts

%% Plot Z data and try symbol sync
figure;
plot(RawData.MagneticFieldzT)
title('Raw Magnetic Data');

symbolSync = comm.SymbolSynchronizer('TimingErrorDetector','Early-Late (non-data-aided)','SamplesPerSymbol', 17);

norm_data = normalize(RawData.MagneticFieldzT,'range');
figure;
plot(norm_data)
title('Normalized Raw Data');

eyediagram(norm_data-.5,17)
title('Raw Data Eye Diagram');

rxSync = symbolSync(norm_data-.5);
scatterplot(rxSync);
title('Matlab Symbol Sync Constellation');

eyediagram(real(rxSync),2)
title('Matlab Symbol Sync Eye Diagram');

figure;
plot(real(rxSync))
title('Matlab Symbol Sync Recovered Symbols');

%% Plot time sampling probably non-uniform
figure;
plot(RawData.Times)
title('Sampling Times');

times = RawData.Times;

for i=1:length(times)-1
    time_diffs(i) = times(i) - times(i+1);
end 

figure;
plot(time_diffs)
title('Difference Between Sample Times');

figure;
plot(times, norm_data)
title('Sampling Time spaced Samples');

%% Create my own symbol syncronizer
% Matchfilter -> Derivative -> signum -> find zero crossings
% select Matched filter sample at zero crossing

% Create Matched Filter
b = zeros(1,17*2);
for i = 12:(22)
  b(i) = 2;
end
  
figure;
plot(b)
title('Matched Filter');

% Filter Normalized Balance-shifted Signal
matched_data = filter(b,1,norm_data-.5);

% Take Derivative of the Matchedfilter Output
diff_matched = diff(matched_data);

figure;
plot(matched_data)
hold on
plot(diff_matched)
title('Filtered Data');

% Find Sign of Derivative Output
s_diff = sign(diff_matched);
figure;
plot(matched_data)
hold on
plot(s_diff)
title('Zero Crossings');

% Find Zero Crossings
n = 1;
decim = 12;
decim_cnt = 1;

sampling_pts = [];
symbols = [];

for i=1:length(s_diff)-1
    test(i) = s_diff(i) + s_diff(i+1);
    if ((s_diff(i) + s_diff(i+1)) == 0) && (decim_cnt >= decim)
        sampling_pts(n) = i;
        symbols(n) = matched_data(i);
        n = n + 1;
        decim_cnt = 1;
    else
        decim_cnt = decim_cnt + 1;
    end
end

% Plot Recovered Symbols
scatterplot(symbols(2:end));
title('Recovered Constellation');

figure;
plot(symbols)
title('Recovered Symbol Samples');

eyediagram(symbols(2:end),2);
title('Recovered Eye');


%% BER pattern

pattern = [1,1,1,-1,-1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,-1,1,1,-1,-1];

full_pat = [];
while length(full_pat) <= length(symbols)
    full_pat = [full_pat pattern];
end

[c,lags] = xcorr(symbols, full_pat);
stem(lags,c)
[M,I] = max(c);

y = circshift(full_pat,lags(I));

figure;
plot(sign(symbols))
hold on;
plot(y)
legend('recovered','actual');
title('Symbol Comparison');
