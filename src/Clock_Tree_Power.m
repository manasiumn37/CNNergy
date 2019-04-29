%%%%%%%%%%%%%%%%%%%%%%This file Computes the Power Dissipation by the Clock-Tree Network%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The clock is distributed as an H-tree with 16 leaf nodes in a chip size of 3.5*3.5 mm^2
clc;
clear all;
close all;

Vdd = 1.1;    %Supply volage
f = 200*1e6;  %Clock Frequency

%Reference sized Inverter
Cap_Invx1 = 0.00155103*1e-12;       %Invx1 gate capacitance from NCSU 45nm PDK .lib file
Cap_min = Cap_Invx1/15;             %Gate Capacitance of one unit sized MOSFET, unit sized mean W = Lmin = 50nm

%Inverter size in the clock tree
Inv_size_tree = 3+6;                %W of NMOS = 3*Lmin, W of PMOS = 6*Lmin
Cap_inv = Cap_min * Inv_size_tree;  %Gate capacitange of each inverter in the clock tree

%% Wire Information
Capw_per_um = 0.0358*1e-15;                     %M10 wire capacitance in farad per um length (extracted from NCSU 45nm PDK)
Chip_size = 3.5*1e3;                            %Chip length/width in um (Extracted from Eyeriss chip micrograph)
wire_length_x4 = Chip_size/4;                   %Length of wire in um between two inverters, for Chip_size/4 and Chip_size/8 wirelengths
wire_length_x8 = Chip_size/8;
Cap_wire_x4 = wire_length_x4 * Capw_per_um;     %Wire capacitance in farad between two inverters, for Chip_size/4 and Chip_size/8 wirelengths
Cap_wire_x8 = wire_length_x8 * Capw_per_um;



%% Clocked capacitive load estimation form processing elements (PEs)
C_FF_min = 0.00646193*1e-12/60;         
C_FF = 30*C_FF_min;                        %Gate capacitance (in farad) from a single transmission gate based flip-flop (extracted from NCSU 45nm PDK)


%Capacitance due to local RF storage for ifmap and psum data in the PE
FF_per_PE = 576+32;                        % #of flip-flop per PE (including one 32-bit pipeline register)
FF_14PE = FF_per_PE * 14;                  % #of flip-flop connected to each leaf node of the H-tree clock (There are 14 PEs per leaf node)
Cap_local_pi = C_FF * FF_14PE;             %Clocked capacitance in ecah leaf node of the H-tree from the RF storage for ifmap and psum data


%Capacitance estimation due to loacl SRAM storage for filter data in the PE
%Address register and read-write register
Adress_FF = 8;                                          %Nos of Flip-Flop in the 8 bit adress register
Read_FF = 16;                                           %Nos of Flip-Flop in the 16 bit data read register
Write_FF = 16;                                          %Nos of Flip-Flop in the 16 bit data write register
Cap_Total_FF = (Adress_FF + Read_FF + Write_FF) * C_FF;

%Row Decoder
PMOS_size_AND3 = 4;                                     %PMOS size of an 3-input AND gate
NMOS_size_AND3 = 6;                                     %NMOS size of an 3-input AND gate
Gate_Load_AND3 = PMOS_size_AND3 + NMOS_size_AND3;       %Load at each gate of one 3-input AND gate
Cap_Row_Dec = Gate_Load_AND3 * 4 * Cap_min;             %Clocked capacitance from the row decoder (in the row decoder clock sees four 3-Input AND gates as load)

%Column Decoder
Cap_Col_Dec = Gate_Load_AND3 * 4 * Cap_min;             %Clocked capacitance from the column decoder (in the column decoder clock sees four 3-Input AND gate as load)

%Precharge Circuit
Nos_of_Col = 64;                                            % #of column in the SRAM array
Inv_size_filt_SRAM = 4+2;                                   %Inverter size in precharge circuit
Cap_Precharge = Nos_of_Col * Inv_size_filt_SRAM * Cap_min;  %Clocked capacitance from the bit-line precharge circuits

%Sense Amplifier
Nos_of_SA = 16;                                             % #of sense-amplifier in the SRAM array
Inv_size_min = 4+2;                                         %Minimum sized inverter
Cap_SA = Nos_of_SA * Inv_size_min * Cap_min;                %Clocked capacitance from the sense amplifier precharge circuits

%Total Cap
Cap_Tot_Per_Filt_SRAM = Cap_Total_FF + Cap_Row_Dec + Cap_Col_Dec + Cap_Precharge + Cap_SA; %Clocked capacitance from the filter storage of one PE (There are 14 PEs per leaf node)
Cap_local_filt = Cap_Tot_Per_Filt_SRAM * 14;                %Clocked capacitance in ecah leaf node of the H-tree from the local storage of filter data


%% Capacitive Load Estimation for 108 kB Global SRAM Buffer (GLB)

Nos_of_Bank = 27;              % #of banks in the SRAM array

Address_FF_GLB = 16;           % #of FF in the 16 bit address register
Read_FF_GLB = 16;              % #of FF in the 16 bit read register
Write_FF_GLB = 16;             % #of FF in the 16 bit write register
Cap_Tot_FF_GLB = (Address_FF_GLB + Read_FF_GLB + Write_FF_GLB) * C_FF;

%Decoder Load
Cap_Dec = Gate_Load_AND3 * 4 * Cap_min;   %Clocked capacitance from the decoder circuitry (in the decoder circuitry, clock sees four 3-Input AND gate as load)

%Precharge Circuit
Col_per_bank = 64;          % #of column per bank
Inv_size_GLB = 20+10;       %Inverter size in precharge circuit, since GLB has 512 cell in a column, this inverter size is bigger than filte-SRAM
Cap_Pre_GLB = Col_per_bank * Nos_of_Bank * Inv_size_GLB * Cap_min;   %Clocked capacitance from the bit-line precharge circuits

% Sense Amplifier
SA_per_bank = 16;                                                     % #of sense amplifier per bank
Cap_SA_GLB = SA_per_bank * Nos_of_Bank * Inv_size_min * Cap_min;      %Clocked capacitance from the sense amplifier precharge circuits

Cap_local_GLB = Cap_Tot_FF_GLB + Cap_Dec + Cap_Pre_GLB + Cap_SA_GLB;  %Total clocked capacitance from the GLB 
%4 leaf nodes of the H-tree are assigned to distribute clock in the Globar SRAM buffer (GLB)

%% Power Model for the Clock Tree
P1 = (2*Cap_inv + Cap_wire_x4) * Vdd^2 * f;
P2 = (Cap_inv + Cap_wire_x8) * Vdd^2 * f * 2;
P3 = (2*Cap_inv + Cap_wire_x4) * Vdd^2 * f * 2;
P4 = (Cap_inv + Cap_wire_x8) * Vdd^2 * f * 4;
P5 = (2*Cap_inv + Cap_wire_x4) * Vdd^2 * f * 4;
P6 = (2*Cap_inv + Cap_wire_x4) * Vdd^2 * f * 8;
P_Tree = P1 + P2 + P3 + P4 + P5 + P6;                      %Power dissipation from different branches of the H-tree

                                                           %12 leaf nodes of the H-tree are assigned to distribute clock in the PE array
P_leaf_pi = Cap_local_pi * Vdd^2 * f * 12;                 %Clock power dissipation due to local RF storage for ifmap and psum data in all PEs of the PE array             
P_leaf_filt = Cap_local_filt * Vdd^2 * f * 12;             %Clock power dissipation due to local SRAM storage for filter data in all PEs of the PE array 
P_leaf_GLB = Cap_local_GLB * Vdd^2 * f;                    %Clock power dissipation due to the on-chip Global SRAM Buffer (GLB)

P_45 = P_Tree + P_leaf_pi + P_leaf_filt + P_leaf_GLB;      %Total power dissipation (in Watt) from the clock network in 45nm technology node

% Power Projection from 45 to 65 nm
s = (65/45)*(1/1.1)^2;                                     %Technology scaling factor
disp('Total power dissipation (in Watt) from the clock network in 65nm with VDD = 1V')
P_65 = s * P_45                                            %Total power dissipation (in Watt) from the clock network in 65nm technology node (Vdd = 1V)

