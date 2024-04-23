#include "alg.cuh"
#include "iostream"

__device__ bool add_tag(Tag5 tag,Tag5* index,Tag5* row_res,int tid_data,int data_size, size_t pitch,int next){
    if(next==0){
        int it = atomicAdd(&row_res[0].data[1], 1) + 1;
        if(it <= row_res[0].data[2]){
            printf("%d---%d,%d\n",row_res[0].data[1],row_res[0].data[2],tid_data);
            row_res[it].data[0] = tag.data[0];
            row_res[it].data[1] = tag.data[1];
            row_res[it].data[2] = tag.data[2];
            row_res[it].data[3] = tag.data[3];
            row_res[it].data[4] = tag.data[4];
        }else{
            ++next;
            add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
        }
    }else{
        Tag5* row_next =  (Tag5*)((char*)index + pitch * ((tid_data + next)%data_size));
        if(row_next[0].data[3] == tid_data){
            int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
            if(new_size >= row_next[0].data[1]){
                printf("%d---%d,%d\n",row_next[0].data[1],row_next[0].data[2],tid_data);
                int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
                row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
                row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
                row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
                row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
                row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
            }else{
                atomicAdd(&row_next[0].data[2], 1);
                ++next;
                add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
            }
        }else if(row_next[0].data[3] == -1 && row_next[0].data[2] > row_next[0].data[1]){
            int old = atomicAdd(&row_next[0].data[3],tid_data+1);
            if(old != -1)
                atomicSub(&row_next[0].data[3],tid_data+1);
            else{
                int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
                if(new_size >= row_next[0].data[1]){
                    printf("%d---%d,%d\n",row_next[0].data[1],row_next[0].data[2],tid_data);
                    int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
                    row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
                    row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
                    row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
                    row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
                    row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
                }else{
                    atomicAdd(&row_next[0].data[2], 1);
                    ++next;
                    add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
                }
            }
        }else{
            ++next;
            add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
        }

    }
    return true;
}


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
                                int query_size){
    int tid_data = blockIdx.x * blockDim.x + threadIdx.x;
    int tid_query = blockIdx.y * blockDim.y + threadIdx.y;
    if(tid_data< data_size && tid_query< query_size){
        if(query_label[tid_query] != data_label[tid_data]) return;
        if(query_degree[tid_query] > data_degree[tid_data]) return;
        int query_len = query_node[tid_query] + query_degree[tid_query];
        int data_len = data_node[tid_data] + data_degree[tid_data];
        int query_loc = query_node[tid_query], data_loc = data_node[tid_data];
//        printf("%d %d\n",tid_data,tid_query);
        while(query_loc < query_len && data_loc < data_len){
//            printf("%d-%d, %d------%d, %d^^^%d\n",tid_data,tid_query,data_label[data_adj[data_loc]],query_label[query_adj[query_loc]],data_loc,query_loc);
            if(query_label[query_adj[query_loc]] == data_label[data_adj[data_loc]]){
                ++query_loc;
                ++data_loc;
            }else if(query_label[query_adj[query_loc]] < data_label[data_adj[data_loc]]){
                break;
            }else{
                ++data_loc;
            }
        }
        if(query_loc == query_len){
//            printf("-----%d %d\n",tid_data,tid_query);
            Tag5* row_res = (Tag5*)((char*)index + pitch * tid_data);
            Tag5 tag = {0,tid_data,0,0,tid_query};
            add_tag(tag,index,row_res,tid_data,data_size,pitch,0);
        }
    }
}


//    test
__host__ void print_h_index(Tag5* h_index,int data_size){
    cout << "=========" << endl;
    for(int i = 0; i<data_size; ++i){
        cout<<i<<": ";
        for(int j = 0 ; j<h_index[i*N_size].data[0]; ++j){
            cout<<h_index[i*N_size + j].data[0]<<" "
                <<h_index[i*N_size + j].data[1]<<" "
                <<h_index[i*N_size + j].data[2]<<" "
                <<h_index[i*N_size + j].data[3]<<" "
                <<h_index[i*N_size + j].data[4]<<" / ";
        }
        cout<<endl;
    }
}

__global__ void d_print(Tag5* index,size_t pitch,int size,int N){
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if(tid < size){
        Tag5 *row = (Tag5*)((char*)index + pitch * tid);
        for(int i = 0 ; i< N ;++i){
            printf("%d: %d %d %d %d %d\n",tid,row[i].data[0],row[i].data[1],row[i].data[2],row[i].data[3],row[i].data[4]);
        }

    }
}

__global__ void add_one(Tag5* index,size_t pitch,Tag5 tag, int loc,int data_v_num){

    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if( tid == 11 || tid == 10 || tid == 0 || tid== 1){
        Tag5 *row = (Tag5*)((char*)index + pitch * tid);
        add_tag(tag,index,row,tid,data_v_num,pitch,0);
    }
}

__global__ void init_edge(Tag5* index,size_t pitch,
                          const int* query_edge_pair,
                          const int* data_label,
                          const int* data_node,
                          const int* data_degree,
                          const int* data_adj,
                          const int* single_group_name,
                          int data_v_num, int edge_num){
    int tid_data = blockIdx.x * blockDim.x + threadIdx.x;
    int tid_query = blockIdx.y * blockDim.y + threadIdx.y;
    if(tid_data< data_v_num && tid_query< edge_num){
        int node_first = query_edge_pair[2* tid_query];
        int node_second = query_edge_pair[2* tid_query + 1];
        bool flag = false;
        Tag5 *row = (Tag5*)((char*)index + pitch * tid_data);
        for(int i = 1 ; i <= row[0].data[2]; ++i){
            if(row[i].data[0] == 0 &&row[i].data[4] == node_first){
                flag = true;
                break;
            }
        }
        if(flag){
            for(int node = data_node[tid_data]; node <data_node[tid_data] + data_degree[tid_data]; ++node){
                int adj_node = data_adj[node];
                Tag5 *row_adj = (Tag5*)((char*)index + pitch * adj_node);
                for(int i = 1 ; i<= row[0].data[2]; ++i){
                    if(row_adj[i].data[0] == 0 && row_adj[i].data[4] == node_second){
                        Tag5 tag_first = {single_group_name[tid_query],tid_data,i-1,adj_node,node_first};
                        Tag5 tag_second = {single_group_name[tid_query],tid_data,i-1,tid_data,node_second};
                        add_tag(tag_first,index,row,tid_data,data_v_num,pitch,0);
                        add_tag(tag_second,index,row_adj,tid_data,data_v_num,pitch,0);
                        break;
                    }
                }
            }
        }
    }
}