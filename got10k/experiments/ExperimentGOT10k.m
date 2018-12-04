classdef ExperimentGOT10k
    
    properties
        dataset
        result_dir
        report_dir
        nbins_iou
        repetitions
    end

    methods

        function obj = ExperimentGOT10k(root_dir, subset, result_dir, report_dir)
            if nargin < 2
                subset = 'val';
            end
            assert(any(strcmp(subset, {'val', 'test'})));
            if nargin < 3
                result_dir = 'results';
            end
            if nargin < 4
                report_dir = 'reports';
            end
            obj.dataset = GOT10k(root_dir, subset);
            obj.result_dir = fullfile(result_dir, 'GOT-10k');
            obj.report_dir = fullfile(report_dir, 'GOT-10k');
            obj.repetitions = 1;
            obj.nbins_iou = 101;
        end

        function run(obj, tracker_name, tracker_fn, visualize)
            fprintf('Running tracker %s on GOT-10k...\n', tracker_name);

            % loop over the complete dataset
            for s = 1:length(obj.dataset)
                seq_name = obj.dataset.seq_names{s};
                fprintf('--Sequence %d/%d: %s\n', s, length(obj.dataset), seq_name);

                [img_files, anno] = obj.dataset(s);

                % run multiple repetitions for each sequence
                for r = 1:obj.repetitions
                    fprintf(' Repetition %d/%d\n', r, obj.repetitions);

                    % paths of records
                    record_dir = fullfile(obj.result_dir, tracker_name, seq_name);
                    record_file = fullfile(record_dir, sprintf('%s_%03d.txt', seq_name, r));
                    time_file = fullfile(record_dir, sprintf('%s_time.txt', seq_name));

                    % skip if found results
                    if exist(record_file, 'file')
                        content = strip(fileread(record_file));
                        if ~strcmp(content, '')
                            fprintf('  Found results, skipping repetition %d\n', r);
                            continue;
                        end
                    end
                    
                    % skip repetitions if detected a deterministic tracker
                    if r == 3 + 1 && obj.check_deterministic(record_dir)
                        disp(['  Detected a deterministic tracker, ',...
                              'skipping remaining trials.']);
                        break;
                    end

                    % tracking loop
                    [boxes, times] = tracker_fn(img_files, anno(1, :), visualize);
                    if visualize; close all; end
                    assert(length(boxes) == length(img_files));

                    % record boxes
                    fprintf('  Recording results at %s\n', record_dir);
                    if ~exist(record_dir, 'dir')
                        mkdir(record_dir);
                    end
                    dlmwrite(record_file, boxes, 'delimiter', ',', 'precision', '%.3f');

                    % record times
                    if r == 1 || ~exist(time_file, 'file')
                        times_all = zeros(length(img_files), obj.repetitions);
                    else
                        times_all = dlmread(time_file);
                        assert(all(size(times_all, 2) == obj.repetitions));
                    end
                    times_all(:, r) = times;
                    dlmwrite(time_file, times_all, 'delimiter', ',', 'precision', '%.8f');
                end
            end
        end

        function report(obj, tracker_names)
            cwd = pwd;

            for i = 1:length(tracker_names)
                result_dir = fullfile(obj.result_dir, tracker_names{i});
                cd(result_dir);
                save_file = sprintf('../%s.zip', tracker_names{i});
                zip(save_file, '.');
            end
        end

        function is_deterministic = check_deterministic(obj, record_dir)
            record_files = dir(fullfile(record_dir, '*_*.txt'));
            record_files = fullfile({record_files.folder}, {record_files.name});
            record_files = record_files(cell2mat(cellfun(@(s) ~strcmp(s(end-7:end-4),...
                'time'), record_files, 'UniformOutput', false)));
            if length(record_files) < 3
                is_deterministic = false;
                return;
            end

            records = {};
            for f = 1:length(record_files)
                records = [records; fileread(record_files{f})];
            end
            is_deterministic = isequal(records{:});
        end

    end

end
