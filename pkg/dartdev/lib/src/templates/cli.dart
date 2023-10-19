// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a simple command-line application with argument parsing.
class CliGenerator extends DefaultGenerator {
  CliGenerator()
      : super(
          'cli',
          'CLI Application',
          'A command-line application with basic argument parsing.',
          alternateId: 'console-cli',
          categories: const ['dart', 'cli'],
        ) {
    addFile('.gitignore', common.gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    setEntrypoint(
      addFile('bin/__projectName__.dart', _mainDart),
    );
  }

  @override
  String getInstallInstructions(
    String directory, {
    String? scriptPath,
  }) =>
      super.getInstallInstructions(directory, scriptPath: 'bin/$scriptPath');
}

final String _pubspec = '''
name: __projectName__
description: A sample command-line application with basic argument parsing.
version: 0.0.1
# repository: https://github.com/my_org/my_repo

environment:
  ${common.sdkConstraint}

# Add regular dependencies here.
dependencies:
  args: ^2.4.2

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
''';

final String _readme = '''
A sample command-line application providing basic argument parsing with an entrypoint in `bin/`.
''';

final String _mainDart = r'''
import 'package:args/args.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart __projectName__.dart <flags> [arguments]');
  print(argParser.usage);
}

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.wasParsed('help')) {
      printUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      print('__projectName__ version: $version');
      return;
    }
    if (results.wasParsed('verbose')) {
      verbose = true;
    }

    // Act on the arguments provided.
    print('Positional arguments: ${results.rest}');
    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
''';
