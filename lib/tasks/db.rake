namespace :db do

  namespace :static do
    desc 'Dumps all static data tables to db/static.sql'
    task :dump => :environment do
      raise 'Can only run in development mode' unless Rails.env.development?
      cmd = "pg_dump #{connection_opts} --clean #{static_tables} > #{Rails.root}/db/static.sql"
      system cmd
    end

    desc 'restores static data tables on api-sandbox'
    task :static_data_restore do
      production_protected

      dump_file = args.file

      unless dump_file.present?
        puts 'Please provide the file to restore to the task. Ex: rake db:restore[20160719112847_dump.psql]'
        puts 'Note: if you are using zsh, scape the brackets. Ex: rake db:restore\[20160719112847_dump.psql\]'
        exit(1)
      end

      unless File.exists?(dump_file)
        puts 'File %s not found.' % dump_file
        exit(1)
      end

      sh (with_config do |_db_name, connection_opts|
        "PGPASSWORD=$DB_PASSWORD psql -q #{connection_opts} -f #{dump_file}"
      end)
    end
  end

  desc "Erase all tables"
  task :clear => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end
  end

  desc 'ADP task: clear the database, run migrations and seeds'
  task :reseed => [:clear, 'db:migrate', 'db:seed'] {}

  desc 'ADP task: clear the database, run migrations, seeds and reloads demo data'
  task :reload do
    Rake::Task['db:clear'].invoke
    Rake::Task['db:schema:load'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['claims:demo_data'].invoke
  end

  desc 'Dumps a backup of the database'
  task :dump => :environment do
    sh (with_config do |db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD pg_dump -v -O -x -w #{connection_opts} -f #{Time.now.strftime('%Y%m%d%H%M%S')}_#{db_name}.psql"
    end)
  end

  desc 'Dumps an anonymised (gzip) backup of the database'
  task :dump_anonymised, [:file] => :environment do |_task, args|
    excluded_tables = %w(providers defendants users messages documents) # make sure a db:dump task exists for each of these tables (i.e. db:dump:providers)

    exclusions = excluded_tables.map { |table| "--exclude-table-data #{table}" }.join(' ')
    filename = args.file || "#{Time.now.strftime('%Y%m%d%H%M%S')}_dump.psql"

    sh (with_config do |_db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD pg_dump -O -x -w #{exclusions} #{connection_opts} -f #{filename}"
    end)

    # The following will export the previously excluded tables data, in an anonymised way
    excluded_tables.each do |table|
      task_name = "db:dump:#{table}"
      puts "Executing task #{task_name}"

      Rake::Task[task_name].invoke(filename)
    end

    compress_file(filename)
  end

  desc 'Anonymise current database data (in-place, no dump)'
  task :anonymise => :environment do
    production_protected

    translation = [('a'..'z'), ('A'..'Z')].map(&:to_a).map(&:shuffle).join

    sh (with_config do |_db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD psql -v translation=\\'#{translation}\\' #{connection_opts} -f #{Rails.root}/db/data/anonymise_db.sql"
    end)
  end

  desc 'Restores the database from a backup'
  task :restore, [:file] => :environment do |_task, args|
    production_protected

    dump_file = args.file

    unless dump_file.present?
      puts 'Please provide the file to restore to the task. Ex: rake db:restore[20160719112847_dump.psql]'
      puts 'Note: if you are using zsh, scape the brackets. Ex: rake db:restore\[20160719112847_dump.psql\]'
      exit(1)
    end

    unless File.exists?(dump_file)
      puts 'File %s not found.' % dump_file
      exit(1)
    end

    if dump_file.end_with?('.gz')
      decompress_file(dump_file)
      dump_file = dump_file[0..-4]
    end

    sh (with_config do |_db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD psql #{connection_opts} -c \"drop schema public cascade\""
    end)
    sh (with_config do |_db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD psql #{connection_opts} -c \"create schema public\""
    end)
    sh (with_config do |_db_name, connection_opts|
      "PGPASSWORD=$DB_PASSWORD psql -q #{connection_opts} -f #{dump_file}"
    end)
  end

  namespace :dump do
    desc 'Export anonymised providers data'
    task :providers, [:file] => :environment do |_task, args|
      write_to_file(args.file) do |writer|
        Provider.find_each(batch_size: 50) do |provider|
          provider.name = [Faker::Company.name, provider.id].join(' ')
          writer.call(provider)
        end
      end
    end

    desc 'Export anonymised defendants data'
    task :defendants, [:file] => :environment do |_task, args|
      write_to_file(args.file) do |writer|
        Defendant.find_each(batch_size: 50) do |defendant|
          defendant.first_name = Faker::Name.first_name
          defendant.last_name  = Faker::Name.last_name
          writer.call(defendant)
        end
      end
    end

    desc 'Export anonymised users data'
    task :users, [:file] => :environment do |_task, args|
      whitelist_domains = %w(example.com agfslgfs.com)

      write_to_file(args.file) do |writer|
        User.find_each(batch_size: 50) do |user|
          user.encrypted_password = '$2a$10$r4CicQylcCuq34E1fysqEuRlWRN4tiTPUOHwksecXT.hbkukPN5F2'

          unless whitelist_domains.detect { |domain| user.email.end_with?(domain) }
            user.first_name = Faker::Name.first_name
            user.last_name  = Faker::Name.last_name
            user.email = [user.id, '@', 'example.com'].join
          end

          writer.call(user)
        end
      end
    end

    desc 'Export anonymised messages data'
    task :messages, [:file] => :environment do |_task, args|
      write_to_file(args.file) do |writer|
        Message.find_each(batch_size: 50) do |message|
          message.body = Faker::Lorem.sentence(6, false, 10)
          if message.attachment_file_name.present?
            message.attachment_file_name = fake_attachment_file_name(message.attachment_file_name)
          end
          writer.call(message)
        end
      end
    end

    desc 'Export anonymised document data'
    task :documents, [:file] => :environment do |_task, args|
      write_to_file(args.file) do |writer|
        Document.find_each(batch_size: 100) do |document|
          with_file_name(fake_attachment_file_name(document.document_file_name)) do |file_name, ext|
            document.document_file_name = "#{file_name}.#{ext}"
            document.converted_preview_document_file_name = "#{file_name}#{ '.' + ext unless ext == 'pdf' }.pdf"
          end
          writer.call(document)
        end
      end
    end

  end

  private

  def production_protected
    raise 'This operation was aborted because the result might destroy production data' if ActiveRecord::Base.connection_config[:database] =~ /gamma/
  end

  def with_config
    yield ActiveRecord::Base.connection_config[:database], connection_opts
  end

  def connection_opts
    [
      ['-U', ActiveRecord::Base.connection_config[:username]],
      ['-h', ActiveRecord::Base.connection_config[:host]],
      ['-d', ActiveRecord::Base.connection_config[:database]]
    ].inject([]) do |result, (flag, value)|
      result.push([flag, value]) unless (value.nil? || value.empty?)
      result
    end.join(' ')
  end

  def write_to_file(name)
    file_name = name || 'anonymised_data.sql'
    puts 'Writing anonymised data to %s' % file_name

    open(file_name, 'a') do |file|
      yield ->(model) do
        file.puts model.class.arel_table.create_insert.tap { |im| im.insert(model.send(:arel_attributes_with_values_for_create, model.attribute_names)) }.to_sql.gsub('"', '') + ';'
      end
    end
  end

  def compress_file(filename)
    puts 'Compressing file...'
    sh "gzip #{filename}"
  end

  def decompress_file(filename)
    puts 'Decompressing file...'
    sh "gzip -d #{filename}"
  end

  def static_tables
    '-t courts -t case_types -t disbursement_types -t expense_types -t fee_types -t offence_classes -t offences'
  end

  def fake_attachment_file_name original_file_name
    *file_parts, _last = Faker::File.file_name.gsub(/\//,'_').split('.')
    file_parts.join + '.' + original_file_name.split('.').last
  end

  def with_file_name file_name, &block
    *file_name, ext = file_name.split('.')
    yield file_name.join, ext if block_given?
  end

end
