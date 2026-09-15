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
  let (:data) { DocxTemplater::TestData::DATA.dup }
  let (:parser) { described_class.new(data) }

  def docx_with(document_xml)
    file = Tempfile.new(%w[fixture .docx])
    Zip::OutputStream.open(file.path) do |out|
      out.put_next_entry('word/document.xml')
      out.write(document_xml)
    end
    file
  end

  def build_shared_document_xml(texts)
    <<~EOF
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body>
        #{texts.map { |text| %(<w:p>#{text}</w:p>)}.join("\n")}
      </w:body>
      </w:document>
    EOF
  end

  def dollar(key)
    "$#{key.to_s.upcase}$"
  end

  def mustache(key)
    "{{#{key.to_s.upcase}}}"
  end

  describe '.scan_params' do
    # ドル記号で囲まれたパラメータがスキャンされること
    it 'should scan dollar keys' do
      fixture = docx_with(build_shared_document_xml(%w[$PATIENT_NAME$ $CLINIC_NAME$]))
      out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)
      expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
    end

    # 二重波括弧で囲まれたパラメータがスキャンされること
    it 'should scan mustache keys' do
      fixture = docx_with(build_shared_document_xml(%w[{{PATIENT_NAME}} {{CLINIC_NAME}}]))
      out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)
      expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
    end

    # ドル記号と二重波括弧の両方で囲まれたパラメータがスキャンされること
    it 'should scan both dollar and mustache keys' do
      fixture = docx_with(build_shared_document_xml(%w[$PATIENT_NAME$ {{CLINIC_NAME}}]))
      out = DocxTemplater::TemplateProcessor.scan_params(fixture.path)
      expect(out).to eq(%w[PATIENT_NAME CLINIC_NAME])
    end
  end

  describe '#render' do
    # ドル記号のキーが値に置き換わること
    it 'should replace dollar keys with values' do
      xml = build_shared_document_xml(%w[$PATIENT_NAME$ $CLINIC_NAME$])
      out = parser.render(xml)
      expect(out).to include(data[:patient_name])
      expect(out).to include(data[:clinic_name])
      expect(out).not_to include('$PATIENT_NAME$')
      expect(out).not_to include('$CLINIC_NAME$')
    end

    # 二重波括弧のキーが値に置き換わること
    it 'should replace mustache keys with values' do
      xml = build_shared_document_xml(%w[{{PATIENT_NAME}} {{CLINIC_NAME}}])
      out = parser.render(xml)
      expect(out).to include(data[:patient_name])
      expect(out).to include(data[:clinic_name])
      expect(out).not_to include('{{PATIENT_NAME}}')
      expect(out).not_to include('{{CLINIC_NAME}}')
    end

    # ドル記号と二重波括弧の両方のキーが値に置き換わること
    it 'should replace both dollar and mustache keys with values' do
      xml = build_shared_document_xml(%w[$PATIENT_NAME$ {{CLINIC_NAME}}])
      out = parser.render(xml)
      expect(out).to include(data[:patient_name])
      expect(out).to include(data[:clinic_name])
      expect(out).not_to include('$PATIENT_NAME$')
      expect(out).not_to include('{{CLINIC_NAME}}')
    end

    # 全キーが値に置き換わること
    it 'should replace all keys with values' do
      xml = build_shared_document_xml(data.keys.map { |key| dollar(key) })
      out = parser.render(xml)
      data.each do |key, value|
        expect(out).to include(value.to_s)
        expect(out).not_to include(dollar(key))
      end
    end

    # 値に半角の & が含まれても壊れた XML を出力しないこと
    it 'should escape xml special characters in values' do
      data[:clinic_name] = 'メディカル&ケアクリニック'
      xml = build_shared_document_xml(['$CLINIC_NAME$'])
      out = parser.render(xml)
      expect(out).to include('メディカル&amp;ケアクリニック')
    end
  end
end
