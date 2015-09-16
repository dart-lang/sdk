#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Runs dev_compiler's checker, and optionally the code generator.
/// Also can run a server for local development.
library dev_compiler.bin.dartdevc;

import 'dart:io';

import 'package:dev_compiler/src/compiler.dart'
    show validateOptions, compile, setupLogger;
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/server/server.dart' show DevServer;

void _showUsageAndExit() {
  print('usage: dartdevc [<options>] <file.dart>...\n');
  print('<file.dart> is one or more Dart files to process.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

main(List<String> args) async {
  var options;

  try {
    options = validateOptions(args);
  } on FormatException catch (e) {
    print('${e.message}\n');
    _showUsageAndExit();
  }

  if (options == null || options.help) _showUsageAndExit();

  setupLogger(options.logLevel, print);

  if (options.serverMode) {
    new DevServer(options).start();
  } else {
    var success = compile(options);
    exit(success ? 0 : 1);
  }
}
