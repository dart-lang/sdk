// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Do not call exit() directly. Use VmInteropHandler.exit() instead.
import 'dart:io' as io hide exit;
import 'dart:isolate';

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dart_style/src/cli/format_command.dart';
import 'package:nnbd_migration/migration_cli.dart';
import 'package:pedantic/pedantic.dart';
import 'package:usage/usage.dart';

import 'src/analytics.dart';
import 'src/commands/analyze.dart';
import 'src/commands/compile.dart';
import 'src/commands/create.dart';
import 'src/commands/fix.dart';
import 'src/commands/pub.dart';
import 'src/commands/run.dart';
import 'src/commands/test.dart';
import 'src/core.dart';
import 'src/events.dart';
import 'src/experiments.dart';
import 'src/utils.dart';
import 'src/vm_interop_handler.dart';

/// This is typically called from bin/, but given the length of the method and
/// analytics logic, it has been moved here.
Future<void> runDartdev(List<String> args, SendPort port) async {
  VmInteropHandler.initialize(port);

  int result;

  // The exit code for the dartdev process; null indicates that it has not been
  // set yet. The value is set in the catch and finally blocks below.
  int exitCode;

  // Any caught non-UsageExceptions when running the sub command.
  Object exception;
  StackTrace stackTrace;

  // The Analytics instance used to report information back to Google Analytics;
  // see lib/src/analytics.dart.
  Analytics analytics =
      createAnalyticsInstance(args.contains('--disable-dartdev-analytics'));

  // If we have not printed the analyticsNoticeOnFirstRunMessage to stdout,
  // the user is on a terminal, and the machine is not a bot, then print the
  // disclosure and set analytics.disclosureShownOnTerminal to true.
  if (analytics is DartdevAnalytics &&
      !analytics.disclosureShownOnTerminal &&
      io.stdout.hasTerminal &&
      !isBot()) {
    print(analyticsNoticeOnFirstRunMessage);
    analytics.disclosureShownOnTerminal = true;
  }

  // When `--disable-analytics` or `--enable-analytics` are called we perform
  // the respective intention and print any notices to standard out and exit.
  if (args.contains('--disable-analytics')) {
    // This block also potentially catches the case of (disableAnalytics &&
    // enableAnalytics), in which we favor the disabling of analytics.
    analytics.enabled = false;

    // Alert the user that analytics has been disabled.
    print(analyticsDisabledNoticeMessage);
    VmInteropHandler.exit(0);
    return;
  } else if (args.contains('--enable-analytics')) {
    analytics.enabled = true;

    // Alert the user again that anonymous data will be collected.
    print(analyticsNoticeOnFirstRunMessage);
    VmInteropHandler.exit(0);
    return;
  }

  try {
    final runner = DartdevRunner(args);

    // Run can't be called with the '--disable-dartdev-analytics' flag; remove
    // it if it is contained in args.
    if (args.contains('--disable-dartdev-analytics')) {
      args = List.from(args)..remove('--disable-dartdev-analytics');
    }

    // These flags have a format that can't be handled by package:args, so while
    // they are valid flags we'll assume the VM has verified them by this point.
    args = args
        .where(
          (element) => !(element.contains('--observe') ||
              element.contains('--enable-vm-service')),
        )
        .toList();

    // If ... help pub ... is in the args list, remove 'help', and add '--help'
    // to the end of the list. This will make it possible to use the help
    // command to access subcommands of pub such as `dart help pub publish`; see
    // https://github.com/dart-lang/sdk/issues/42965.
    if (PubUtils.shouldModifyArgs(args, runner.commands.keys.toList())) {
      args = PubUtils.modifyArgs(args);
    }

    // Finally, call the runner to execute the command; see DartdevRunner.
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
    // Set the exitCode, if it wasn't set in the catch block above.
    exitCode ??= result ?? 0;

    // Send analytics before exiting
    if (analytics.enabled) {
      // And now send the exceptions and events to Google Analytics:
      if (exception != null) {
        unawaited(
          analytics.sendException(
              '${exception.runtimeType}\n${sanitizeStacktrace(stackTrace)}',
              fatal: true),
        );
      }

      await analytics.waitForLastPing(
          timeout: const Duration(milliseconds: 200));
    }

    // Set the enabled flag in the analytics object to true. Note: this will not
    // enable the analytics unless the disclosure was shown (terminal detected),
    // and the machine is not detected to be a bot.
    if (analytics.firstRun) {
      analytics.enabled = true;
    }
    analytics.close();
    VmInteropHandler.exit(exitCode);
  }
}

class DartdevRunner extends CommandRunner {
  @override
  final ArgParser argParser =
      ArgParser(usageLineLength: dartdevUsageLineLength);

  static const String dartdevDescription =
      'A command-line utility for Dart development';

  DartdevRunner(List<String> args) : super('dart', '$dartdevDescription.') {
    final bool verbose = args.contains('-v') || args.contains('--verbose');

    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show additional command output.');
    argParser.addFlag('version',
        negatable: false, help: 'Print the Dart SDK version.');
    argParser.addFlag('enable-analytics',
        negatable: false, help: 'Enable anonymous analytics.');
    argParser.addFlag('disable-analytics',
        negatable: false, help: 'Disable anonymous analytics.');

    addExperimentalFlags(argParser, verbose);

    argParser.addFlag('diagnostics',
        negatable: false, help: 'Show tool diagnostic output.', hide: !verbose);

    // A hidden flag to disable analytics on this run, this constructor can be
    // called with this flag, but should be removed before run() is called as
    // the flag has not been added to all sub-commands.
    argParser.addFlag(
      'disable-dartdev-analytics',
      negatable: false,
      help: 'Disable anonymous analytics for this `dart *` run',
      hide: true,
    );

    addCommand(AnalyzeCommand());
    addCommand(CreateCommand(verbose: verbose));
    addCommand(CompileCommand());
    addCommand(FixCommand());
    addCommand(FormatCommand(verbose: verbose));
    addCommand(MigrateCommand(verbose: verbose));
    addCommand(PubCommand());
    addCommand(RunCommand(verbose: verbose));
    addCommand(TestCommand());
  }

  @override
  String get usageFooter =>
      'See https://dart.dev/tools/dart-tool for detailed documentation.';

  @override
  String get invocation =>
      'dart [<vm-flags>] <command|dart-file> [<arguments>]';

  void addExperimentalFlags(ArgParser argParser, bool verbose) {
    List<ExperimentalFeature> features = experimentalFeatures;

    Map<String, String> allowedHelp = {};
    for (ExperimentalFeature feature in features) {
      String suffix =
          feature.isEnabledByDefault ? ' (no-op - enabled by default)' : '';
      allowedHelp[feature.enableString] = '${feature.documentation}$suffix';
    }

    argParser.addMultiOption(
      experimentFlagName,
      valueHelp: 'experiment',
      allowedHelp: verbose ? allowedHelp : null,
      help: 'Enable one or more experimental features '
          '(see dart.dev/go/experiments).',
      hide: !verbose,
    );
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    final stopwatch = Stopwatch()..start();
    assert(!topLevelResults.arguments.contains('--disable-dartdev-analytics'));

    if (topLevelResults.command == null &&
        topLevelResults.arguments.isNotEmpty) {
      final firstArg = topLevelResults.arguments.first;
      // If we make it this far, it means the VM couldn't find the file on disk.
      if (firstArg.endsWith('.dart')) {
        io.stderr.writeln(
            "Error when reading '$firstArg': No such file or directory.");
        // This is the exit code used by the frontend.
        VmInteropHandler.exit(254);
      }
    }

    isDiagnostics = topLevelResults['diagnostics'];

    final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);
    log = isDiagnostics
        ? Logger.verbose(ansi: ansi)
        : Logger.standard(ansi: ansi);

    if (topLevelResults.wasParsed(experimentFlagName)) {
      List<String> experimentIds = topLevelResults[experimentFlagName];
      for (ExperimentalFeature feature in experimentalFeatures) {
        // We allow default true flags, but complain when they are passed in.
        if (feature.isEnabledByDefault &&
            experimentIds.contains(feature.enableString)) {
          print("'${feature.enableString}' is now enabled by default; this "
              'flag is no longer required.');
        }
      }
    }

    var command = topLevelResults.command;
    final commandNames = [];
    while (command != null) {
      commandNames.add(command.name);
      if (command.command == null) break;
      command = command.command;
    }

    final path = commandNames.join('/');
    // Send the screen view to analytics
    unawaited(
      analyticsInstance.sendScreenView(path),
    );

    final topLevelCommand = topLevelResults.command == null
        ? null
        : commands[topLevelResults.command.name];

    try {
      final exitCode = await super.runCommand(topLevelResults);

      if (path != null &&
          analyticsInstance != null &&
          analyticsInstance.enabled) {
        // Send the event to analytics
        unawaited(
          sendUsageEvent(
            analyticsInstance,
            path,
            exitCode: exitCode,
            commandFlags:
                // This finds the options that where explicitly given to the command
                // (and not for an eventual subcommand) without including the actual
                // value.
                //
                // Note that this will also conflate short-options and long-options.
                command?.options?.where(command.wasParsed)?.toList(),
            specifiedExperiments: topLevelCommand?.specifiedExperiments,
          ),
        );
      }

      return exitCode;
    } finally {
      stopwatch.stop();
      if (analyticsInstance.enabled) {
        unawaited(
          analyticsInstance.sendTiming(
            path ?? '',
            stopwatch.elapsedMilliseconds,
            category: 'commands',
          ),
        );
      }
    }
  }
}
