// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartfix/src/context.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

/// Command line options for `dartfix`.
class Options {
  final Context context;
  Logger logger;

  List<String> targets;
  final String sdkPath;

  final bool requiredFixes;
  final List<String> includeFixes;
  final List<String> excludeFixes;

  final bool force;
  final bool listFixes;
  final bool overwrite;
  final bool useColor;
  final bool verbose;

  static Options parse(List<String> args, {Context context, Logger logger}) {
    final parser = new ArgParser(allowTrailingOptions: true)
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
      ..addFlag(listOption,
          abbr: 'l',
          help: 'Display a list of fixes that can be applied.',
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
      ..addSeparator('Miscelaneous:')
      ..addFlag(_colorOption,
          help: 'Use ansi colors when printing messages.',
          defaultsTo: Ansi.terminalSupportsAnsi)
      ..addFlag(_helpOption,
          abbr: 'h',
          help: 'Display this help message.',
          defaultsTo: false,
          negatable: false)
      ..addFlag(_verboseOption,
          abbr: 'v',
          defaultsTo: false,
          help: 'Verbose output.',
          negatable: false);

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

    if (options.listFixes) {
      _showUsage(parser, logger, showListHint: false);
      return options;
    }

    // Validate the Dart SDK location
    String sdkPath = options.sdkPath;
    if (sdkPath == null) {
      logger.stderr('No Dart SDK found.');
      _showUsage(parser, logger);
      context.exit(15);
    }
    if (!context.exists(sdkPath)) {
      logger.stderr('Invalid Dart SDK path: $sdkPath');
      _showUsage(parser, logger);
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
      : force = results[forceOption] as bool,
        includeFixes =
            (results[includeOption] as List ?? []).cast<String>().toList(),
        excludeFixes =
            (results[excludeOption] as List ?? []).cast<String>().toList(),
        listFixes = results[listOption] as bool,
        overwrite = results[overwriteOption] as bool,
        requiredFixes = results[requiredOption] as bool,
        sdkPath = _getSdkPath(),
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

  static String _getSdkPath() {
    return Platform.environment['DART_SDK'] != null
        ? Platform.environment['DART_SDK']
        : path.dirname(path.dirname(Platform.resolvedExecutable));
  }

  static _showUsage(ArgParser parser, Logger logger,
      {bool showListHint = true}) {
    logger.stderr('Usage: $_binaryName [options...] <directory paths>');
    logger.stderr('');
    logger.stderr(parser.usage);
    logger.stderr('''

If neither --$includeOption nor --$requiredOption is specified, then all fixes
will be applied. Any fixes specified using --$excludeOption will not be applied
regardless of whether they are required or specifed using --$includeOption.''');
    if (showListHint) {
      logger.stderr('''

Use --list to display the fixes that can be specified
using either --$includeOption or --$excludeOption.''');
    }
  }
}

const _binaryName = 'dartfix';
const _colorOption = 'color';
const forceOption = 'force';
const _helpOption = 'help';
const overwriteOption = 'overwrite';
const _verboseOption = 'verbose';

// options only supported by server 1.22.2 and greater
const excludeOption = 'exclude';
const includeOption = 'include';
const listOption = 'list';
const requiredOption = 'required';
