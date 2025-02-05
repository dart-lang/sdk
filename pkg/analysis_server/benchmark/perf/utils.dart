// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

Future<int> runProcess(
  String command,
  List<String> args, {
  String? cwd,
  bool failOnError = true,
  bool verbose = true,
  List<String>? stdout,
}) async {
  if (verbose) {
    print('\n$command ${args.join(' ')}');
  }

  var process = await Process.start(command, args, workingDirectory: cwd);

  process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((
    line,
  ) {
    if (verbose) {
      print('  $line');
    }
    if (stdout != null) {
      stdout.add(line);
    }
  });
  process.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((
    line,
  ) {
    if (verbose) {
      print('  $line');
    }
  });

  var exitCode = await process.exitCode;
  if (exitCode != 0 && failOnError) {
    throw '$command exited with $exitCode';
  }

  return exitCode;
}
