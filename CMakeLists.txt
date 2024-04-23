cmake_minimum_required(VERSION 3.27)
project(joint_0419 CUDA)

set(CMAKE_CUDA_STANDARD 17)

add_executable(joint_0419 main.cu
        Graph.cu
        Graph.cuh
        type.cuh
        alg.cu
        alg.cuh)

set_target_properties(joint_0419 PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
