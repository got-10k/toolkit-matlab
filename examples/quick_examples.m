setup_got10k;

tracker_fn = @identity_tracker;

experiment = ExperimentGOT10k('data/GOT-10k', 'test');
experiment.run('IdentityTracker', tracker_fn, false);
experiment.report({'IdentityTracker'});
