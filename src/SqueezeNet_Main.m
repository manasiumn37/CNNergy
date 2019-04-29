clc;
clear all;
close all;

load 'SqueezeNet_v11_Input_File.txt';  %.txt file which contains the layer input parameters for SqueezeNet-v11

%SqueezeNet-v11 Layer Input Parameters
Layer = SqueezeNet_v11_Input_File(:,1);              % layer index number
Ifmap_size_unpad = SqueezeNet_v11_Input_File(:,2);   % Height/Width of ifmap without padding
Nos_of_Channel = SqueezeNet_v11_Input_File(:,3);     % #of total channels in the ifmap/filter
filter_size = SqueezeNet_v11_Input_File(:,4);        % Height/Width of filter
Nos_of_Filter = SqueezeNet_v11_Input_File(:,5);      % #of total 3D filters
Ofmap_size = SqueezeNet_v11_Input_File(:,6);         % Height/Width of ofmap
Stride = SqueezeNet_v11_Input_File(:,7);             % Convolution stride
Pad = SqueezeNet_v11_Input_File(:,8);                % Amount of padding in the ifmap
Ifmap_size = Ifmap_size_unpad + (2.*Pad);            % Height/Width of padded ifmap


%Sparsity extraction for padded ifmap
Sparsity_if_unpad = SqueezeNet_v11_Input_File(:,9);      %percent sparsity in the unpadded ifmap volume
Padded_zero = (Ifmap_size.*Ifmap_size.*Nos_of_Channel) - (Ifmap_size_unpad.*Ifmap_size_unpad.*Nos_of_Channel);   %total nos of padded zero in the ifmap volume
Ifmap_zero_unpad = Sparsity_if_unpad.*(Ifmap_size_unpad.*Ifmap_size_unpad.*Nos_of_Channel);    %total zero in the unpadded ifmap volume

Sparsity_if = (Ifmap_zero_unpad + Padded_zero)./(Ifmap_size.*Ifmap_size.*Nos_of_Channel);    %percent sparsity in the padded ifmap volume
Sparsity_Of = SqueezeNet_v11_Input_File(:,10);           %percent sparsity in the ofmap volume, ofmap does not have any padding


n2 = [1 1 1 1 1 1 1 1 1 2 1 1 2 2 2 6 2 2 6 2 2 6 2 2 6 2]; %Nos of ifmap to process at a time. This values are determined by first simulation.
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


%%%Plot of energy for all 26 layer
figure
Stage = 1:1:length(Final_Energy_per_Ifmap);
plot(Stage,Final_Energy_per_Ifmap.*1e3,'--ro')
set(gca,'xtick',Stage);
xlim([0 27]);
xlabel('Layers of SqueezeNet-v11');
ylabel('Energy (mJ)');
title('Energy for all uncombined layers')
grid on


%%%Energy extracton for 18 layers (energy of a fire module is broken into squeeze and expand layer)
Energy(1) = Final_Energy_per_Ifmap(1);
Energy(2) = Final_Energy_per_Ifmap(2);          %fire squeeze layer energy
Energy(3) = sum(Final_Energy_per_Ifmap(3:4));   %fire expand layer energy
Energy(4) = Final_Energy_per_Ifmap(5);          
Energy(5) = sum(Final_Energy_per_Ifmap(6:7));
Energy(6) = Final_Energy_per_Ifmap(8); 
Energy(7) = sum(Final_Energy_per_Ifmap(9:10));
Energy(8) = Final_Energy_per_Ifmap(11); 
Energy(9) = sum(Final_Energy_per_Ifmap(12:13));
Energy(10) = Final_Energy_per_Ifmap(14); 
Energy(11) = sum(Final_Energy_per_Ifmap(15:16));
Energy(12) = Final_Energy_per_Ifmap(17); 
Energy(13) = sum(Final_Energy_per_Ifmap(18:19));
Energy(14) = Final_Energy_per_Ifmap(20); 
Energy(15) = sum(Final_Energy_per_Ifmap(21:22));
Energy(16) = Final_Energy_per_Ifmap(23); 
Energy(17) = sum(Final_Energy_per_Ifmap(24:25));
Energy(18) = Final_Energy_per_Ifmap(26); 

Energy;

%%%Plot of energy for combined 18 layer
figure
FS = 20;
LW = 1.5;
A = categorical({'C1','F2s','F2e','F3s','F3e','F4s','F4e','F5s','F5e','F6s','F6e','F7s','F7e','F8s','F8e','F9s','F9e','C10'});
neworder = ({'C1','F2s','F2e','F3s','F3e','F4s','F4e','F5s','F5e','F6s','F6e','F7s','F7e','F8s','F8e','F9s','F9e','C10'});
Stage2 = reordercats(A,neworder);
bar(Stage2,Energy.*1e3,'BarWidth',0.6)
xlabel('Layers of SqueezeNet-v11','FontSize',FS,'FontName','Times');
ylabel('Energy (mJ)','FontSize',FS,'FontName','Times');
title('Energy to process an image by SqueezeNet-v11','FontSize',18,'FontName','Times')
grid on

% %%%%Writing the Energy Results into File Without Control Energy
% E_Data_Write = Energy';
% fileID = fopen('SqueezeNet_WO_Cntrl.txt','w');
% fprintf(fileID,'%.16f\n',E_Data_Write);
% fclose(fileID);

%%%%Writing the Energy Results into File With Control Energy
E_Data_Write2 = Energy';
fileID = fopen('SqueezeNet_With_Cntrl.txt','w');
fprintf(fileID,'%.16f\n',E_Data_Write2);
fclose(fileID);



