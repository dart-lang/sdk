// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.src.compiler_options;

import 'package:args/args.dart';

class CompilerOptions {
  /** Report warnings as errors. */
  final bool warningsAsErrors;

  /** True to show informational messages. The `--verbose` flag. */
  final bool verbose;

  /** Remove any generated files. */
  final bool clean;

  /** Whether to use colors to print messages on the terminal. */
  final bool useColors;

  /** Force mangling any generated name (even when --out is provided). */
  final bool forceMangle;

  /** Generate component's dart code, but not the main entry point file. */
  final bool componentsOnly;

  /** File to process by the compiler. */
  String inputFile;

  /** Directory where all sources are found. */
  final String baseDir;

  /** Directory where all output will be generated. */
  final String outputDir;

  /** Directory where to look for 'package:' imports. */
  final String packageRoot;

  /**
   * Adjust resource URLs in the output HTML to point back to the original
   * location in the file system. Commonly this is enabled during development,
   * but disabled for deployment.
   */
  final bool rewriteUrls;

  /**
   * Whether to print error messages using the json format understood by the
   * Dart editor.
   */
  final bool jsonFormat;

  /** Emulate scoped styles using a CSS polyfill. */
  final bool emulateScopedCss;

  /** Use CSS file for CSS Reset. */
  final String resetCssFile;

  // We could make this faster, if it ever matters.
  factory CompilerOptions() => parse(['']);

  CompilerOptions.fromArgs(ArgResults args)
    : warningsAsErrors = args['warnings_as_errors'],
      verbose = args['verbose'],
      clean = args['clean'],
      useColors = args['colors'],
      baseDir = args['basedir'],
      outputDir = args['out'],
      packageRoot = args['package-root'],
      rewriteUrls = args['rewrite-urls'],
      forceMangle = args['unique_output_filenames'],
      jsonFormat = args['json_format'],
      componentsOnly = args['components_only'],
      emulateScopedCss = args['scoped-css'],
      resetCssFile = args['css-reset'],
      inputFile = args.rest.length > 0 ? args.rest[0] : null;

  /**
   * Returns the compiler options parsed from [arguments]. Set [checkUsage] to
   * false to suppress checking of correct usage or printing help messages.
   */
  // TODO(sigmund): convert all flags to use dashes instead of underscores
  static CompilerOptions parse(List<String> arguments,
      {bool checkUsage: true}) {
    var parser = new ArgParser()
      ..addFlag('verbose', abbr: 'v')
      ..addFlag('clean', help: 'Remove all generated files',
          defaultsTo: false, negatable: false)
      ..addFlag('warnings_as_errors', abbr: 'e',
          help: 'Warnings handled as errors',
          defaultsTo: false, negatable: false)
      ..addFlag('colors', help: 'Display errors/warnings in colored text',
          defaultsTo: true)
      ..addFlag('rewrite-urls',
          help: 'Adjust every resource url to point to the original location in'
          ' the filesystem.\nThis on by default during development and can be'
          ' disabled to make the generated code easier to deploy.',
          defaultsTo: true)
      ..addFlag('unique_output_filenames', abbr: 'u',
          help: 'Use unique names for all generated files, so they will not '
                'have the\nsame name as your input files, even if they are in a'
                ' different directory',
          defaultsTo: false, negatable: false)
      ..addFlag('json_format',
          help: 'Print error messsages in a json format easy to parse by tools,'
                ' such as the Dart editor',
          defaultsTo: false, negatable: false)
      ..addFlag('components_only',
          help: 'Generate only the code for component classes, do not generate '
                'HTML files or the main bootstrap code.',
          defaultsTo: false, negatable: false)
      ..addFlag('scoped-css', help: 'Emulate scoped styles with CSS polyfill',
          defaultsTo: false)
      ..addOption('css-reset', abbr: 'r', help: 'CSS file used to reset CSS')
      // TODO(sigmund): remove this flag 
      ..addFlag('deploy', help: '(deprecated) currently a noop',
          defaultsTo: false, negatable: false)
      ..addOption('out', abbr: 'o', help: 'Directory where to generate files'
          ' (defaults to the same directory as the source file)')
      ..addOption('basedir', help: 'Base directory where to find all source '
          'files (defaults to the source file\'s directory)')
      ..addOption('package-root', help: 'Where to find "package:" imports'
          '(defaults to the "packages/" subdirectory next to the source file)')
      ..addFlag('help', abbr: 'h', help: 'Displays this help message',
          defaultsTo: false, negatable: false);
    try {
      var results = parser.parse(arguments);
      if (checkUsage && (results['help'] || results.rest.length == 0)) {
        showUsage(parser);
        return null;
      }
      return new CompilerOptions.fromArgs(results);
    } on FormatException catch (e) {
      print(e.message);
      showUsage(parser);
      return null;
    }
  }

  static showUsage(parser) {
    print('Usage: dwc [options...] input.html');
    print(parser.getUsage());
  }
}
