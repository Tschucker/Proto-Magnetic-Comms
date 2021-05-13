%% Magnicomms PAM8 900Hz Lowsub 0Boost
% Tom Schucker
%
% Description:
%   Recover symbols from recorded magnetometer readings transmitted from
%   flexAR connected to AnalogDiscovery Waveform gen
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
RawData1 = readtable("/home/tom/Desktop/working_dir/magnicoms/data/pam8/pam8_300hz_lowsub_0boost_moretransitions/Raw Data.csv", opts);


%Clear temporary variables
clear opts

%% Plot Z data and try symbol sync
figure;
plot(RawData1.MagneticFieldzT)
title('Raw Magnetic Data');

symbolSync = comm.SymbolSynchronizer('TimingErrorDetector','Early-Late (non-data-aided)','SamplesPerSymbol', 26);

norm_data = normalize(RawData1.MagneticFieldzT,'range');
figure;
plot(norm_data)
title('Normalized Raw Data');

eyediagram(norm_data-.5,26)
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
plot(RawData1.Times)
title('Sampling Times');

times = RawData1.Times;

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
b = zeros(1,24*2);
for i =17:(17+18)
  b(i) = 1;
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
decim = 20;
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
scatterplot(symbols);
title('Recovered Constellation');

figure;
plot(symbols)
title('Recovered Symbol Samples');

eyediagram(symbols,2);
title('Recovered Eye');




