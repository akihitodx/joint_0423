#include <iostream>
#include "vector"
#include "Graph.cuh"
#include "thrust/device_vector.h"
#include "thrust/host_vector.h"
#include "alg.cuh"
#include "unordered_set"
using namespace std;


vector<vector<int>> midNode;
vector<vector<Tag3>> joint_group;
vector<int> single_pair;
unordered_map<int,vector<int>> group_name_map;
vector<int> single_pair_name;
int cutStep;

int main() {
//    int device = 0;  // 要查询的设备索引
//    int value;
//
//    cudaDeviceProp props;
//    cudaGetDeviceProperties(&props, device);
//    cudaDeviceGetAttribute(&value, cudaDevAttrMaxSharedMemoryPerBlock, device);
//
//    std::cout << "Max shared memory per block: " << value << " bytes" << std::endl;

    string query_path = "../test/query";
    string data_path = "../test/data";
    auto *query = new Graph();
    auto *data = new Graph();
    query->ReadInFile(query_path,1);
    data->ReadInFile(data_path,0);
    query->except_ring();
    query->calcLevelId();
    int name = 0;
    query->division(0,name);
    joint_group.resize(cutStep+1);

    thrust::device_vector<int> dev_data_node(data->q_h_node);
    thrust::device_vector<int> dev_data_label(data->q_h_label);
    thrust::device_vector<int> dev_data_adj(data->q_h_adj);
    thrust::device_vector<int> dev_data_degree(data->q_h_degree);

    thrust::device_vector<int> dev_query_node(query->q_h_node);
    thrust::device_vector<int> dev_query_label(query->q_h_label);
    thrust::device_vector<int> dev_query_adj(query->q_h_adj);
    thrust::device_vector<int> dev_query_degree(query->q_h_degree);

    thrust::device_vector<int> dev_single_pair_name(single_pair_name);
    thrust::device_vector<int> dev_single_pair(single_pair);

    //index
    Tag5 *d_index, *h_index;
    size_t pitch;
    h_index = new Tag5[N_size * data->v_num];
    memset(h_index,-1,N_size * data->v_num*sizeof(Tag5));
    for (int i = 0; i < N_size * data->v_num; i = i + N_size) {
        h_index[i] = {N_size,0, N_size-1, -1, 0};
    }
    cudaMallocPitch(&d_index, &pitch, N_size * sizeof(Tag5), data->v_num);
    cudaMemcpy2D(d_index, pitch, h_index, N_size * sizeof(Tag5), N_size * sizeof(Tag5), data->v_num,cudaMemcpyHostToDevice);


    dim3 grid_2D((data->v_num/32)+1,(query->v_num/32)+1);
    dim3 block_2D(32,32);
    //filter
    data_filter<<<grid_2D,block_2D>>>(d_index,pitch,thrust::raw_pointer_cast(dev_data_node.data()),
                                      thrust::raw_pointer_cast(dev_data_degree.data()),
                                      thrust::raw_pointer_cast(dev_data_label.data()),
                                      thrust::raw_pointer_cast(dev_data_adj.data()),
                                      thrust::raw_pointer_cast(dev_query_node.data()),
                                      thrust::raw_pointer_cast(dev_query_degree.data()),
                                      thrust::raw_pointer_cast(dev_query_label.data()),
                                      thrust::raw_pointer_cast(dev_query_adj.data()),data->v_num,query->v_num);

    cudaDeviceSynchronize();

//    test
    cudaMemcpy2D(h_index, N_size * sizeof(Tag5), d_index, pitch, N_size * sizeof(Tag5), data->v_num,cudaMemcpyDeviceToHost);
    print_h_index(h_index,data->v_num);


    cout<<"==============="<<endl;
    d_print<<<(data->v_num/32)+1,32>>>(d_index,pitch,data->v_num,N_size);
    cudaDeviceSynchronize();

    Tag5 tag = {999,999,999,999,999};
    add_one<<<1,13>>>(d_index,pitch,tag,11,data->v_num);
    cudaDeviceSynchronize();
    cudaMemcpy2D(h_index, N_size * sizeof(Tag5), d_index, pitch, N_size * sizeof(Tag5), data->v_num,cudaMemcpyDeviceToHost);
    print_h_index(h_index,data->v_num);

    return 0;
//    Tag3 = {, 4 ,};



    grid_2D = dim3 ((data->v_num/32)+1 , (single_pair_name.size()/32)+1);
    init_edge<<<grid_2D,block_2D>>>(d_index,pitch,thrust::raw_pointer_cast(dev_single_pair.data()),
                                    thrust::raw_pointer_cast(dev_data_label.data()),
                                    thrust::raw_pointer_cast(dev_data_node.data()),
                                    thrust::raw_pointer_cast(dev_data_degree.data()),
                                    thrust::raw_pointer_cast(dev_data_adj.data()),
                                    thrust::raw_pointer_cast(dev_single_pair_name.data()),data->v_num,(int)single_pair_name.size());

    cudaDeviceSynchronize();
    //    test
    cudaMemcpy2D(h_index, N_size * sizeof(Tag5), d_index, pitch, N_size * sizeof(Tag5), data->v_num,cudaMemcpyDeviceToHost);
    print_h_index(h_index,data->v_num);



//    add_one<<<1,13>>>(d_index,pitch,tag,11,data->v_num);
//    cudaDeviceSynchronize();
//    cudaMemcpy2D(h_index, N_size * sizeof(Tag5), d_index, pitch, N_size * sizeof(Tag5), data->v_num,cudaMemcpyDeviceToHost);
//    print_h_index(h_index,data->v_num);

    return 0;
}
