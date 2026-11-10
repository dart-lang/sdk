// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_data_home/src/pid_files.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: test_script.dart <package_name> <pid_file_content>');
    exit(1);
  }
  if (!createPidFile(args[0], args[1])) {
    throw StateError('Failed to create pid file');
  }
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.startsWith('UPDATE:')) {
      final newContent = line.substring('UPDATE:'.length);
      if (!updatePidFile(newContent)) {
        throw StateError('Failed to update pid file');
      }
      print('UPDATED:$pid');
    }
  });
  print('OK:$pid');

  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    print('.');
  }
}
