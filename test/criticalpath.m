function [len,date] = criticalpath(net,pred) 

%This function calculates Critical Path of the AON network. 
%Input parameters: net -- vector with lenghts of activities; 
%pred(n,n) -- square matrix with dimensions of lenght(net) x length(net), 
%filled with zeros and ones -- on the places of dependencies. For example, 
%to specify dependency between activities 3 and 7 you should set 
%pred(3,7)=1, etc. Output parameters: len -- length of the Critical Path 
%and date(length(net),5) matrix, containing in each row corresponding 
%to activity: ES EF LS LF CP, where CP is 1 if activity is on the critical 
%path and 0 otherwise. 
 
date = zeros(length(net),5); %initialization of date matrix 
 
date(:,2)=net(:); %copy the initial values to EF 
for i=1:1:length(net) 
    date(i,2) = max(date(:,2).*pred(:,i))+date(i,2); %iteratively calculate EF 
    date(i,1) = date(i,2)-net(i);                    %and ES 
end 
 
date(:,4)=date(:,2); %copy the initial values to LF 
date(:,3)=date(:,1); %and LS 
 
for i=length(net):(-1):1 
    temp = sort(date(:,3).*pred(i,:)'); %sort successors of the activity by LS 
    lf=0; 
    for j=length(net):(-1):1 %calculate minimal non-zero value of successor's LS 
        if temp(j)>0  
            lf=temp(j); 
        end 
    end 
    date(i,4) = max(date(i,2),lf); %set activity.LF to minimal non-zero LS of successor 
    date(i,3) = date(i,4) - net(i);%calculate LS 
    if abs(date(i,1)-date(i,3))<0.001 %if ES=LS specify that activity is on critical path 
        date(i,5) = 1; 
    end 
end 
len = max(date(:,2)); %return length of critical path 
end