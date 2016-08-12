import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

Future launchDart2Js(args,
    {bool noStdoutEncoding: false}) {
  String basePath = path.fromUri(Platform.script);
  while (path.basename(basePath) != 'sdk') {
    basePath = path.dirname(basePath);
  }
  String dart2jsPath = path.normalize(
      path.join(basePath, 'pkg/compiler/lib/src/dart2js.dart'));
  List allArgs = [];
  if (Platform.packageRoot != null) {
    allArgs.add('--package-root=${Platform.packageRoot}');
  } else if (Platform.packageConfig != null) {
    allArgs.add('--packages=${Platform.packageConfig}');
  }
  allArgs.add(dart2jsPath);
  allArgs.addAll(args);
  if (noStdoutEncoding) {
    return Process.run(Platform.executable, allArgs, stdoutEncoding: null);
  } else {
    return Process.run(Platform.executable, allArgs);
  }
}

