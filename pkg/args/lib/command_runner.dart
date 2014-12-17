// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args.command_runner;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'src/arg_parser.dart';
import 'src/arg_results.dart';
import 'src/help_command.dart';
import 'src/usage_exception.dart';
import 'src/utils.dart';

export 'src/usage_exception.dart';

/// A class for invoking [Commands] based on raw command-line arguments.
class CommandRunner {
  /// The name of the executable being run.
  ///
  /// Used for error reporting and [usage].
  final String executableName;

  /// A short description of this executable.
  final String description;

  /// A single-line template for how to invoke this executable.
  ///
  /// Defaults to "$executableName <command> [arguments]". Subclasses can
  /// override this for a more specific template.
  String get invocation => "$executableName <command> [arguments]";

  /// Generates a string displaying usage information for the executable.
  ///
  /// This includes usage for the global arguments as well as a list of
  /// top-level commands.
  String get usage => "$description\n\n$_usageWithoutDescription";

  /// An optional footer for [usage].
  ///
  /// If a subclass overrides this to return a string, it will automatically be
  /// added to the end of [usage].
  final String usageFooter = null;

  /// Returns [usage] with [description] removed from the beginning.
  String get _usageWithoutDescription {
    var usage = '''
Usage: $invocation

Global options:
${argParser.usage}

${_getCommandUsage(_commands)}

Run "$executableName help <command>" for more information about a command.''';

    if (usageFooter != null) usage += "\n$usageFooter";
    return usage;
  }

  /// An unmodifiable view of all top-level commands defined for this runner.
  Map<String, Command> get commands =>
      new UnmodifiableMapView(_commands);
  final _commands = new Map<String, Command>();

  /// The top-level argument parser.
  ///
  /// Global options should be registered with this parser; they'll end up
  /// available via [Command.globalResults]. Commands should be registered with
  /// [addCommand] rather than directly on the parser.
  final argParser = new ArgParser();

  CommandRunner(this.executableName, this.description) {
    argParser.addFlag('help', abbr: 'h', negatable: false,
        help: 'Print this usage information.');
    addCommand(new HelpCommand());
  }

  /// Prints the usage information for this runner.
  ///
  /// This is called internally by [run] and can be overridden by subclasses to
  /// control how output is displayed or integrate with a logging system.
  void printUsage() => print(usage);

  /// Throws a [UsageException] with [message].
  void usageException(String message) =>
      throw new UsageException(message, _usageWithoutDescription);

  /// Adds [Command] as a top-level command to this runner.
  void addCommand(Command command) {
    var names = [command.name]..addAll(command.aliases);
    for (var name in names) {
      _commands[name] = command;
      argParser.addCommand(name, command.argParser);
    }
    command._runner = this;
  }

  /// Parses [args] and invokes [Command.run] on the chosen command.
  ///
  /// This always returns a [Future] in case the command is asynchronous. The
  /// [Future] will throw a [UsageError] if [args] was invalid.
  Future run(Iterable<String> args) =>
      new Future.sync(() => runCommand(parse(args)));

  /// Parses [args] and returns the result, converting a [FormatException] to a
  /// [UsageException].
  ///
  /// This is notionally a protected method. It may be overridden or called from
  /// subclasses, but it shouldn't be called externally.
  ArgResults parse(Iterable<String> args) {
    try {
      // TODO(nweiz): if arg parsing fails for a command, print that command's
      // usage, not the global usage.
      return argParser.parse(args);
    } on FormatException catch (error) {
      usageException(error.message);
    }
  }

  /// Runs the command specified by [topLevelResults].
  ///
  /// This is notionally a protected method. It may be overridden or called from
  /// subclasses, but it shouldn't be called externally.
  ///
  /// It's useful to override this to handle global flags and/or wrap the entire
  /// command in a block. For example, you might handle the `--verbose` flag
  /// here to enable verbose logging before running the command.
  Future runCommand(ArgResults topLevelResults) {
    return new Future.sync(() {
      var argResults = topLevelResults;
      var commands = _commands;
      var command;
      var commandString = executableName;

      while (commands.isNotEmpty) {
        if (argResults.command == null) {
          if (argResults.rest.isEmpty) {
            if (command == null) {
              // No top-level command was chosen.
              printUsage();
              return new Future.value();
            }

            command.usageException('Missing subcommand for "$commandString".');
          } else {
            if (command == null) {
              usageException(
                  'Could not find a command named "${argResults.rest[0]}".');
            }

            command.usageException('Could not find a subcommand named '
                '"${argResults.rest[0]}" for "$commandString".');
          }
        }

        // Step into the command.
        argResults = argResults.command;
        command = commands[argResults.name];
        command._globalResults = topLevelResults;
        command._argResults = argResults;
        commands = command._subcommands;
        commandString += " ${argResults.name}";

        if (argResults['help']) {
          command.printUsage();
          return new Future.value();
        }
      }

      // Make sure there aren't unexpected arguments.
      if (!command.takesArguments && argResults.rest.isNotEmpty) {
        command.usageException(
            'Command "${argResults.name}" does not take any arguments.');
      }

      return command.run();
    });
  }
}

/// A single command.
///
/// A command is known as a "leaf command" if it has no subcommands and is meant
/// to be run. Leaf commands must override [run].
///
/// A command with subcommands is known as a "branch command" and cannot be run
/// itself. It should call [addSubcommand] (often from the constructor) to
/// register subcommands.
abstract class Command {
  /// The name of this command.
  String get name;

  /// A short description of this command.
  String get description;

  /// A single-line template for how to invoke this command (e.g. `"pub get
  /// [package]"`).
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner.executableName);

    var invocation = parents.reversed.join(" ");
    return _subcommands.isNotEmpty ?
        "$invocation <subcommand> [arguments]" :
        "$invocation [arguments]";
  }

  /// The command's parent command, if this is a subcommand.
  ///
  /// This will be `null` until [Command.addSubcommmand] has been called with
  /// this command.
  Command get parent => _parent;
  Command _parent;

  /// The command runner for this command.
  ///
  /// This will be `null` until [CommandRunner.addCommand] has been called with
  /// this command or one of its parents.
  CommandRunner get runner {
    if (parent == null) return _runner;
    return parent.runner;
  }
  CommandRunner _runner;

  /// The parsed global argument results.
  ///
  /// This will be `null` until just before [Command.run] is called.
  ArgResults get globalResults => _globalResults;
  ArgResults _globalResults;

  /// The parsed argument results for this command.
  ///
  /// This will be `null` until just before [Command.run] is called.
  ArgResults get argResults => _argResults;
  ArgResults _argResults;

  /// The argument parser for this command.
  ///
  /// Options for this command should be registered with this parser (often in
  /// the constructor); they'll end up available via [argResults]. Subcommands
  /// should be registered with [addSubcommand] rather than directly on the
  /// parser.
  final argParser = new ArgParser();

  /// Generates a string displaying usage information for this command.
  ///
  /// This includes usage for the command's arguments as well as a list of
  /// subcommands, if there are any.
  String get usage => "$description\n\n$_usageWithoutDescription";

  /// An optional footer for [usage].
  ///
  /// If a subclass overrides this to return a string, it will automatically be
  /// added to the end of [usage].
  final String usageFooter = null;

  /// Returns [usage] with [description] removed from the beginning.
  String get _usageWithoutDescription {
    var buffer = new StringBuffer()
        ..writeln('Usage: $invocation')
        ..writeln(argParser.usage);

    if (_subcommands.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_getCommandUsage(_subcommands, isSubcommand: true));
    }

    buffer.writeln();
    buffer.write('Run "${runner.executableName} help" to see global options.');

    if (usageFooter != null) {
      buffer.writeln();
      buffer.write(usageFooter);
    }

    return buffer.toString();
  }

  /// An unmodifiable view of all sublevel commands of this command.
  Map<String, Command> get subcommands =>
      new UnmodifiableMapView(_subcommands);
  final _subcommands = new Map<String, Command>();

  /// Whether or not this command should be hidden from help listings.
  ///
  /// This is intended to be overridden by commands that want to mark themselves
  /// hidden.
  ///
  /// By default, leaf commands are always visible. Branch commands are visible
  /// as long as any of their leaf commands are visible.
  bool get hidden {
    // Leaf commands are visible by default.
    if (_subcommands.isEmpty) return false;

    // Otherwise, a command is hidden if all of its subcommands are.
    return _subcommands.values.every((subcommand) => subcommand.hidden);
  }

  /// Whether or not this command takes positional arguments in addition to
  /// options.
  ///
  /// If false, [CommandRunner.run] will throw a [UsageException] if arguments
  /// are provided. Defaults to true.
  ///
  /// This is intended to be overridden by commands that don't want to receive
  /// arguments. It has no effect for branch commands.
  final takesArguments = true;

  /// Alternate names for this command.
  ///
  /// These names won't be used in the documentation, but they will work when
  /// invoked on the command line.
  ///
  /// This is intended to be overridden.
  final aliases = const <String>[];

  Command() {
    argParser.addFlag('help', abbr: 'h', negatable: false,
        help: 'Print this usage information.');
  }

  /// Runs this command.
  ///
  /// If this returns a [Future], [CommandRunner.run] won't complete until the
  /// returned [Future] does. Otherwise, the return value is ignored.
  run() {
    throw new UnimplementedError("Leaf command $this must implement run().");
  }

  /// Adds [Command] as a subcommand of this.
  void addSubcommand(Command command) {
    var names = [command.name]..addAll(command.aliases);
    for (var name in names) {
      _subcommands[name] = command;
      argParser.addCommand(name, command.argParser);
    }
    command._parent = this;
  }

  /// Prints the usage information for this command.
  ///
  /// This is called internally by [run] and can be overridden by subclasses to
  /// control how output is displayed or integrate with a logging system.
  void printUsage() => print(usage);

  /// Throws a [UsageException] with [message].
  void usageException(String message) =>
      throw new UsageException(message, _usageWithoutDescription);
}

/// Returns a string representation of [commands] fit for use in a usage string.
///
/// [isSubcommand] indicates whether the commands should be called "commands" or
/// "subcommands".
String _getCommandUsage(Map<String, Command> commands,
    {bool isSubcommand: false}) {
  // Don't include aliases.
  var names = commands.keys
      .where((name) => !commands[name].aliases.contains(name));

  // Filter out hidden ones, unless they are all hidden.
  var visible = names.where((name) => !commands[name].hidden);
  if (visible.isNotEmpty) names = visible;

  // Show the commands alphabetically.
  names = names.toList()..sort();
  var length = names.map((name) => name.length).reduce(math.max);

  var buffer = new StringBuffer(
      'Available ${isSubcommand ? "sub" : ""}commands:');
  for (var name in names) {
    buffer.writeln();
    buffer.write('  ${padRight(name, length)}   '
        '${commands[name].description.split("\n").first}');
  }

  return buffer.toString();
}
