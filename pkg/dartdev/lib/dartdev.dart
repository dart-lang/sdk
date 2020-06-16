// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:nnbd_migration/migration_cli.dart';
import 'package:usage/usage.dart';

import 'src/analytics.dart';
import 'src/commands/analyze.dart';
import 'src/commands/create.dart';
import 'src/commands/format.dart';
import 'src/commands/pub.dart';
import 'src/commands/run.dart';
import 'src/commands/test.dart';
import 'src/core.dart';

/// This is typically called from bin/, but given the length of the method and
/// analytics logic, it has been moved here. Also note that this method calls
/// [io.exit(code)] directly.
void runDartdev(List<String> args) async {
  final stopwatch = Stopwatch();
  dynamic result;

  // The Analytics instance used to report information back to Google Analytics,
  // see lib/src/analytics.dart.
  Analytics analytics;

  // The exit code for the dartdev process, null indicates that it has not yet
  // been set yet. The value is set in the catch and finally blocks below.
  int exitCode;

  // Any caught non-UsageExceptions when running the sub command
  Exception exception;
  StackTrace stackTrace;

  var runner;

  analytics =
      createAnalyticsInstance(args.contains('--disable-dartdev-analytics'));

  // On the first run, print the message to alert users that anonymous data will
  // be collected by default.
  if (analytics.firstRun) {
    print(analyticsNoticeOnFirstRunMessage);
  }

  // When `--disable-analytics` or `--enable-analytics` are called we perform
  // the respective intention and print any notices to standard out and exit.
  if (args.contains('--disable-analytics')) {
    // This block also potentially catches the case of (disableAnalytics &&
    // enableAnalytics), in which we favor the disabling of analytics.
    analytics.enabled = false;

    // Alert the user that analytics have been disabled:
    print(analyticsDisabledNoticeMessage);
    io.exit(0);
  } else if (args.contains('--enable-analytics')) {
    analytics.enabled = true;

    // Alert the user again that anonymous data will be collected:
    print(analyticsNoticeOnFirstRunMessage);
    io.exit(0);
  }

  var commandName;

  try {
    stopwatch.start();
    runner = DartdevRunner(args);
    // Run can't be called with the '--disable-dartdev-analytics' flag, remove
    // it if it is contained in args.
    if (args.contains('--disable-dartdev-analytics')) {
      args = List.from(args)..remove('--disable-dartdev-analytics');
    }

    // Before calling to run, send the first ping to analytics to have the first
    // ping, as well as the command itself, running in parallel.
    if (analytics.enabled) {
      analytics.setSessionValue(flagsParam, getFlags(args));
      commandName = getCommandStr(args, runner.commands.keys.toList());
      // ignore: unawaited_futures
      analytics.sendEvent(eventCategory, commandName);
    }

    // Finally, call the runner to execute the command, see DartdevRunner.
    result = await runner.run(args);
  } catch (e, st) {
    if (e is UsageException) {
      io.stderr.writeln('$e');
      exitCode = 64;
    } else {
      // Set the exception and stack trace only for non-UsageException cases:
      exception = e;
      stackTrace = st;
      io.stderr.writeln('$e');
      io.stderr.writeln('$st');
      exitCode = 1;
    }
  } finally {
    stopwatch.stop();

    // Set the exitCode, if it wasn't set in the catch block above.
    if (exitCode == null) {
      exitCode = result is int ? result : 0;
    }

    // Send analytics before exiting
    if (analytics.enabled) {
      analytics.setSessionValue(exitCodeParam, exitCode);
      // ignore: unawaited_futures
      analytics.sendTiming(commandName, stopwatch.elapsedMilliseconds,
          category: 'commands');

      // And now send the exceptions and events to Google Analytics:
      if (exception != null) {
        // ignore: unawaited_futures
        analytics.sendException(
            '${exception.runtimeType}\n${sanitizeStacktrace(stackTrace)}',
            fatal: true);
      }

      await analytics.waitForLastPing(timeout: Duration(milliseconds: 200));
    }

    // As the notification to the user read on the first run, analytics are
    // enabled by default, on the first run only.
    if (analytics.firstRun) {
      analytics.enabled = true;
    }
    analytics.close();
    io.exit(exitCode);
  }
}

class DartdevRunner<int> extends CommandRunner {
  static const String dartdevDescription =
      'A command-line utility for Dart development';

  DartdevRunner(List<String> args) : super('dart', '$dartdevDescription.') {
    final bool verbose = args.contains('-v') || args.contains('--verbose');

    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output.');
    argParser.addFlag('version',
        negatable: false, help: 'Print the Dart SDK version.');
    argParser.addFlag('enable-analytics',
        negatable: false, help: 'Enable anonymous analytics.');
    argParser.addFlag('disable-analytics',
        negatable: false, help: 'Disable anonymous analytics.');

    // A hidden flag to disable analytics on this run, this constructor can be
    // called with this flag, but should be removed before run() is called as
    // the flag has not been added to all sub-commands.
    argParser.addFlag('disable-dartdev-analytics',
        negatable: false,
        help: 'Disable anonymous analytics for this `dart *` run',
        hide: true);

    addCommand(AnalyzeCommand(verbose: verbose));
    addCommand(CreateCommand(verbose: verbose));
    addCommand(FormatCommand(verbose: verbose));
    addCommand(MigrateCommand(verbose: verbose));
    addCommand(PubCommand(verbose: verbose));
    addCommand(RunCommand(verbose: verbose));
    addCommand(TestCommand(verbose: verbose));
  }

  @override
  String get invocation =>
      'dart [<vm-flags>] <command|dart-file> [<arguments>]';

  @override
  Future<int> runCommand(ArgResults results) async {
    assert(!results.arguments.contains('--disable-dartdev-analytics'));
    if (results.command == null && results.arguments.isNotEmpty) {
      final firstArg = results.arguments.first;
      // If we make it this far, it means the VM couldn't find the file on disk.
      if (firstArg.endsWith('.dart')) {
        io.stderr.writeln(
            "Error when reading '$firstArg': No such file or directory.");
        // This is the exit code used by the frontend.
        io.exit(254);
      }
    }
    isVerbose = results['verbose'];

    final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);
    log = isVerbose ? Logger.verbose(ansi: ansi) : Logger.standard(ansi: ansi);

    return await super.runCommand(results);
  }
}
