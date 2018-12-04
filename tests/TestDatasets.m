classdef TestDatasets < matlab.unittest.TestCase

    properties
        data_dir
    end

    methods (TestMethodSetup)
        function setup(obj)
            obj.data_dir = '../data';
        end
    end

    methods (TestMethodTeardown)
        function teardown(obj)
            return
        end
    end

    methods (Test)

        function test_got10k(obj)
            root_dir = fullfile(obj.data_dir, 'GOT-10k');
            % check validation subset
            dataset = GOT10k(root_dir, 'val');
            obj.check_dataset(dataset);
            % check training subset
            dataset = GOT10k(root_dir, 'train');
            obj.check_dataset(dataset);
            % check test subset
            dataset = GOT10k(root_dir, 'test');
            obj.assertGreaterThan(length(dataset), 0);
        end

        function test_otb(obj)
            root_dir = fullfile(obj.data_dir, 'OTB');
            dataset = OTB(root_dir, 2015, true);
            obj.check_dataset(dataset);
        end

        function test_vot(obj)
            root_dir = fullfile(obj.data_dir, 'vot2017');
            dataset = VOT(root_dir, 2017, 'rect', true);
            obj.check_dataset(dataset);
        end

    end

    methods

        function check_dataset(obj, dataset)
            n = length(dataset);
            obj.assertGreaterThan(n, 0);
            for i = 1:min(n, 100)
                [img_files, anno] = dataset(i);
                obj.assertEqual(length(img_files), length(anno));
            end
        end

    end
    
end
