namespace :cron do

	desc "Syncing everything from API to DB"
	task :sync_all => :environment do
		Tag.sync_from_stackshare_api
		Layer.sync_from_stackshare_api
		Tool.sync_from_stackshare_api
		# We're not syncing stacks here, because there are close to 2000 right now,
		# and we'd hit quota in one go soon as StackShare grows. Therefore, it is
		# synced on the fly as pages get requested.
	end

end
