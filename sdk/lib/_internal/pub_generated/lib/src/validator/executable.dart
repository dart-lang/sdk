library pub.validator.executable;
import 'dart:async';
import 'package:path/path.dart' as p;
import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';
class ExecutableValidator extends Validator {
  ExecutableValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var binFiles = entrypoint.root.listFiles(
            beneath: "bin",
            recursive: false).map(
                ((path) => p.relative(path, from: entrypoint.root.dir))).toList();
        entrypoint.root.pubspec.executables.forEach(((executable, script) {
          var scriptPath = p.join("bin", "$script.dart");
          if (binFiles.contains(scriptPath)) return;
          warnings.add(
              'Your pubspec.yaml lists an executable "$executable" that '
                  'points to a script "$scriptPath" that does not exist.');
        }));
        completer0.complete(null);
      } catch (e0) {
        completer0.completeError(e0);
      }
    });
    return completer0.future;
  }
}
