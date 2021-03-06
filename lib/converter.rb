require 'bundler/setup'
require 'qif'

require_relative 'transaction'
require_relative 'categories_collection'
require_relative 'user_interface'
require_relative 'input_file'
require_relative 'arguments'

class Converter
  TRANSACTION_TYPE = 'Bank'.freeze
  def initialize(ui, categories, input_file, arguments)
    @ui = ui
    @categories = categories
    @input_file = input_file
    @arguments = arguments
  end

  def get_output_path
    File.join(File.dirname(__FILE__), '../resultado.qif')
  end

  def run
    @ui.set_locale
    options = @arguments.read
    @categories.load
    @input_file.load(options[:input])

    if options[:format] == 'qif'
      @ui.localized_message(:info_wont_be_saved)
      Qif::Writer.open(options[:output], TRANSACTION_TYPE) do |writer|
        @input_file.file.each InputFile::HEADER_ROWS_NUMBER do |row|
          writer << Transaction.new(@ui, @categories)
                    .set_attributes(row)
                    .set_category
                    .to_qif
        end
      end
    else
      CSV.open(options[:output], 'wb', {:col_sep => ';'}) do |writer|
        @input_file.file.each InputFile::HEADER_ROWS_NUMBER do |row|
          writer << Transaction.new(@ui, @categories)
                    .set_attributes(row)
                    .set_category
                    .to_csv
        end
      end
    end

    @categories.save_if_modified
    @ui.localized_message(:file_generated)
  end
end
