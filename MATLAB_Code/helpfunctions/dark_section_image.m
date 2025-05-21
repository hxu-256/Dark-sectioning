function result_final = dark_section_image(image0, wavelength_nm, pixelsize_um, NA, factor, thres)
    % Rescale
    pixelsize_nm = pixelsize_um * 1000;
    image0 = double(image0);
    image0 = 255 * 255*(image0 - min(min(image0)))./(max(max(image0))-min(min(image0)));
    [Nx0,Ny0,~] = size(image0);
    [Nx,Ny,~] = size(image0);
    if Ny>Nx
        image0(Nx+1:Ny,:,:)=0;
    elseif Ny<Nx
        image0(:,Ny+1:Nx,:)=0;
    end
    [Nx,Ny,Nz] = size(image0);

    % Dark sectioning parameters
    pad_size = 15;
    pad = 1;
    %thres_ = 60;
    divide = 0.5;
    background = 0;
    denoise = 0;

    % Image padding
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

    % Params
    [params.Nx,params.Ny,~] = size(image);
    params.NA = NA;
    params.emwavelength = wavelength_nm;
    params.pixelsize = pixelsize_nm;
    params.factor = factor;
    % background setting
    if background == 1
        maxtime = 2;
        deg_matrix = [6,3,1.2];   % 3-10
        dep_matrix = [3,3,2];   % 0.7-2
        hl_matrix = [1,1,1];    % 3-8
    elseif background == 0
        maxtime=1;
        deg_matrix = [6];   % 3-10
        dep_matrix = [3];   % 0.7-2
        hl_matrix = [1];    % 3-8
    end

    for time = 1:maxtime
        parfor jz = 1:Nz
            %fprintf('Dark sectioning %d/%d\n',jz,Nz);
            deg = deg_matrix(time);   % 3-10
            dep = dep_matrix(time);   % 0.7-2
            hl = hl_matrix(maxtime);    % 3-8
            % Seperate spectrum and confirm block size
            [Hi,Lo,lp,EL] = separateHiLo(squeeze(image(:,:,jz)),params,deg,divide);
            block_size = confirm_block(params,lp);
            % Remove background for low-frequency part
            Lo_process = dehaze_fast2(Lo, 0.95, block_size, EL,dep,thres);
            result = Lo_process/hl + Hi;
            % Cutting edge
            Lo_process = Lo_process(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
            Lo = Lo(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
            Hi = Hi(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
            result = result(floor(Nx/pad_size)+2:floor(Nx/pad_size)+Nx+1,floor(Ny/pad_size)+2:floor(Ny/pad_size)+Ny+1);
            % Saving results
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
    % denoise
    result_final = zeros(Nx,Ny,Nz);
    for jz = 1:Nz
        %fprintf('denoising %d/%d\n',jz,Nz);
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
    % select region of interest
    if Nx0~=Nx || Ny0~=Ny
        if Nx>Nx0
            result_final(Nx0+1:Nx,:,:)=[];
        end
        if Ny0>Ny
            result_final(:,Ny0+1:Ny,:)=[];
        end
    end

    maxnum = max(max(max(result_final)));
    result_final = uint16(65535*result_final./maxnum);

end
