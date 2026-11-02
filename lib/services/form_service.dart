import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FormFieldInfo {
  final String name;
  final String type;
  final String value;
  final int pageIndex;

  const FormFieldInfo({
    required this.name,
    required this.type,
    required this.value,
    required this.pageIndex,
  });
}

class FormService {
  /// Extracts all form fields from a PDF document
  static List<FormFieldInfo> extractFormFields(Uint8List pdfBytes) {
    final List<FormFieldInfo> fields = [];
    final document = PdfDocument(inputBytes: pdfBytes);
    final form = document.form;

    if (form.fields.count > 0) {
      for (int i = 0; i < form.fields.count; i++) {
        final field = form.fields[i];
        String type = 'Text';
        String value = '';

        if (field is PdfTextBoxField) {
          type = 'Text';
          value = field.text;
        } else if (field is PdfCheckBoxField) {
          type = 'CheckBox';
          value = field.isChecked ? 'true' : 'false';
        } else if (field is PdfRadioButtonListField) {
          type = 'Radio';
          value = field.selectedValue;
        } else if (field is PdfComboBoxField) {
          type = 'Dropdown';
          value = field.selectedValue;
        }

        fields.add(
          FormFieldInfo(
            name: field.name ?? 'Field $i',
            type: type,
            value: value,
            pageIndex: 0,
          ),
        );
      }
    }

    document.dispose();
    return fields;
  }

  /// Updates form field values and saves the PDF (optionally flattening)
  static Uint8List fillFormFields({
    required Uint8List pdfBytes,
    required Map<String, String> values,
    bool flatten = false,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final form = document.form;

    for (int i = 0; i < form.fields.count; i++) {
      final field = form.fields[i];
      final name = field.name;
      if (name != null && values.containsKey(name)) {
        final val = values[name]!;
        if (field is PdfTextBoxField) {
          field.text = val;
        } else if (field is PdfCheckBoxField) {
          field.isChecked = val.toLowerCase() == 'true';
        } else if (field is PdfComboBoxField) {
          field.selectedValue = val;
        }
      }
    }

    if (flatten) {
      form.flattenAllFields();
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }
}
