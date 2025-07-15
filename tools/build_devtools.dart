#!/usr/bin/env dart
// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

// Builds the Flutter DevTools app from source.
void main() {
  final flutterSdk = path.absolute('third_party', 'flutter', 'bin', 'flutter');
  if (!File(flutterSdk).existsSync()) {
    stderr.writeln('Missing Flutter SDK at "$flutterSdk"; '
        'make sure that "../.client" has a `custom_vars` section with '
        '`"build_devtools_from_sources": True,` and then run `gclient sync`');
    exitCode = 1;
    return;
  }

  final devtoolsDir = path.absolute('third_party', 'devtools_src');
  if (!Directory(devtoolsDir).existsSync()) {
    stderr.writeln('Missing devtools dir in devtools sources "$devtoolsDir"; '
        'make sure that "../.client" has a `custom_vars` section with '
        '`"build_devtools_from_sources": True,` and then run `gclient sync`');
    exitCode = 1;
    return;
  }

  final dtPath = path.absolute(devtoolsDir, 'tool', 'bin', 'dt.dart');
  final buildResult = Process.runSync(
    Platform.resolvedExecutable,
    [dtPath, '--flutter-sdk-path=$flutterSdk', 'build'],
    workingDirectory: devtoolsDir,
  );
  if (buildResult.exitCode != 0) {
    stderr.writeln(
        '\'${Platform.resolvedExecutable} $dtPath --flutter-sdk-path=$flutterSdk '
        'build\' failed: exit code ${buildResult.exitCode}');
    stderr.writeln('stdout: >>>${buildResult.stdout}<<<');
    stderr.writeln('stderr: >>>${buildResult.stderr}<<<');
    exitCode = 1;
    return;
  }

  // One final check.
  final buildDir = path.absolute('third_party', 'devtools_src', 'packages',
      'devtools_app', 'build', 'web');
  final mainJs = path.absolute(buildDir, 'main.dart.js');
  final mainWasm = path.absolute(buildDir, 'main.dart.wasm');
  if (!File(mainJs).existsSync()) {
    stderr.writeln('Missing expected built JS app at "$mainJs"');
    exitCode = 1;
    return;
  }
  if (!File(mainWasm).existsSync()) {
    stderr.writeln('Missing expected built WASM app at "$mainWasm"');
    exitCode = 1;
    return;
  }

  // Otherwise, this script is silent.
}
