// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

Future<void> main() async {
  final origDir = Directory.current;
  final exePath = Platform.resolvedExecutable;
  final d = Directory.systemTemp.createTempSync('dart_symlink');

  // Roughly emulate a Brew installation:
  //   - $BREW/bin/dart -> ../Cellar/dart/2.8.0-dev.20.0/bin/dart
  //   - $BREW/Cellar/dart/2.8.0-dev.20.0/bin/dart -> $DART_SDK/bin/dart
  final a = Directory('${d.path}/usr/local/bin');
  a.createSync(recursive: true);

  // /usr/local/Cellar/dart/2.8.0-dev.20.0/bin/dart -> $DART_SDK/bin/dart
  Directory.current = a;
  final linkLocation = '../Cellar/dart/2.8.0-dev.20.0/bin/dart';
  final link = Link(linkLocation);
  link.createSync(exePath, recursive: true);

  // /usr/local/bin/dart -> /usr/local/Cellar/dart/2.8.0-dev.20/bin/dart
  final link2 = Link('dart')..createSync(linkLocation, recursive: true);
  final path = Uri.parse(link2.absolute.path).path;
  Directory.current = origDir;
  final result = await Process.run('${path}', ['help']);
  Expect.equals(result.exitCode, 0);
}
