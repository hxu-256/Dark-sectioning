%% Define parameters
UM_TO_NM = 1000;
%% load nd2 data
addpath("./bfmatlab");
data_folder = fullfile(getenv('HOME'), 'scratch/IHC/raw');
nd2_files = dir(fullfile(data_folder, '*.nd2'));

for k = 1:length(nd2_files)
    nd2_path = fullfile(data_folder,nd2_files(k).name);
    fprintf('loading file:%s\n',nd2_path);
    data = bfopen(nd2_path);
end

%% disect each channel
img_cells = data{1,1};  % All planes
ome_meta = data{1,4};
num_planes = size(img_cells, 1);

num_channels = ome_meta.getChannelCount(0);
planes_per_channel = num_planes / num_channels;

channel_images = cell(num_channels, 1);
for c = 1:num_channels
    idx = c:num_channels:num_planes;
    planes = cellfun(@(x) x, img_cells(idx,1), 'UniformOutput', false);
    channel_images{c} = cat(3, planes{:});
end

%% Metadata
ome_meta = data{1,4};
% Get channel names
channel_names = cell(num_channels, 1);
for c = 1:num_channels
    try
        channel_names{c} = char(ome_meta.getChannelName(0, c-1));  % Series 0, Java index
    catch
        channel_names{c} = sprintf('Channel %d', c);
    end
end

% Pixel size (physical units, if available)
try
    px_size_x = ome_meta.getPixelsPhysicalSizeX(0).value().doubleValue();  % in µm
    px_size_y = ome_meta.getPixelsPhysicalSizeY(0).value().doubleValue();
    fprintf('Pixel size: %.3f µm (X) × %.3f µm (Y)\n', px_size_x, px_size_y);
catch
    fprintf('Pixel size not found in metadata.\n');
end

% Print channel names
fprintf('Detected %d channel(s):\n', num_channels);
for c = 1:num_channels
    fprintf('  Channel %d: %s\n', c, channel_names{c});
end
