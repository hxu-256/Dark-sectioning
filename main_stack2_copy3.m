%% The main program of Dark section
% https://github.com/sjtrny/Dark-Channel-Haze-Removal
% This program is finished by Caoruijie and professor Xipeng in Peking 
% University. 
%
% For referrence:
% Single Image Haze Removal Using Dark Channel Prior
% Kaiming He, Jian Sun and Xiaoou Tang
% IEEE Transactions on Pattern Analysis and Machine Intelligence
% Volume 30, Number 12, Pages 2341-2353
%
% For any question, please contact: caoruijie@stu.pku.edu.cn or 
% xipeng@pku.edu.cn
%
% We claim a Apache liscence for Dark section.

clear; close all; clc;
tic;

%% 读入数据
image0 = double(imstackread('.\input\Caorj(1).tif'));
image0 = 255*(image0 - min(min(image0)))./(max(max(image0))-min(min(image0)));
[Nx0,Ny0,~] = size(image0);
[Nx,Ny,~] = size(image0);
if Ny>Nx
    image0(Nx+1:Ny,:,:)=0;
elseif Ny<Nx
    image0(:,Ny+1:Nx,:)=0;
end
[Nx,Ny,Nz] = size(image0);
pad = 1;        %1-sysemtic,0-pad0
denoise = 1;    % Guassion denoise
thres = 100;   % 之前都是20


%% 补充0
pad_size = 15;
result_stack = zeros(Nx,Ny,Nz);
Lo_process_stack = zeros(Nx,Ny,Nz);
Hi_stack = zeros(Nx,Ny,Nz);
for jz = 1:Nz
    if pad ==1
        image(:,:,jz) = padarray(image0(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1],'symmetric');
    else
        image(:,:,jz) = padarray(image0(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1]);
    end

end

%% 基本参数信息
[params.Nx,params.Ny,~] = size(image);
params.NA = 1.49;
params.emwavelength =525;
params.pixelsize = 65;
params.factor = 1;
background = 1; % 0-middle,1-severve

if background == 1
    maxtime = 2;
    deg_matrix = [6,3,1.2];   % 3-10
    dep_matrix = [3,2,2];   % 0.7-2
    hl_matrix = [1,1,1];    % 3-8
elseif background == 0
    maxtime=1;
    deg_matrix = [6];   % 3-10
    dep_matrix = [3];   % 0.7-2
    hl_matrix = [1];    % 3-8
end

for time = 1:maxtime
    for jz = 1:Nz
        deg = deg_matrix(maxtime);   % 3-10
        dep = dep_matrix(maxtime);   % 0.7-2
        hl = hl_matrix(maxtime);    % 3-8
        %% 保留高频，去除低频，提取极低频
        [Hi,Lo,lp,EL] = separateHiLo(squeeze(image(:,:,jz)),params,deg);
        block_size = confirm_block(params,lp);

        %% 对低频做暗通道先验去雾
        Lo_process = dehaze_fast2(Lo, 0.95, block_size, EL,dep,thres);

        result = Lo_process/hl + Hi;
        Lo_process = Lo_process(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
        Lo =                 Lo(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
        Hi =                 Hi(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
        result =         result(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);

        result_stack(:,:,jz) = result;
        Lo_process_stack(:,:,jz) = Lo_process;
        Hi_stack(:,:,jz) = Hi;
    end
    image0 = result_stack;
    for jz = 1:Nz
        if pad==1
            image(:,:,jz) = padarray(image0(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1],'symmetric');
        else
            image(:,:,jz) = padarray(image0(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1]);
        end
    end
end

result_final = zeros(Nx,Ny,Nz);
for jz = 1:Nz
    if pad ==1
        temp = padarray(result_stack(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1],'symmetric');
    else
        temp = padarray(result_stack(:,:,jz),[floor(Nx/pad_size)+1,floor(Ny/pad_size)+1]);
    end
    if denoise == 0
        temp1 = temp;
    else
        W = fspecial('gaussian',[2,2],1); 
        temp1 = imfilter(temp, W, 'replicate');
    end
    result_final(:,:,jz) = temp1(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
end

if Nx0~=Nx || Ny0~=Ny
    if Nx>Nx0
        image0(Nx0+1:Nx,:,:)=[];
    end
    if Ny0>Ny
        image0(:,Ny0+1:Ny,:)=[];
    end
end


maxnum = max(max(max(result_final)));
final_image = uint16(65535*result_final./maxnum);
stackfilename = ['.\output\Rongmeiti2.tif'];
for k = 1:Nz
    imwrite(final_image(:,:,k), stackfilename, 'WriteMode','append') % 写入stack图像
end

% maxnum = max(max(max(Lo_process_stack)));
% final_image = uint16(65535*Lo_process_stack./maxnum);
% stackfilename = ['.\output\Dark_meijunhi.tif'];
% for k = 1:Nz
%     imwrite(final_image(:,:,k), stackfilename, 'WriteMode','append') % 写入stack图像
% end
% 
% maxnum = max(max(max(Hi_stack)));
% final_image = uint16(65535*Hi_stack./maxnum);
% stackfilename = ['.\output\Dark_meijunlo.tif'];
% for k = 1:Nz
%     imwrite(final_image(:,:,k), stackfilename, 'WriteMode','append') % 写入stack图像
% end

toc
