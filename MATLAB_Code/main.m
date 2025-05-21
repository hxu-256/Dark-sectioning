
%  load data
clear; close all; clc;
addpath("./bfmatlab");
addpath("./helpfunctions");
data_folder = fullfile(getenv('HOME'), 'scratch/IHC/raw');      %you may change this
data_files = dir(fullfile(data_folder, '*.nd2'));
for k = 1:length(data_files)
    data_path = fullfile(data_folder, data_files(k).name);
    fprintf('Processing file: %s\n', data_path);
    [channel_images, ome_meta, channel_names] = load_data(data_path);

    % dark sec
    num_channels = ome_meta.getChannelCount(0);
    processed = cell(num_channels, 1);
    thres_mat = [60,60,60,60];
    for c = 1:num_channels
        fprintf('Processing channel %d: %s\n', c, channel_names{c});
        factor = 2;
        thres = thres_mat(c);
        NA = 1.45;
        tic;
        processed{c} = dark_section_image(channel_images{c}, ...
            ome_meta.getChannelEmissionWavelength(0, c-1).value().doubleValue(), ...
            ome_meta.getPixelsPhysicalSizeX(0).value().doubleValue(),...
            NA, factor, thres);
        toc;
    end
    % stack data to 4d
    [Ny, Nx, Nz] = size(processed{1});
    output = zeros(Ny, Nx, Nz, num_channels, 1,'uint16');  % Last dim is Time = 1
    
    for c = 1:num_channels
        if isempty(processed{c})
            continue;
        end
        output(:,:,:,c,1) = processed{c};   % saved in x
    end
    % Save to OME-TIFF with metadata
    if num_channels == 1   %boundary condition
        output_permute = output;
    else
        output_permute = permute(output,[1,2,4,3,5]);    %need to permute to xyczt
    end
    outname = fullfile(data_folder, [data_files(k).name(1:end-4), '_processed.ome.tif']);
    if exist(outname, 'file')
        delete(outname);
    end
    bfsave(output_permute, outname, 'metadata', ome_meta);
end

