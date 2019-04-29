clc;
clear all;
close all;

load 'GoogleNet_v1_Input_File.txt';      %.txt file which contains the layer input parameters for GoogleNet-v1

%GoogleNet-v1 Layer Input Parameters
Layer = GoogleNet_v1_Input_File(:,1);              % layer index number
Ifmap_size_unpad = GoogleNet_v1_Input_File(:,2);   % Height/Width of ifmap without padding
Nos_of_Channel = GoogleNet_v1_Input_File(:,3);     % #of total channels in the ifmap/filter
filter_size = GoogleNet_v1_Input_File(:,4);        % Height/Width of filter
Nos_of_Filter = GoogleNet_v1_Input_File(:,5);      % #of total 3D filters
Ofmap_size = GoogleNet_v1_Input_File(:,6);         % Height/Width of ofmap
Stride = GoogleNet_v1_Input_File(:,7);             % Convolution stride
Pad = GoogleNet_v1_Input_File(:,8);                % Amount of padding in the ifmap
Ifmap_size = Ifmap_size_unpad + (2.*Pad);          % Height/Width of padded ifmap


%Sparsity (i.e.,fraction of zeros) extraction for padded ifmap
Sparsity_if_unpad = GoogleNet_v1_Input_File(:,9);      %percent sparsity in the unpadded ifmap volume
Padded_zero = (Ifmap_size.*Ifmap_size.*Nos_of_Channel) - (Ifmap_size_unpad.*Ifmap_size_unpad.*Nos_of_Channel);   %total nos of padded zero in the ifmap volume
Ifmap_zero_unpad = Sparsity_if_unpad.*(Ifmap_size_unpad.*Ifmap_size_unpad.*Nos_of_Channel);    %total zero in the unpadded ifmap volume

Sparsity_if = (Ifmap_zero_unpad + Padded_zero)./(Ifmap_size.*Ifmap_size.*Nos_of_Channel);    %percent sparsity in the padded ifmap volume
Sparsity_Of = GoogleNet_v1_Input_File(:,10);           %percent sparsity in the ofmap volume, ofmap does not have any padding


n2 = [1 1 1 1 1 1 2 2 1 1 1 1 2 2 1 2 2 2 6 6 2 2 2 2 6 6 2 2 2 2 6 6 2 2 2 2 6 6 2 2 2 2 6 6 2 6 6 6 18 18 6 6 6 6 18 18 6 36];  %Nos of ifmap to process at a time. This values are determined by first simulation.
                                        %Since these ifmaps are processed together, it has been made sure that a larger n2(i) value is always wholey divisible...
                                        %by a smaller n2(i) value for all values in the n2 array so that there is always zero remainder from the division

%Parameters To Compute Control Energy
MAC = ((filter_size.*filter_size).*Nos_of_Channel).*((Ofmap_size.*Ofmap_size).*Nos_of_Filter);
GMAC = MAC./1e9;                                            % #of MACs in Giga 
Throughput = 23.1;                                          %Throughput of CNN accelerator in GMAC/second
Latency_time = GMAC./Throughput;                            %Time to process each layer
Clock_Power = 0.1063;                                       %This power number for the clock tree is computed from Clock_Tree_Power.m file
%Clock_Power = 0;                                           %To compute CNN energy without the control energy, set Clock_Power = 0
Clock_Energy = Clock_Power.*Latency_time;
xx = ones(length(Layer),1);
C_prcnt = (xx.*15)./100;                                    %Percent control energy from components other than the clock network
%C_prcnt = (xx.*0)./100;                                    %To compute CNN energy without the control energy, set C_prcnt = 0

bit_flag = 1;  %Binary flag to indicate whether an 8-bit or 16-bit implementation (set bit_flag = 0 for 8-bit, set bit_flag = 1 for 16-bit)

n_flag = 0; %For the first simulation to determine n2 
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


%%%Plot of energy for all 58 layer
Stage = 1:1:length(Final_Energy_per_Ifmap);
figure
plot(Stage,Final_Energy_per_Ifmap.*1e3,'--ro')
set(gca,'xtick',[Stage]);
xlabel('Layers of GoogleNet-v1');
ylabel('Energy (mJ)');
title('Energy for all uncombined layers')
grid on

%%%Extraction of energy for actual 13 layer (The layers inside an inception module are combined)
Energy(1) = Final_Energy_per_Ifmap(1);
Energy(2) = Final_Energy_per_Ifmap(2); 
Energy(3) = Final_Energy_per_Ifmap(3);
Energy(4) = sum(Final_Energy_per_Ifmap(4:9));         % Inception layer energy
Energy(5) = sum(Final_Energy_per_Ifmap(10:15));
Energy(6) = sum(Final_Energy_per_Ifmap(16:21));
Energy(7) = sum(Final_Energy_per_Ifmap(22:27));
Energy(8) = sum(Final_Energy_per_Ifmap(28:33));
Energy(9) = sum(Final_Energy_per_Ifmap(34:39));
Energy(10) = sum(Final_Energy_per_Ifmap(40:45));
Energy(11) = sum(Final_Energy_per_Ifmap(46:51));
Energy(12) = sum(Final_Energy_per_Ifmap(52:57));
Energy(13) = Final_Energy_per_Ifmap(58);

Energy;

%%%Plot of energy for the combined 13 layer
figure
FS = 20;
LW = 1.5;
A = categorical({'C1','C2a','C2b','IC3a','IC3b','IC4a','IC4b','IC4c','IC4d','IC4e','IC5a','IC5b','FC'});
neworder = ({'C1','C2a','C2b','IC3a','IC3b','IC4a','IC4b','IC4c','IC4d','IC4e','IC5a','IC5b','FC'});
Stage2 = reordercats(A,neworder);
bar(Stage2,Energy.*1e3,'BarWidth',0.6)
xlabel('Layers of GoogleNet-v1','FontSize',FS,'FontName','Times');
ylabel('Energy (mJ)','FontSize',FS,'FontName','Times');
title('Energy to process an image by GoogleNet-v1','FontSize',18,'FontName','Times')
grid on


% %%%%Writing the Energy Results into File Without EControl
% E_Data_Write1 = Energy';
% fileID = fopen('GoogleNet_WO_Cntrl.txt','w');
% fprintf(fileID,'%.16f\n',E_Data_Write1);
% fclose(fileID);

%%%%Writing the Energy Results into File With EControl
E_Data_Write2 = Energy';
fileID = fopen('GoogleNet_With_Cntrl.txt','w');
fprintf(fileID,'%.16f\n',E_Data_Write2);
fclose(fileID);





