classdef OTB

    properties
        otb13_seqs
        otb15_seqs
        tb50_seqs
        tb100_seqs
        root_dir
        version
        seq_names
        seq_dirs
        anno_files
    end
    
    methods

        function obj = OTB(root_dir, version, download)
            obj.otb13_seqs = {...
                'Basketball', 'Bolt', 'Boy', 'Car4', 'CarDark',...
                'CarScale', 'Coke', 'Couple', 'Crossing', 'David',...
                'David2', 'David3', 'Deer', 'Dog1', 'Doll', 'Dudek',...
                'FaceOcc1', 'FaceOcc2', 'Fish', 'FleetFace',...
                'Football', 'Football1', 'Freeman1', 'Freeman3',...
                'Freeman4', 'Girl', 'Ironman', 'Jogging', 'Jumping',...
                'Lemming', 'Liquor', 'Matrix', 'Mhyang', 'MotorRolling',...
                'MountainBike', 'Shaking', 'Singer1', 'Singer2',...
                'Skating1', 'Skiing', 'Soccer', 'Subway', 'Suv',...
                'Sylvester', 'Tiger1', 'Tiger2', 'Trellis', 'Walking',...
                'Walking2', 'Woman'};
            obj.tb50_seqs = {...
                'Basketball', 'Biker', 'Bird1', 'BlurBody', 'BlurCar2',...
                'BlurFace', 'BlurOwl', 'Bolt', 'Box', 'Car1', 'Car4',...
                'CarDark', 'CarScale', 'ClifBar', 'Couple', 'Crowds',...
                'David', 'Deer', 'Diving', 'DragonBaby', 'Dudek',...
                'Football', 'Freeman4', 'Girl', 'Human3', 'Human4',...
                'Human6', 'Human9', 'Ironman', 'Jump', 'Jumping',...
                'Liquor', 'Matrix', 'MotorRolling', 'Panda', 'RedTeam',...
                'Shaking', 'Singer2', 'Skating1', 'Skating2', 'Skiing',...
                'Soccer', 'Surfer', 'Sylvester', 'Tiger2', 'Trellis',...
                'Walking', 'Walking2', 'Woman'};
            obj.tb100_seqs = {...
                'Bird2', 'BlurCar1', 'BlurCar3', 'BlurCar4', 'Board',...
                'Bolt2', 'Boy', 'Car2', 'Car24', 'Coke', 'Coupon',...
                'Crossing', 'Dancer', 'Dancer2', 'David2', 'David3',...
                'Dog', 'Dog1', 'Doll', 'FaceOcc1', 'FaceOcc2', 'Fish',...
                'FleetFace', 'Football1', 'Freeman1', 'Freeman3',...
                'Girl2', 'Gym', 'Human2', 'Human5', 'Human7', 'Human8',...
                'Jogging', 'KiteSurf', 'Lemming', 'Man', 'Mhyang',...
                'MountainBike', 'Rubik', 'Singer1', 'Skater',...
                'Skater2', 'Subway', 'Suv', 'Tiger1', 'Toy', 'Trans',...
                'Twinnings', 'Vase'};
            obj.tb100_seqs = [obj.tb50_seqs, obj.tb100_seqs];
            obj.otb15_seqs = obj.tb100_seqs;

            if nargin < 2
                % version has to be one of 2013, 2015,
                % 'otb2013', 'otb2015', 'tb50' and 'tb100'
                version = 2015;
            end
            if nargin < 3
                download = true;
            end
            
            obj.root_dir = root_dir;
            obj.version = version;
            if download
                obj.download(root_dir, version);
            end
            obj.check_integrity(root_dir, version);

            valid_seqs = obj.get_seqs(version);
            obj.anno_files = {};
            for s = 1:length(valid_seqs)
                files = dir(fullfile(root_dir, valid_seqs{s}, 'groundtruth_rect*.txt'));
                obj.anno_files = [obj.anno_files fullfile({files.folder}, {files.name})];
            end
            % remove empty annotation files
            % (e.g., groundtruth_rect.1.txt of Human4)
            obj.anno_files = obj.filter_files(obj.anno_files);
            obj.seq_dirs = {};
            obj.seq_names = {};
            for f = 1:length(obj.anno_files)
                obj.seq_dirs{f} = fileparts(obj.anno_files{f});
                [~, obj.seq_names{f}, ~] = fileparts(obj.seq_dirs{f});
            end
            % rename repeated sequence names
            % (e.g., Jogging and Skating2)
            obj.seq_names = obj.rename_seqs(obj.seq_names);
        end

        function varargout = subsref(obj, s)
            switch s(1).type
                case '.'
                    varargout{1} = builtin('subsref', obj, s);
                case {'()', '{}'}
                    s.type = '{}';
                    seq_dir = builtin('subsref', obj.seq_dirs, s);
                    img_files = dir(fullfile(seq_dir, 'img/*.jpg'));
                    img_files = sort(fullfile(...
                        {img_files.folder}, {img_files.name}));

                    % special sequences
                    % (visit http://cvlab.hanyang.ac.kr/tracker_benchmark/index.html for detail)
                    [~, seq_name, ~] = fileparts(seq_dir);
                    if strcmpi(seq_name, 'david')
                        img_files = img_files(300:770);
                    elseif strcmpi(seq_name, 'football1')
                        img_files = img_files(1:74);
                    elseif strcmpi(seq_name, 'freeman3')
                        img_files = img_files(1:460);
                    elseif strcmpi(seq_name, 'freeman4')
                        img_files = img_files(1:283);
                    elseif strcmpi(seq_name, 'diving')
                        img_files = img_files(1:215);
                    end

                    anno_file = builtin('subsref', obj.anno_files, s);
                    anno = dlmread(anno_file);
                    assert(length(img_files) == size(anno, 1));
                    varargout{1} = img_files;
                    varargout{2} = anno;
            end
        end

        function seq_num = length(obj)
            seq_num = length(obj.seq_names);
        end

        function seq_names = get_seqs(obj, version)
            if isnumeric(version)
                assert(any(version == [2013, 2015]));
                if version == 2013
                    seq_names = obj.otb13_seqs;
                elseif version == 2015
                    seq_names = obj.otb15_seqs;
                end
            elseif isstr(version)
                assert(any(strcmp(version, {'otb2013', 'otb2015', 'tb50', 'tb100'})));
                if strcmp(version, 'otb2013')
                    seq_names = obj.otb13_seqs;
                elseif strcmp(version, 'otb2015')
                    seq_names = obj.otb15_seqs;
                elseif strcmp(version, 'tb50')
                    seq_names = obj.tb50_seqs;
                elseif strcmp(version, 'tb100')
                    seq_names = obj.tb100_seqs;
                end
            end
        end

        function filtered_files = filter_files(obj, filenames)
            filtered_files = {};
            for f = 1:length(filenames)
                content = fileread(filenames{f});
                content = strip(content);
                if strcmp(content, '')
                    fprintf('warning: %s is empty\n', filenames{f});
                else
                    filtered_files = [filtered_files filenames{f}];
                end
            end
        end

        function renamed_seqs = rename_seqs(obj, seq_names)
            % in case some sequences may have multiple targets
            renamed_seqs = {};
            for s = 1:length(seq_names)
                if sum(strcmp(seq_names{s}, seq_names)) == 1
                    renamed_seqs = [renamed_seqs seq_names{s}];
                else
                    ind = sum(strcmp(seq_names{s}, seq_names(1:s)));
                    renamed_seqs = [renamed_seqs sprintf('%s.%d', seq_names{s}, ind)];
                end
            end
        end

        function root_dir = download(obj, root_dir, version)
            seq_names = obj.get_seqs(version);

            if ~exist(root_dir, 'dir')
                mkdir(root_dir);
            else
                downloaded = true;
                for s = 1:length(seq_names)
                    if ~exist(fullfile(root_dir, seq_names{s}), 'dir')
                        downloaded = false;
                        break;
                    end
                end
                if downloaded
                    disp('Files already downloaded.');
                    return;
                end
            end

            url_fmt = 'http://cvlab.hanyang.ac.kr/tracker_benchmark/seq/%s.zip';
            for s = 1:length(seq_names)
                seq_dir = fullfile(root_dir, seq_names{s});
                if exist(seq_dir, 'dir')
                    continue;
                end
                url = sprintf(url_fmt, seq_names{s});
                zip_file = fullfile(root_dir, [seq_names{s} '.zip']);
                fprintf('Downloading to %s...\n', zip_file);
                urlwrite(url, zip_file);
                fprintf('Extracting to %s...\n', root_dir);
                unzip(zip_file, root_dir);
            end
        end

        function check_integrity(obj, root_dir, version)
            seq_names = obj.get_seqs(version);

            if exist(root_dir, 'dir')
                % check each sequence folder
                for s = 1:length(seq_names)
                    seq_dir = fullfile(root_dir, seq_names{s});
                    if ~exist(seq_dir, 'dir')
                        fprintf('Warning: sequence %s not exist.', seq_names{s});
                    end
                end
            else
                % dataset not exist
                error(['Dataset not found or corrupted. '...
                       'You can set download to true to download it.']);
            end
        end

    end

end
