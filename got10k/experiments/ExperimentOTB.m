classdef ExperimentOTB
    
    properties
        
    end

    methods

        function obj = ExperimentOTB(root_dir, version, result_dir, report_dir)
            if nargin < 2
                version = 2015;
            end
            if nargin < 3
                result_dir = 'results';
            end
            if nargin < 4
                report_dir = 'reports';
            end

            obj.dataset = OTB(root_dir, version, true);
            obj.result_dir = fullfile(result_dir, ['OTB-' num2str(version)]);
            obj.report_dir = fullfile(report_dir, ['OTB-' num2str(version)]);
            % as nbins_iou increases, the success score
            % converges to average overlap (AO)
            obj.nbins_iou = 101;
            obj.nbins_ce = 51;
        end

        function obj = run(obj, tracker_fn, visualize)
            if nargin < 3
                visualize = false;
            end
            fprintf('Running tracker %s on OTB...\n', tracker_fn);

            % loop over the complete dataset
            for s = 1:length(obj.dataset)
                seq_name = obj.dataset.seq_names{s};
                fprintf('--Sequence %d/%d: %s\n', s, length(obj.dataset), seq_name);

                % tracking loop
                [img_files, anno] = dataset(s);
                [rects, speed_fps] = tracker_fn(img_files, anno(1, :), visualize);
                assert(size(rects, 1) == size(anno, 1));

                % record results
                obj.record(tracker_fn, seq_name, rects, speed_fps);
            end
        end

        function obj = record(obj, tracker_name, seq_name, rects, speed_fps)
        end

    end

end
