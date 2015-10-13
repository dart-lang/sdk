#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Runs dev_compiler's checker, and optionally the code generator.
/// Also can run a server for local development.
library dev_compiler.bin.dartdevc;

import 'dart:io';

import 'package:dev_compiler/devc.dart' show devCompilerVersion;
import 'package:dev_compiler/src/compiler.dart'
    show validateOptions, compile, setupLogger;
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/server/server.dart' show DevServer;

const String _appName = 'dartdevc';

void _showUsageAndExit() {
  print('usage: dartdevc [<options>] <file.dart>...\n');
  print('<file.dart> is one or more Dart files to process.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

main(List<String> args) {
  var options;

  try {
    options = validateOptions(args);
  } on FormatException catch (e) {
    print('${e.message}\n');
    _showUsageAndExit();
  }

  if (options == null || options.help) _showUsageAndExit();
  if (options.version) {
    print('${_appName} version ${devCompilerVersion}');
    exit(0);
  }

  setupLogger(options.logLevel, print);

  if (options.serverMode) {
    new DevServer(options).start();
  } else {
    exit(compile(options) ? 0 : 1);
  }
}
