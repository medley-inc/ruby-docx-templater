require 'spec_helper'

module DocxTemplater
  module TestData
    DATA = {
      patient_id: '00001',
      patient_kana: 'サンプルカンジャ',
      patient_name: 'サンプル患者',
      patient_sex: '男',
      patient_postal: '123-4567',
      patient_address: '東京都港区メドレーヶ丘１-２−３',
      patient_birthdate_ad: '1989年01月01日',
      patient_birthdate_jc: '昭和64年1月1日',
      patient_age: '40',
      patient_tel: '09012345678',
      clinic_name: 'サンプルクリニック',
      clinic_address: '東京都港区123丁目456番地クリニクスビル1Ｆ',
      clinic_tel: '123456789',
      clinic_staff: 'サンプル医師',
      yyyy: 2022,
      yyyy_jc: '令和4',
      mm: 8,
      dd: 25,
      medication_1: 'サンプル薬剤名1 ３錠 １日３回朝昼夕食後 ７日分',
      medication_2: 'サンプル薬剤名2 3錠 １日２回朝夕食後 ５日分',
      disease_name_1: 'サンプル病名1',
      anamnesis_name_1: 'サンプル既往歴1',
    }
  end
end

describe DocxTemplater::TemplateProcessor do
  let(:data) { Marshal.load(Marshal.dump(DocxTemplater::TestData::DATA)) } # deep copy
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
  <w:p>$PATIENT_NAME$</w:p>
  <w:p>$CLINIC_NAME$</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
  end

  it 'should scan mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>{{PATIENT_NAME}}</w:p>
  <w:p>{{CLINIC_NAME}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
  end

  it 'should scan both dollar and mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$PATIENT_NAME$</w:p>
  <w:p>{{CLINIC_NAME}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)
    out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)

    expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
  end

  it 'should replace dollar keys with values' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
#{data.keys.map { |key| "  <w:p>$#{key.to_s.upcase}$</w:p>" }.join("\n")}
</w:body>
</w:document>
EOF
    out = parser.render(xml)

    data.each do |key, value|
      expect(out).to include(value.to_s)
      expect(out).not_to include("$#{key.to_s.upcase}$")
    end
  end

  it 'should replace mustache keys with values' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>{{PATIENT_NAME}}</w:p>
</w:body>
</w:document>
EOF
    expect(xml).to include('{{PATIENT_NAME}}')
    expect(xml).not_to include(data[:patient_name])

    out = parser.render(xml)

    expect(out).to include(data[:patient_name])
    expect(out).not_to include('{{PATIENT_NAME}}')
  end

  it 'should replace both dollar and mustache keys with values' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$PATIENT_NAME$</w:p>
  <w:p>{{CLINIC_NAME}}</w:p>
</w:body>
</w:document>
EOF
    expect(xml).to include('$PATIENT_NAME$')
    expect(xml).to include('{{CLINIC_NAME}}')
    expect(xml).not_to include(data[:patient_name])
    expect(xml).not_to include(data[:clinic_name])

    out = parser.render(xml)

    expect(out).to include(data[:patient_name])
    expect(out).to include(data[:clinic_name])
    expect(out).not_to include('$PATIENT_NAME$')
    expect(out).not_to include('{{CLINIC_NAME}}')
  end

  it 'should scan and replace both dollar and mustache keys' do
    xml = <<EOF
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
  <w:p>$PATIENT_NAME$</w:p>
  <w:p>{{CLINIC_NAME}}</w:p>
</w:body>
</w:document>
EOF
    fixture = docx_with(xml)

    keys = DocxTemplater::TemplateProcessor.scan_params(fixture.path)
    expect(keys).to eq(%w[PATIENT_NAME CLINIC_NAME])

    out = parser.render(xml)
    expect(out).to include(data[:patient_name])
    expect(out).to include(data[:clinic_name])
    expect(out).not_to include('$')
    expect(out).not_to include('{{')
  end

end
