// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

List<String> dart2JsCommand(List<String> args) {
  String basePath = path.fromUri(Platform.script);
  const dart2jsEntry = 'pkg/compiler/lib/src/dart2js.dart';
  String dart2jsPath;
  while (true) {
    dart2jsPath = path.normalize(path.join(basePath, dart2jsEntry));
    if (File(dart2jsPath).existsSync()) {
      break;
    }
    String parentPath = path.dirname(basePath);
    if (parentPath == basePath) {
      throw Exception('Failed to find $dart2jsEntry');
    }
    basePath = parentPath;
  }
  final command = <String>[];
  command.add('--no-sound-null-safety');
  if (Platform.packageConfig != null) {
    command.add('--packages=${Platform.packageConfig}');
  }
  command.add(dart2jsPath);
  command.addAll(args);
  return command;
}

Future<ProcessResult> launchDart2Js(args, {bool noStdoutEncoding = false}) {
  if (noStdoutEncoding) {
    return Process.run(Platform.executable, dart2JsCommand(args),
        stdoutEncoding: null);
  } else {
    return Process.run(Platform.executable, dart2JsCommand(args));
  }
}
