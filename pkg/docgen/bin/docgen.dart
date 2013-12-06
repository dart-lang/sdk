// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../lib/docgen.dart';
import 'package:path/path.dart' as path;

List<String> excludedLibraries = [];

/**
 * Analyzes Dart files and generates a representation of included libraries,
 * classes, and members.
 */
void main(List<String> arguments) {
  logger.onRecord.listen((record) => print(record.message));
  var results = _initArgParser().parse(arguments);

  var includeSdk = results['parse-sdk'] || results['include-sdk'];
  var scriptDir = path.dirname(Platform.script.toFilePath());
  var introFile =
      path.join(path.dirname(scriptDir), 'doc', 'sdk-introduction.md');
  var introduction = includeSdk ? introFile : results['introduction'];
  docgen(results.rest.map(path.normalize).toList(),
      packageRoot: results['package-root'],
      outputToYaml: !results['json'],
      includePrivate: results['include-private'],
      includeSdk: includeSdk,
      parseSdk: results['parse-sdk'],
      append: results['append'] && new Directory(results['out']).existsSync(),
      introduction: introduction,
      out: results['out'],
      excludeLibraries: excludedLibraries,
      includeDependentPackages: results['include-dependent-packages']);
}

/**
 * Creates parser for docgen command line arguments.
 */
ArgParser _initArgParser() {
  var parser = new ArgParser();
  parser.addFlag('help', abbr: 'h',
      help: 'Prints help and usage information.',
      negatable: false,
      callback: (help) {
        if (help) {
          logger.info(parser.getUsage());
          logger.info(USAGE);
          exit(0);
        }
      });
  parser.addFlag('verbose', abbr: 'v',
      help: 'Output more logging information.', negatable: false,
      callback: (verbose) {
        if (verbose) Logger.root.level = Level.FINEST;
      });
  parser.addFlag('json', abbr: 'j',
      help: 'Outputs to JSON. Files are outputted to YAML by default. '
        'If --append is used, it takes the file-format of the previous '
        'run stated in library_list.json ignoring the flag.',
      negatable: true);
  parser.addFlag('include-private',
      help: 'Flag to include private declarations.', negatable: false);
  parser.addFlag('include-sdk',
      help: 'Flag to parse SDK Library files.', negatable: false);
  parser.addFlag('parse-sdk',
      help: 'Parses the SDK libraries only.',
      defaultsTo: false, negatable: false);
  parser.addOption('package-root',
      help: 'Sets the package root of the library being analyzed.');
  parser.addFlag('append',
      help: 'Append to the docs folder, library_list.json and index.txt',
      defaultsTo: false, negatable: false);
  parser.addOption('introduction',
      help: 'Adds the provided markdown text file as the introduction'
        ' for the outputted documentation.', defaultsTo: '');
  parser.addOption('out',
      help: 'The name of the output directory.',
      defaultsTo: 'docs');
  parser.addOption('exclude-lib',
      help: 'Exclude the library by this name from the documentation',
      allowMultiple: true,
      callback: (libs) => excludedLibraries.addAll(libs));
  parser.addFlag('include-dependent-packages',
      help: 'Assumes we are documenting a single package and are running '
        'in the directory with its pubspec. Includes documentation for all '
        'of its dependent packages.',
      defaultsTo: false, negatable: false);
  return parser;
}
