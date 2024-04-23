//
// Created by nino on 2024/4/19.
//

#ifndef JOINT_0419_GRAPH_CUH
#define JOINT_0419_GRAPH_CUH

#include <vector>
#include <string>
#include <unordered_set>
#include <unordered_map>
#include "set"
#include "type.cuh"
using namespace std;

extern vector<vector<int>> midNode;
extern vector<vector<Tag3>> joint_group;
extern vector<int> single_pair;
extern unordered_map<int,vector<int>> group_name_map;
extern vector<int> single_pair_name;
extern int cutStep;
class Graph{
public:
    int v_num, e_num;
    vector<int> q_h_node;
    vector<int> q_h_label;
    vector<int> q_h_adj;
    vector<int> q_h_degree;
    vector<int> q_h_adj_chai;
    vector<int> originalId;
    int maxLevelId = -1;
    int minLevelId = -1;
    Graph *father;
    Graph *leftChild;
    Graph *rightChild;


    vector<set<int>> adj_vs;
    vector<int> single_edge;

    bool ReadInFile(const string &FileName,int flag);
    void except_ring();
    bool calcLevelId();
    bool division(int count, int & name);
    void print();
};

#endif //JOINT_0419_GRAPH_CUH
