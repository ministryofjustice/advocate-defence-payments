if %w(development test).include? Rails.env
  task(:default).prerequisites.unshift('jasmine:ci') if Gem.loaded_specs.key?('jasmine')
end
