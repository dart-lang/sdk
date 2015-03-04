#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to run the checker on a Dart program.
library ddc.bin.checker;

import 'dart:io';

import 'package:dev_compiler/devc.dart';
import 'package:dev_compiler/src/options.dart';

void _showUsageAndExit() {
  print('usage: dartdevc [<options>] <file.dart>\n');
  print('<file.dart> is a single Dart file to process.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

void main(List<String> args) {
  var options = parseOptions(args);
  if (options.help) _showUsageAndExit();

  if (!options.useMockSdk && options.dartSdkPath == null) {
    print('Could not automatically find dart sdk path.');
    print('Please pass in explicitly: --dart-sdk <path>');
    exit(1);
  }

  if (options.entryPointFile == null) {
    print('Expected filename.');
    _showUsageAndExit();
  }

  if (!options.dumpInfo) setupLogger(options.logLevel, print);

  if (options.serverMode) {
    new CompilerServer(options).start();
  } else {
    var result = new Compiler(options).run();
    exit(result.failure ? 1 : 0);
  }
}
