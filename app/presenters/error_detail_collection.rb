# This class holds a collection of ErrorDetail objects, keyed by fieldname to which error it pertains.
# Each key can hold more than one ErrorDetail.  The class provides specialised methods for retrieving
# short messages by fieldname, and all the long messages with associated fieldnames
#
class ErrorDetailCollection
  def initialize
    @error_details = {}
  end

  def []=(fieldname, error_detail)
    if @error_details.key?(fieldname)
      @error_details[fieldname] << error_detail
    else
      @error_details[fieldname] = [error_detail]
    end
  end

  def errors_for?(fieldname)
    @error_details.key?(fieldname)
  end

  def [](fieldname)
    @error_details[fieldname]
  end

  def short_messages_for(fieldname)
    error_details_for(fieldname).map(&:short_message).join(', ')
  end

  def long_messages_for(fieldname)
    error_details_for(fieldname).map(&:long_message).join(', ')
  end

  def api_messages_for(fieldname)
    error_details_for(fieldname).map(&:api_message).join(', ')
  end

  def error_details_for(fieldname)
    self[fieldname] || []
  end

  def header_errors
    result_array = []
    @error_details.each_value do |value_array|
      value_array.each do |error_detail|
        result_array << error_detail
      end
    end
    result_array.sort!
  end

  def size
    @error_details.values.sum(&:size)
  end
end
