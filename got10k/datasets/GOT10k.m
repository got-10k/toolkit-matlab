classdef GOT10k
    
    properties
        root_dir
        subset
        seq_names
        seq_dirs
        anno_files
    end

    methods

        function obj = GOT10k(root_dir, subset)
            if nargin < 2
                subset = 'val';
            end
            assert(any(strcmp(subset, {'train', 'val', 'test'})));
            
            obj.check_integrity(root_dir, subset);
            obj.root_dir = root_dir;
            obj.subset = subset;

            list = fileread(fullfile(root_dir, subset, 'list.txt'));
            obj.seq_names = strsplit(strip(list), '\n');
            obj.seq_dirs = fullfile(root_dir, subset, obj.seq_names);
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
                    if numel(anno) == 4
                        anno = reshape(anno, 1, 4);
                    end
                    varargout{1} = img_files;
                    varargout{2} = anno;
            end
        end

        function seq_num = length(obj)
            seq_num = length(obj.seq_names);
        end

        function check_integrity(obj, root_dir, subset)
            assert(any(strcmp(subset, {'train', 'val', 'test'})));
            list_file = fullfile(root_dir, subset, 'list.txt');

            if exist(list_file, 'file')
                list = fileread(list_file);
                seq_names = strsplit(strip(list), '\n');

                % check each sequence folder
                for s = 1:length(seq_names)
                    seq_dir = fullfile(root_dir, subset, seq_names{s});
                    if ~exist(seq_dir, 'dir')
                        warning('Warning: sequence %s not exist.', seq_names{s});
                    end
                end
            else
                % dataset not exist
                error('Dataset not found or corrupted.');
            end
        end

    end

end
