// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/sdk.dart';
import 'package:dartfix/src/context.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

/// Command line options for `dartfix`.
class Options {
  final Context context;
  Logger logger;

  List<String> targets;
  String sdkPath;
  final bool force;
  final bool overwrite;
  final bool verbose;
  final bool useColor;

  static Options parse(List<String> args, {Context context, Logger logger}) {
    final parser = new ArgParser(allowTrailingOptions: true)
      ..addFlag(overwriteOption,
          abbr: 'w',
          help: 'Overwrite files with the recommended changes.',
          defaultsTo: false,
          negatable: false)
      ..addFlag(forceOption,
          abbr: 'f',
          help: 'Apply the recommended changes even if there are errors.',
          defaultsTo: false,
          negatable: false)
      ..addFlag(_helpOption,
          abbr: 'h',
          help: 'Display this help message.',
          defaultsTo: false,
          negatable: false)
      ..addFlag(_verboseOption,
          abbr: 'v',
          defaultsTo: false,
          help: 'Verbose output.',
          negatable: false)
      ..addFlag('color',
          help: 'Use ansi colors when printing messages.',
          defaultsTo: Ansi.terminalSupportsAnsi);

    context ??= new Context();

    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (e) {
      logger ??= new Logger.standard(ansi: new Ansi(Ansi.terminalSupportsAnsi));
      logger.stderr(e.message);
      _showUsage(parser, logger);
      context.exit(15);
    }

    Options options = new Options._fromArgs(context, results);

    if (logger == null) {
      if (options.verbose) {
        logger = new Logger.verbose();
      } else {
        logger = new Logger.standard(
            ansi: new Ansi(
          options.useColor != null
              ? options.useColor
              : Ansi.terminalSupportsAnsi,
        ));
      }
    }
    options.logger = logger;

    if (results[_helpOption] as bool) {
      _showUsage(parser, logger);
      context.exit(1);
    }

    // Infer the Dart SDK location
    options.sdkPath = getSdkPath(args);
    String sdkPath = options.sdkPath;
    if (sdkPath == null) {
      logger.stderr('No Dart SDK found.');
      _showUsage(parser, logger);
    }
    if (!context.exists(sdkPath)) {
      logger.stderr('Invalid Dart SDK path: $sdkPath');
      context.exit(15);
    }

    // Check for files and/or directories to analyze.
    if (options.targets == null || options.targets.isEmpty) {
      logger.stderr('Expected at least one file or directory to analyze.');
      _showUsage(parser, logger);
      context.exit(15);
    }

    // Normalize and verify paths
    options.targets =
        options.targets.map<String>(options.makeAbsoluteAndNormalize).toList();
    for (String target in options.targets) {
      if (!context.isDirectory(target)) {
        if (!context.exists(target)) {
          logger.stderr('Target does not exist: $target');
        } else {
          logger.stderr('Expected directory, but found: $target');
        }
        _showUsage(parser, logger);
        context.exit(15);
      }
    }

    if (options.verbose) {
      logger.trace('Targets:');
      for (String target in options.targets) {
        logger.trace('  $target');
      }
    }

    return options;
  }

  Options._fromArgs(this.context, ArgResults results)
      : targets = results.rest,
        force = results[forceOption] as bool,
        overwrite = results[overwriteOption] as bool,
        verbose = results[_verboseOption] as bool,
        useColor = results.wasParsed('color') ? results['color'] as bool : null;

  String makeAbsoluteAndNormalize(String target) {
    if (!path.isAbsolute(target)) {
      target = path.join(context.workingDir, target);
    }
    return path.normalize(target);
  }

  static _showUsage(ArgParser parser, Logger logger) {
    logger.stderr('Usage: $_binaryName [options...] <directory paths>');
    logger.stderr('');
    logger.stderr(parser.usage);
  }
}

const _binaryName = 'dartfix';
const forceOption = 'force';
const _helpOption = 'help';
const overwriteOption = 'overwrite';
const _verboseOption = 'verbose';
