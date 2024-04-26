#include "alg.cuh"
#include "iostream"
__device__ bool add_tag(Tag5 tag,Tag5* index,Tag5* row_res,int tid_data,int data_size, size_t pitch,int next){
    if(next == 0){
        int it = atomicAdd(&row_res[0].data[1], 1) + 1;
        if(it <= row_res[0].data[2]){
            printf("insert self %d---%d,%d\n",row_res[0].data[1],row_res[0].data[2],tid_data);
            row_res[it].data[0] = tag.data[0];
            row_res[it].data[1] = tag.data[1];
            row_res[it].data[2] = tag.data[2];
            row_res[it].data[3] = tag.data[3];
            row_res[it].data[4] = tag.data[4];
            return true;
        }else{
            return false;
        }
    }else{
        printf("try insert %d -to- >%d\n",tid_data,(tid_data + next)%data_size);
        Tag5* row_next =  (Tag5*)((char*)index + pitch * ((tid_data + next)%data_size));
        if(row_next[0].data[3] == tid_data){
            printf("%d == data[3]\n",tid_data);
            int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
            if(new_size >= row_next[0].data[1]){
                printf("insert others %d---%d,%d--to--> %d\n",row_next[0].data[1],row_next[0].data[2],tid_data,(tid_data + next)%data_size);
                int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
                row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
                row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
                row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
                row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
                row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
                return true;
            }else{
                printf("others failed %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
                atomicAdd(&row_next[0].data[2], 1);
                return false;
            }
        }else if(row_next[0].data[3] == -1 && row_next[0].data[2] > row_next[0].data[1]){
            printf("%d == -1 >data[1]\n",tid_data);
            int old = atomicAdd(&row_next[0].data[3],tid_data+1);
            if(old != -1){
                printf("%d --> %d update failed\n",tid_data,(tid_data + next)%data_size);
                atomicSub(&row_next[0].data[3],tid_data+1);
                return false;
            }
            else{
                int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
                if(new_size >= row_next[0].data[1]){
                    printf("%d --> %d update succeed and insert\n",tid_data,(tid_data + next)%data_size);
                    printf("%d---%d,%d\n",row_next[0].data[1],row_next[0].data[2],tid_data);
                    int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
                    row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
                    row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
                    row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
                    row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
                    row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
                    return true;
                }else{
                    printf("others failed but in %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
                    atomicAdd(&row_next[0].data[2], 1);
                    return false;
                }
            }
        }else{
            printf("%d shit!\n",tid_data);
            printf("over and next %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
            return false;
        }
    }
}


//__device__ bool add_tag_old(Tag5 tag,Tag5* index,Tag5* row_res,int tid_data,int data_size, size_t pitch,int next){
//    if(next==0){
//        int it = atomicAdd(&row_res[0].data[1], 1) + 1;
//        if(it <= row_res[0].data[2]){
//            printf("insert self %d---%d,%d\n",row_res[0].data[1],row_res[0].data[2],tid_data);
//            row_res[it].data[0] = tag.data[0];
//            row_res[it].data[1] = tag.data[1];
//            row_res[it].data[2] = tag.data[2];
//            row_res[it].data[3] = tag.data[3];
//            row_res[it].data[4] = tag.data[4];
//        }else{
//            printf("need insert others %d\n",tid_data);
//            ++next;
//            add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
//        }
//    }else{
//        printf("try insert %d -to- >%d\n",tid_data,(tid_data + next)%data_size);
//        Tag5* row_next =  (Tag5*)((char*)index + pitch * ((tid_data + next)%data_size));
//        printf("%d --> %d : %d , %d ,%d ,%d\n",tid_data,(tid_data + next)%data_size,row_next[0].data[1],row_next[0].data[2],row_next[0].data[3],row_next[0].data[4]);
//        if(row_next[0].data[3] == tid_data){
//            printf("%d == data[3]\n",tid_data);
//            int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
//            if(new_size >= row_next[0].data[1]){
//                printf("insert others %d---%d,%d--to--> %d\n",row_next[0].data[1],row_next[0].data[2],tid_data,(tid_data + next)%data_size);
//                int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
//                row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
//                row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
//                row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
//                row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
//                row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
//            }else{
//                printf("others failed %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
//                atomicAdd(&row_next[0].data[2], 1);
//                ++next;
//                add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
//            }
//        }else if(row_next[0].data[3] == -1 && row_next[0].data[2] > row_next[0].data[1]){
//            printf("%d == -1 >data[1]\n",tid_data);
//            int old = atomicAdd(&row_next[0].data[3],tid_data+1);
//            if(old != -1){
//                printf("%d --> %d update failed\n",tid_data,(tid_data + next)%data_size);
//                atomicSub(&row_next[0].data[3],tid_data+1);
//                ++next;
//                add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
//            }
//            else{
//
//                int new_size = atomicSub(&row_next[0].data[2], 1) - 1;
//                if(new_size >= row_next[0].data[1]){
//                    printf("%d --> %d update succeed and insert\n",tid_data,(tid_data + next)%data_size);
//                    printf("%d---%d,%d\n",row_next[0].data[1],row_next[0].data[2],tid_data);
//                    int old_loc_o = atomicAdd(&row_next[0].data[4], 1);
//                    row_next[N_size - old_loc_o -1].data[0] = tag.data[0];
//                    row_next[N_size - old_loc_o -1].data[1] = tag.data[1];
//                    row_next[N_size - old_loc_o -1].data[2] = tag.data[2];
//                    row_next[N_size - old_loc_o -1].data[3] = tag.data[3];
//                    row_next[N_size - old_loc_o -1].data[4] = tag.data[4];
//                }else{
//                    printf("others failed but in %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
//                    atomicAdd(&row_next[0].data[2], 1);
//                    ++next;
//                    add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
//                }
//            }
//        }else{
//            printf("%d shit!\n",tid_data);
//            printf("over and next %d --to--> %d\n",tid_data,(tid_data + next)%data_size);
//            ++next;
//            add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
//        }
//
//    }
//    return true;
//}


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
            int next = 0;
            bool flag = false;
            while (!flag && next<data_size){
                flag = add_tag(tag,index,row_res,tid_data,data_size,pitch,next);
                ++next;
            }

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
    if( tid == 11 || tid == 10 || tid == 0 || tid == 1 || tid == 2){
        printf("tid --> %d\n",tid);
        Tag5 *row = (Tag5*)((char*)index + pitch * tid);
        int next = 0;
        bool flag = false;
        while (!flag && next<data_v_num){
            flag = add_tag(tag,index,row,tid,data_v_num,pitch,next);
            ++next;
        }
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
        for(int i = 1 ; i <= row[0].data[1]; ++i){
            if(row[i].data[0] == 0 && row[i].data[4] == node_first){
                flag = true;
                break;
            }
        }
        if(flag){
//            printf("%d--%d == %d %d\n",tid_data,tid_query, node_first, node_second);
            for(int node = data_node[tid_data]; node <data_node[tid_data] + data_degree[tid_data]; ++node){
//                printf("%d, %d ---%d\n",tid_data,node,data_node[tid_data] + data_degree[tid_data]);
                int adj_node = data_adj[node];
//                printf("%d--%d == %d %d ---%d\n",tid_data,tid_query, node_first, node_second ,adj_node);
                Tag5 *row_adj = (Tag5*)((char*)index + pitch * adj_node);
                for(int i = 1 ; i<= row_adj[0].data[1]; ++i){
                    if(row_adj[i].data[0] == 0 && row_adj[i].data[4] == node_second){
                        Tag5 tag_first = {single_group_name[tid_query],tid_data,i-1,adj_node,node_first};
                        Tag5 tag_second = {single_group_name[tid_query],tid_data,i-1,tid_data,node_second};
                        printf("add tag %d, %d\n",tid_data,adj_node);
                        int next = 0;
                        bool ff = false;
                        while(!ff && next<data_v_num){
                            ff = add_tag(tag_first,index,row,tid_data,data_v_num,pitch,next);
                            ++next;
                        }
                        next = 0;
                        ff = false;
                        while(!ff && next<data_v_num){
                            ff = add_tag(tag_second,index,row_adj,adj_node,data_v_num,pitch,next);
                            ++next;
                        }
                        break;
                    }
                }
            }
        }
    }
}

__device__ int find_next(int cur_tid,int ori_tid,Tag5* index,size_t pitch){
    ++cur_tid;
    Tag5 *row = (Tag5*)((char*)index + pitch * cur_tid);
    while (row[0].data[3] != ori_tid){
        ++cur_tid;
        row = (Tag5*)((char*)index + pitch * cur_tid);
    }
    return cur_tid;
};

__global__ void joint(Tag5* index,size_t pitch,Tag3 info,
                      const int* del_edge,
                      const int* node_set,
                      const int* degree_set,
                      const int* adj_set,
                      int data_v_num){
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if(tid == 10 || tid == 11){
        Tag2 first_set[N_size/2];
        Tag2 second_set[N_size/2];
        int first_count = 0, second_count = 0;
        Tag5 *row = (Tag5*)((char*)index + pitch * tid);
        for (int i = 1 ; i <= row[0].data[2]; ++i){
            if(row[i].data[0] == info.data[0] && row[i].data[4] == info.data[2]){
                first_set[first_count++] = {tid,i};
                break;
            }
            if(row[i].data[0] == info.data[1] && row[i].data[4] == info.data[2]){
                second_set[second_count++] = {tid,i};
                break;
            }
        }
        if(row[0].data[1] > row[0].data[2]){
            int cur_count = row[0].data[2];
            int sum_count = row[0].data[1];
            int cur_tid = tid;
            int next_tid = find_next(cur_tid,tid,index,pitch);
            while (cur_count < sum_count){
                Tag5 *row_next = (Tag5*)((char*)index + pitch * next_tid);
                cur_count += row_next[0].data[4];
                for (int i = 0 ; i < row_next[0].data[4]; ++i){
                    if(row_next[i].data[0] == info.data[0] && row_next[i].data[4] == info.data[2]){
                        first_set[first_count++] = {next_tid,N_size- i -1};
                        break;
                    }
                    if(row_next[i].data[0] == info.data[1] && row_next[i].data[4] == info.data[2]){
                        second_set[second_count++] = {next_tid,N_size- i -1};
                        break;
                    }
                }
            }
        }
        for(int i = 0 ;i < second_count; ++i){
            printf("%d,%d\n",second_set[i].data[0],second_set[i].data[1]);
        }
    }

}