// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library csslib.src.options;

import 'package:args/args.dart';

class PreprocessorOptions {
  /** Generate polyfill code (e.g., var, etc.) */
  final bool polyfill;

  /** Report warnings as errors. */
  final bool warningsAsErrors;

  /** Throw an exception on warnings (not used by command line tool). */
  final bool throwOnWarnings;

  /** Throw an exception on errors (not used by command line tool). */
  final bool throwOnErrors;

  /** True to show informational messages. The `--verbose` flag. */
  final bool verbose;

  /** True to show warning messages for bad CSS.  The '--checked' flag. */
  final bool checked;

  // TODO(terry): Add mixin support and nested rules.
  /**
   * Subset of Less commands enabled; disable with '--no-less'.
   * Less syntax supported:
   * - @name at root level statically defines variables resolved at compilation
   * time.  Essentially a directive e.g., @var-name.
   */
  final bool lessSupport;

  /** Whether to use colors to print messages on the terminal. */
  final bool useColors;

  /** File to process by the compiler. */
  String inputFile;

  // We could make this faster, if it ever matters.
  factory PreprocessorOptions() => parse(['']);

  PreprocessorOptions.fromArgs(ArgResults args)
    : warningsAsErrors = args['warnings_as_errors'],
      throwOnWarnings = args['throw_on_warnings'],
      throwOnErrors = args['throw_on_errors'],
      verbose = args['verbose'],
      checked = args['checked'],
      lessSupport = args['less'],
      useColors = args['colors'],
      polyfill = args['polyfill'],
      inputFile = args.rest.length > 0 ? args.rest[0] : null;

  // tool.dart [options...] <css file>
  static PreprocessorOptions parse(List<String> arguments) {
    var parser = new ArgParser()
      ..addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false,
          help: 'Display detail info')
      ..addFlag('checked', defaultsTo: false, negatable: false,
          help: 'Validate CSS values invalid value display a warning message')
      ..addFlag('less', defaultsTo: true, negatable: true,
          help: 'Supports subset of Less syntax')
      ..addFlag('suppress_warnings', defaultsTo: true,
          help: 'Warnings not displayed')
      ..addFlag('warnings_as_errors', defaultsTo: false,
          help: 'Warning handled as errors')
      ..addFlag('throw_on_errors', defaultsTo: false,
          help: 'Throw on errors encountered')
      ..addFlag('throw_on_warnings', defaultsTo: false,
          help: 'Throw on warnings encountered')
      ..addFlag('colors', defaultsTo: true,
          help: 'Display errors/warnings in colored text')
      ..addFlag('polyfill', defaultsTo: false,
          help: 'Generate polyfill for new CSS features')
      ..addFlag('help', abbr: 'h', defaultsTo: false, negatable: false,
          help: 'Displays this help message');

    try {
      var results = parser.parse(arguments);
      if (results['help'] || results.rest.length == 0) {
        showUsage(parser);
        return null;
      }
      return new PreprocessorOptions.fromArgs(results);
    } on FormatException catch (e) {
      print(e.message);
      showUsage(parser);
      return null;
    }
  }

  static showUsage(parser) {
    print('Usage: css [options...] input.css');
    print(parser.getUsage());
  }

}
