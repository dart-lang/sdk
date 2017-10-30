import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

List<String> dart2JsCommand(List<String> args) {
  String basePath = path.fromUri(Platform.script);
  while (path.basename(basePath) != 'sdk') {
    basePath = path.dirname(basePath);
  }
  String dart2jsPath =
      path.normalize(path.join(basePath, 'pkg/compiler/lib/src/dart2js.dart'));
  List command = <String>[];
  if (Platform.packageRoot != null) {
    command.add('--package-root=${Platform.packageRoot}');
  } else if (Platform.packageConfig != null) {
    command.add('--packages=${Platform.packageConfig}');
  }
  command.add(dart2jsPath);
  command.addAll(args);
  return command;
}

Future<ProcessResult> launchDart2Js(args, {bool noStdoutEncoding: false}) {
  if (noStdoutEncoding) {
    return Process.run(Platform.executable, dart2JsCommand(args),
        stdoutEncoding: null);
  } else {
    return Process.run(Platform.executable, dart2JsCommand(args));
  }
}
