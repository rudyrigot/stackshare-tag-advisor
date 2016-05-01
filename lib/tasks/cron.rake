namespace :cron do

	desc "Syncing everything from API to DB"
	task :sync_all => :environment do
		StackShareService.new.sync_all_tags!
		StackShareService.new.sync_all_layers!
		StackShareService.new.sync_all_tools!
	end

end
