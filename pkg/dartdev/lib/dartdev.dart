// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Do not call exit() directly. Use VmInteropHandler.exit() instead.
import 'dart:async';
import 'dart:io' as io hide exit;
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dart_style/src/cli/format_command.dart';
import 'package:meta/meta.dart';
import 'package:pub/pub.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'src/commands/analyze.dart';
import 'src/commands/build.dart';
import 'src/commands/compilation_server.dart';
import 'src/commands/compile.dart';
import 'src/commands/create.dart';
import 'src/commands/debug_adapter.dart';
import 'src/commands/development_service.dart';
import 'src/commands/devtools.dart';
import 'src/commands/doc.dart';
import 'src/commands/fix.dart';
import 'src/commands/info.dart';
import 'src/commands/language_server.dart';
import 'src/commands/run.dart';
import 'src/commands/test.dart';
import 'src/commands/tooling_daemon.dart';
import 'src/core.dart';
import 'src/experiments.dart';
import 'src/unified_analytics.dart';
import 'src/utils.dart';
import 'src/vm_interop_handler.dart';

/// This is typically called from bin/, but given the length of the method and
/// analytics logic, it has been moved here.
Future<void> runDartdev(List<String> args, SendPort? port) async {
  int? exitCode = 1;
  try {
    VmInteropHandler.initialize(port);
    // Call the runner to execute the command; see DartdevRunner.
    final runner = DartdevRunner(args, vmArgs: io.Platform.executableArguments);
    exitCode = await runner.run(args);
  } on UsageException catch (e) {
    // TODO(sigurdm): It is unclear when a UsageException gets to here, and
    // when it is in DartdevRunner.runCommand.
    io.stderr.writeln('$e');
    exitCode = 64;
  } catch (e, st) {
    // Unexpected error encountered.
    io.stderr.writeln('An unexpected error was encountered by the Dart CLI.');
    io.stderr.writeln('Please file an issue at '
        'https://github.com/dart-lang/sdk/issues/new with the following '
        'details:\n');
    io.stderr.writeln("Invocation: 'dart ${args.join(' ')}'");
    io.stderr.writeln("Exception: '$e'");
    io.stderr.writeln('Stack Trace:');
    io.stderr.writeln(st.toString());
    exitCode = 255;
  } finally {
    VmInteropHandler.exit(exitCode);
  }
}

class DartdevRunner extends CommandRunner<int> {
  static const String dartdevDescription =
      'A command-line utility for Dart development';

  @override
  final ArgParser argParser;

  final bool verbose;

  final List<String> vmEnabledExperiments;

  Analytics? _unifiedAnalytics;
  final bool _isAnalyticsTest;

  DartdevRunner(
    List<String> args, {
    Analytics? analyticsOverride,
    bool isAnalyticsTest = false,
    List<String> vmArgs = const [],
  })  : verbose = args.contains('-v') || args.contains('--verbose'),
        argParser = globalDartdevOptionsParser(
            verbose: args.contains('-v') || args.contains('--verbose')),
        vmEnabledExperiments = parseVmEnabledExperiments(vmArgs),
        _unifiedAnalytics = analyticsOverride,
        _isAnalyticsTest = isAnalyticsTest,
        super('dart', '$dartdevDescription.') {
    // The list of commands should be kept in sync with
    // `DartDevIsolate::ShouldParseCommand` in `runtime/bin/dartdev_isolate.cc`.
    addCommand(AnalyzeCommand(verbose: verbose));
    addCommand(CompilationServerCommand(verbose: verbose));
    final nativeAssetsExperimentEnabled =
        nativeAssetsEnabled(vmEnabledExperiments);
    if (nativeAssetsExperimentEnabled) {
      addCommand(BuildCommand(verbose: verbose));
    }
    addCommand(CompileCommand(
      verbose: verbose,
      nativeAssetsExperimentEnabled: nativeAssetsExperimentEnabled,
    ));
    addCommand(CreateCommand(verbose: verbose));
    addCommand(DebugAdapterCommand(verbose: verbose));
    addCommand(DevelopmentServiceCommand(verbose: verbose));
    addCommand(DevToolsCommand(verbose: verbose));
    addCommand(DocCommand(verbose: verbose));
    addCommand(FixCommand(verbose: verbose));
    addCommand(FormatCommand(verbose: verbose));
    addCommand(InfoCommand(verbose: verbose));
    addCommand(LanguageServerCommand(verbose: verbose));
    addCommand(pubCommand(isVerbose: () => verbose));
    addCommand(RunCommand(
      verbose: verbose,
      nativeAssetsExperimentEnabled: nativeAssetsExperimentEnabled,
    ));
    addCommand(TestCommand(
      nativeAssetsExperimentEnabled: nativeAssetsExperimentEnabled,
    ));
    addCommand(ToolingDaemonCommand(verbose: verbose));
  }

  @visibleForTesting
  Analytics get unifiedAnalytics => _unifiedAnalytics!;

  @override
  String get invocation =>
      'dart ${verbose ? '[vm-options] ' : ''}<command|dart-file> [arguments]';

  @override
  String get usageFooter =>
      'See https://dart.dev/tools/dart-tool for detailed documentation.';

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    final stopwatch = Stopwatch()..start();

    // We don't want to run analytics when we're running in a CI environment
    // unless we're explicitly testing analytics for dartdev.
    final implicitlySuppressAnalytics = isBot() && !_isAnalyticsTest;
    bool suppressAnalytics = !topLevelResults.flag('analytics') ||
        topLevelResults.flag('suppress-analytics') ||
        implicitlySuppressAnalytics;

    if (topLevelResults.wasParsed('analytics')) {
      io.stderr.writeln(
          '`--[no-]analytics` is deprecated.  Use `--suppress-analytics` '
          'to disable analytics for one run instead.');
    }
    final enableAnalytics = topLevelResults.flag('enable-analytics');
    final disableAnalytics = topLevelResults.flag('disable-analytics');

    if (!implicitlySuppressAnalytics &&
        suppressAnalytics &&
        (enableAnalytics || disableAnalytics)) {
      // This isn't an error if we're implicitly disabling analytics because
      // we're running in a CI environment.
      io.stderr.writeln('`--suppress-analytics` cannot be used with either'
          ' `--enable-analytics` or `--disable-analytics`.');
      return 254;
    }
    // The Analytics instance used to report information back to Google Analytics;
    // see lib/src/unified_analytics.dart.
    _unifiedAnalytics ??= createUnifiedAnalytics(
      disableAnalytics: suppressAnalytics,
    );

    // If we have not printed the analytics notification to stdout, the user is
    // on a terminal, and the machine is not a bot, then print the disclosure.
    bool analyticsMessagePrinted = false;
    if (unifiedAnalytics.shouldShowMessage &&
        io.stdout.hasTerminal &&
        !isBot()) {
      print(unifiedAnalytics.getConsentMessage);
      unifiedAnalytics.clientShowedMessage();
      analyticsMessagePrinted = true;
    }

    // When `--disable-analytics` or `--enable-analytics` are called we perform
    // the respective intention and print any notices to standard out and exit.
    if (disableAnalytics) {
      // Disable sending data via the unified analytics package.
      await unifiedAnalytics.setTelemetry(false);
      await unifiedAnalytics.close();

      // Alert the user that analytics has been disabled.
      print(analyticsDisabledNoticeMessage);
      return 0;
    } else if (enableAnalytics) {
      // Enable sending data via the unified analytics package.
      await unifiedAnalytics.setTelemetry(true);
      await unifiedAnalytics.close();

      // Alert the user again that data will be collected.
      if (!analyticsMessagePrinted) {
        print(unifiedAnalytics.getConsentMessage);
      }
      return 0;
    }

    if (topLevelResults.command == null &&
        topLevelResults.arguments.isNotEmpty) {
      final firstArg = topLevelResults.arguments.first;
      // If we make it this far, it means the VM couldn't find the file on disk.
      if (firstArg.endsWith('.dart')) {
        io.stderr.writeln(
            "Error when reading '$firstArg': No such file or directory.");
        // This is the exit code used by the frontend.
        return 254;
      }
    }

    if (topLevelResults.flag('diagnostics')) {
      log = Logger.verbose(ansi: ansi);
    }

    var command = topLevelResults.command;
    final commandNames = [];
    while (command != null) {
      commandNames.add(command.name);
      if (command.command == null) break;
      command = command.command;
    }

    // The exit code for the dartdev process; null indicates that it has not been
    // set yet. The value is set in the catch and finally blocks below.
    int? exitCode;

    // Any caught non-UsageExceptions when running the sub command.
    try {
      exitCode = await super.runCommand(topLevelResults);
      if (unifiedAnalytics.telemetryEnabled) {
        // Send the event to analytics
        final path = commandNames.join('/');
        final experiments = topLevelResults.enabledExperiments
          ..sort((a, b) => a.compareTo(b));
        unifiedAnalytics.send(
          Event.dartCliCommandExecuted(
            name: path,
            enabledExperiments: experiments.join(','),
          ),
        );
      }
    } on UsageException catch (e) {
      io.stderr.writeln('$e');
      exitCode = 64;
    } catch (e, st) {
      // Set the exception and stack trace only for non-UsageException cases:
      io.stderr.writeln('$e');
      io.stderr.writeln('$st');
      exitCode = 1;
    } finally {
      stopwatch.stop();

      // Set the exitCode, if it wasn't set in the catch block above.
      exitCode ??= 0;
      await unifiedAnalytics.close();
    }

    return exitCode;
  }
}
