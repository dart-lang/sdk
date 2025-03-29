// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error path in datagram bind call.
//
// OtherResources=datagram_error.dart

import 'dart:io';

import "package:expect/expect.dart";
import 'package:path/path.dart' as path;

void main() async {
  var sdkPath = path.absolute(path.dirname(Platform.executable));
  var dartPath = path.absolute(
    sdkPath,
    Platform.isWindows ? 'dart.exe' : 'dart',
  );
  // Get the Dart script file that generates output.
  var scriptFile = new File(
    Platform.script.resolve("datagram_error.dart").toFilePath(),
  );
  var args = <String>[scriptFile.path];
  ProcessResult syncResult = Process.runSync(dartPath, args);
  Expect.notEquals(0, syncResult.exitCode);
  Expect.stringEquals(
    syncResult.stderr,
    "Unexpected type for socket address" + Platform.lineTerminator,
  );
}
