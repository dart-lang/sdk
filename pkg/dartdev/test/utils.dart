// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

TestProject project({String mainSrc}) => TestProject(mainSrc: mainSrc);

class TestProject {
  Directory dir;

  static String get defaultProjectName => 'dartdev_temp';

  String get name => defaultProjectName;

  String get relativeFilePath => 'lib/main.dart';

  TestProject({String mainSrc}) {
    dir = Directory.systemTemp.createTempSync('dartdev');
    if (mainSrc != null) {
      file(relativeFilePath, mainSrc);
    }
    file('pubspec.yaml', 'name: $name\ndev_dependencies:\n  test: any\n');
  }

  void file(String name, String contents) {
    var file = File(path.join(dir.path, name));
    file.parent.createSync();
    file.writeAsStringSync(contents);
  }

  void dispose() {
    dir.deleteSync(recursive: true);
  }

  ProcessResult runSync(String command, [List<String> args]) {
    var arguments = [
      absolutePathToDartdevFile,
      command,
    ];

    if (args != null && args.isNotEmpty) {
      arguments.addAll(args);
    }

    return Process.runSync(
      Platform.resolvedExecutable,
      arguments,
      workingDirectory: dir.path,
    );
  }

  /// The path relative from `Directory.current.path` to `dartdev.dart` is
  /// different when executing these tests locally versus on the Dart
  /// buildbots, this if-else captures this change and branches for each case.
  String get absolutePathToDartdevFile {
    var dartdevFilePathOnBots = path.absolute(path.join(
        Directory.current.path, 'pkg', 'dartdev', 'bin', 'dartdev.dart'));
    if (File(dartdevFilePathOnBots).existsSync()) {
      return dartdevFilePathOnBots;
    } else {
      return path
          .absolute(path.join(Directory.current.path, 'bin', 'dartdev.dart'));
    }
  }

  File findFile(String name) {
    var file = File(path.join(dir.path, name));
    return file.existsSync() ? file : null;
  }
}
