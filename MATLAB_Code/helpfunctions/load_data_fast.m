function [channel_images, ome_meta, channel_names] = load_data_fast(nd2_path)
    % Fast ND2 loader using Memoizer to speed up subsequent reads
    import loci.formats.Memoizer
    import loci.formats.ImageReader
    import loci.formats.MetadataTools

    % Initialize Bio-Formats
    bfInitLogging('OFF');
    reader = Memoizer(ImageReader(), 0);  % Enable caching
    reader.setId(nd2_path);

    % Metadata
    ome_meta = reader.getMetadataStore();  % Fixed here
    num_channels = ome_meta.getChannelCount(0);
    num_z = reader.getSizeZ();
    reader.setSeries(0);  % If multiple series

    % Image size
    Nx = reader.getSizeX();
    Ny = reader.getSizeY();

    % Load each channel's Z-stack
    channel_images = cell(num_channels, 1);
    for c = 1:num_channels
        stack = zeros(Ny, Nx, num_z, 'like', bfGetPlane(reader, 1));
        for z = 1:num_z
            index = reader.getIndex(z - 1, c - 1, 0);  % Z, C, T
            stack(:,:,z) = bfGetPlane(reader, index + 1);  % MATLAB is 1-based
        end
        channel_images{c} = stack;
    end

    % Channel names
    channel_names = cell(num_channels, 1);
    for c = 1:num_channels
        try
            channel_names{c} = char(ome_meta.getChannelName(0, c-1));
        catch
            channel_names{c} = sprintf('Channel %d', c);
        end
    end

    reader.close();
end
