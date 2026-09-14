require 'spec_helper'

module DocxTemplater
  module TestData
    DATA = {
      teacher: 'Priya Vora',
      building: 'Building #14',
      classroom: 'Rm 202'.to_sym,
      district: 'Washington County Public Schools',
      senority: 12.25,
      roster: [
        { name: 'Sally', age: 12, attendence: '100%' },
        { name: :Xiao, age: 10, attendence: '94%' },
        { name: 'Bryan', age: 13, attendence: '100%' },
        { name: 'Larry', age: 11, attendence: '90%' },
        { name: 'Kumar', age: 12, attendence: '76%' },
        { name: 'Amber', age: 11, attendence: '100%' },
        { name: 'Isaiah', age: 12, attendence: '89%' },
        { name: 'Omar', age: 12, attendence: '99%' },
        { name: 'Xi', age: 11, attendence: '20%' },
        { name: 'Noushin', age: 12, attendence: '100%' }
      ],
      event_reports: [
        { name: 'Science Museum Field Trip', notes: 'PTA sponsored event. Spoke to Astronaut with HAM radio.' },
        { name: 'Wilderness Center Retreat', notes: '2 days hiking for charity:water fundraiser, $10,200 raised.' }
      ],
      true_cond: true,
      false_cond: false,
      created_at: '11-12-03 02:01'
    }.freeze
  end
end

describe DocxTemplater::TemplateProcessor do
  let(:data) { Marshal.load(Marshal.dump(DocxTemplater::TestData::DATA)) } # deep copy
  let(:base_path) { SPEC_BASE_PATH.join('example_input') }
  let(:xml) { File.read("#{base_path}/word/document.xml") }
  let(:parser) { DocxTemplater::TemplateProcessor.new(data) }

  def docx_with(document_xml)
    file = Tempfile.new(['fixture', '.docx'])
    Zip::OutputStream.open(file.path) do |out|
      out.put_next_entry('word/document.xml')
      out.write(document_xml)
    end
    file
  end

  it 'should enter no text for a nil value' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>Before.$KEY$After</w:p>
</w:body>
</w:document>
EOF
    actual = DocxTemplater::TemplateProcessor.new(key: nil).render(xml)
    expected_xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>Before.After</w:p>
</w:body>
</w:document>
EOF
    expect(actual).to eq(expected_xml)
  end

  it 'should scan dollar keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$TEACHER$</w:p>
  <w:p>$DISTRICT$</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[TEACHER DISTRICT])
  end

  it 'should scan mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>{{TEACHER}}</w:p>
  <w:p>{{DISTRICT}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[TEACHER DISTRICT])
  end

  it 'should scan both dollar and mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$TEACHER$</w:p>
  <w:p>{{DISTRICT}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[TEACHER DISTRICT])
  end

  it 'should replace dollar keys with values' do
    non_array_keys = data.reject { |_, v| [Array, TrueClass, FalseClass].include?(v.class) }
    non_array_keys.keys.each do |key|
      expect(xml).to include("$#{key.to_s.upcase}$")
      expect(xml).not_to include(data[key].to_s)
    end
    out = parser.render(xml)

    non_array_keys.each do |key|
      expect(out).not_to include("$#{key}$")
      expect(out).to include(data[key].to_s)
    end
  end

  it 'should replace mustache keys with values' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>{{TEACHER}}</w:p>
</w:body>
</w:document>
EOF
    expect(xml).to include('{{TEACHER}}')
    expect(xml).not_to include(data[:teacher])

    out = parser.render(xml)

    expect(out).to include(data[:teacher])
    expect(out).not_to include('{{TEACHER}}')
  end

  it 'should replace both dollar and mustache keys with values' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$TEACHER$</w:p>
  <w:p>{{DISTRICT}}</w:p>
</w:body>
</w:document>
EOF
    expect(xml).to include('$TEACHER$')
    expect(xml).to include('{{DISTRICT}}')
    expect(xml).not_to include(data[:teacher])
    expect(xml).not_to include(data[:district])

    out = parser.render(xml)

    expect(out).to include(data[:teacher])
    expect(out).to include(data[:district])
    expect(out).not_to include('$TEACHER$')
    expect(out).not_to include('{{DISTRICT}}')
  end

  it 'should scan and replace both dollar and mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$TEACHER$</w:p>
  <w:p>{{DISTRICT}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)

    keys = DocxTemplater::TemplateProcessor.scan_params(fixture.path)
    expect(keys).to eq(%w[TEACHER DISTRICT])

    out = parser.render(xml)
    expect(out).to include(data[:teacher])
    expect(out).to include(data[:district])
    expect(out).not_to include('$')
    expect(out).not_to include('{{')
  end

end
