#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart2native/generate.dart';

void printUsage(final ArgParser parser) {
  print('''
Usage: dart2native <main-dart-file> [<options>]

Generates an executable or an AOT snapshot from <main-dart-file>.
''');
  print(parser.usage);
}

Future<void> main(List<String> args) async {
  // If we're outputting to a terminal, wrap usage text to that width.
  int outputLineWidth;
  try {
    outputLineWidth = stdout.terminalColumns;
  } catch (_) {/* Ignore. */}

  final ArgParser parser = ArgParser(usageLineLength: outputLineWidth)
    ..addMultiOption('define', abbr: 'D', valueHelp: 'key=value', help: '''
Define an environment declaration. To specify multiple declarations, use multiple options or use commas to separate key-value pairs.
E.g.: dart2native -Da=1,b=2 main.dart''')
    ..addFlag('enable-asserts',
        negatable: false, help: 'Enable assert statements.')
    ..addMultiOption(
      'extra-gen-snapshot-options',
      help: 'Pass additional options to gen_snapshot.',
      hide: true,
      valueHelp: 'opt1,opt2,...',
    )
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Display this help message.')
    ..addOption(
      'output-kind',
      abbr: 'k',
      allowed: ['aot', 'exe'],
      allowedHelp: {
        'aot': 'Generate an AOT snapshot.',
        'exe': 'Generate a standalone executable.',
      },
      defaultsTo: 'exe',
      valueHelp: 'aot|exe',
    )
    ..addOption('output', abbr: 'o', valueHelp: 'path', help: '''
Set the output filename. <path> can be relative or absolute.
E.g.: dart2native main.dart -o ../bin/my_app.exe
''')
    ..addOption('packages', abbr: 'p', valueHelp: 'path', help: '''
Get package locations from the specified file instead of .packages. <path> can be relative or absolute.
E.g.: dart2native --packages=/tmp/pkgs main.dart
''')
    ..addOption('save-debugging-info', abbr: 'S', valueHelp: 'path', help: '''
Remove debugging information from the output and save it separately to the specified file. <path> can be relative or absolute.
''')
    ..addOption('enable-experiment',
        defaultsTo: '', valueHelp: 'feature', hide: true, help: '''
Comma separated list of experimental features.
''')
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output.');

  ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    await stderr.flush();
    printUsage(parser);
    exit(1);
  }

  if (parsedArgs['help']) {
    printUsage(parser);
    exit(0);
  }

  if (parsedArgs.rest.length != 1) {
    printUsage(parser);
    exit(1);
  }

  final String sourceFile = parsedArgs.rest[0];
  if (!FileSystemEntity.isFileSync(sourceFile)) {
    stderr.writeln(
        '"${sourceFile}" is not a file. See \'--help\' for more information.');
    await stderr.flush();
    exit(1);
  }

  try {
    await generateNative(
        kind: parsedArgs['output-kind'],
        sourceFile: sourceFile,
        outputFile: parsedArgs['output'],
        debugFile: parsedArgs['save-debugging-info'],
        packages: parsedArgs['packages'],
        defines: parsedArgs['define'],
        enableExperiment: parsedArgs['enable-experiment'],
        enableAsserts: parsedArgs['enable-asserts'],
        verbose: parsedArgs['verbose'],
        extraOptions: parsedArgs['extra-gen-snapshot-options']);
  } catch (e) {
    stderr.writeln('Failed to generate native files:');
    stderr.writeln(e);
    await stderr.flush();
    exit(1);
  }
}
