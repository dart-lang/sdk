import 'package:expect/expect.dart';

void main() {
  try {
    var re = RegExp(r'[c-');
  } on FormatException catch (e, s) {
    Expect.equals(
        "FormatException: Unterminated character class [c-", e.toString());
  }
}
