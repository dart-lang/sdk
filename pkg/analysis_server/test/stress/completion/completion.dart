// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'completion_runner.dart';

/// The main entry point for the code completion stress test.
void main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var analysisRoot = result.rest[0];

    var runner = CompletionRunner(
        output: stdout,
        printMissing: result['missing'],
        printQuality: result['quality'],
        timing: result['timing'],
        verbose: result['verbose']);
    await runner.runAll(analysisRoot);
    await stdout.flush();
  }
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  var parser = ArgParser();
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Print this help message',
    negatable: false,
  );
  parser.addFlag(
    'missing',
    help: 'Report locations where the current identifier was not suggested',
    negatable: false,
  );
  parser.addFlag(
    'quality',
    help: 'Report on the quality of the sort order',
    negatable: false,
  );
  parser.addFlag(
    'timing',
    help: 'Report timing information',
    negatable: false,
  );
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Produce verbose output',
    negatable: false,
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart completion path');
  print('');
  print('Test the completion engine by requesting completion at the offset of');
  print('each identifier in the files contained in the given path. The path');
  print('can be either a single Dart file or a directory.');
  print('');
  print(parser.usage);
}

/// Return `true` if the command-line arguments (represented by the [result] and
/// parsed by the [parser]) are valid.
bool validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    printUsage(parser);
    return false;
  } else if (result.rest.isEmpty) {
    printUsage(parser, error: 'Missing path to files');
    return false;
  } else if (result.rest.length > 1) {
    printUsage(parser, error: 'Only one file can be analyzed');
    return false;
  }
  return true;
}
