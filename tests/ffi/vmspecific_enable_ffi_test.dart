// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing the --enable-ffi=false flag.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

final _execSuffix = Platform.isWindows ? '.exe' : '';

void main() {
  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  // Use the JIT `dart` executable from the build directory rather than
  // `Platform.executable`, which is the AOT runtime under dartkp and cannot run
  // the source helper.
  final dartExecutable = path.join(buildDir, 'dart$_execSuffix');
  final helperPath = path.join(
    sdkDir,
    'tests',
    'ffi',
    'vmspecific_enable_ffi_test_helper.dart',
  );

  final result = Process.runSync(dartExecutable, [
    '--enable-ffi=false',
    helperPath,
  ]);

  Expect.equals(254, result.exitCode);
  Expect.contains(
    'import of dart:ffi is not supported in the current Dart runtime',
    result.stderr,
  );
}
