module DocxFixtureHelper
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
        #{texts.map { |text| %(<w:p>#{text}</w:p>) }.join("\n")}
      </w:body>
      </w:document>
    EOF
  end

  def dollar(key)
    "$#{key.to_s.upcase}$"
  end
end