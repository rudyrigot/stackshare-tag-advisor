namespace :cron do

	desc "Syncing everything from API to DB"
	task :sync_all => :environment do
		StackShareService.new.sync_all_tags!
		StackShareService.new.sync_all_layers!
		StackShareService.new.sync_all_tools!
		# We're not syncing stacks here, because there are close to 2000 right now,
		# and we'd hit quota in one go soon as StackShare grows. Therefore, it is
		# synced on the fly as pages get requested.
	end

end
