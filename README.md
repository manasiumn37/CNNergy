# CNNergy: An Analytical CNN Energy Model

If you use any part of this project please cite: 
S. D Manasi, F. S Snigdha, and S. S. Sapatnekar, "NeuPart: Using Analytical Models to Drive Energy-Efficient Partitioning of CNN Computations on Cloud-Connected Mobile Clients," arXiv preprint arXiv:1905.05011, May 2019.

The directories named "src" and "data" contain all the required files to use the tool

## Guideline to use CNNergy

**List of the files in the "data" directory:**

1. GoogleNet_v1_Input_File.txt -- This file contains the layer shape parameters for all the layers of GoogleNet_v1 and is used as input to the "GoogleNet_Main.m" file.

2. SqueezeNet_v11_Input_File.txt -- This file contains the layer shape parameters for all the layers of SqueezeNet_v11 and is used as input to the "SqueezeNet_Main.m" file.

3. GoogleNet_v1_Input_File_with_description.txt -- This is same as the "GoogleNet_v1_Input_File.txt" with a description of the format of each row.

4. SqueezeNet_v11_Input_File_with_description.txt -- This is same as the "SqueezeNet_v11_Input_File.txt" with a description of the format of each row.

**List of the files in the "src" directory:**

5. AlexNet_Main.m -- The main file to run all the layers of AlexNet. 
6. VGG16_Main.m -- The main file to run all the layers of VGG-16.
7. GoogleNet_Main.m -- The main file to run all the layers of GoogleNet_v1. 
8. SqueezeNet_Main.m -- The main file to run all the layers of SqueezeNet_v11. 
9. Clock_Tree_Power.m -- This file implements the model to estimate the power consumption by the clock network.
10. Analytical_Model.m -- This is the function which implements the analytical CNN energy model. Details about the function are provided below.

  **Notes:** (In order to run the "GoogleNet_Main.m" file, keep "GoogleNet_Main.m" and "GoogleNet_v1_Input_File.txt" in the same directory.

In order to run the "SqueezeNet_Main.m" file, keep "SqueezeNet_Main.m" and "SqueezeNet_v11_Input_File.txt" in the same directory.

In order to run each of the main.m files listed above in 5-8, keep the main.m files and the "Analytical_Model.m" file in the same directory.

After running each of the main.m files listed above in 5-8, the energy values required to process each layer of that CNN will be plotted in a figure as well as the energy results will be written in a .txt file)


## The function: Analytical_Model.m

This function computes the energy required to process a given CNN layer on a deep learning accelerator

***INPUTS:***

The inputs to the function are as follows:

1. Layer = index of a CNN layer
2. filter_size = Height/Width of a filter
3. Nos_of_Filter = #of total 3D filters in a layer
4. Ifmap_size = Height/Width of an input feature map (ifmap)
5. Nos_of_Channel = #of total channels in the ifmap/filter
6. Stride = convolution stride
7. Ofmap_size = Height/Width of an output feature map (ofmap)
8. Sparsity_if = Percent sparsity (i.e., #of zeros) in the padded ifmap volume
9. Sparsity_Of = Percent sparsity (i.e., #of zeros) in the ofmap volume

10. n2 = #of ifmap to be processed together
11. n_flag = Binary flag to indicate whether this is the first simulation or second simulation
12. C_prcnt = Percent control energy from components other than the clock network
13. Clock_Energy = Energy consumption (in joule) by the clock network

14. bit_flag = Binary flag to indicate whether it is an 8-bit or 16-bit implementation

    in 8-bit implementation, all data types (i.e., ifmap, filter, psum, ofmap) are 8-bit (set bit_flag = 0)

    in 16-bit implementation, all data types (i.e., ifmap, filter, psum, ofmap) are 16-bit (set bit_flag = 1)


***OUTPUTS:***

For a given input layer the function provides the following outputs:

1. Final_Energy_per_Ifmap = Energy (in joule) to process the given CNN layer per image 
   (The energy value is computed in 65nm technology node with Vdd = 1V)

2. n = maximum #of ifmap which can be processed together depending on the hardware constraints
3. psum_kb = On-chip Global SRAM Buffer(GLB) storage for the intermediate partial sums (psum) in kilobyte
4. ifmap_kb = GLB storage for ifmap in kilobyte
5. Total_kb = Total GLB storage used in kilobyte

6. Nos_of_NZMAC = Number of Nonzero-MAC operations per image
7. RF_Acc_MB_1N = Total amount of access into register file (RF) in MegaByte per image (both Inter-PE RF access and RF access from the same PE are included here)
8. GLB_Acc_MB_1N = Total amount of access into GLB in MegaByte per image
9. DARM_Acc_MB_1N = Total amount of access into off-chip DRAM in MegaByte per image

10. Filter_GLB_MB = Amount of GLB access in Megabyte from filter data per image
11. Ifmap_GLB_MB = Amount of GLB access in Megabyte from ifmap data per image
12. psum_GLB_MB = Amount of GLB access in Megabyte from psum data per image
13. Filter_DRAM_MB = Amount of DRAM access in Megabyte from filter data per image
14. Ifmap_DRAM_MB = Amount of DRAM access in Megabyte from ifmap data per image
15. Ofmap_DRAM_MB = Amount of DRAM access in Megabyte from ofmap data per image

For a detail description of our analytical CNN energy model please read our paper: S. D. Manasi, F. S. Snigdha, and S. S. Sapatnekar, “NeuPart: Using Analytical Models to Drive Energy-Efficient Partitioning of CNN Computations on Cloud-Connected Mobile Clients.” (Link: https://arxiv.org/abs/1905.05011).

