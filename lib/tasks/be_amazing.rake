namespace :bam do

  desc "Counts real published items for each user"
  task :count_published_items => :environment do
    TaskUtils.update_individual_counters
    TaskUtils.update_subcategories_counters
  end

  desc "Generates cat/subcat autocomplete JS files (in production, run also: rake asset:packager:build_all)"
  task :generate_autocomplete_js => :environment do
    TaskUtils.generate_autocomplete
  end
    
  desc "Import existing users"
  task :import_users => :environment do
			ImportUtils.import_users
			TaskUtils.count_users
			TaskUtils.update_counters
	end
	
  desc "Loads roles, districts, modalities, etc. in the current database"
  task :load => :environment do
      puts "Importing charities"
      ImportUtils.import_charities
      puts "Importing roles"
			ImportUtils.import_roles
      puts "Importing districts"
			ImportUtils.import_districts
      puts "Importing counters"
			ImportUtils.import_counters
      puts "Importing categories"
			ImportUtils.import_categories
      puts "Importing subcategories"
			ImportUtils.import_subcategories
      puts "Creating default admins"
      TaskUtils.create_default_admins
      puts "Counting users"
			TaskUtils.count_users
      puts "Updating counters"
			TaskUtils.update_counters
  end

  desc "Loads all users and districts in the current database"
  task :load_demo_data => :environment do
			ImportUtils.import_districts
			ImportUtils.import_users
      TaskUtils.create_default_admins
			TaskUtils.count_users
  end

	desc "Recreates the database and reloads all users and districts (can only be used in dev, as it sends email to new users)"
	task :reload => :environment do
		if ENV["RAILS_ENV"].blank? || ENV["RAILS_ENV"] == "development"
			Rake::Task["db:drop"].invoke
			Rake::Task["db:create"].invoke
			Rake::Task["db:migrate"].invoke
			Rake::Task["bam:load"].invoke
		else
      if ENV["RAILS_ENV"] == "test"
        Rake::Task["db:drop"].invoke
        Rake::Task["db:create"].invoke
        Rake::Task["db:migrate"].invoke
      else
        puts "Sorry, you can not use this in #{ENV["RAILS_ENV"]}, only in development"
      end
		end
	end
end
