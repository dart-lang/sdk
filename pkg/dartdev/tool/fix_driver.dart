// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/commands/fix.dart';
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/utils.dart';
import 'package:meta/meta.dart';

Future<void> main(List<String> args) async {
  var runner = FixRunner(logger: Logger.standard());
  var result = await runner.runFix(args);
  return result.returnCode;
}

class CapturedProgress extends Progress {
  final LoggerOutput output;

  bool canceled = false;
  bool finished = false;

  CapturedProgress(this.output, String message) : super(message) {
    output.progress.writeln(message);
  }

  @override
  void cancel() {
    canceled = true;
  }

  @override
  void finish({String message, bool showTiming = false}) {
    // todo (pq): consider capturing / tracking finish display updates.
    finished = true;
  }
}

class CapturingLogger implements Logger {
  final LoggerOutput output = LoggerOutput();

  @override
  final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);

  @override
  bool isVerbose;

  CapturingLogger({this.isVerbose = false});

  @override
  void flush() {
    // deprecated.
  }

  @override
  Progress progress(String message) => CapturedProgress(output, message);

  @override
  void stderr(String message) {
    output.stderr.writeln(message);
  }

  @override
  void stdout(String message) {
    output.stdout.writeln(message);
  }

  @override
  void trace(String message) {
    output.trace.writeln(message);
  }

  @override
  void write(String message) {
    output.stdout.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    output.stdout.writeCharCode(charCode);
  }
}

class FixResult<T extends Logger> {
  /// The value returned by [FixCommand.run].
  final int returnCode;

  /// The logger used in driving fixes.
  final T logger;

  FixResult(this.logger, this.returnCode);
}

class FixRunner<T extends Logger> extends CommandRunner<int> {
  final _supportedOptions = ['dry-run', 'apply'];

  T logger;

  @override
  final ArgParser argParser = ArgParser(
    usageLineLength: dartdevUsageLineLength,
    allowTrailingOptions: false,
  );

  FixRunner({@required this.logger})
      : super('fix_runner',
            'A command-line utility for testing the `dart fix` command.') {
    addCommand(FixCommand());
    _supportedOptions.forEach(argParser.addOption);
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    var result = await super.runCommand(topLevelResults);
    return result;
  }

  Future<FixResult<T>> runFix(List<String> args) async {
    log = logger;
    var argResults = argParser.parse(['fix', ...?args]);
    var result = await runCommand(argResults);
    return FixResult(logger, result);
  }
}

class LoggerOutput {
  /// Messages reported to progress.
  final StringBuffer progress = StringBuffer();

  /// Messages reported to stdout.
  final StringBuffer stdout = StringBuffer();

  /// Messages reported to stderr.
  final StringBuffer stderr = StringBuffer();

  /// Messages reported to trace.
  final StringBuffer trace = StringBuffer();
}
