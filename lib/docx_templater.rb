module DocxTemplater
  # Some docx, such as generated by non-microsoft word, sometime make invalid docx. Its input stream returns Zip::NullInputStream. When it detected, this error is raised.
  InvalidInputError = Class.new(StandardError)


  module_function

  def log(str)
    # braindead logging
    puts str if ENV['DEBUG']
  end
end

require 'docx_templater/template_processor'
require 'docx_templater/docx_creator'
