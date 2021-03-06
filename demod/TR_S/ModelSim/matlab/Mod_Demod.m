clear;
%clc;
close all;
tic;

%% setup
% Define parameters.
M = 4; % Size of signal constellation
k = log2(M); % Number of bits per symbol
n = 2e4; % Number of bits to process
nsamp = 4; % Oversampling rate
nresamp = 3.992; % Oversampling of TR
carr_offset = 0.001; %0.001; %Carrier frequence offset

%% Signal Source
% Create a binary data stream as a column vector.
x = randint(n,1); % Random binary data stream

%% Bit-to-Symbol Mapping
% Convert the bits in x into k-bit symbols
mapping = [1 0 3 2].';
xsym = bi2de(reshape(x,k,length(x)/k).','left-msb');
xsym = mapping(xsym+1);

%% Modulation
% Modulate using QPSK
y = modulate( modem.qammod(M), xsym);

%% Filter Definition
% Define filter-related parameters.
filtorder = 64; % Filter order
delay = filtorder/(nsamp*2); % Group delay (# of input samples)
rolloff = 0.5; % Rolloff factor of filter

% Create a square root raised cosine filter.
rrcfilter = rcosine(1,nsamp,'fir/sqrt',rolloff,delay);
%rrcfilter = rcosine(1,nsamp,'fir',rolloff,delay);
%rrcfilter = firrcos(64,0.5,0.25,2,'rolloff');

% Plot impulse response.
%figure; impz(rrcfilter,1);

%% Transmitted Signal
% Upsample and apply square root raised cosine filter.

ytx = rcosflt(y,1,nsamp,'filter',rrcfilter);
%figure; 
% subplot(2,1,1),plot(real(ytx(200:500)),'*-');
% title(strcat('���ƶ˳����˲�����źŲ��Σ�I·��(',num2str(nsamp),'�����Ų���)'));
% subplot(2,1,2),plot(imag(ytx(200:500)),'*-');
% title(strcat('���ƶ˳����˲�����źŲ��Σ�Q·��(',num2str(nsamp),'�����Ų���)'));

%Create eye diagram for part of filtered signal.
%eyediagram(ytx(1:2000),nsamp*2);

%% Channel
% Send signal over an AWGN channel.
EbNo = 1500; % In dB
snr = EbNo + 10*log10(k) - 10*log10(nsamp);
ynoisy = awgn(ytx,snr,'measured');
%test
%ynoisy = ytx;

%% Add carrier freq offset
len_y = length(ynoisy);
for ii = 1:len_y   
    ynoisy_carr(ii) = ynoisy(ii)*( cos(2*pi*carr_offset/nsamp*ii) + j*sin(2*pi*carr_offset/nsamp*ii) );   %freq offset is nsamp*(1/4000)
end 

%% Signal Resampling
samp_rate_up=floor(nresamp*1000+1e-10);
samp_rate_down=4000;
ynoisy_resamp = resample( ynoisy_carr,samp_rate_up,samp_rate_down);
%ynoisy_resamp = ynoisy

%% Received Signal
% Filter received signal using square root raised cosine filter.
yrx = rcosflt(ynoisy_resamp,1,nsamp,'Fs/filter',rrcfilter);
% figure; subplot(2,1,1),plot(real(yrx(200:500)),'*-');
% title(strcat('�����ƥ���˲�����źŲ��Σ�I·��(',num2str(nresamp),'�����Ų���)'));
% subplot(2,1,2),plot(imag(yrx(200:500)),'*-');
% title(strcat('�����ƥ���˲�����źŲ��Σ�Q·��(',num2str(nresamp),'�����Ų���)'));

%% Timing Recovery

%plot(real(yrx),'*-');
remove_end = 128;
yrx = yrx( 1:length(yrx)-remove_end );

m=[real(yrx),imag(yrx)];
m=round(m*60);
fid = fopen('tr_in.txt','w');
for i=1:length(m)
    fprintf(fid,'%d\t%d\n',[m(i,1),m(i,2)]);
end
fclose(fid); 
 
% m_len = length(m(:,1));
% m_len2 = m_len-mod(m_len,8);
% m_mod8 = m(1:m_len2 , :);
% m_p8 = reshape(m_mod8',16,m_len2/8);
% fid = fopen('DataP8_matlab_gen.txt','w');
% for i=1:length(m_p8(1,:))
%     fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',[m_p8(1,i),m_p8(2,i),m_p8(3,i),m_p8(4,i),m_p8(5,i),m_p8(6,i),m_p8(7,i),m_p8(8,i),m_p8(9,i),m_p8(10,i),m_p8(11,i),m_p8(12,i),m_p8(13,i),m_p8(14,i),m_p8(15,i),m_p8(16,i)]);
% end
% fclose(fid); 

return;

 [yrx_trout,loop_filter,ob_u,loop_acc]=TimerRecovery_QPSK_v4(yrx,0,0);

figure;
plot(loop_filter);
title('ʱ�ӻָ�ģ�黷·�˲������');
%ylim([-0.12,0.12]);
figure;
plot(loop_acc);
title('ʱ�ӻָ�ģ�黷·�˲������ۼ�·���');
%return;
figure;
plot(ob_u);
ylim([-0.1,1.1]);
title('ʱ�ӻָ�ģ���ֵ����ֵ��ƫ�');

%% Scatter Plot (TR)
% % Create scatter plot of received signal before and
% % after filtering.
% h = scatterplot(sqrt(nsamp)*ynoisy(1:nsamp*5e3),nsamp,0,'g.');
% hold on;
% scatterplot(yrx_out(1:5e3),1,0,'kx',h);
% title('Received Signal, Before and After Filtering');
% legend('Before Filtering','After Filtering');
% axis([-5 5 -5 5]); % Set axis ranges.

figure;
m_inphase = yrx_trout( :,1);
m_quadphase = yrx_trout(:,2);
m_n = 1000;
m_k = floor( length(m_inphase)/m_n );
for m_i= 1:m_k
    m_inphase_t = m_inphase( (m_i-1)*m_n+1 : m_i*m_n );
    m_quadphase_t = m_quadphase( (m_i-1)*m_n+1 : m_i*m_n );
    plot(m_inphase_t,m_quadphase_t,'*');
    title('ʱ�ӻָ�ģ���������ͼ');
    axis([-1,1,-1,1]);
    grid on;
    pause(0.5);
end

%% Carrier Recovery
yrx_trout_complex=yrx_trout(:,1)+j*yrx_trout(:,2);

[yrx_crout,yrx_loopf]=carrier_recovery(yrx_trout_complex.');

figure; plot(yrx_loopf/(2*pi));
title('�ز��ָ�ģ�黷·�˲������');
%% Scatter Plot (TR)
figure;
m_inphase = real(yrx_crout);
m_quadphase = imag(yrx_crout);
m_n = 1000;
m_k = floor( length(m_inphase)/m_n );
for m_i= 1:m_k
    m_inphase_t = m_inphase( (m_i-1)*m_n+1 : m_i*m_n );
    m_quadphase_t = m_quadphase( (m_i-1)*m_n+1 : m_i*m_n );
    plot(m_inphase_t,m_quadphase_t,'*');
    title('�ز��ָ�ģ���������ͼ');
    axis([-1,1,-1,1]);
    grid on;
    pause(0.5);
end

%% Demodulation
% Demodulate signal using 16-QAM.
yrx_trout = complex( yrx_trout(:,1), yrx_trout(:,2) );
zsym = demodulate(modem.qamdemod(M),yrx_trout);

%% Symbol-to-Bit Mapping
% Undo the bit-to-symbol mapping performed earlier.

% A. Define a vector that inverts the mapping operation.
[dummy demapping] = sort(mapping);
% Initially, demapping has values between 1 and M.
% Subtract 1 to obtain values between 0 and M-1.
demapping = demapping - 1;

% B. Map between Gray and binary coding.
zsym = demapping(zsym+1);

% C. Do ordinary decimal-to-binary mapping.
z = de2bi(zsym,'left-msb');
% Convert z from a matrix to a vector.
z = reshape(z.',prod(size(z)),1);

%% BER Computation
% Compare x and z to obtain the number of errors and
% the bit error rate.
z = z(1: length(z)-4*delay);
% x = x(1: min(length(x),length(z)));
num_throw = 1e4; %5.5e4
%throw2 = fir_order/4;
throw2 = filtorder;
x_comp = x(num_throw-throw2:length(x)-throw2);
z_comp = z( num_throw-length(x)+length(z) : length(z) );
[number_of_errors,bit_error_rate] = biterr( x_comp , z_comp )

toc















