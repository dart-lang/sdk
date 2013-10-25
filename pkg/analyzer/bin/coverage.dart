// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library runtime.coverage;

import 'dart:io';

import 'package:args/args.dart';

import 'package:analyzer/src/services/runtime/log.dart' as log;
import 'package:analyzer/src/services/runtime/coverage/coverage_impl.dart';


main(args) {
  ArgResults options;
  try {
    options = _argParser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    print('Run "coverage --help" to see available options.');
    exit(ERROR);
  }

  if (options['help']) {
    printUsage();
    return;
  }

  // No script to run.
  if (options.rest.isEmpty) {
    printUsage('<No script to run specified>');
    exit(ERROR);
  }

  // More than one script specified.
  if (options.rest.length != 1) {
    print('<Only one script should be specified>');
    exit(ERROR);
  }

  var scriptPath = options.rest[0];

  // Validate that script file exists.
  if (!new File(scriptPath).existsSync()) {
    print('<File "$scriptPath" does not exist>');
    exit(ERROR);
  }

  // Prepare output file path.
  var outPath = options['out'];
  if (outPath == null) {
    printUsage('No --out specified.');
    exit(ERROR);
  }

  // Configure logigng.
  log.everything();
  log.toConsole();

  // Run script.
  runServerApplication(scriptPath, outPath);
}


final ArgParser _argParser = new ArgParser()
    ..addFlag('help', negatable: false, help: 'Print this usage information.')
    ..addOption(
        'level',
        help: 'The level of the coverage.',
        allowed: ['method', 'block', 'statement'],
        defaultsTo: 'statement')
    ..addOption('out', help: 'The output file with statistics.')
    ..addOption(
        'port',
        help: 'The port to run server on, if 0 select any.',
        defaultsTo: '0');


printUsage([var description = 'Code coverage tool for Dart.']) {
  var usage = _argParser.getUsage();
  print('$description\n');
  print('Usage: coverage [options] <script>\n');
  print('$usage\n');
}


/// General error code.
const ERROR = 1;
