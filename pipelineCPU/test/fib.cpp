#include<bits/stdc++.h>
using namespace std;
const int maxn=1e5+1000;
int main() {
	int n;cin>>n;
	unsigned int f0=1,f1=1;
	for (int i=2;i<=n;i++) {
		unsigned int f2=f0+f1;
		f0=f1;
		f1=f2;
	}
	cout<<f1<<endl;
}
