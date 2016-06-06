module Select2Helper
  #
  # a select2 alternative method that can be used
  # on select2 select-lists in place of the capybara
  # select method.
  # e.g. select2 'value-to-select', from: 'select2-list-id'
  #
  def select2(value, options)
    # if value == 'E: Burglary'
    #   puts page.body
    # end
    using_wait_time 5 do
      select "#{value}", :from => "#{options[:from]}", :visible => false
    end
  end
end

World(Select2Helper)
