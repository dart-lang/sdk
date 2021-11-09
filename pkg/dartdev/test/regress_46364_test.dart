// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

// Copied from package:io
Future<void> copyPath(String from, String to) async {
  await Directory(to).create(recursive: true);
  await for (final file in Directory(from).list(recursive: true)) {
    final copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      await Directory(copyTo).create(recursive: true);
    } else if (file is File) {
      await File(file.path).copy(copyTo);
    } else if (file is Link) {
      await Link(copyTo).create(await file.target(), recursive: true);
    }
  }
}

Future<void> main() async {
  final exePath = Platform.resolvedExecutable;
  final sdkDir = p.dirname(p.dirname(exePath));
  // Try to run the VM located on a path with % encoded characters. The VM
  // should not try and resolve the path as a URI for SDK artifacts (e.g.,
  // dartdev.dart.snapshot).
  final d = Directory.systemTemp.createTempSync('dart_symlink%3A');
  try {
    await copyPath(sdkDir, d.path);
    final path = '${d.path}/bin/dart';
    final result = await Process.run(path, ['help']);
    Expect.equals(result.exitCode, 0);
  } finally {
    await d.delete(recursive: true);
  }
}
