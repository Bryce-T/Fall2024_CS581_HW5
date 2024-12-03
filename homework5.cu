/*
Bryce Taylor
bktaylor2@crimson.ua.edu
CS 581
Homework #5

To compile:
nvcc homework5.cu -o homework5

To run:
./homework5 (Size of board) (Max generations) (Output file directory)
./homework5 5000 5000 outputs
*/

#include <chrono>
#include <fstream>
#include <iostream>
#include <string>

using namespace std;

// Main Game of Life kernel
__global__ void mainKernel(int* curBoard, int* newBoard, int realSize) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    // Make sure cell is not a ghost cell
    if (row > 0 && row < realSize - 1 && col > 0 && col < realSize - 1) {
        // Logic to find number of neighbors and calculate new cell
        int numNeighbors = 0;
        numNeighbors += curBoard[(row-1)*realSize + col-1] + curBoard[(row-1)*realSize + col] + curBoard[(row-1)*realSize + col+1] + \
                        curBoard[(row+1)*realSize + col-1] + curBoard[(row+1)*realSize + col] + curBoard[(row+1)*realSize + col+1] + \
                        curBoard[(row)*realSize + col-1] + curBoard[(row)*realSize + col+1];
        if (curBoard[row * realSize + col] == 0) {
            if (numNeighbors == 3) {
                newBoard[row * realSize + col] = 1;
            }
            else {
                newBoard[row * realSize + col] = 0;
            }
        }
        else if (curBoard[row * realSize + col] == 1) {
            if (numNeighbors < 2) {
                newBoard[row * realSize + col] = 0;
            }
            else if (numNeighbors > 3) {
                newBoard[row * realSize + col] = 0;
            }
            else {
                newBoard[row * realSize + col] = 1;
            }
        }
    }
}

int main(int argc, char* argv[]) {
    int boardSize; // Board size (N)
    int realSize;
    int maxGenerations; // Max # of iterations
    string outputDir; // Directory to write output file to

    srand(0); // Set seed
    
    // Input processing
    boardSize = atoi(argv[1]);
    realSize = atoi(argv[1]) + 2;
    maxGenerations = atoi(argv[2]);
    outputDir = argv[3];

    // Allocate and initialize board
    int* curBoard = (int*)malloc(realSize * realSize * sizeof(int));
    for (int i = 0; i < realSize * realSize; i++) {
        curBoard[i] = 0;
    }
    for (int i = 1; i < realSize - 1; i++) {
        for (int j = 1; j < realSize - 1; j++) {
            curBoard[(i * realSize) + j] = rand() % 2;
        }
    }

    // Allocate and copy device memory
    int* devCur;
    int* devNew;
    cudaMalloc(&devCur, realSize * realSize * sizeof(int));
    cudaMalloc(&devNew, realSize * realSize * sizeof(int));
    cudaMemcpy(devCur, curBoard, realSize * realSize * sizeof(int), cudaMemcpyHostToDevice);

    // Initialize block and thread size
    int blockSize = 16;
    dim3 threads(blockSize, blockSize);
    dim3 blocks((boardSize + blockSize - 1) / blockSize, (boardSize + blockSize - 1) / blockSize);

    // Start timer
    auto start = chrono::high_resolution_clock::now();

    // Main algorithm loop
    for (int n = 1; n <= maxGenerations; n++) {
        // Call main kernel for game of life logic
        mainKernel<<<blocks, threads>>>(devCur, devNew, realSize);
        cudaDeviceSynchronize();
        cudaMemcpy(devCur, devNew, realSize * realSize * sizeof(int), cudaMemcpyDeviceToDevice);
    }
    // Copy board back to host
    cudaMemcpy(curBoard, devCur, realSize * realSize * sizeof(int), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();

    // End timer and calculate time taken
    auto end = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    cout << "Time taken: " << duration.count() << " ms" << endl;
    
    // Write output to a file
    string outputFileName = outputDir + "/gpu_" + to_string(boardSize) + "_" + to_string(maxGenerations) + ".txt";
    ofstream OutputFile(outputFileName);
    for (int i = 0; i < realSize; i++) {
        for (int j = 0; j < realSize; j++) {
            OutputFile << curBoard[(i * realSize) + j] << " ";
        }
        OutputFile << endl;
    }
    OutputFile.close();

    return 0;
}
