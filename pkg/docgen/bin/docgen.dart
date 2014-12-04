// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

// Must use relative paths because library imports mirrors via relative paths
import '../lib/docgen.dart';

/**
 * Analyzes Dart files and generates a representation of included libraries,
 * classes, and members.
 */
void main(List<String> arguments) {
  var options = _initArgParser().parse(arguments);
  var files = options.rest.map(path.normalize).toList();
  if (files.isEmpty) _printHelpAndExit();
  var startPage = options['start-page'];
  if (_singlePackage(files) && startPage == null) {
    startPage = _defaultStartPageFor(files);
    print("Using default options for documenting a single package: "
        "--start-page=$startPage");
  }
  var includeSdk = options['parse-sdk'] || options['include-sdk'];
  var scriptDir = path.dirname(Platform.script.toFilePath());
  var introduction = includeSdk ? '' : options['introduction'];

  var pubScript = options['sdk'] != null ?
      path.join(options['sdk'], 'bin', 'pub') : 'pub';

  var dartBinary = options['sdk'] != null ?
      path.join(options['sdk'], 'bin', 'dart') : 'dart';

  var excludedLibraries = options['exclude-lib'];
  if (excludedLibraries == null) excludedLibraries = [];

  var indentJSON = options['indent-json'] as bool;

  docgen(files,
      packageRoot: options['package-root'],
      includePrivate: options['include-private'],
      includeSdk: includeSdk,
      parseSdk: options['parse-sdk'],
      introFileName: introduction,
      out: options['out'],
      excludeLibraries: excludedLibraries,
      includeDependentPackages: options['include-dependent-packages'],
      compile: options['compile'],
      serve: options['serve'],
      dartBinary: dartBinary,
      pubScript: pubScript,
      noDocs: options['no-docs'],
      startPage: startPage,
      indentJSON: indentJSON,
      sdk: options['sdk']);
}

/**
 * Print help if we are passed the help option or invalid arguments.
 */
void _printHelpAndExit() {
  print(_initArgParser().usage);
  print('Usage: dartdocgen [OPTIONS] fooDir/barFile');
  exit(0);
}

/**
 * If the user seems to have given us a single package to document, use some
 * reasonable arguments for what they probably meant.
 */
bool _singlePackage(List files) {
  if (files.length != 1) return false;
  var pubspec = new File(path.join(files.first, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  return true;
}

/**
 * If we've specified just a package and no other command-line options,
 * use the single package name as the start page.
 */
String _defaultStartPageFor(files) {
  var pubspec = new File(path.join(files.first, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return null;
  return packageNameFor(files.first);
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
        if (help) _printHelpAndExit();
      });
  parser.addFlag('verbose', abbr: 'v',
      help: 'Output more logging information.', negatable: false,
      callback: (verbose) {
        if (verbose) Logger.root.level = Level.FINEST;
      });
  parser.addFlag('include-private',
      help: 'Flag to include private declarations.', negatable: false);
  parser.addFlag('include-sdk',
      help: 'Flag to parse SDK Library files.',
      defaultsTo: false,
      negatable: true);
  parser.addFlag('parse-sdk',
      help: 'Parses the SDK libraries only.',
      defaultsTo: false, negatable: false);
  parser.addOption('package-root',
      help: 'Sets the package root of the library being analyzed.');
  parser.addFlag('compile', help: 'Clone the documentation viewer repo locally '
      '(if not already present) and compile with dart2js', defaultsTo: false,
      negatable: false);
  parser.addFlag('serve', help: 'Clone the documentation viewer repo locally '
      '(if not already present), compile with dart2js, '
      'and start a simple server',
      defaultsTo: false, negatable: false);
  parser.addFlag('no-docs', help: 'Do not generate any new documentation',
      defaultsTo: false, negatable: false);
  parser.addOption('introduction',
      help: 'Adds the provided markdown text file as the introduction'
        ' for the generated documentation.', defaultsTo: '');
  parser.addOption('out',
      help: 'The name of the output directory.',
      defaultsTo: 'docs');
  parser.addOption('exclude-lib',
      help: 'Exclude the library by this name from the documentation',
      allowMultiple: true);
  parser.addFlag('include-dependent-packages',
      help: 'Assumes we are documenting a single package and are running '
        'in the directory with its pubspec. Includes documentation for all '
        'of its dependent packages.',
      defaultsTo: true, negatable: true);
  parser.addOption('sdk',
      help: 'SDK directory',
      defaultsTo: null);
  parser.addOption('start-page',
      help: 'By default the viewer will start at the SDK introduction page. '
        'To start at some other page, e.g. for a package, provide the name '
        'of the package in this argument, e.g. --start-page=intl will make '
        'the start page of the viewer be the intl package.',
        defaultsTo: null);
  parser.addFlag('indent-json',
      help: 'Indents each level of JSON output by two spaces',
      defaultsTo: false, negatable: true);

  return parser;
}
