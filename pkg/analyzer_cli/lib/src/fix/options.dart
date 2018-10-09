// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/util/sdk.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

@visibleForTesting
StringSink errorSink = stderr;

@visibleForTesting
StringSink outSink = stdout;

@visibleForTesting
Stream<List<int>> inputStream = stdin;

@visibleForTesting
ExitHandler exitHandler = exit;

@visibleForTesting
typedef void ExitHandler(int code);

/// Command line options for `dartfix`.
class Options {
  List<String> targets;
  List<String> analysisRoots;
  bool dryRun;
  String sdkPath;
  bool verbose;

  static Options parse(List<String> args,
      {printAndFail(String msg) = printAndFail, bool checkExists = true}) {
    final parser = new ArgParser(allowTrailingOptions: true);

    parser
      ..addOption(_sdkPathOption, help: 'The path to the Dart SDK.')
      ..addFlag(_dryRunOption,
          abbr: 'n',
          help: 'Calculate and display the recommended changes,'
              ' but exit before applying them',
          defaultsTo: false,
          negatable: false)
      ..addFlag(_helpOption,
          abbr: 'h',
          help:
              'Display this help message. Add --verbose to show hidden options.',
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
      errorSink.writeln(e.message);
      _showUsage(parser);
      exitHandler(15);
      return null; // Only reachable in testing.
    }

    if (results[_helpOption] as bool) {
      _showUsage(parser);
      exitHandler(0);
      return null; // Only reachable in testing.
    }

    Options options = new Options._fromArgs(results);

    // Check Dart SDK, and infer if unspecified.
    options.sdkPath ??= getSdkPath(args);
    String sdkPath = options.sdkPath;
    if (sdkPath == null) {
      errorSink.writeln('No Dart SDK found.');
      _showUsage(parser);
      return null; // Only reachable in testing.
    }
    if (!(new Directory(sdkPath)).existsSync()) {
      printAndFail('Invalid Dart SDK path: $sdkPath');
      return null; // Only reachable in testing.
    }

    // Check for files and/or directories to analyze.
    if (options.targets == null || options.targets.isEmpty) {
      errorSink.writeln('Expected at least one file or directory to analyze.');
      _showUsage(parser);
      exitHandler(15);
      return null; // Only reachable in testing.
    }

    // Normalize and verify paths
    options.targets =
        options.targets.map<String>(makeAbsoluteAndNormalize).toList();
    for (String target in options.targets) {
      // TODO(danrubel): Consider a driver context for existence checks,
      // reporting errors, and the like.
      if (checkExists && !_exists(target)) {
        errorSink.writeln('Expected an existing file or directory: $target');
        _showUsage(parser);
        exitHandler(15);
        return null; // Only reachable in testing.
      }
      options._addAnalysisRoot(target);
    }

    return options;
  }

  Options._fromArgs(ArgResults results)
      : targets = results.rest,
        analysisRoots = <String>[],
        dryRun = results[_dryRunOption] as bool,
        sdkPath = results[_sdkPathOption] as String,
        verbose = results[_verboseOption] as bool;

  void _addAnalysisRoot(String target) {
    // TODO(danrubel): Consider finding the directory containing `pubspec.yaml`
    // and using that as the analysis root
    String parent = target.endsWith('.dart') ? dirname(target) : target;
    for (String root in analysisRoots) {
      if (root == parent || isWithin(root, parent)) {
        return;
      }
    }
    analysisRoots.removeWhere((String root) => isWithin(parent, root));
    analysisRoots.add(parent);
  }

  static _showUsage(ArgParser parser) {
    errorSink.writeln(
        'Usage: $_binaryName [options...] <directory or list of files>');
    errorSink.writeln('');
    errorSink.writeln(parser.usage);
  }
}

const _binaryName = 'dartfix';
const _dryRunOption = 'dry-run';
const _helpOption = 'help';
const _sdkPathOption = 'dart-sdk';
const _verboseOption = 'verbose';

String makeAbsoluteAndNormalize(String target) {
  if (!isAbsolute(target)) {
    target = join(Directory.current.path, target);
  }
  return normalize(target);
}

/// Print the given [message] to stderr and exit with the given [exitCode].
void printAndFail(String message, {int exitCode: 15}) {
  errorSink.writeln(message);
  exitHandler(exitCode);
}

bool _exists(String target) =>
    FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound;
