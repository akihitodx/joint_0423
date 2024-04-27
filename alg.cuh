#ifndef JOINT_0419_ALG_CUH
#define JOINT_0419_ALG_CUH
#include "type.cuh"
#include "Graph.cuh"


__global__ void init_edge(Tag5* index,size_t pitch,
                          const int* query_edge_pair,
                          const int* data_label,
                          const int* data_node,
                          const int* data_degree,
                          const int* data_adj,
                          const int* single_group_name,
                          int data_v_num, int edge_num);

__global__ void data_filter(Tag5* index,
                            size_t pitch,
                            const int* data_node,
                            const int* data_degree,
                            const int* data_label,
                            const int* data_adj,
                            const int* query_node,
                            const int* query_degree,
                            const int* query_label,
                            const int* query_adj,
                            int data_size,
                            int query_size);

__global__ void joint(Tag5* index,size_t pitch,Tag4 info,
                      const int* del_edge,
                      const int* node_set,
                      const int* degree_set,
                      const int* adj_set,
                      int data_v_num, int query_v_num, int del_edge_size);

__device__ bool add_tag(Tag5 tag,Tag5* index,Tag5* row_res,int tid_data,int data_size, size_t pitch,int next);

__host__ void print_h_index(Tag5* h_index,int data_size);

__global__ void d_print(Tag5* index,size_t pitch,int size,int N);
__global__ void add_one(Tag5* index,size_t pitch,Tag5 tag, int loc,int data_v_num);
#endif //JOINT_0419_ALG_CUH
