namespace :cron do

	desc "Syncing all tags from API and DB"
	task :sync_all_tags => :environment do
		StackShareService.new.sync_all_tags!
	end

end
