module TemplateDataBuilder
  def build_template_data
    {
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