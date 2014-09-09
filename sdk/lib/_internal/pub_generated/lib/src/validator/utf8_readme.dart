library pub.validator.utf8_readme;
import 'dart:async';
import 'dart:convert';
import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';
class Utf8ReadmeValidator extends Validator {
  Utf8ReadmeValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    return syncFuture(() {
      var readme = entrypoint.root.readmePath;
      if (readme == null) return;
      var bytes = readBinaryFile(readme);
      try {
        UTF8.decode(bytes);
      } on FormatException catch (_) {
        warnings.add(
            "$readme contains invalid UTF-8.\n"
                "This will cause it to be displayed incorrectly on " "pub.dartlang.org.");
      }
    });
  }
}
