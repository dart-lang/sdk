#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Runs dev_compiler's checker, and optionally the code generator.
/// Also can run a server for local development.
library dev_compiler.bin.devc;

import 'dart:io';

import 'package:dev_compiler/devc.dart';
import 'package:dev_compiler/src/options.dart';

void _showUsageAndExit() {
  print('usage: dartdevc [<options>] <file.dart>...\n');
  print('<file.dart> is one or more Dart files to process.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

void main(List<String> args) {
  var options = parseOptions(args);
  if (options.help) _showUsageAndExit();

  var srcOpts = options.sourceOptions;
  if (!srcOpts.useMockSdk && srcOpts.dartSdkPath == null) {
    print('Could not automatically find dart sdk path.');
    print('Please pass in explicitly: --dart-sdk <path>');
    exit(1);
  }

  if (options.inputs.length == 0) {
    print('Expected filename.');
    _showUsageAndExit();
  }

  setupLogger(options.logLevel, print);

  if (options.serverMode) {
    new DevServer(options).start();
  } else {
    var context = createAnalysisContextWithSources(
        options.strongOptions, options.sourceOptions);
    var reporter = createErrorReporter(context, options);
    var success = new BatchCompiler(context, options, reporter: reporter).run();
    exit(success ? 0 : 1);
  }
}
