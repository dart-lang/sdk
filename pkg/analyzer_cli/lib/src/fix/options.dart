import 'dart:io';

import 'package:analyzer/src/util/sdk.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';

@visibleForTesting
StringSink errorSink = stderr;

@visibleForTesting
StringSink outSink = stdout;

@visibleForTesting
ExitHandler exitHandler = exit;

@visibleForTesting
typedef void ExitHandler(int code);

/// Command line options for `dartfix`.
class Options {
  String sdkPath;
  List<String> analysisRoots;
  bool verbose;

  static Options parse(List<String> args,
      {printAndFail(String msg) = printAndFail}) {
    final parser = new ArgParser(allowTrailingOptions: true);

    parser
      ..addOption(_sdkPathOption, help: 'The path to the Dart SDK.')
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
    if (options.analysisRoots == null || options.analysisRoots.isEmpty) {
      errorSink.writeln('Expected at least one file or directory to analyze.');
      _showUsage(parser);
      exitHandler(15);
      return null; // Only reachable in testing.
    }

    return options;
  }

  Options._fromArgs(ArgResults results)
      : analysisRoots = results.rest,
        sdkPath = results[_sdkPathOption] as String,
        verbose = results[_verboseOption] as bool;

  static _showUsage(ArgParser parser) {
    errorSink.writeln(
        'Usage: $_binaryName [options...] <directory or list of files>');
    errorSink.writeln('');
    errorSink.writeln(parser.usage);
  }
}

const _binaryName = 'dartfix';
const _helpOption = 'help';
const _sdkPathOption = 'dart-sdk';
const _verboseOption = 'verbose';

/// Print the given [message] to stderr and exit with the given [exitCode].
void printAndFail(String message, {int exitCode: 15}) {
  errorSink.writeln(message);
  exitHandler(exitCode);
}
