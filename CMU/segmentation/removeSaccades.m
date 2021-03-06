function removeSaccades(input_dir, type, type2)

if ~exist('input_dir', 'var')
    fprintf('Need an input_dir\n');
    return
end

output_dir=fullfile(input_dir);
flow_dir=fullfile(input_dir,'flow');
input_dir=fullfile(input_dir,'data');

if ~exist(input_dir, 'dir')
    fprintf('intput_dir does''nt exist\n');
    return
end


if ~exist('type', 'var') %saccades detection algorithm
    type=1;
end

if ~exist('type2', 'var') %image extraction algorithm
    type2=2;
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

imgFixs_dir=[output_dir '/output/imgs_fixs'];
if ~exist(imgFixs_dir, 'dir')
    mkdir(imgFixs_dir);
else
    delete([imgFixs_dir, '/*.*']);
end 

%% NEED TO CHANGE IT IF YOU CHANGE THE INPUT DATA (images)
imageBasename='/capture_img_out_*.jpg'; % basename of image files
filenames=dir([input_dir, imageBasename]);
N=length(filenames);
if N==0
    disp('No data!!!');
    exit(1);
end

%% NEED TO CHANGE IT IF YOU CHANGE THE INPUT DATA (eyes positions data)
%% what's needed is a N*2 matrix representing the coords (x,y) of the gaze
%% in each frame
logs=read_log_file([input_dir '/image_save/Log_data.txt']);
if isempty(logs)
    logs=read_log_file([input_dir '/Log_data.txt']);
end
timestamps=logs.Data(:,14);
fixs=logs.Data(:,8:9)+ones(size(logs.Data,1),1)*logs.Offset_xy; %Matrix N*2 for the eyes coordinates in each frame (x,y)

fixs=max(fixs,-200);%thresolding to remove the -Inf values given by the eye-tracking system when it does not converge

% interpolating the eye's pos data according to the error score (PROBABLY NOT NEEDED FOR OTHER INPUTS)
i=2;
while i<size(fixs,1)
    if logs.Data(i,7)>200%error score
        j=i;
        while logs.Data(j,7)>200
            j=j+1;
        end
        fixs(i:j,:)=ones(j-i+1,1)*fixs(i-1,:)+(1:j-i+1)'*(fixs(j+1,:)-fixs(i-1,:))/(j-i);
        i=j;
    end
    i=i+1;
end

%% biaising the values with the optical flow
dlmwrite([input_dir '/fixs.txt'],fixs,'delimiter',' '); %write the values in a txt file
cmd=['export LD_LIBRARY_PATH=""; ./trackingGaze ' input_dir];
if unix(cmd)%launch the external program for calculation
    disp(['Impossible to use correctly the executable : ' cmd '. Is the folder correct and the executables compiled?']);
end;
flows=load([input_dir '/flows.txt']);%load the results of the computation
flows(2:size(flows,1)+1,:)=flows;
flows(1,:)=[0 0];
fixs2(:,:)=fixs(:,:)-cumsum(flows,1); %biaised values

%% denoising
x=fixs2(:,1);
y=fixs2(:,2);
[THR,SORH,KEEPAPP] = ddencmp('den','wv',x(1:600));
x= wdencmp('gbl',x,'db3',8,THR,SORH,KEEPAPP);
y= wdencmp('gbl',y,'db3',8,THR,SORH,KEEPAPP);
fixs2=[x y];

fixs=fixs2+cumsum(flows,1);%original fixations denoised

%% saccades detection algorithms
if type==0
    fixations=HMMSimpleExtraction(fixs2);
elseif type==1
    fixations=dispersionExtraction(fixs2);
elseif type ==2
    fixations=HMMWithFlowExtraction(max(fixs,-200),flow_dir);%deprecated
elseif type ==3
    fixations=dispersionWithFlowExtraction(max(fixs,-200),flow_dir);%deprecated
end;
disp(fixations);

%% deprecated (old optical flow method)
% flowFilenames=dir([flow_dir, '/capture_img_out_*.png']);
% using_flow=false;
% if length(flowFilenames)~=N-1
%     disp('All the flow calculation hasn''t been done...');
%     using_flow=false;
% end;

%% extraction of images from the fixations
unix(['rm ' output_dir '/*.jpg']);
unix(['rm ' imgFixs_dir '/*']);
names=zeros(1,size(filenames(1).name,2));
names2=zeros(1,size(filenames(1).name,2));
eye_pos=zeros(1,2);
if type2==0 % extract one image per fixation
    n=0;
    for i=1:size(fixations,1)
        k=fixations(i,1);
        if fixs(k,1)<=0 || fixs(k,2)<=0 || fixs(k,2)>logs.siz_Outimg(1) || fixs(k,1)>logs.siz_Outimg(2)
            fprintf('Dropping out-of-range fixation points...\n');
            if fixations(i,3)<=0
                fprintf('\ttop\n');
            end
            if fixations(i,2)<=0
                fprintf('\tleft\n');
            end
            if fixations(i,3)>logs.siz_Outimg(1)
                fprintf('\tbottom\n');
            end
            if fixations(i,2)>logs.siz_Outimg(2)
                fprintf('\tright\n');
            end
            continue
        end;
        n=n+1;
        bestScore=0;
        argMax=-1;
        for k=round(fixations(i,1)-30/3*fixations(i,4)):round(fixations(i,1)+30/3*fixations(i,4))
            input_name=fullfile(input_dir,filenames(k).name);
            img=imread(input_name);
            tmp=sharpnessScore(img);
            if using_flow
                flow_name=fullfile(flow_dir,flowFilenames(k).name);
                flow_img=imread(flow_name);
                tmp=sharpnessScore(img)+sum(std(std(double(flow_img),0,1),0,2));
            end
            if tmp>bestScore
                argMax=k;
                bestScore=tmp;
            end
    %         if isVerticalSync(img) || k==1
    %             break;
    %         else
    %             k=k-1;
    %             fprintf('Dropping out-of-VSync frame : %i\n',k);
    %         end;
        end;
        
        input_name=fullfile(input_dir,filenames(argMax).name);
        new_name=sprintf('%010i.jpg',argMax);
        output_name=fullfile(output_dir, new_name);
        names(n,:)=filenames(argMax).name;
        names2(n,:)=filenames(argMax+1).name;
        fixationsResult(n).fixs=round([fixs(argMax,1) fixs(argMax,2)]);
        fixationsResult(n).name=new_name;
        copyfile(input_name,output_name);
        img=imread(input_name);
        img=drawCross(img,fixationsResult(argMax).fixs(1,1),fixationsResult(argMax).fixs(1,2),[0 255 0]);
        imwrite(img,fullfile(imgFixs_dir,new_name));
    end
elseif type2==1 % extract multiple images (if fixations are long enough)
    green=[0 255 0];
    blue=[0 0 255];
    windowSize=20;
    color=blue;
    n=0;
    for i=1:size(fixations,1)
        gotOne=false;
        d=fixations(i,6)+1-fixations(i,5);
        begin=fixations(i,5)+round(d/6);
        ending=fixations(i,5)+round(5*d/6);
        nbSteps=round((ending+1-begin)/windowSize)+1;
        stepSize=round((ending+1-begin)/nbSteps);
        for l=0:nbSteps-1
            bestScore=0;
            argMax=-1;
            for k=(begin+l*stepSize):min(ending,begin+(l+1)*stepSize)
                input_name=fullfile(input_dir,filenames(k).name);
                img=imread(input_name);
                tmp=sharpnessScore(img);
                if tmp>bestScore
                    argMax=k;
                    bestScore=tmp;
                end
            end
            if fixs(k,1)<=0 || fixs(k,2)<=0 || fixs(k,2)>logs.siz_Outimg(1) || fixs(k,1)>logs.siz_Outimg(2)
                continue
            end
            gotOne=true;
            n=n+1;
            input_name=fullfile(input_dir,filenames(argMax).name);
            new_name=sprintf('%010i.jpg',argMax);
            output_name=fullfile(output_dir, new_name);
            names(n,:)=filenames(argMax).name;
            names2(n,:)=filenames(argMax+1).name;
            fixationsResult(n).fixs=round([fixs(argMax,1) fixs(argMax,2)]);
            fixationsResult(n).name=new_name;
            copyfile(input_name,output_name);
            img=imread(input_name);
            img=drawCross(img,eye_pos(n,1),eye_pos(n,2),color);
            imwrite(img,fullfile(imgFixs_dir,new_name));
        end
        if gotOne
            if isequal(color,green)
                color=blue;
            else
                color=green;
            end
        end
    end
elseif type2==2 % track fixations and extract one image every subsampleStep images
    subsampleStep=10;
    n=0;
    m=0;
    fid = fopen([input_dir '/fixs2.txt'], 'w');
    for i=1:size(fixations,1)
        k=fixations(i,1);
        if fixs(k,1)<=0 || fixs(k,2)<=0 || fixs(k,2)>logs.siz_Outimg(1) || fixs(k,1)>logs.siz_Outimg(2)
            fprintf('Dropping out-of-range fixation points...\n');
            if fixs(k,2)<=0
                fprintf('\ttop\n');
            end
            if fixs(k,1)<=0
                fprintf('\tleft\n');
            end
            if fixs(k,2)>logs.siz_Outimg(1)
                fprintf('\tbottom\n');
            end
            if fixs(k,1)>logs.siz_Outimg(2)
                fprintf('\tright\n');
            end
            continue
        end;
        while m<fixations(i,1)
            fprintf(fid,'\n');
            m=m+1;
        end;
        
        fprintf(fid,'%i %i\n',round(fixs(k,1)),round(fixs(k,2)));
        m=m+1;
        
    end
    while m<size(fixs,1)
            fprintf(fid,'\n');
            m=m+1;
    end;
    fclose(fid);
    cmd=['export LD_LIBRARY_PATH=""; ./trackingFixations ' input_dir];
    unix(cmd);
    % get back the results of tracking
    fid=fopen([input_dir '/fixs3.txt']);
    m=0;
    while ~feof(fid)
        a=sscanf(fgetl(fid),'%i %i',[2 inf]);
        a=a';
        m=m+1;
        fixationsTracked(m).fixs=a;
    end
    fclose(fid);
    
    % subsample video
    n=0;
    nbImages=0;
    while n<size(fixationsTracked,2)
        mask=[];
        m=0;
        while n<size(fixationsTracked,2) && m<subsampleStep
           n=n+1;
           m=m+1;
           if(size(fixationsTracked(n).fixs,1)>0)
               mask=[mask n];
           end
        end
        if size(mask)>0
            bestScore=0;
            argMax=-1;
            for k=mask
               input_name=fullfile(input_dir,filenames(k).name);
               img=imread(input_name);
               tmp=sharpnessScore(img);
               if tmp>bestScore
                   argMax=k;
                   bestScore=tmp;
               end
            end;
            nbImages=nbImages+1;
            input_name=fullfile(input_dir,filenames(argMax).name);
            new_name=sprintf('%010i.jpg',argMax);
            output_name=fullfile(output_dir, new_name);
            names(n,:)=filenames(argMax).name;
            names2(n,:)=filenames(argMax+1).name;
            
            copyfile(input_name,output_name);
            img=imread(input_name);
            fprintf('Image %i ',argMax);
            for k=1:size(fixationsTracked(argMax).fixs,1)
               img=drawCross(img,fixationsTracked(argMax).fixs(k,1),fixationsTracked(argMax).fixs(k,2),[0 255 0]);
               fprintf(', %i %i ',fixationsTracked(argMax).fixs(k,1),fixationsTracked(argMax).fixs(k,2));
            end
            fprintf('\n');
            imwrite(img,fullfile(imgFixs_dir,new_name));
            
            fixationsResult(nbImages).fixs=fixationsTracked(argMax).fixs;
            fixationsResult(nbImages).name=new_name;
        end;
    end
else %extract all images in fixations duration
    n=0;
    for i=1:size(fixations,1)
        for k=fixations(i,5):fixations(i,6)
            if fixs(k,1)<=0 || fixs(k,2)<=0 || fixs(k,2)>logs.siz_Outimg(1) || fixs(k,1)>logs.siz_Outimg(2)
                continue
            end;
            n=n+1;
            input_name=fullfile(input_dir,filenames(k).name);
            output_name=fullfile(output_dir, sprintf('%010i.jpg',k));
            names(n,:)=filenames(k).name;
            names2(n,:)=filenames(k+1).name;
            fixationsResult(n).fixs=round([fixs(k,1) fixs(k,2)]);
            fixationsResult(n).name=sprintf('%010i.jpg',k);
            copyfile(input_name,output_name);
        end
    end
end
names=char(names);
names2=char(names2);
save([output_dir '/save.mat'],'names','names2','fixationsResult');
end

%% SharpnessScore of an img, based on the mean and standard deviation of
%% gradient
function result = sharpnessScore(img)
    tmp=im2double(rgb2gray(img));
    Gx=imfilter(imfilter(tmp,[-1 0 1]),[1;2;1]);
    Gy=imfilter(imfilter(tmp,[1 2 1]),[1;0;-1]);
    gradient=sqrt(Gx.^2+Gy.^2);
    result=norm([mean(gradient(:)) std(gradient(:))]); 
end

%% Deprecated, used when the vertical sync of frames was far from perfect
function result = isVerticalSync(img)
tmp=im2double(img);
tmp=tmp(2:size(tmp,1),:)-tmp(1:size(tmp,1)-1,:);
tmp=tmp(2:size(tmp,1),:)-tmp(1:size(tmp,1)-1,:); % second degree derivative
result = max(sum(tmp,2)/size(tmp,2)) < 0.07; 
end

%% deprecated, old optical flow method
function result = dispersionWithFlowExtraction(fixs,flow_dir,timestamps,durationThreshold,dispersionThreshold)

if ~exist('durationThreshold', 'var') || isempty(durationThreshold)
    durationThreshold=0.2;
end

if ~exist('dispersionThreshold', 'var') || isempty(dispersionThreshold)
    dispersionThreshold=150;
end

N=size(fixs,1);
filenames=dir([flow_dir, '/capture_img_out_*.png']);
if length(filenames)~=N-1
    disp('All the flow calculation hasn''t been done...');
end;

if ~exist('timestamps', 'var') || isempty(timestamps)
    timestamps = 1/30*(1:N)';
end

flows=zeros(N,2);
for i=1:N-1
    flow=getFlow(fullfile(flow_dir,filenames(i).name));
    if fixs(i,1)<1 || fixs(i,2)<1 || fixs(i,2)>size(flow,1) || fixs(i,1)>size(flow,2)
       continue 
    end
    flows(i+1,:)=[ flow(round(fixs(i,2)),round(fixs(i,1)),1) , flow(round(fixs(i,2)),round(fixs(i,1)),2)];
end;
fixs(:,:)=fixs(:,:)-cumsum(flows,1);
x=fixs(:,1);
y=fixs(:,2);
[THR,SORH,KEEPAPP] = ddencmp('den','wv',x(1:400));
x= wdencmp('gbl',x,'db3',8,THR,SORH,KEEPAPP);
y= wdencmp('gbl',y,'db3',8,THR,SORH,KEEPAPP);
fixs=[x y];

result = dispersionExtraction(fixs,timestamps,durationThreshold,dispersionThreshold);
end

%% Keep relevant fixation points from raw data (dispersion based)
% fixs : array of [x y] for each image
% timestamps : vector of images' timestamps
% result : matrix of found fixation points
%       first column -> index of middle image
%       second column -> duration of fixation
%       third column -> index of first image in the fixation
%       fourth column -> index of last image in the fixation
function result = dispersionExtraction(fixs,timestamps,durationThreshold,dispersionThreshold)

if ~exist('durationThreshold', 'var') || isempty(durationThreshold)
    durationThreshold=0.2;
end

if ~exist('dispersionThreshold', 'var') || isempty(dispersionThreshold)
    dispersionThreshold=300;
end

N=size(fixs,1);

if ~exist('timestamps', 'var') || isempty(timestamps)
    timestamps = 1/30*(1:N)';
end

i=1;%origin of considered window
numberFixations=0;
result=[ ];

while i<=N
   d=0;%duration of window
   n=0;%# of points in window
   sumPt=[0 0];
   minPt=[1000000 1000000];
   maxPt=[-1000000 -1000000];
   j=i;
   while j<=N && d<=durationThreshold %initialisation on a minimal duration window
       d=timestamps(j)-timestamps(i);
       n=n+1;
       sumPt=sumPt+fixs(j,:);
       minPt=min(minPt,fixs(j,:));
       maxPt=max(maxPt,fixs(j,:));
       j=j+1;
   end
   if d<=durationThreshold % whitout it the last image would always be considered as a fixation point
       break
   end
   if sum(maxPt-minPt)<=dispersionThreshold && j-i>=2 %this is a fixation point
       while j<=N && sum(max(maxPt,fixs(j,:))-min(minPt,fixs(j,:)))<=dispersionThreshold %add point while the dispersion is not too big
           d=timestamps(j)-timestamps(i);
           n=n+1;
           sumPt=sumPt+fixs(j,:);
           minPt=min(minPt,fixs(j,:));
           maxPt=max(maxPt,fixs(j,:));
           j=j+1;
       end
       numberFixations=numberFixations+1;
       result(numberFixations,:)=[round(i+n/2) d i j-1];
       i=j;
   else
       i=i+1;
   end
end

fprintf('%i fixations points found \n',numberFixations);
end

%% Keep relevant fixation points from raw data (HMM based)
% fixs : array of [x y] for each image
% timestamps : vector of images' timestamps
% result : matrix of found fixation points
%       first column -> index of middle image
%       second column -> duration of fixation
%       third column -> index of first image in the fixation
%       fourth column -> index of last image in the fixation
function result = HMMSimpleExtraction(fixs,timestamps)
addpath(genpath('../HMMall/'));
N=size(fixs,1);

velocities=fixs(2:N,:)-fixs(1:N-1,:);
velocities=sum(velocities.^2,2).^0.5; % norm-2 of the velocities
velocities=velocities';

if ~exist('timestamps', 'var') || isempty(timestamps)
    timestamps = 1/30*(1:N)';
end

result= HMMExtraction(fixs,velocities,timestamps);
end

%% deprecated (old optical flow method)
function result = HMMWithFlowExtraction(fixs,flow_dir,timestamps)
addpath(genpath('../HMMall/'));
N=size(fixs,1);
filenames=dir([flow_dir, '/capture_img_out_*.png']);

% velocities=fixs(2:N,:)-fixs(1:N-1,:);
% if length(filenames)~=N-1
%     disp('All the flow calculation hasn''t been done...');
% end;
% for i=1:N-1
%     flow=getFlow(fullfile(flow_dir,filenames(i).name));
%     if fixs(i,1)<1 || fixs(i,2)<1 || fixs(i,2)>size(flow,1) || fixs(i,1)>size(flow,2)
%        continue 
%     end
%     f=[ flow(round(fixs(i,2)),round(fixs(i,1)),1) , flow(round(fixs(i,2)),round(fixs(i,1)),2)];
% %     disp(velocities(i,:));
% %     disp(f);
% %     disp('_______________');
%     velocities(i,:)=velocities(i,:)+f;
% end
% velocities=sum(velocities.^2,2).^0.5; % norm-2 of the velocities
% velocities=velocities';

flows=zeros(N,2);
for i=1:N-1
    flow=getFlow(fullfile(flow_dir,filenames(i).name));
    if fixs(i,1)<1 || fixs(i,2)<1 || fixs(i,2)>size(flow,1) || fixs(i,1)>size(flow,2)
       continue 
    end
    flows(i+1,:)=[ flow(round(fixs(i,2)),round(fixs(i,1)),1) , flow(round(fixs(i,2)),round(fixs(i,1)),2)];
end;
fixs(:,:)=fixs(:,:)-cumsum(flows,1);
x=fixs(:,1);
y=fixs(:,2);
[THR,SORH,KEEPAPP] = ddencmp('den','wv',x(1:400));
x= wdencmp('gbl',x,'db3',8,THR,SORH,KEEPAPP);
y= wdencmp('gbl',y,'db3',8,THR,SORH,KEEPAPP);
fixs=[x y];

velocities=fixs(2:N,:)-fixs(1:N-1,:);
velocities=sum(velocities.^2,2).^0.5; % norm-2 of the velocities
velocities=velocities';

if ~exist('timestamps', 'var') || isempty(timestamps)
    timestamps = 1/30*(1:N)';
end

result= HMMExtraction(fixs,velocities,timestamps);
end

function flow = getFlow(filename)
    flow=(double(imread(filename))/255-0.5)*40;
end

%% Extraction based on Viterbi algorithm on Hidden Markov Models
function result = HMMExtraction(fixs,velocities,timestamps)
addpath(genpath('../HMMall/'));
N=size(velocities,1);

if ~exist('timestamps', 'var') || isempty(timestamps)
    timestamps = 1/30*(1:N)';
end

m=[20 100];
m=reshape(m, [1 2 1]);
sigma=[50;5000];
sigma=reshape(sigma, [1 1 2 1]);
transmat=[0.95 0.05 ; 0.05 0.95];
prior=[0.5 ; 0.5];

[LL, prior, transmat, m, sigma, ] = mhmm_em(velocities, prior, transmat, m, sigma, [] , 'max_iter', 5);

B= mixgauss_prob(velocities,m,sigma);
path=viterbi_path(prior, transmat, B);
disp(path');
sigma
m
transmat
i=1;
numberFixations=0;
while i<=size(path,2)
	if path(i)==1
		j=i;
        while j<=size(path,2) && path(j)==1
			j=j+1;
        end
        d=timestamps(j-1)-timestamps(i);
        if d>=0.1 && j-i>=2
            numberFixations=numberFixations+1;
            result(numberFixations,:)=[round((i+j-1)/2) sum(fixs(i:j-1,:),1)/(j-i) d i j-1];
        end
        i=j;
	else
		i=i+1;	
	end
end
fprintf('%i fixations points found \n',numberFixations);
end
