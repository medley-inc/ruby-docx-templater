require 'pathname'
require 'docx_templater'

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  %i[expect_with mock_with].each do |method|
    config.send(method, :rspec) do |c|
      c.syntax = :expect
    end
  end

  config.include DocxFixtureHelper
  config.include TemplateDataBuilder
end
