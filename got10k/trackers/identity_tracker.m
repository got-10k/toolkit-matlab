function [boxes, times] = identity_tracker(img_files, box, visualize)
    n = length(img_files);
    boxes = repmat(box, [n, 1]);
    times = rand(n, 1);
end
