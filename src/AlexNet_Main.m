clc;
clear all;
close all;

%AlexNet Layer Input Parameters (The layer input parameters are directly provided here instead of a text file since the number of layers are small)
Layer = [1 2 3 4 5 6 7 8];                                  % layer index number
filter_size = [11 5 3 3 3 6 1 1];                           % Height/Width of filter
Nos_of_Filter = [96 256 384 384 256 4096 4096 1000];        % #of total 3D filters
Ifmap_size = [227 31 15 15 15 6 1 1];                       % Height/Width of padded ifmap
Nos_of_Channel = [3 48 256 192 192 256 4096 4096];          % #of total channels in the ifmap/filter
Stride = [4 1 1 1 1 1 1 1];                                 % Convolution stride
Ofmap_size = [55 27 13 13 13 1 1 1];                        % Height/Width of ofmap

%Sparsity (i.e.,fraction of zeros)
Sparsity_if = [00.01 38.70 72.50 79.30 77.60 71.13 83.12 81.25]./100;   %percent sparsity in the padded ifmap volume
Sparsity_Of = [51.02 80.66 72.44 70.18 90.50 83.12 81.25 0]./100;       %percent sparsity in the ofmap volume, ofmap does not have padding

n2 = [1 2 6 6 6 18 18 18];  %Nos of ifmap to process at a time. This values are determined by first simulation.
                            %Since these ifmaps are processed together, it has been made sure that a larger n2(i) value is always wholey divisible...
                            %by a smaller n2(i) value for all values in the n2 array so that there is always zero remainder from the division

%Parameters To Compute Control Energy
MAC = ((filter_size.*filter_size).*Nos_of_Channel).*((Ofmap_size.*Ofmap_size).*Nos_of_Filter);
GMAC = MAC./1e9;                                            % #of MACs in Giga in each layer
Throughput = 23.1;                                          %Throughput of CNN accelerator in GMAC/second
Latency_time = GMAC./Throughput;                            %Time (in second) to process each layer
Clock_Power = 0.1063;                                       %This power (in watt) number for the clock tree is computed from Clock_Tree_Power.m file
%Clock_Power = 0;                                           %To compute CNN energy without the control energy, set Clock_Power = 0
Clock_Energy = Clock_Power.*Latency_time;                   %Energy consumption (in joule) by the clock network
xx = ones(length(Layer),1);
C_prcnt = (xx.*15)./100;                                    %Percent control energy from components other than the clock network
%C_prcnt = (xx.*0)./100;                                    %To compute CNN energy without the control energy, set C_prcnt = 0


bit_flag = 1;  %Binary flag to indicate whether an 8-bit or 16-bit implementation (set bit_flag = 0 for 8-bit, set bit_flag = 1 for 16-bit)

n_flag = 0;  %For the first simulation to determine n2
for i = 1:1:length(Layer)
    [Final_Energy_per_Ifmap(i), n(i), psum_kb(i), ifmap_kb(i), Total_kb(i), Nos_of_NZMAC(i), RF_Acc_MB_1N(i), GLB_Acc_MB_1N(i), DARM_Acc_MB_1N(i),...
       Filter_GLB_MB(i), Ifmap_GLB_MB(i), psum_GLB_MB(i), Filter_DRAM_MB(i), Ifmap_DRAM_MB(i), Ofmap_DRAM_MB(i)] = Analytical_Model(Layer(i),filter_size(i),...
        Nos_of_Filter(i),Ifmap_size(i),Nos_of_Channel(i),Stride(i),Ofmap_size(i),Sparsity_if(i),Sparsity_Of(i),n2(i),n_flag,C_prcnt(i),Clock_Energy(i),bit_flag);
end
n;


n_flag = 1; %For the second simulation. The final energy values are obtained from this simulation
for i = 1:1:length(Layer)
    [Final_Energy_per_Ifmap(i), n(i), psum_kb(i), ifmap_kb(i), Total_kb(i), Nos_of_NZMAC(i), RF_Acc_MB_1N(i), GLB_Acc_MB_1N(i), DARM_Acc_MB_1N(i),...
       Filter_GLB_MB(i), Ifmap_GLB_MB(i), psum_GLB_MB(i), Filter_DRAM_MB(i), Ifmap_DRAM_MB(i), Ofmap_DRAM_MB(i)] = Analytical_Model(Layer(i),filter_size(i),...
        Nos_of_Filter(i),Ifmap_size(i),Nos_of_Channel(i),Stride(i),Ofmap_size(i),Sparsity_if(i),Sparsity_Of(i),n2(i),n_flag,C_prcnt(i),Clock_Energy(i),bit_flag);
end
Final_Energy_per_Ifmap   %This variable contains the final energy values in joule to process each input image


% %%%%Writing the Energy Results into File Without Control Energy
% E_Data_Write = Final_Energy_per_Ifmap';
% fileID = fopen('AlexNet_WO_Cntrl.txt','w');
% fprintf(fileID,'%.16f\n',E_Data_Write);
% fclose(fileID);

%%%%Writing the Energy Results into File With Control Energy
E_Data_Write2 = Final_Energy_per_Ifmap';
fileID = fopen('AlexNet_With_Cntrl.txt','w');
fprintf(fileID,'%.16f\n',E_Data_Write2);
fclose(fileID);

%%%%Plotting The Figure
FS = 24;
LW = 1.5;

h1=figure('Units','inches','PaperPositionMode','Auto');

axes1 = axes('Parent',h1,...
    'FontSize',20,...
    'FontName','Times');

box(axes1,'on');
grid(axes1,'on');
hold(axes1,'all');

A = categorical({'C1','C2','C3','C4','C5','FC1','FC2','FC3'});
neworder = ({'C1','C2','C3','C4','C5','FC1','FC2','FC3'});
Stage1 = reordercats(A,neworder);

bar(Stage1,Final_Energy_per_Ifmap.*1e3,'BarWidth',0.6);

xlabel('Layers of AlexNet','FontSize',FS,'FontName','Times');
ylabel('Energy (mJ)','FontSize',FS,'FontName','Times');
title('Energy to process an image by AlexNet','FontSize',20,'FontName','Times')
grid on;



