%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% This function computes the energy required to process a given CNN layer %%%%%%%%%%%%%%%%%%%%%

%***********************************INPUTS***********************************
%%%%%%%%%%%%%% The inputs to the function are as follows:

% 1. Layer = index of a CNN layer
% 2. filter_size = Height/Width of a filter
% 3. Nos_of_Filter = #of total 3D filters in a layer
% 4. Ifmap_size = Height/Width of an input feature map (ifmap)
% 5. Nos_of_Channel = #of total channels in the ifmap/filter
% 6. Stride = convolution stride
% 7. Ofmap_size = Height/Width of an output feature map (ofmap)
% 8. Sparsity_if = Percent sparsity (i.e., #of zeros) in the padded ifmap volume
% 9. Sparsity_Of = Percent sparsity (i.e., #of zeros) in the ofmap volume

% 10. n2 = #of ifmap to be processed together
% 11. n_flag = Binary flag to indicate whether this is the first simulation or second simulation
% 12. C_prcnt = Percent control energy from components other than the clock network
% 13. Clock_Energy = Energy consumption (in joule) by the clock network

% 14. bit_flag = Binary flag to indicate whether it is an 8-bit or 16-bit implementation
%     in 8-bit implementation, all data types (i.e., ifmap, filetr, psum, ofmap) are 8-bit (set bit_flag = 0)
%     in 16-bit implementation, all data types (i.e., ifmap, filetr, psum, ofmap) are 16-bit (set bit_flag = 1)


%**********************************OUTPUTS***********************************
%%%%%%%%%%%%% For a given input layer the function provides the following outputs:

% 1. Final_Energy_per_Ifmap = Energy (in joule) to process the given CNN layer per image 
%    (The energy value is computed in 65nm technology node with Vdd = 1V)

% 2. n = maximum #of ifmap which can be processed together depending on the hardware constraints
% 3. psum_kb = On-chip Global SRAM Buffer(GLB) storage for the intermediate partial sums (psum) in kilobyte
% 4. ifmap_kb = GLB storage for ifmap in kilobyte
% 5. Total_kb = Total GLB storage used in kilobyte

% 6. Nos_of_NZMAC = Number of Nonzero-MAC operations per image
% 7. RF_Acc_MB_1N = Total amount of access into register file (RF) in MegaByte per image (both Inter-PE RF access and RF access from the same PE are included here)
% 8. GLB_Acc_MB_1N = Total amount of access into GLB in MegaByte per image
% 9. DARM_Acc_MB_1N = Total amount of access into off-chip DRAM in MegaByte per image

% 10. Filter_GLB_MB = Amount of GLB access in Megabyte from filter data per image
% 11. Ifmap_GLB_MB = Amount of GLB access in Megabyte from ifmap data per image
% 12. psum_GLB_MB = Amount of GLB access in Megabyte from psum data per image
% 13. Filter_DRAM_MB = Amount of DRAM access in Megabyte from filter data per image
% 14. Ifmap_DRAM_MB = Amount of DRAM access in Megabyte from ifmap data per image
% 15. Ofmap_DRAM_MB = Amount of DRAM access in Megabyte from ofmap data per image

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Final_Energy_per_Ifmap, n, psum_kb, ifmap_kb, Total_kb, Nos_of_NZMAC, RF_Acc_MB_1N, GLB_Acc_MB_1N, DARM_Acc_MB_1N,...
    Filter_GLB_MB, Ifmap_GLB_MB, psum_GLB_MB, Filter_DRAM_MB, Ifmap_DRAM_MB, Ofmap_DRAM_MB] = Analytical_Model(Layer,filter_size,Nos_of_Filter,...
    Ifmap_size,Nos_of_Channel,Stride,Ofmap_size,Sparsity_if,Sparsity_Of,n2,n_flag,C_prcnt,Clock_Energy,bit_flag)


%Fraction of nonzero values in the ifmap and ofmap volume
NZ_Ifmap = 1 - Sparsity_if;
NZ_Ofmap = 1 - Sparsity_Of;

%Accelerator Hardware Parameters, Bit-width of Data, and Technology Parameters for Energy Per Operation
PE_array_Height = 12;   %Height (i.e., #of rows) of the array of the processing elemnt (PE)
PE_array_Width = 14;    %Width (i.e., #of columns) of the PE array
GLB_Size = 100;         %On-chip global SRAM buffer (GLB) size in KB

s = (65/45)*(1/0.9)^2;  %Technology scaling parameter; 65nm Technology node, Vdd = 1V; 45nm Technology node, Vdd = 0.9V

if (bit_flag == 1)
    Bw = 16;                                  %data bit-width
    Filter_storage = 224;                     %maximum number of Bw-bit filter elements that can be stored in a the register file (RF) of a PE.
    Ifmap_storage = 12;                       %maximum number of Bw-bit ifmap elements that can be stored in a the RF of a PE.
    psum_storage = 24;                        %maximum number of Bw-bit psum elements that can be stored in a the RF of a PE.
    
    Energy_MAC = (0.05 + 0.9)*1e-12 * s;      %Energy (in joule) for one 16-bit interger/fixed point add+mul (MAC) in 65nm node 
    
    E_RF_to_ALU = Energy_MAC;             %One data access energy from RF to ALU
    E_PE_to_PE = 2*Energy_MAC;            %One data communication energy between PEs; Inter-PE communication only happens for vertical psum accumulation in a PE column
    E_GLB_to_PE = 6*Energy_MAC;           %One data access energy from GLB to RF
    E_DRAM_to_GLB = 200*Energy_MAC;       %One data access energy from DRAM to GLB
    
    RLC_factor = 3;                       % #of RLC encoded 16-bit non-zero data in a 64-bit RLC encoded word...
                                          %(the remaining bits are used to encode the information of zeros between nonzero data)
end
if (bit_flag == 0)
    Bw = 8;                                     
    Filter_storage = 224*2;                     
    Ifmap_storage = 12*2;                       
    psum_storage = 24*2;  
    Energy_MAC16 = (0.05 + 0.9)*1e-12 * s;      %Energy (in joule) for one 16-bit interger/fixed point add+mul (MAC) in 65nm node     
    
    %The above 16-bit energy parameters are quadratically scaled for multiplication...
    %and linearly scaled for addition and memory access to obtain 8-bit energy parameters. 
    Energy_MAC = (0.05/2 + 0.9/4)*1e-12 * s;    %Energy (in joule) for one 8-bit interger/fixed point add+mul (MAC) in 65nm node 
    E_RF_to_ALU = Energy_MAC16/2;
    E_PE_to_PE = (2*Energy_MAC16)/2;     
    E_GLB_to_PE = (6*Energy_MAC16)/2;
    E_DRAM_to_GLB = (200*Energy_MAC16)/2;
    
    RLC_factor = 5;                 % #of RLC encoded 8-bit non-zero data in a 64-bit RLC encoded word...
                                    %(the remaining bits are used to encode the information of zeros between nonzero data)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Computation Scheduling Parameter Calculation

%initial parameter computation
Set_per_pass = floor(PE_array_Height/filter_size);                      % #of sets per pass (i.e., in the full PE array)
Channel_per_set = floor(Ifmap_storage/filter_size);                     % #of channel per set
Total_Filter_per_set = floor(Filter_storage/filter_size);
Diff_filter_per_set = floor(Total_Filter_per_set/Channel_per_set);      % #of different 3D filters per set

%Adjustments of the computed parameters depending on whether various exception rules triggered for a given layer shape
if (Channel_per_set >= Nos_of_Channel)        %This condition checks whether the precomputed #of channel per set is greater than the total #of channels in the layer
    disp("Ex Rule-1")
    Channel_per_set = Nos_of_Channel;         
    Channel_per_pass = Channel_per_set;                                   
    z_flag = 1;                                                           %z_flag = 1 indicates that all channels are processed in a set/pass.
    Diff_filter_per_set = floor(Total_Filter_per_set/Channel_per_set);    %Recomputing #of different filter per set since channel number changed 
    Diff_filter_per_pass = Diff_filter_per_set * Set_per_pass;            %Sets are accomodating more filter due to lack of input channel
else
    Channel_per_pass = Channel_per_set * Set_per_pass;                    % #of channel per pass; Sets are accomodating more channel of the same 3D filter
    Diff_filter_per_pass = Diff_filter_per_set;                           % #of different 3D filters per pass; 
    z_flag = 0;
end

if ((Channel_per_set < Nos_of_Channel) && (Channel_per_pass > Nos_of_Channel))  
    disp("Ex Rule-2")     
    Channel_per_pass = Nos_of_Channel;
    set_for_all_ch = ceil(Channel_per_pass/Channel_per_set);      % #of set required to process all channels
    super_set = floor(Set_per_pass/set_for_all_ch);               % #of super set for accomodating more filter since all channels got fit in a subset of total #of sets in the PE array
    Diff_filter_per_pass = Diff_filter_per_set * super_set;
    z_flag = 1;                                                   %All channels are processed in one pass
end


if ((filter_size == 1) && (Ofmap_size ~=1))    %Customized Rule for 1*1 filter sized Conv layers
    if (z_flag == 0)                           
        disp("Ex Rule-3")   
        Channel_per_pass = 72;                                      %Fixed 72 channels are being processed. This is a heuristic to apply for all 1*1 filter sized Conv layers to reduce energy
        set_for_all_ch = ceil(Channel_per_pass/Channel_per_set);    % #of set required to process all channel
        super_set = floor(Set_per_pass/set_for_all_ch);             % #of super set to accomodate more filter if possible
        if (Nos_of_Filter<=18)
            super_set = 1;
            Diff_filter_per_set = Nos_of_Filter;                    %All filters are processed in one super-set
            Diff_filter_per_pass = Diff_filter_per_set * super_set;
        elseif(Nos_of_Filter<36)
            Diff_filter_per_set = Nos_of_Filter/super_set;          %All filters are processed in two super-sets; Filters are redistributed equally among the super-sets
            Diff_filter_per_pass = Diff_filter_per_set * super_set;
        else
            Diff_filter_per_pass = Diff_filter_per_set * super_set; %There are enough filters. So super sets grow along filter to accomodate more filters
        end
    end           
end


if (Diff_filter_per_pass > Nos_of_Filter)                 %Due to lack of enough filters, this condition redistributes all filters equally among sets
    disp("Ex Rule-4")
    Diff_filter_per_set = Nos_of_Filter/Set_per_pass;            
    Diff_filter_per_pass = Diff_filter_per_set * Set_per_pass;   
end                                                             

if (psum_storage < Diff_filter_per_set)   %This condition triggers if the psum storage is not large enough to fit the previously computed #of different filters per set
    disp("Ex Rule-5")
    Diff_filter_per_set = psum_storage;   %Reducing #of filter to be processed in a set to handle the storage limit
    Diff_filter_per_pass = Diff_filter_per_set * Set_per_pass;
end

%%%Calculation of X (width) and Y (height) direction coverage of ifmap and ofmap based on PE Array size & GLB size...
%%%as well as calculation of n and storage allocation of GLB for ifmap and psum data

x_ifmap = Ifmap_size;                           %initial setup for the x-direction coverage of ifmap/ofmap
y = Stride*(PE_array_Width - 1) + filter_size;
if (y>=Ifmap_size)                              %the full ifmap/ofmap height can fit in the PE array
    y_ifmap = Ifmap_size;
    y_ofmap = Ofmap_size;
else
    y_ifmap = y;                                %A fraction of full ifmap/ofmap height fits in the PE array
    y_ofmap = PE_array_Width;
end

%Calculating n value (maximum #of ifmap to be processed at a time) as well as ifmap and psum storage in GLB
ifmap_kb_prob = (x_ifmap * y_ifmap * Channel_per_pass) * Bw / (1024 * 8);               %initial GLB storage requirement in kilobyte for ifmap for n = 1
psum_kb_prob = (Ofmap_size * Ofmap_size * Diff_filter_per_pass) * Bw / (1024 * 8);      %initial GLB storage requirement in kilobyte for psum for n = 1
n_max = GLB_Size/(ifmap_kb_prob + psum_kb_prob);                                        %maximum #of ifmap that can be processed with the GLB storage

%Adjustment in x-direction
x_ofmp_comp = Ofmap_size;               %x_ofmp_comp is the width of ofmap which is processed together depending on the GLB storage limit 
while(ifmap_kb_prob >= GLB_Size)        %this condition triggers when the GLB size is not large enough to fit the previously computed ifmap storage requirement
    x_ifmap = x_ifmap/2;                %Partial ifmap/ofmap width is processed since full x-direction coverage of ifmap is not possible due to GLB_stogae limit
    ifmap_kb_prob = (x_ifmap * y_ifmap * Channel_per_pass) * Bw / (1024 * 8);           %Updated GLB storage requirement of ifmap for n = 1
    x_ofmp_comp = (x_ifmap - filter_size)/Stride + 1;
    psum_kb_prob = (x_ofmp_comp * Ofmap_size * Diff_filter_per_pass) * Bw / (1024 * 8); %Updated GLB storage requirement of psum for n = 1
    n_max = GLB_Size/(ifmap_kb_prob + psum_kb_prob);                                    %Updated maximum #of ifmap that can be processed with the GLB storage
end

%Adjustment in y-direction
if (n_max >= 1)
    n = floor(n_max);
    y_ofmp_comp = Ofmap_size;          %y_ofmp_comp is the height of ofmap which is processed before a write back to DRAM 
                                       %GLB size supports the full y-direction (i.e., height) coverage of ofmap when n_max>=1
elseif (z_flag == 1)
        y_ofmp_comp = Ofmap_size;      %When z-flag = 1 (i.e., all channels are processed at a time), no strict requirement for psum_kb and full y-direction coverage is possible by GLB,
        n = 1;
        psum_kb = GLB_Size - ifmap_kb_prob;       
else                                   %This condition triggers when the GLB size is not large enough to to process the full y-direction (height) of ofmap
    n_new = n_max;
    y_ofmp_comp = Ofmap_size;               
    while(n_new < 1)                   
        y_ofmp_comp = y_ofmp_comp/2;   %Partial ofmap height is processed since full y-direction coverage of ofmap is not possible due to GLB_stogae limit
        psum_kb_new = (x_ofmp_comp * y_ofmp_comp * Diff_filter_per_pass) * Bw / (1024 * 8);         %Updated GLB storage requirement of psum
        n_new = GLB_Size/(ifmap_kb_prob + psum_kb_new);    
    end                                  
    n = 1;                              
end

if (y_ofmp_comp < y_ofmap)   %This condition avoids to have unused PE columns
    disp("Ex Rule-6: Y direction determination")
    y_ofmp_comp = y_ofmap;   %Minimum requirement of y_ofmap_comp to avoid unused PE columns
    if (z_flag == 0)
        n_new2 = 0;
        while(n_new2 < 1)
            Diff_filter_per_pass = Diff_filter_per_pass - 1;   %Reduing #of different filters to be processed in a pass to make room for the additional ofmap height
            psum_kb_new2 = (x_ofmp_comp * y_ofmap * Diff_filter_per_pass) * Bw / (1024 * 8);           %Updated GLB storage requirement of psum
            n_new2 = GLB_Size/(ifmap_kb_prob + psum_kb_new2);
        end
    else
        psum_kb = GLB_Size - ifmap_kb_prob;     
    end                                        
end

% n value from first simulation which follows divisible rule
if (n_flag == 1)
    n = n2;
end
if (z_flag == 0)
    psum_kb = n * ((x_ofmp_comp * y_ofmp_comp * Diff_filter_per_pass) * Bw / (1024 * 8));   %Final GLB storage requirement of psum based on n in kilobyte
end

ifmap_kb = ifmap_kb_prob * n;           %Final GLB storage requirement of ifmap based on n in kilobyte

if ((z_flag == 1) && (n_max >= 1))
    psum_kb = GLB_Size - ifmap_kb;  
end

Total_kb = psum_kb + ifmap_kb;          %Total GLB storage used in kilobyte

%Uncommnet to view different scheduling parameters for a certain layer
% if(Layer==3)      %provide the layer index here
%     Layer
%     n
%     Channel_per_set
%     Diff_filter_per_set
%     Set_per_pass
%     Channel_per_pass
%     Diff_filter_per_pass
%     z_flag
%     x_ofmp_comp
%     y_ofmap
%     y_ofmp_comp
%     psum_kb
%     ifmap_kb
%     Total_kb
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Energy Computation for the Given Layer
%Filter Access Energy for a pass
filter_to_load = Diff_filter_per_pass * Channel_per_pass * filter_size * filter_size;       % #of filter element to load in a pass
filter_AEnergy_per_pass = (E_DRAM_to_GLB + E_GLB_to_PE)*filter_to_load;                     % Access energy in joule (From DRAM to GLB to RF)

%Ifmap Access Energy for a pass
Ifmap_to_Load = x_ifmap * y_ifmap * Channel_per_pass;                                 % #of ifmap which navigate from DRAM to GLB and/or GLB to RF in a pass for one image
Ifmap_to_Load_ov = x_ifmap * (y_ifmap - (filter_size - Stride)) * Channel_per_pass;   % #of Ifmap to load from DRAM deducting the overlapped one with previous load

if (Layer == 1)
    RLC_Ifmap = Ifmap_to_Load * n;                                                    %No RLC Compression for the layer-1 Ifmap
    RLC_Ifmap_ov = Ifmap_to_Load_ov * n;
else
    RLC_Ifmap = ((Ifmap_to_Load * NZ_Ifmap)/RLC_factor) * (64/Bw) * n;                % #of Bw-bit RLC Compressed Ifmap, for n images
    RLC_Ifmap_ov = ((Ifmap_to_Load_ov * NZ_Ifmap)/RLC_factor) * (64/Bw) * n;       
end   
Energy_Ifmap_DRAMtoGLB = E_DRAM_to_GLB * RLC_Ifmap;         %Ifmap is read in RLC compressed format only for the load from DRAM to GLB, n is considered already
Energy_Ifmap_DRAMtoGLB_ov = E_DRAM_to_GLB * RLC_Ifmap_ov;   %After deducting overlapped ifmap
Ifmap_AEnergy_per_pass = E_GLB_to_PE * Ifmap_to_Load;       %ifmap read energy from GLB to RF for each pass, n will be considered in later equations

%psum Read/Write Energy (Between RF and GLB) per pass
psum_to_RW = Diff_filter_per_pass * x_ofmp_comp * y_ofmap;
psum_RWEnergy_per_pass = E_GLB_to_PE * psum_to_RW;          %psum communication energy per pass between GLB & RF, n will be considered in later equations

%MAC energy per pass (Computation and Data access)
MAC_per_pass = (filter_size * filter_size) * (x_ofmp_comp * y_ofmap) * (Diff_filter_per_pass * Channel_per_pass);
NZ_MAC = MAC_per_pass * NZ_Ifmap;                           % #of non-zero MAC computation per pass
MAC_Comp_Energy = Energy_MAC * NZ_MAC;                      %Energy just for the nonzero MAC operations in a pass

Inter_PE_height = ceil(filter_size * (Channel_per_pass/Channel_per_set));      
Inter_PE_psum_read = (Inter_PE_height-1) * x_ofmp_comp * Diff_filter_per_pass * y_ofmap;   % #of Inter-PE psum communication in a pass
MAC_Data_AEnergy = (NZ_MAC * 3 * E_RF_to_ALU) + (Inter_PE_psum_read * E_PE_to_PE) + (NZ_MAC - Inter_PE_psum_read) * E_RF_to_ALU + (MAC_per_pass - NZ_MAC)*E_RF_to_ALU;  
%RF accesses for psum read-write and filter read are skipped for a zero-valued MAC

MAC_TEnergy_per_pass = MAC_Comp_Energy + MAC_Data_AEnergy;   %MAC computation energy + RF level data access energy associated with the MAC operations per pass; n will be considered in later equations

%%%%%%%Energy to process the y_ofmp_comp height of ofmap
y_pass = y_ofmp_comp/y_ofmap;                                % #of y_pass to process y_ofmp_comp of ofmap

%In the first pass, no psum read from GLB, only write
%Both read and write of psum needed for the next passes along the z-direction (i.e., along the direction of channels)
Energy_First_y_pass = filter_AEnergy_per_pass + (Energy_Ifmap_DRAMtoGLB + (y_pass - 1) * Energy_Ifmap_DRAMtoGLB_ov) + (Ifmap_AEnergy_per_pass * n * y_pass) + (psum_RWEnergy_per_pass * n * y_pass) + (MAC_TEnergy_per_pass * n * y_pass);
Energy_Next_y_pass = filter_AEnergy_per_pass + (Energy_Ifmap_DRAMtoGLB + (y_pass - 1) * Energy_Ifmap_DRAMtoGLB_ov) + (Ifmap_AEnergy_per_pass * n * y_pass) + (psum_RWEnergy_per_pass * n * y_pass * 2) + (MAC_TEnergy_per_pass * n * y_pass);

%%%%%%%%Energy to process the full z-direction (i.e., all the channels)
z_pass = Nos_of_Channel/Channel_per_pass;                                   % #of passes to cover the full z-direction
Energy_z_pass = Energy_First_y_pass + (z_pass - 1)* Energy_Next_y_pass;     % Associated energy in joule

%%%%%%%%Energy to process all the filters
filter_pass = Nos_of_Filter/Diff_filter_per_pass;                           % #of passes to cover all 3D filters in a layer
Energy_filter_pass = filter_pass * Energy_z_pass;                           % Associated energy in joule

%%%%%%%%Energy for full y-direction (i.e., height) coverage
full_y_pass = Ofmap_size/y_ofmp_comp;                                       % #of passes to complete the full y-direction of ofmap
Energy_full_y_pass = Energy_filter_pass * full_y_pass;                      % Associated energy in joule

%%%%%%%%Energy for full x-direction (i.e., width) coverage
x_pass = Ofmap_size/x_ofmp_comp;                                            % #of passes to complete the full x-direction of ofmap
Total_pass_Energy = Energy_full_y_pass * x_pass;                            % Associated energy in joule

%%%%%%%Writting All Ofmap to DRAM (RLC compressed format)
Ofmap_to_DRAM = Ofmap_size * Ofmap_size * Nos_of_Filter;
Ofmap_RLC = ((Ofmap_to_DRAM * NZ_Ofmap)/RLC_factor) * (64/Bw) * n;          % #of Bw-bit RLC-compressed ofmap for n images
Ofmap_WEnergy_to_DRAM = Ofmap_RLC * E_DRAM_to_GLB;                          % Energy to write the RLC-compressed ofmap from GLB to DRAM

%%%%%%%%Total Energy to process The Layer (without control energy)
Layer_Energy = Total_pass_Energy + Ofmap_WEnergy_to_DRAM;                   % Total energy to process the layer for n images
Energy_per_Ifmap = Layer_Energy/n;                                          % Total energy to process the layer for each image

%%%%%%%%%Control Energy Calculation
DRAM_AEnergy_Ifmap = (Energy_Ifmap_DRAMtoGLB + (y_pass - 1) * Energy_Ifmap_DRAMtoGLB_ov) * z_pass * filter_pass * full_y_pass * x_pass;   
DRAM_AEnergy_Filter = (filter_to_load * E_DRAM_to_GLB) * z_pass * filter_pass * full_y_pass * x_pass;
DRAM_AEnergy = DRAM_AEnergy_Ifmap + DRAM_AEnergy_Filter;                               

G = Total_pass_Energy - DRAM_AEnergy;                                       %On-chip Energy to process a layer (i.e., excluding the DRAM access energy) for n images
G1 = G/n;                                                                   %Normalized to one image

Other_Control_E = (C_prcnt/(1 - C_prcnt)) * (G1 + Clock_Energy);            %Control energy from components other than the clock network
Con_E_per_Ifmap = Other_Control_E + Clock_Energy;                           %Total control energy for each image


%%%%%%%%%Final Energy with Control Energy
Final_Energy_per_Ifmap = Energy_per_Ifmap + Con_E_per_Ifmap;                %Final energy to process the given layer for each image

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Calculation of Various Memory Accesses and #of MAC Computations
%GLB Access in MB for Each Image
psum_GLB_Acc = (psum_to_RW * n * y_pass + psum_to_RW * 2 * n * y_pass * (z_pass - 1)) * filter_pass * full_y_pass * x_pass; % #of GLB access for psum elements for n images
Filter_GLB_Acc = filter_to_load * z_pass * filter_pass * full_y_pass * x_pass;                              % #of GLB access for filter elements for n images
Ifmap_GLB_Acc = Ifmap_to_Load * n * y_pass * z_pass * filter_pass * full_y_pass * x_pass;                   % #of GLB access for ifmap elements for n images
Nos_of_GLB_ACC = psum_GLB_Acc + Filter_GLB_Acc + Ifmap_GLB_Acc;                                             % #of total GLB access for n images

GLB_Acc_MB_1N = ((Nos_of_GLB_ACC * Bw)/(8*1024*1024)) / n;  %Amount of total GLB access in Megabyte from all three data types (filter, ifmap, psum) per image
psum_GLB_MB = ((psum_GLB_Acc * Bw)/(8*1024*1024)) / n;      %Amount of GLB access in Megabyte from psum data per image
Filter_GLB_MB = ((Filter_GLB_Acc * Bw)/(8*1024*1024)) / n;  %Amount of GLB access in Megabyte from filter data per image
Ifmap_GLB_MB = ((Ifmap_GLB_Acc * Bw)/(8*1024*1024)) / n;    %Amount of GLB access in Megabyte from ifmap data per image


%DARM Access in MB for Each Image
Filter_DRAM_Acc = (filter_to_load * z_pass * filter_pass * full_y_pass * x_pass);                           % #of DRAM access for filter elements for n images
Ifmap_DRAM_Acc = ((RLC_Ifmap + (y_pass - 1) * RLC_Ifmap_ov) * z_pass * filter_pass * full_y_pass * x_pass); % #of DRAM access for ifmap elements for n images
Ofmap_DRAM_Acc = Ofmap_RLC;                                                                                 % #of DRAM access for ofmap elements for n images
Nos_of_DRAM_ACC = Filter_DRAM_Acc + Ifmap_DRAM_Acc + Ofmap_DRAM_Acc;                                        % #of total DRAM access for n images

DARM_Acc_MB_1N = ((Nos_of_DRAM_ACC * Bw)/(8*1024*1024)) / n;    %Amount of total DRAM access in Megabyte from all three data types (filter, ifmap, ofmap) per image
Filter_DRAM_MB = ((Filter_DRAM_Acc * Bw)/(8*1024*1024)) / n;    %Amount of DRAM access in Megabyte from filter data per image
Ifmap_DRAM_MB = ((Ifmap_DRAM_Acc * Bw)/(8*1024*1024)) / n;      %Amount of DRAM access in Megabyte from ifmap data per image
Ofmap_DRAM_MB = ((Ofmap_DRAM_Acc * Bw)/(8*1024*1024)) / n;      %Amount of DRAM access in Megabyte from ofmap data per image


%Computation of Nonzero MAC Operations for Each Image
Nos_of_MAC = ((filter_size*filter_size)*Nos_of_Channel)*((Ofmap_size.*Ofmap_size)*Nos_of_Filter);   % #of  total MAC operations per image in the given layer
Nos_of_NZMAC = Nos_of_MAC * NZ_Ifmap;               % #of Nonzero-MAC operations per image in the given layer

%RF Access in MB for Each Image
Nos_of_RF_ACC = Nos_of_MAC + Nos_of_NZMAC*3;        % #of total RF accesses per image (both Inter-PE RF access and RF access from the same PE are incuded here)
RF_Acc_MB_1N = (Nos_of_RF_ACC * Bw)/(8*1024*1024);  %Amount of total RF access in Megabyte from all three data types (filter, ifmap, psum) per image

end

