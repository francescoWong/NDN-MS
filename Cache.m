classdef Cache %  The NDN-MS Cache
    
    properties
        CS;
        PIT;
        RUT;
        TIS;
        TNS;
        
        access_num; % amount of requests related to Interest
        hit_num; % amount of hits
        
        cache_id;
        cache_size;
        
        missTrace; % for interest
        missTraceNup; % for Nup 
        missTraceData; % for Data
        hit_signal;
        
        probability;
        average_hit;
        nonPIT;
    end
    
    methods
        function obj=Cache(cache_id, cache_size, probability)
            if nargin>0
                obj.cache_id=cache_id;
                obj.cache_size=cache_size;
                
                obj.CS=cell(cache_size,1);
                obj.PIT=cell(cache_size,1);
                obj.RUT=cell(cache_size,2);
                obj.TIS=cell(cache_size,1);
                obj.TNS=cell(cache_size,2);
                
                obj.access_num=0;
                obj.hit_num=0;
                obj.hit_signal=0;
                obj.probability=probability;
                obj.nonPIT=0;
            end
        end
        
        function obj=set_access_num(obj, access_num)          
             obj.access_num=access_num;
        end
        
        function obj=set_hit_num(obj, hit_num)          
             obj.hit_num=hit_num;
        end
        
        function obj=set_TNS(obj, cache_size)          
             obj.TNS=cell(cache_size,1);
        end
        
        function obj=set_TIS(obj, cache_size)          
             obj.TIS=cell(cache_size,1);
        end
        
        function obj=set_RUT(obj, cache_size)          
             obj.RUT=cell(cache_size,1);
        end
        
        function obj=set_PIT(obj, cache_size)          
             obj.PIT=cell(cache_size,1);
        end
        
        function obj=set_CS(obj, cache_size)          
             obj.CS=cell(cache_size,1);
        end
        
        function obj=set_CacheSize(obj, cache_size)          
             obj.cache_size=cache_size;
        end
        
         function obj=set_Probability(obj, probability)          
             obj.probability=probability;
        end
        
       function obj=set_ID(obj, id)
            obj.cache_id=id;
       end
        
        function average_hit=average_HitRate(obj)
            average_hit=obj.hit_num/obj.access_num;
            if isnan(average_hit)
                average_hit=0;
            end
       end
        
        function obj=handle_Interest(obj, interest_CN, interest_DM)
            obj.hit_signal=0;
            obj.nonPIT=0;
            c=find(strcmp(obj.CS(:),interest_CN));
            obj.access_num=obj.access_num+1; 
            if (numel(c)~=0) % Cache hit
                obj.nonPIT=1;
                obj=obj.handle_Data(interest_CN);
                obj.hit_num=obj.hit_num+1;
                obj.hit_signal=1;
            else % handle PIT
                p=find(strcmp(obj.PIT(:, 1),interest_CN));
                if (numel(p)~=0) % PIT.Y
                     t=find(strcmp(obj.TIS(:, 1),interest_CN)); % find Interest in TIS
                     if (numel(t)~=0) 
                        obj.TIS=obj.refresh_TIS(interest_CN);  %refresh Interest.lifetime in TIS
                     end
                else % PIT.N
                     r=find(strcmp(obj.RUT(:, 1),interest_CN));
                     if (numel(r)~=0) %  RUT.Y
                         obj.PIT=obj.storePIT(interest_CN); % store interest_CN in PIT
                         obj.missTrace=obj.forwardInterest(interest_CN, interest_DM); % forward interest_CN according to RUT.DM
                     else %  RUT.N
                         % omit FIB
                          t=find(strcmp(obj.TIS(:, 1),interest_CN));
                          if (numel(t)==0) %  TIS
                              obj.TIS=obj.storeTIS(interest_CN); 
                          end                        
                         obj.RUT=obj.storeRUT(interest_CN, interest_DM); 
                         obj.PIT=obj.storePIT(interest_CN); 
                         obj.missTrace=obj.forwardInterestFIB(interest_CN, interest_DM);  % forward interest_CN according to FIB
                     end
                end      
            end 
        end
        
        function missTrace=forwardInterest(obj, interest_CN, interest_DM)
                missTrace=cell(1, 2);
                missTrace(1,1)= {interest_CN}; 
                missTrace(1,2)= {interest_DM};
                t=find(strcmp(obj.RUT(:, 1),interest_CN));
                if(numel(t)~=0) 
                     missTrace(1,2)=obj.RUT(t, 2);
                end
        end
         
        function missTrace=forwardInterestFIB(~, interest_CN, interest_DM)
            missTrace=cell(1, 2);
            missTrace(1,1)= {interest_CN}; 
            missTrace(1,2)= {interest_DM};
        end
             
        function RUT=storeRUT(obj, interest_CN, interest_DM)
            RUT=cell(size(obj.RUT, 1)+1, 2);
            RUT(1,1)={interest_CN};
            RUT(1,2)={interest_DM};
            j=2;
            for i=1:1:size(obj.RUT, 1)
                    RUT(j,1)=obj.RUT(i,1);
                    RUT(j,2)=obj.RUT(i,2);
                    j=j+1;
            end
            if size(RUT, 1) > size(obj.RUT, 1)
                temp_RUT=cell(size(obj.RUT, 1), 2);
                for i=1:1:size(obj.RUT, 1)
                    temp_RUT(i,1)=RUT(i,1);
                    temp_RUT(i,2)=RUT(i,2);
                end
                RUT=temp_RUT;
            end           
        end
        
        function TIS=storeTIS(obj, interest_CN)
            TIS=cell(size(obj.TIS, 1)+1, 1);
            TIS(1,:)={interest_CN};
            j=2;
            for i=1:1:size(obj.TIS, 1)
                    TIS(j,:)=obj.TIS(i,:);
                    j=j+1;
            end
            if size(TIS, 1) > size(obj.TIS, 1)
                temp_TIS=cell(size(obj.TIS, 1), 1);
                for i=1:1:size(obj.TIS, 1)
                    temp_TIS(i,:)=TIS(i,:);
                end
                TIS=temp_TIS;
            end           
        end
        
        
        function PIT=storePIT(obj, interest_CN)
            PIT=cell(size(obj.PIT, 1)+1, 1);
            PIT(1,:)={interest_CN};
            j=2;
            for i=1:1:size(obj.PIT, 1)
                    PIT(j,:)=obj.PIT(i,:);
                    j=j+1;
            end
            if size(PIT, 1) > size(obj.PIT, 1)
                temp_PIT=cell(size(obj.PIT, 1), 1);
                for i=1:1:size(obj.PIT, 1)
                    temp_PIT(i,:)=PIT(i,:);
                end
                PIT=temp_PIT;
            end           
        end
             
        
        function TIS=refresh_TIS(obj, interest_CN)         
            temp_TIS=cell(size(obj.TIS,1),1);
            t=find(strcmp(obj.TIS(:, 1),interest_CN));
            if(numel(t)~=0) 
                j=2;
                temp_TIS(1,:)=obj.TIS(t,:);
                for i=1:1:size(obj.TIS,1)
                    if i~=t
                         temp_TIS(j,:)=obj.TIS(i,:);
                         j=j+1;
                    end
                end
                TIS=temp_TIS;  
            end
        end
        
        
        function obj=handle_Nup(obj, nup_CN, nup_UM)
            t=find(strcmp(obj.TNS(:,1),nup_CN)); % handle TNS
            if (numel(t)~=0 && strcmp(obj.TNS{t, 2}, nup_UM) ) % TNS.Y
                 obj.TNS=obj.refresh_TNS(nup_CN); %refresh nup.lifetime in TNS
            else % TNS.N
                t=find(strcmp(obj.TIS(:,1),nup_CN)); % handle TIS
                if (numel(t)~=0) % TIS.Y
                    obj.TNS=obj.store_TNS(nup_CN, nup_UM); %store nup in TNS
                    obj.missTrace=obj.updateAndPop_RUT(nup_CN, nup_UM); %updata RUT and pop Interest
                else % TIS.N
                    obj.RUT=obj.updateAndStore_RUT(nup_CN, nup_UM); %update and store Nup in RUT
                    obj.TNS=obj.store_TNS(nup_CN, nup_UM); %store nup in TNS
                    obj.missTraceNup=obj.forwardNup(nup_CN, nup_UM); %forward Nup
                end
            end
        end
        
         function RUT=updateAndStore_RUT(obj, nup_CN, nup_UM)
             %% update RUT
            temp_RUT=cell(size(obj.RUT,1),2);
            t=find(strcmp(obj.RUT(:, 1),nup_CN));
            if(numel(t)~=0) 
                j=2;
                temp_RUT(1,1)=obj.RUT(t,1);
                temp_RUT(1,2)={nup_UM};
                for i=1:1:size(obj.RUT,1)
                    if i~=t
                         temp_RUT(j,1)=obj.RUT(i,1);
                         temp_RUT(j,2)=obj.RUT(i,2);
                         j=j+1;
                    end
                end
                RUT=temp_RUT;
            else % cannot find nup_CN in RUT
                RUT=cell(size(obj.RUT, 1)+1, 2);
                RUT(1,1)={nup_CN};
                RUT(1,2)={nup_UM};
                j=2;
                for i=1:1:size(obj.RUT, 1)
                        RUT(j,1)=obj.RUT(i,1);
                        RUT(j,2)=obj.RUT(i,2);
                        j=j+1;
                end
                if size(RUT, 1) > size(obj.RUT, 1)
                    temp_RUT=cell(size(obj.RUT, 1), 2);
                    for i=1:1:size(obj.RUT, 1)
                        temp_RUT(i,1)=RUT(i,1);
                        temp_RUT(i,2)=RUT(i,2);
                    end
                    RUT=temp_RUT;
                end                  
            end
             
         end
        
        function missTraceNup=forwardNup(~, nup_CN, nup_UM)
            missTraceNup=cell(1, 2);
            missTraceNup(1,1)= {nup_CN}; 
            missTraceNup(1,2)= {nup_UM};
        end
        
        function missTrace=updateAndPop_RUT(obj, nup_CN, nup_UM)
            %% update RUT
            temp_RUT=cell(size(obj.RUT,1),2);
            t=find(strcmp(obj.RUT(:, 1),nup_CN));
            if(numel(t)~=0) 
                j=2;
                temp_RUT(1,1)=obj.RUT(t,1);
                temp_RUT(1,2)={nup_UM};
                for i=1:1:size(obj.RUT,1)
                    if i~=t
                         temp_RUT(j,1)=obj.RUT(i,1);
                         temp_RUT(j,2)=obj.RUT(i,2);
                         j=j+1;
                    end
                end
                obj.RUT=temp_RUT;  
            end
            %% Pop  interest from TIS
            missTrace=cell(1, 2); 
            t=find(strcmp(obj.TIS(:, 1),nup_CN));
            if(numel(t)~=0) 
                  missTrace(1,1)= {nup_CN}; 
                  missTrace(1,2)= {nup_UM};
            end              
        end
        
                
        function TNS=refresh_TNS(obj, nup_CN)         
            temp_TNS=cell(size(obj.TNS,1),2);
            t=find(strcmp(obj.TNS(:, 1),nup_CN));
            if(numel(t)~=0) 
                j=2;
                temp_TNS(1,1)=obj.TNS(t,1);
                temp_TNS(1,2)=obj.TNS(t,2);
                for i=1:1:size(obj.TNS,1)
                    if i~=t
                         temp_TNS(j,1)=obj.TNS(i,1);
                         temp_TNS(j,2)=obj.TNS(i,2);
                         j=j+1;
                    end
                end
                TNS=temp_TNS;  
            end
        end
        
        function TNS=store_TNS(obj, nup_CN, nup_UM)
            TNS=cell(size(obj.TNS, 1)+1, 2);
            TNS(1,1)={nup_CN};
            TNS(1,2)={nup_UM};
            j=2;
            for i=1:1:size(obj.TNS, 1)
                    TNS(j,1)=obj.TNS(i,1);
                    TNS(j,2)=obj.TNS(i,2);
                    j=j+1;
            end
            if size(TNS, 1) > size(obj.TNS, 1)
                temp_TNS=cell(size(obj.TNS, 1), 2);
                for i=1:1:size(obj.TNS, 1)
                    temp_TNS(i,1)=TNS(i,1);
                    temp_TNS(i,2)=TNS(i,2);
                end
                TNS=temp_TNS;
            end           
        end
        

        function obj=handle_Data(obj, data_CN)
            t=find(strcmp(obj.PIT(:, 1),data_CN)); % handle PIT
            if (numel(t)~=0 ) || (obj.nonPIT==1)  % PIT.Y
                 obj.CS=obj.store_CS(data_CN); %store data_CN in CS
                 obj.TNS=obj.remove_TNS(data_CN); %remove data_CN in TNS
                 obj.TIS=obj.remove_TIS(data_CN); %remove data_CN in TIS
                 obj.PIT=obj.remove_PIT(data_CN); %remove data_CN in PIT
                 obj.missTraceData=obj.forwardData(data_CN); %forward data
            end
        end
        
        function missTraceData=forwardData(~, data_CN)
            missTraceData=cell(1, 1);
             missTraceData(1,1)= {data_CN}; 
        end
        
        function PIT=remove_PIT(obj, data_CN)
            t=find(strcmp(obj.PIT(:, 1),data_CN));
            if(numel(t)~=0) 
                obj.PIT{t,1}=[];
            end
            PIT=obj.PIT;
        end
        
        function TNS=remove_TNS(obj, data_CN)
            t=find(strcmp(obj.TNS(:, 1),data_CN));
            if(numel(t)~=0) 
                obj.TNS{t,1}=[];
                obj.TNS{t,2}=[];
            end
            TNS=obj.TNS;
        end
        
        function TIS=remove_TIS(obj, data_CN)
         t=find(strcmp(obj.TIS(:, 1),data_CN));
            if(numel(t)~=0) 
                obj.TIS{t,1}=[];
            end
            TIS=obj.TIS;
        end
        
         function CS=store_CS(obj, data_CN)
            % store and refresh CS
            CS=cell(size(obj.CS, 1)+1, 1);
            CS(1,:)={data_CN};
            j=2;
            for i=1:1:size(obj.CS, 1)
                    CS(j,:)=obj.CS(i,:);
                    j=j+1;
            end
            t=find(strcmp(CS(:,1),data_CN));
            if  (numel(t)==1)
                if size(CS, 1) > size(obj.CS, 1)
                    temp_CS=cell(size(obj.CS, 1), 1);
                    for i=1:1:size(obj.CS, 1)
                        temp_CS(i,:)=CS(i,:);
                    end
                    CS=temp_CS;
                end               
            else            
                if size(CS, 1) > size(obj.CS, 1)
                    temp_CS=cell(size(obj.CS, 1), 1);
                    num=1;
                    for i=1:1:size(CS, 1)
                        if t(2)~=i
                            temp_CS(num,:)=CS(i,:);
                            num=num+1;
                        else
                            i=i+1;
                        end
                    end
                    CS=temp_CS;
                end
            end
     end
        

    end
    
    
end