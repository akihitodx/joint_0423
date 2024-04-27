#include "Graph.cuh"
#include "fstream"
#include "iostream"
#include "set"
#include "queue"
#include "unordered_map"
#include "unordered_set"
#include <iomanip>

using namespace std;

struct CompareFirst {
    bool operator()(const std::pair<int, int>& lhs, const std::pair<int, int>& rhs) const {
        return lhs.first < rhs.first;
    }
};
bool Graph::ReadInFile(const std::string &FileName, int flag) {
    char type;
    int vv_num, ee_num;
    int a,b,c;
    ifstream infile;
    cout<<"Read File: "<<FileName <<endl;
    infile.open(FileName, ios::in);
    if (!infile.is_open()) {
        cout << "file open failed" << endl;
        return false;
    }
    infile >> type >> vv_num >> ee_num;
    v_num = vv_num;
    e_num = ee_num;
    q_h_node.resize(v_num,0);
    q_h_label.resize(v_num,-1);
    q_h_degree.resize(v_num,-1);
    originalId.resize(v_num, -1);
    vector<vector<int>> adj_temp(v_num);
    vector<multiset<pair<int,int>,CompareFirst>> adj_L_temp(v_num);

    for(int i = 0 ; i <v_num; ++i){
        infile >>type >> a>> b>> c;
        originalId[i] = a;
        q_h_label[a] = b;
        q_h_degree[a] = c;
    }
    for(int i = 0; i <e_num; ++i){
        infile >>type >> a>> b>> c;
//        adj_temp[a].insert(b);
//        adj_temp[b].insert(a);
        adj_L_temp[a].insert({q_h_label[b],b});
        adj_L_temp[b].insert({q_h_label[a],a});
    }
    for(int i = 0; i<v_num; ++i){
        for(auto ele : adj_L_temp[i]){
            adj_temp[i].push_back(ele.second);
        }
    }
    q_h_adj.clear();
    q_h_adj.insert(q_h_adj.end(),adj_temp[0].begin(), adj_temp[0].end());
    int count = 0;
    for(int i = 1; i<q_h_node.size(); ++i){
        count += (int)adj_temp[i-1].size();
        q_h_node[i] = count;
        q_h_adj.insert(q_h_adj.end(),adj_temp[i].begin(), adj_temp[i].end());
    }
    if(flag == 1) {
        adj_vs.resize(adj_temp.size());
        for(int i = 0 ; i< v_num ;++i){
            adj_vs[i].insert(adj_temp[i].begin(), adj_temp[i].end());
        }
    }
    cutStep = 0;
    midNode = vector<vector<int>>(q_h_label.size(), vector<int>());
    joint_group = vector<vector<Tag4>>(q_h_label.size(), vector<Tag4>());
    cout << "read finish" << endl;
    print();
    return true;
}

void Graph::except_ring() {
    auto adj_temp = adj_vs;
    auto adj_update = adj_vs;
    queue<int> queue;
    unordered_set<int> used;
    queue.push(0);
    while(!queue.empty()){
        int id = queue.front();
        queue.pop();
        used.insert(id);
        for(auto i : adj_temp[id]){
            if (used.count(i) > 0){
                single_edge.push_back(i);
                single_edge.push_back(id);
                adj_update[i].erase(id);
                adj_update[id].erase(i);
                adj_temp[i].erase(id);
            }else{
                queue.push(i);
                used.insert(i);
                adj_temp[i].erase(id);
            }
        }
    }

    vector<multiset<pair<int,int>,CompareFirst>> adj_L_temp(v_num);
    for(int i = 0 ;i < v_num; ++i){
        for(auto ele : adj_update[i]){
            adj_L_temp[i].insert({q_h_label[ele],ele});
        }
    }
    int count = 0;
    for(int i = 0; i < v_num; ++i){
        q_h_degree[i] = (int)adj_update[i].size();
        count += (int)adj_update[i].size();
        if(i+1 < q_h_node.size()) q_h_node[i+1] = count;
    }
    q_h_adj.clear();
    for(auto &i : adj_L_temp){
        for(auto ele : i){
            q_h_adj.push_back(ele.second);
        }
    }
    cout<<"finish except ring"<<endl;
    for(auto i : this->single_edge){
        cout<<i <<" ";
    }
    cout<<endl;
    print();
}

void GuangDu(vector<int>& q_h_level, vector<int>& q_h_node, vector<int>& q_h_adj, int level, int vId) {
    int next;
    if (vId < q_h_node.size() - 1) {
        next = q_h_node[vId + 1];
    }
    else {
        next = q_h_adj.size();
    }
    bool isAllNotFu1 = true;
    for (int i = q_h_node[vId]; i < next; i++) {
        if (q_h_level[q_h_adj[i]] == -1) {
            q_h_level[q_h_adj[i]] = level;
            isAllNotFu1 = false;
        }
    }
    if (isAllNotFu1) {
        return;
    }
    else {
        for (int i = q_h_node[vId]; i < next; i++) {
            GuangDu(q_h_level, q_h_node, q_h_adj, level + 1, q_h_adj[i]);
        }
    }
}

bool Graph::calcLevelId() {
    //找到度最小的节点
    int minDu = q_h_node.size();
    for (int i = 0; i < q_h_node.size(); i++) {
        if (minDu > q_h_degree[i]) {
            minDu = q_h_degree[i];
            minLevelId = i;
        }
    }
    vector<int> q_h_level(q_h_node.size(), -1);
    q_h_level[minLevelId] = 0;
    GuangDu(q_h_level, q_h_node, q_h_adj, 1, minLevelId);
    int max = 0;
    for (int i = 0; i <= q_h_level.size() - 1; i++) {
        if (max < q_h_level[i]) {
            max = q_h_level[i];
            maxLevelId = i;
        }
    }
    return true;
}

 bool Graph::division(int count, int & name) {
    cout << "start split" << endl;
//    print();

    q_h_adj_chai.resize(q_h_adj.size(), -1);
    queue<int> leftQueue;
    queue<int> rightQueue;
    //左右队列放入元素
    leftQueue.push(maxLevelId);
    rightQueue.push(minLevelId);
    while (!(leftQueue.empty() && rightQueue.empty())) {
        int checkV = -1;
        int searchV = -1;
        while (!leftQueue.empty() && checkV == -1) {
            //从left队列取出第一个
            searchV = leftQueue.front();
            //判断有没有可取点,若有选取一个点
            for (int i = q_h_node[searchV]; i < q_h_node[searchV] + q_h_degree[searchV]; i++) {
                if (q_h_adj_chai[i] == -1) {
                    //找到可取点，设置checkV为选中点id，将this_chai的这个位置设置为当前编号time
                    checkV = q_h_adj[i];
                    leftQueue.push(checkV);
                    q_h_adj_chai[i] = 0;
                    break;
                }
            }
            //没有可取点,队列弹出
            if (checkV == -1) {
                leftQueue.pop();
            }
        }
        //找到另一个边
        if (checkV != -1 && searchV != -1) {
            for (int i = q_h_node[checkV]; i < q_h_node[checkV] + q_h_degree[checkV]; i++) {
                if (q_h_adj[i] == searchV) {
                    q_h_adj_chai[i] = 0;
                    break;
                }
            }
        }
        checkV = -1;
        searchV = -1;
        while (!rightQueue.empty() && checkV == -1) {
            //从left队列取出第一个
            searchV = rightQueue.front();
            //判断有没有可取点,若有选取一个点
            for (int i = q_h_node[searchV]; i < q_h_node[searchV] + q_h_degree[searchV]; i++) {
                if (q_h_adj_chai[i] == -1) {
                    //找到可取点，设置checkV为选中点id，将this_chai的这个位置设置为当前编号time
                    checkV = q_h_adj[i];
                    rightQueue.push(checkV);
                    q_h_adj_chai[i] = 1;
                    break;
                }
            }
            //没有可取点,队列弹出
            if (checkV == -1) {
                rightQueue.pop();
            }
        }
        //找到另一个边
        if (checkV != -1 && searchV != -1) {
            for (int i = q_h_node[checkV]; i < q_h_node[checkV] + q_h_degree[checkV]; i++) {
                if (q_h_adj[i] == searchV) {
                    q_h_adj_chai[i] = 1;
                    break;
                }
            }
        }
    }
    //扫描分割点

    int get = -1;

    for (int i = 0; i < q_h_node.size(); i++) {
        for (int j = q_h_node[i]; j < q_h_node[i] + q_h_degree[i] - 1; j++) {
            if (q_h_adj_chai[j] != q_h_adj_chai[j + 1]) {
                get = originalId[i];
                break;
            }
        }
    }

    cout << "split finish" << endl;
    print();

    vector<int> leftQMap;//偏移量数组
    vector<int> rightQMap;
    vector<int> leftLabelMap;//标签数组
    vector<int> rightLabelMap;
    vector<int> leftAdjMap;//临接点数组
    vector<int> rightAdjMap;

    vector<int> leftOldQMap;
    vector<int> rightOldQMap;
    vector<int> leftOldQMapOri;
    vector<int> rightOldQMapOri;
    vector<int> leftDuMap;//上一个点id
    vector<int> rightDuMap;
    //构建左右两个GSI
    for (int i = 0; i < q_h_node.size(); i++) {
        bool isLeftPush = false;
        bool isRightPush = false;
        int thisLeftQ = leftAdjMap.size();
        int thisRightQ = rightAdjMap.size();
        for (int j = q_h_node[i]; j < q_h_node[i] + q_h_degree[i]; j++) {
            if (q_h_adj_chai[j] == 0) {
                leftAdjMap.push_back(q_h_adj[j]);
                isLeftPush = true;
            }
            if (q_h_adj_chai[j] == 1) {
                rightAdjMap.push_back(q_h_adj[j]);
                isRightPush = true;
            }
        }
        if (isLeftPush) {
            leftQMap.push_back(thisLeftQ);
            leftOldQMap.push_back(i);
            leftOldQMapOri.push_back(originalId[i]);
            leftLabelMap.push_back(q_h_label[i]);
        }
        if (isRightPush) {
            rightQMap.push_back(thisRightQ);
            rightOldQMap.push_back(i);
            rightOldQMapOri.push_back(originalId[i]);
            rightLabelMap.push_back(q_h_label[i]);
        }
    }
    //邻接点id转为新图id
    for (int i = 0; i < leftAdjMap.size(); i++) {
        for (int j = 0; j < leftOldQMap.size(); j++) {
            if (leftAdjMap[i] == leftOldQMap[j]) {
                leftAdjMap[i] = j;
                break;
            }
        }
    }
    for (int i = 0; i < rightAdjMap.size(); i++) {
        for (int j = 0; j < rightOldQMap.size(); j++) {
            if (rightAdjMap[i] == rightOldQMap[j]) {
                rightAdjMap[i] = j;
                break;
            }
        }
    }
    //设置新图的度数组
    for (int i = 0; i < leftQMap.size(); i++) {
        if (i < leftQMap.size() - 1) {
            leftDuMap.push_back(leftQMap[i + 1] - leftQMap[i]);
        }
        else {
            leftDuMap.push_back(leftAdjMap.size() - leftQMap[i]);
        }
    }
    for (int i = 0; i < rightQMap.size(); i++) {
        if (i < rightQMap.size() - 1) {
            rightDuMap.push_back(rightQMap[i + 1] - rightQMap[i]);
        }
        else {
            rightDuMap.push_back(rightAdjMap.size() - rightQMap[i]);
        }
    }

    //设置两个分割后子图的属性
    Graph left = Graph();
    Graph right = Graph();
    left.q_h_node.assign(leftQMap.begin(), leftQMap.end());
    left.q_h_label.assign(leftLabelMap.begin(), leftLabelMap.end());
    left.q_h_degree.assign(leftDuMap.begin(), leftDuMap.end());
    left.q_h_adj.assign(leftAdjMap.begin(), leftAdjMap.end());
    left.originalId.assign(leftOldQMapOri.begin(), leftOldQMapOri.end());
    this->leftChild = &left;
    left.father = this;

    left.group_name = ++name;

    right.q_h_node.assign(rightQMap.begin(), rightQMap.end());
    right.q_h_label.assign(rightLabelMap.begin(), rightLabelMap.end());
    right.q_h_degree.assign(rightDuMap.begin(), rightDuMap.end());
    right.q_h_adj.assign(rightAdjMap.begin(), rightAdjMap.end());
    right.originalId.assign(rightOldQMapOri.begin(), rightOldQMapOri.end());
    this->rightChild = &right;
    right.father = this;

    right.group_name = ++name;
    cout << "split over" << endl;
    cout << "left subgraph" << endl;


    group_name_map[left.group_name].insert(left.originalId.begin(), left.originalId.end());
    group_name_map[right.group_name].insert(right.originalId.begin(), right.originalId.end());

    left.print();
    cout << "right subgraph" << endl;
    right.print();

    joint_group[count].emplace_back(Tag4({left.group_name,right.group_name,get, this->group_name}));
    //如果拆分后的子图节点的个数大于2的话，递归进行下一次分割
    if (left.q_h_node.size() > 2) {
        left.calcLevelId();
        left.division(count + 1,name);
    }
    else {

        int another = 0;
        if(left.originalId[0]==get){
            another = left.originalId[1];
        }else{
            another = left.originalId[0];
        }
        single_pair.push_back(get);
        single_pair.push_back(another);
        single_pair_name.push_back(left.group_name);
    }

    if (right.q_h_node.size() > 2) {
        right.calcLevelId();
        right.division(count + 1,name);
    }
    else {
        int another = 0;
        if(right.originalId[0]==get){
            another = right.originalId[1];
        }else{
            another = right.originalId[0];
        }
        single_pair.push_back(get);
        single_pair.push_back(another);
        single_pair_name.push_back(right.group_name);
    }
    if (cutStep < count) {
        cutStep = count;
    }
    return true;

}

void Graph::print() {
    cout << "=============================================" << endl;
    cout << setw(12) << "node:";

    for (int i = 0; i < q_h_node.size(); i++)
        cout << setw(3) << q_h_node[i];
    cout << endl;
    cout << setw(12) << "label:";
    for (int i = 0; i < q_h_label.size(); i++)
        cout << setw(3) << q_h_label[i];
    cout << endl;
    cout << setw(12) << "originalId:";
    for (int i = 0; i < originalId.size(); i++)
        cout << setw(3) << originalId[i];
    cout << endl;
    cout << setw(12) << "degree:";
    for (int i = 0; i < q_h_degree.size(); i++)
        cout << setw(3) << q_h_degree[i];
    cout << endl;
    cout << setw(12) << "adj:";
    for (int i = 0; i < q_h_adj.size(); i++)
        cout << setw(3) << q_h_adj[i];
    cout << endl;
    cout << "=============================================" << endl;
}

