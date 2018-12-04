classdef VOT

    properties
        root_dir
        version
        anno_type
        seq_names
        seq_dirs
        anno_files
    end
    
    methods

        function obj = VOT(root_dir, version, anno_type, download)
            if nargin < 2
                version = 2017;
            end
            if nargin < 3
                anno_type = 'rect';
            end
            if nargin < 4
                download = true;
            end
            assert(isnumeric(version) && any(version == 2013:2017));
            assert(any(strcmp(anno_type, {'rect', 'corner'})));

            obj.root_dir = root_dir;
            obj.version = version;
            obj.anno_type = anno_type;
            if download
                obj.download(root_dir, version);
            end
            obj.check_integrity(root_dir, version);

            list = fileread(fullfile(root_dir, 'list.txt'));
            obj.seq_names = strsplit(strip(list), '\n');
            obj.seq_dirs = fullfile(root_dir, obj.seq_names);
            obj.anno_files = fullfile(obj.seq_dirs, 'groundtruth.txt');
        end

        function varargout = subsref(obj, s)
            switch s(1).type
                case '.'
                    varargout{1} = builtin('subsref', obj, s);
                case {'()', '{}'}
                    s.type = '{}';
                    seq_dir = builtin('subsref', obj.seq_dirs, s);
                    img_files = dir(fullfile(seq_dir, '*.jpg'));
                    img_files = sort(fullfile(...
                        {img_files.folder}, {img_files.name}));
                    anno_file = builtin('subsref', obj.anno_files, s);
                    anno = dlmread(anno_file);
                    assert(length(img_files) == size(anno, 1));
                    assert(size(anno, 2) == 4 || size(anno, 2) == 8);
                    if strcmp(obj.anno_type, 'rect') && size(anno, 2) > 4
                        anno = obj.corner2rect(anno);
                    end
                    varargout{1} = img_files;
                    varargout{2} = anno;
            end
        end

        function seq_num = length(obj)
            seq_num = length(obj.seq_names);
        end

        function root_dir = download(obj, root_dir, version)
            assert(any(version == 2013:2017));

            if ~exist(root_dir, 'dir')
                mkdir(root_dir);
            elseif exist(fullfile(root_dir, 'list.txt'), 'file')
                list = fileread(fullfile(root_dir, 'list.txt'));
                seq_names = strsplit(strip(list), '\n');
                seq_dirs = fullfile(root_dir, seq_names);
                downloaded = true;
                for d = 1:length(seq_dirs)
                    if ~exist(seq_dirs{d}, 'dir')
                        downloaded = false;
                        break;
                    end
                end
                if downloaded
                    disp('Files already downloaded.')
                    return;
                end
            end

            version_str = sprintf('vot%d', version);
            url = sprintf('http://data.votchallenge.net/%s/%s.zip', version_str, version_str);
            zip_file = fullfile(root_dir, [version_str '.zip']);
            
            fprintf('Downloading to %s ...\n', zip_file);
            urlwrite(url, zip_file);
            
            fprintf('Extracting to %s...\n', root_dir);
            unzip(zip_file, root_dir);
        end

        function check_integrity(obj, root_dir, version)
            assert(any(version == 2013:2017))

            if exist(fullfile(root_dir, 'list.txt'))
                list = fileread(fullfile(root_dir, 'list.txt'));
                seq_names = strsplit(strip(list), '\n');

                % check each sequence folder
                for s = 1:length(seq_names)
                    seq_dir = fullfile(root_dir, seq_names{s});
                    if ~exist(seq_dir, 'dir')
                        fprintf('Warning: sequence %s not exist.\n', seq_names{s});
                    end
                end
            else
                % dataset not exist
                error(['Dataset not found or corrupted. '...
                       'You can set download to true to download it.']);
            end
        end

        function rects = corner2rect(obj, corners, center)
            if nargin < 3
                center = false;
            end
            cx = mean(corners(:, 1:2:end), 2);
            cy = mean(corners(:, 2:2:end), 2);

            x1 = min(corners(:, 1:2:end), [], 2);
            x2 = max(corners(:, 1:2:end), [], 2);
            y1 = min(corners(:, 2:2:end), [], 2);
            y2 = max(corners(:, 2:2:end), [], 2);

            area1 = vecnorm(corners(:, 1:2) - corners(:, 3:4), 2, 2) .* ...
                vecnorm(corners(:, 3:4) - corners(:, 5:6), 2, 2);
            area2 = (x2 - x1) .* (y2 - y1);
            scale = sqrt(area1 ./ area2);
            w = scale .* (x2 - x1) + 1;
            h = scale .* (y2 - y1) + 1;

            if center
                rects = [cx, cy, w, h];
            else
                rects = [cx - w / 2, cy - h / 2, w, h];
            end
        end

    end

end
