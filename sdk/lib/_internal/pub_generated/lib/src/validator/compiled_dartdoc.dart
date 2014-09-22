library pub.validator.compiled_dartdoc;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../entrypoint.dart';
import '../io.dart';
import '../validator.dart';
class CompiledDartdocValidator extends Validator {
  CompiledDartdocValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    return new Future.sync(() {
      for (var entry in entrypoint.root.listFiles()) {
        if (path.basename(entry) != "nav.json") continue;
        var dir = path.dirname(entry);
        var files = [
            entry,
            path.join(dir, "index.html"),
            path.join(dir, "styles.css"),
            path.join(dir, "dart-logo-small.png"),
            path.join(dir, "client-live-nav.js")];
        if (files.every((val) => fileExists(val))) {
          warnings.add(
              "Avoid putting generated documentation in " "${path.relative(dir)}.\n"
                  "Generated documentation bloats the package with redundant " "data.");
        }
      }
    });
  }
}
