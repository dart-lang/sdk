// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This checks that use of 'vm:shared' pragma crashes VM if no flag is passed.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/config.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main(List<String> args) async {
  if (isVmAotConfiguration) return; // Skip testing on AOT
  asyncStart();

  final dartExecutable = Platform.executable;
  final Directory tempDir = Directory.systemTemp.createTempSync();
  try {
    final sharedUseTest = path.join(tempDir.path, 'shared_use_test.dart');
    File(sharedUseTest).writeAsStringSync(r'''
@pragma('vm:shared') int foo = 1;
void main() {}
''');

    {
      final process = await Process.start(dartExecutable,
          <String>[...Platform.executableArguments, sharedUseTest]);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        stdout.writeln('stdout:>$line');
        stdout.writeln(line);
      });
      final sb = StringBuffer();
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        stderr.writeln('stderr:>$line');
        sb.writeln(line);
      });
      Expect.notEquals(0, await process.exitCode);
      Expect.contains(
          "Encountered vm:shared when functionality is disabled. "
          "Pass --experimental-shared-data",
          sb.toString());
    }

    {
      final process = await Process.start(dartExecutable, <String>[
        ...Platform.executableArguments,
        '--experimental_shared_data',
        sharedUseTest
      ]);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        stdout.writeln('stdout:>$line');
        stdout.writeln(line);
      });
      final sb = StringBuffer();
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        stderr.writeln('stderr:>$line');
        sb.writeln(line);
      });
      final exitCode = await process.exitCode;
      if (Platform.version.contains('(main)') ||
          Platform.version.contains('(dev)')) {
        Expect.equals(0, exitCode);
      } else {
        Expect.notEquals(0, exitCode);
        Expect.contains(
            "Shared memory multithreading in only available for "
            "experimentation in dev or main",
            sb.toString());
      }
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
  asyncEnd();
}
