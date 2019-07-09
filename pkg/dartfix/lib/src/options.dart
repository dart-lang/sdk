// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/context.dart';
import 'package:path/path.dart' as path;

const excludeOption = 'exclude';

const forceOption = 'force';
const includeOption = 'include';
const overwriteOption = 'overwrite';
const requiredOption = 'required';
const _binaryName = 'dartfix';
const _colorOption = 'color';
const _serverSnapshot = 'server';

// options only supported by server 1.22.2 and greater
const _helpOption = 'help';
const _verboseOption = 'verbose';

/// Command line options for `dartfix`.
class Options {
  final Context context;
  Logger logger;

  List<String> targets;
  final String sdkPath;
  final String serverSnapshot;

  final bool requiredFixes;
  final List<String> includeFixes;
  final List<String> excludeFixes;

  final bool force;
  final bool showHelp;
  final bool overwrite;
  final bool useColor;
  final bool verbose;

  Options._fromArgs(this.context, ArgResults results)
      : force = results[forceOption] as bool,
        includeFixes =
            (results[includeOption] as List ?? []).cast<String>().toList(),
        excludeFixes =
            (results[excludeOption] as List ?? []).cast<String>().toList(),
        overwrite = results[overwriteOption] as bool,
        requiredFixes = results[requiredOption] as bool,
        sdkPath = _getSdkPath(),
        serverSnapshot = results[_serverSnapshot],
        showHelp = results[_helpOption] as bool || results.arguments.isEmpty,
        targets = results.rest,
        useColor = results.wasParsed(_colorOption)
            ? results[_colorOption] as bool
            : null,
        verbose = results[_verboseOption] as bool;

  String makeAbsoluteAndNormalize(String target) {
    if (!path.isAbsolute(target)) {
      target = path.join(context.workingDir, target);
    }
    return path.normalize(target);
  }

  static Options parse(List<String> args, Context context, Logger logger) {
    final parser = ArgParser(allowTrailingOptions: true)
      ..addSeparator('Choosing fixes to be applied:')
      ..addMultiOption(includeOption,
          abbr: 'i', help: 'Include a specific fix.', valueHelp: 'name-of-fix')
      ..addMultiOption(excludeOption,
          abbr: 'x', help: 'Exclude a specific fix.', valueHelp: 'name-of-fix')
      ..addFlag(requiredOption,
          abbr: 'r',
          help: 'Apply required fixes.',
          defaultsTo: false,
          negatable: false)
      ..addSeparator('Modifying files:')
      ..addFlag(overwriteOption,
          abbr: 'w',
          help: 'Overwrite files with the changes.',
          defaultsTo: false,
          negatable: false)
      ..addFlag(forceOption,
          abbr: 'f',
          help: 'Overwrite files even if there are errors.',
          defaultsTo: false,
          negatable: false)
      ..addSeparator('Miscellaneous:')
      ..addFlag(_helpOption,
          abbr: 'h',
          help: 'Display this help message.',
          defaultsTo: false,
          negatable: false)
      ..addOption(_serverSnapshot,
          help: 'Path to the analysis server snapshot file.', valueHelp: 'path')
      ..addFlag(_verboseOption,
          abbr: 'v',
          defaultsTo: false,
          help: 'Verbose output.',
          negatable: false)
      ..addFlag(_colorOption,
          help: 'Use ansi colors when printing messages.',
          defaultsTo: Ansi.terminalSupportsAnsi);

    context ??= Context();

    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (e) {
      logger ??= Logger.standard(ansi: Ansi(Ansi.terminalSupportsAnsi));
      logger.stderr(e.message);
      _showUsage(parser, logger);
      context.exit(15);
    }

    Options options = Options._fromArgs(context, results);

    if (logger == null) {
      if (options.verbose) {
        logger = Logger.verbose();
      } else {
        logger = Logger.standard(
            ansi: Ansi(
          options.useColor != null
              ? options.useColor
              : Ansi.terminalSupportsAnsi,
        ));
      }
    }
    options.logger = logger;

    // For '--help', we short circuit the logic to validate the sdk and project.
    if (options.showHelp) {
      _showUsage(parser, logger, showHelpHint: false);
      return options;
    }

    // Validate the Dart SDK location
    String sdkPath = options.sdkPath;
    if (sdkPath == null) {
      logger.stderr('No Dart SDK found.');
      context.exit(15);
    }

    if (!context.exists(sdkPath)) {
      logger.stderr('Invalid Dart SDK path: $sdkPath');
      context.exit(15);
    }

    // Check for files and/or directories to analyze.
    if (options.targets == null || options.targets.isEmpty) {
      logger.stderr('Expected at least one file or directory to analyze.');
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

  static String _getSdkPath() {
    return Platform.environment['DART_SDK'] != null
        ? Platform.environment['DART_SDK']
        : path.dirname(path.dirname(Platform.resolvedExecutable));
  }

  static _showUsage(ArgParser parser, Logger logger,
      {bool showHelpHint = true}) {
    Function(String message) out = showHelpHint ? logger.stderr : logger.stdout;
    // show help on stdout when showHelp is true and showHelpHint is false
    out('''
Usage: $_binaryName [options...] <directory paths>
''');
    out(parser.usage);
    out(showHelpHint
        ? '''

Use --$_helpOption to display the fixes that can be specified using either
--$includeOption or --$excludeOption.'''
        : '');
  }
}
