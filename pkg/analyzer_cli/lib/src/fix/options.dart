// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_cli/src/fix/context.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Command line options for `dartfix`.
class Options {
  final Context context;

  List<String> targets;
  bool dryRun;
  bool force;
  String sdkPath;
  bool verbose;

  Options(this.context);

  static Options parse(List<String> args, Context context) {
    Options options = new Options(context ?? new Context());
    final parser = new ArgParser(allowTrailingOptions: true);

    parser
      ..addOption(_sdkPathOption, help: 'The path to the Dart SDK.')
      ..addFlag(_dryRunOption,
          abbr: 'n',
          help: 'Calculate and display the recommended changes,'
              ' but exit before applying them',
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
          negatable: false);

    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (e) {
      context.stderr.writeln(e.message);
      _showUsage(parser, context);
      context.exit(15);
    }

    if (results[_helpOption] as bool) {
      _showUsage(parser, context);
      context.exit(0);
    }

    options._fromArgs(results);

    // Check Dart SDK, and infer if unspecified.
    options.sdkPath ??= getSdkPath(args);
    String sdkPath = options.sdkPath;
    if (sdkPath == null) {
      context.stderr.writeln('No Dart SDK found.');
      _showUsage(parser, context);
    }
    if (!context.exists(sdkPath)) {
      context.stderr.writeln('Invalid Dart SDK path: $sdkPath');
      context.exit(15);
    }

    // Check for files and/or directories to analyze.
    if (options.targets == null || options.targets.isEmpty) {
      context.stderr
          .writeln('Expected at least one file or directory to analyze.');
      _showUsage(parser, context);
      context.exit(15);
    }

    // Normalize and verify paths
    options.targets =
        options.targets.map<String>(options.makeAbsoluteAndNormalize).toList();
    for (String target in options.targets) {
      if (!context.isDirectory(target)) {
        if (!context.exists(target)) {
          context.stderr.writeln('Target does not exist: $target');
        } else {
          context.stderr.writeln('Expected directory, but found: $target');
        }
        _showUsage(parser, context);
        context.exit(15);
      }
    }

    if (options.verbose) {
      context.print('Targets:');
      for (String target in options.targets) {
        context.print('  $target');
      }
    }

    return options;
  }

  void _fromArgs(ArgResults results) {
    targets = results.rest;
    dryRun = results[_dryRunOption] as bool;
    force = results[forceOption] as bool;
    sdkPath = results[_sdkPathOption] as String;
    verbose = results[_verboseOption] as bool;
  }

  String makeAbsoluteAndNormalize(String target) {
    if (!path.isAbsolute(target)) {
      target = path.join(context.workingDir, target);
    }
    return path.normalize(target);
  }

  static _showUsage(ArgParser parser, Context context) {
    context.stderr
        .writeln('Usage: $_binaryName [options...] <directory paths>');
    context.stderr.writeln('');
    context.stderr.writeln(parser.usage);
  }
}

const _binaryName = 'dartfix';
const _dryRunOption = 'dry-run';
const forceOption = 'force';
const _helpOption = 'help';
const _sdkPathOption = 'dart-sdk';
const _verboseOption = 'verbose';
