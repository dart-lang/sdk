// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:usage/usage.dart';

import 'commands/analyze.dart';
import 'commands/compile.dart';
import 'commands/create.dart';
import 'commands/fix.dart';
import 'commands/pub.dart';
import 'commands/run.dart';

/// A list of all commands under dartdev.
const List<String> allCommands = [
  'help',
  AnalyzeCommand.cmdName,
  CreateCommand.cmdName,
  CompileCommand.cmdName,
  FixCommand.cmdName,
  formatCmdName,
  migrateCmdName,
  PubCommand.cmdName,
  RunCommand.cmdName,
  'test'
];

/// The [String] identifier `dartdev`, used as the category in the events sent
/// to analytics.
const String _dartdev = 'dartdev';

/// The [String] identifier `format`.
const String formatCmdName = 'format';

/// The [String] identifier `migrate`.
const String migrateCmdName = 'migrate';

/// The separator used to for joining the flag sets sent to analytics.
const String _flagSeparator = ',';

/// When some unknown command is used, for instance `dart foo`, the command is
/// designated with this identifier.
const String _unknownCommand = '<unknown>';

/// The collection of custom dimensions understood by the analytics backend.
/// When adding to this list, first ensure that the custom dimension is
/// defined in the backend, or will be defined shortly after the relevant PR
/// lands. The pattern here matches the flutter cli.
enum CustomDimensions {
  commandExitCode, // cd1
  enabledExperiments, // cd2
  commandFlags, // cd3
}

String cdKey(CustomDimensions cd) => 'cd${cd.index + 1}';

Map<String, String> _useCdKeys(Map<CustomDimensions, String> parameters) {
  return parameters.map(
      (CustomDimensions k, String v) => MapEntry<String, String>(cdKey(k), v));
}

/// Utilities for parsing arguments passed to dartdev.  These utilities have all
/// been marked as static to assist with testing, see events_test.dart.
class ArgParserUtils {
  /// Return the first member from [args] that occurs in [allCommands],
  /// otherwise '<unknown>' is returned.
  ///
  /// 'help' is special cased to have 'dart analyze help', 'dart help analyze',
  /// and 'dart analyze --help' all be recorded as a call to 'help' instead of
  /// 'help' and 'analyze'.
  static String getCommandStr(List<String> args) {
    if (args.contains('help') ||
        args.contains('-h') ||
        args.contains('--help')) {
      return 'help';
    }
    return args.firstWhere((arg) => allCommands.contains(arg),
        orElse: () => _unknownCommand);
  }

  /// Return true if the first character of the passed [String] is '-'.
  static bool isFlag(String arg) => arg != null && arg.startsWith('-');

  /// Returns true if and only if the passed argument equals 'help', '--help' or
  /// '-h'.
  static bool isHelp(String arg) =>
      arg == 'help' || arg == '--help' || arg == '-h';

  /// Given some command in args, return the set of flags after the command.
  static List<String> parseCommandFlags(String command, List<String> args) {
    var result = <String>[];
    if (args == null || args.isEmpty) {
      return result;
    }

    var indexOfCmd = args.indexOf(command);
    if (indexOfCmd < 0) {
      return result;
    }

    for (var i = indexOfCmd + 1; i < args.length; i++) {
      if (!isHelp(args[i]) && isFlag(args[i])) {
        result.add(sanitizeFlag(args[i]));
      }
    }
    return result;
  }

  /// Return the passed flag, only if it is considered a flag, see [isFlag], and
  /// if '=' is in the flag, return only the contents of the left hand side of
  /// the '='.
  static String sanitizeFlag(String arg) {
    if (isFlag(arg)) {
      if (arg.contains('=')) {
        return arg.substring(0, arg.indexOf('='));
      } else {
        return arg;
      }
    }
    return '';
  }
}

/// The [UsageEvent] for the format command.
class FormatUsageEvent extends UsageEvent {
  FormatUsageEvent(
      {String label, @required int exitCode, @required List<String> args})
      : super(formatCmdName, formatCmdName,
            label: label, exitCode: exitCode, args: args);
}

/// The [UsageEvent] for the migrate command.
class MigrateUsageEvent extends UsageEvent {
  MigrateUsageEvent(
      {String label, @required int exitCode, @required List<String> args})
      : super(migrateCmdName, migrateCmdName,
            label: label, exitCode: exitCode, args: args);
}

/// The superclass for all dartdev events, see the [send] method to see what is
/// sent to analytics.
abstract class UsageEvent {
  /// The category stores the name of this cli tool, 'dartdev'. This matches the
  /// pattern from the flutter cli tool which always passes 'flutter' as the
  /// category.
  final String category;

  /// The action is the command, and optionally the subcommand, joined with '/',
  /// an example here is 'pub/get'. The usagePath getter in each of the
  final String action;

  /// The command name being executed here, 'analyze' and 'pub' are examples.
  final String command;

  /// Labels are not used yet used when reporting dartdev analytics, but the API
  /// is included here for possible future use.
  final String label;

  /// The [String] list of arguments passed to dartdev, the list of args is not
  /// passed back via analytics itself, but is used to compute other values such
  /// as the [enabledExperiments] which are passed back as part of analytics.
  final List<String> args;

  /// The exit code returned from this invocation of dartdev.
  final int exitCode;

  /// A comma separated list of enabled experiments passed into the dartdev
  /// command. If the command doesn't use the experiments, they are not reported
  /// in the [UsageEvent].
  final String enabledExperiments;

  /// A comma separated list of flags on this commands
  final String commandFlags;

  UsageEvent(
    this.command,
    this.action, {
    this.label,
    List<String> specifiedExperiments,
    @required this.exitCode,
    @required this.args,
  })  : category = _dartdev,
        enabledExperiments = specifiedExperiments?.join(_flagSeparator),
        commandFlags = ArgParserUtils.parseCommandFlags(command, args)
            .join(_flagSeparator);

  Future send(Analytics analytics) {
    final Map<String, String> parameters =
        _useCdKeys(<CustomDimensions, String>{
      if (exitCode != null)
        CustomDimensions.commandExitCode: exitCode.toString(),
      if (enabledExperiments != null)
        CustomDimensions.enabledExperiments: enabledExperiments,
      if (commandFlags != null) CustomDimensions.commandFlags: commandFlags,
    });
    return analytics.sendEvent(
      category,
      action,
      label: label,
      parameters: parameters,
    );
  }
}
