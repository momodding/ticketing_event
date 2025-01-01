import 'package:intl/intl.dart';

extension StringExt on String {
  int get toIntegerFromText {
    final cleanedText = replaceAll(RegExp(r'[^0-9]'), '');
    final parsedValue = int.tryParse(cleanedText) ?? 0;
    return parsedValue;
  }

  DateTime parseFormatISO8601() {
    var formatter =  DateFormat('MM/dd/yyyy');
    var formatted = formatter.parse(this);

    return formatted;
  }
}
