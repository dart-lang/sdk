// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command;

import 'dart:async';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'command/build.dart';
import 'command/cache.dart';
import 'command/deps.dart';
import 'command/downgrade.dart';
import 'command/get.dart';
import 'command/global.dart';
import 'command/help.dart';
import 'command/lish.dart';
import 'command/list_package_dirs.dart';
import 'command/run.dart';
import 'command/serve.dart';
import 'command/upgrade.dart';
import 'command/uploader.dart';
import 'command/version.dart';
import 'entrypoint.dart';
import 'exceptions.dart';
import 'log.dart' as log;
import 'global_packages.dart';
import 'system_cache.dart';
import 'utils.dart';

/// The base class for commands for the pub executable.
///
/// A command may either be a "leaf" command or it may be a parent for a set
/// of subcommands. Only leaf commands are ever actually invoked. If a command
/// has subcommands, then one of those must always be chosen.
abstract class PubCommand {
  /// The commands that pub understands.
  static final Map<String, PubCommand> mainCommands = _initCommands();

  /// The top-level [ArgParser] used to parse the pub command line.
  static final pubArgParser = _initArgParser();

  /// Displays usage information for the app.
  static void printGlobalUsage() {
    // Build up a buffer so it shows up as a single log entry.
    var buffer = new StringBuffer();
    buffer.writeln('Pub is a package manager for Dart.');
    buffer.writeln();
    buffer.writeln('Usage: pub <command> [arguments]');
    buffer.writeln();
    buffer.writeln('Global options:');
    buffer.writeln(pubArgParser.getUsage());
    buffer.writeln();
    buffer.write(_listCommands(mainCommands));
    buffer.writeln();
    buffer.writeln(
        'Run "pub help [command]" for more information about a command.');
    buffer.writeln(
        'See http://dartlang.org/tools/pub for detailed documentation.');

    log.message(buffer);
  }

  /// Fails with a usage error [message] when trying to select from one of
  /// [commands].
  static void usageErrorWithCommands(Map<String, PubCommand> commands,
                                String message) {
    throw new UsageException(message, _listCommands(commands));
  }

  /// Writes [commands] in a nicely formatted list to [buffer].
  static String _listCommands(Map<String, PubCommand> commands) {
    // If there are no subcommands, do nothing.
    if (commands.isEmpty) return "";

    // Don't include aliases.
    var names = commands.keys
        .where((name) => !commands[name].aliases.contains(name));

    // Filter out hidden ones, unless they are all hidden.
    var visible = names.where((name) => !commands[name].hidden);
    if (visible.isNotEmpty) names = visible;

    // Show the commands alphabetically.
    names = ordered(names);
    var length = names.map((name) => name.length).reduce(math.max);
    var isSubcommand = commands != mainCommands;

    var buffer = new StringBuffer();
    buffer.writeln('Available ${isSubcommand ? "sub" : ""}commands:');
    for (var name in names) {
      buffer.writeln('  ${padRight(name, length)}   '
          '${commands[name].description.split("\n").first}');
    }

    return buffer.toString();
  }

  SystemCache get cache => _cache;
  SystemCache _cache;

  GlobalPackages get globals => _globals;
  GlobalPackages _globals;

  /// The parsed options for this command.
  ArgResults get commandOptions => _commandOptions;
  ArgResults _commandOptions;

  Entrypoint entrypoint;

  /// A one-line description of this command.
  String get description;

  /// If the command is undocumented and should not appear in command listings,
  /// this will be `true`.
  bool get hidden {
    // Leaf commands are visible by default.
    if (subcommands.isEmpty) return false;

    // Otherwise, a command is hidden if all of its subcommands are.
    return subcommands.values.every((subcommand) => subcommand.hidden);
  }

  /// How to invoke this command (e.g. `"pub get [package]"`).
  String get usage;

  /// The URL for web documentation for this command.
  String get docUrl => null;

  /// Whether or not this command requires [entrypoint] to be defined.
  ///
  /// If false, pub won't look for a pubspec and [entrypoint] will be null when
  /// the command runs. This only needs to be set in leaf commands.
  bool get requiresEntrypoint => true;

  /// Whether or not this command takes arguments in addition to options.
  ///
  /// If false, pub will exit with an error if arguments are provided. This
  /// only needs to be set in leaf commands.
  bool get takesArguments => false;

  /// Override this and return `false` to disallow trailing options from being
  /// parsed after a non-option argument is parsed.
  bool get allowTrailingOptions => true;

  /// Alternate names for this command.
  ///
  /// These names won't be used in the documentation, but they will work when
  /// invoked on the command line.
  final aliases = const <String>[];

  /// The [ArgParser] for this command.
  ArgParser get commandParser => _commandParser;
  ArgParser _commandParser;

  /// Subcommands exposed by this command.
  ///
  /// If empty, then this command has no subcommands. Otherwise, a subcommand
  /// must be specified by the user. In that case, this command's [onRun] will
  /// not be called and the subcommand's will.
  final subcommands = <String, PubCommand>{};

  /// Override this to use offline-only sources instead of hitting the network.
  ///
  /// This will only be called before the [SystemCache] is created. After that,
  /// it has no effect. This only needs to be set in leaf commands.
  bool get isOffline => false;

  PubCommand() {
    _commandParser = new ArgParser(allowTrailingOptions: allowTrailingOptions);

    // Allow "--help" after a command to get command help.
    commandParser.addFlag('help', abbr: 'h', negatable: false,
        help: 'Print usage information for this command.');
  }

  /// Runs this command using a system cache at [cacheDir] with [options].
  Future run(String cacheDir, ArgResults options) {
    _commandOptions = options;

    _cache = new SystemCache.withSources(cacheDir, isOffline: isOffline);
    _globals = new GlobalPackages(_cache);

    if (requiresEntrypoint) {
      // TODO(rnystrom): Will eventually need better logic to walk up
      // subdirectories until we hit one that looks package-like. For now,
      // just assume the cwd is it.
      entrypoint = new Entrypoint(path.current, cache);
    }

    return syncFuture(onRun);
  }

  /// Override this to perform the specific command.
  ///
  /// Return a future that completes when the command is done or fails if the
  /// command fails. If the command is synchronous, it may return `null`. Only
  /// leaf command should override this.
  Future onRun() {
    // Leaf commands should override this and non-leaf commands should never
    // call it.
    assert(false);
    return null;
  }

  /// Displays usage information for this command.
  ///
  /// If [description] is omitted, defaults to the command's description.
  void printUsage([String description]) {
    if (description == null) description = this.description;
    log.message('$description\n\n${_getUsage()}');
  }

  /// Throw a [UsageException] for a usage error of this command with
  /// [message].
  void usageError(String message) {
    throw new UsageException(message, _getUsage());
  }

  /// Parses a user-supplied integer [intString] named [name].
  ///
  /// If the parsing fails, prints a usage message and exits.
  int parseInt(String intString, String name) {
    try {
      return int.parse(intString);
    } on FormatException catch (_) {
      usageError('Could not parse $name "$intString".');
    }
  }

  /// Generates a string of usage information for this command.
  String _getUsage() {
    var buffer = new StringBuffer();
    buffer.write('Usage: $usage');

    var commandUsage = commandParser.getUsage();
    if (!commandUsage.isEmpty) {
      buffer.writeln();
      buffer.writeln(commandUsage);
    }

    if (subcommands.isNotEmpty) {
      buffer.writeln();
      buffer.write(_listCommands(subcommands));
    }

    buffer.writeln();
    buffer.writeln('Run "pub help" to see global options.');
    if (docUrl != null) {
      buffer.writeln("See $docUrl for detailed documentation.");
    }

    return buffer.toString();
  }
}

_initCommands() {
  var commands = {
    'build': new BuildCommand(),
    'cache': new CacheCommand(),
    'deps': new DepsCommand(),
    'downgrade': new DowngradeCommand(),
    'global': new GlobalCommand(),
    'get': new GetCommand(),
    'help': new HelpCommand(),
    'list-package-dirs': new ListPackageDirsCommand(),
    'publish': new LishCommand(),
    'run': new RunCommand(),
    'serve': new ServeCommand(),
    'upgrade': new UpgradeCommand(),
    'uploader': new UploaderCommand(),
    'version': new VersionCommand()
  };

  for (var command in commands.values.toList()) {
    for (var alias in command.aliases) {
      commands[alias] = command;
    }
  }

  return commands;
}

/// Creates the top-level [ArgParser] used to parse the pub command line.
ArgParser _initArgParser() {
  var argParser = new ArgParser(allowTrailingOptions: true);

  // Add the global options.
  argParser.addFlag('help', abbr: 'h', negatable: false,
      help: 'Print this usage information.');
  argParser.addFlag('version', negatable: false,
      help: 'Print pub version.');
  argParser.addFlag('trace',
       help: 'Print debugging information when an error occurs.');
  argParser.addOption('verbosity',
      help: 'Control output verbosity.',
      allowed: ['normal', 'io', 'solver', 'all'],
      allowedHelp: {
        'normal': 'Show errors, warnings, and user messages.',
        'io':     'Also show IO operations.',
        'solver': 'Show steps during version resolution.',
        'all':    'Show all output including internal tracing messages.'
      });
  argParser.addFlag('verbose', abbr: 'v', negatable: false,
      help: 'Shortcut for "--verbosity=all".');
  argParser.addFlag('with-prejudice', hide: !isAprilFools, negatable: false,
      help: 'Execute commands with prejudice.');

  // Register the commands.
  PubCommand.mainCommands.forEach((name, command) {
    _registerCommand(name, command, argParser);
  });

  return argParser;
}

/// Registers a [command] with [name] on [parser].
void _registerCommand(String name, PubCommand command, ArgParser parser) {
  parser.addCommand(name, command.commandParser);

  // Recursively wire up any subcommands.
  command.subcommands.forEach((name, subcommand) {
    _registerCommand(name, subcommand, command.commandParser);
  });
}
