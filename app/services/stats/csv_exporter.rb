require 'csv'

module Stats
  class CsvExporter
    def self.call(data, options = {})
      new(data, options).call
    end

    def initialize(data, options)
      @data = data
      @headers = options[:headers]
    end

    def call
      CSV.generate do |csv|
        csv << headers if headers.present?
        rows.each { |row| csv << row }
      end
    end

    private

    attr_reader :data, :headers

    def rows
      return [] if data.nil?

      data.map { |row| row.is_a?(Array) ? row : row.values }
    end
  end
end
