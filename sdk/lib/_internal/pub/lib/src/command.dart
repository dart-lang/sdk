// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:pathos/path.dart' as path;

import 'command_cache.dart';
import 'command_deploy.dart';
import 'command_help.dart';
import 'command_install.dart';
import 'command_lish.dart';
import 'command_update.dart';
import 'command_uploader.dart';
import 'command_version.dart';
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'http.dart';
import 'log.dart' as log;
import 'package.dart';
import 'system_cache.dart';
import 'utils.dart';

/// The base class for commands for the pub executable.
abstract class PubCommand {
  /// The commands that Pub understands.
  static final Map<String, PubCommand> commands = _initCommands();

  SystemCache cache;

  /// The parsed options for this command.
  ArgResults commandOptions;

  Entrypoint entrypoint;

  /// A one-line description of this command.
  String get description;

  /// How to invoke this command (e.g. `"pub install [package]"`).
  String get usage;

  /// Whether or not this command requires [entrypoint] to be defined. If false,
  /// Pub won't look for a pubspec and [entrypoint] will be null when the
  /// command runs.
  final requiresEntrypoint = true;

  /// Alternate names for this command. These names won't be used in the
  /// documentation, but they will work when invoked on the command line.
  final aliases = const <String>[];

  /// The [ArgParser] for this command.
  final commandParser = new ArgParser();

  /// Override this to use offline-only sources instead of hitting the network.
  /// This will only be called before the [SystemCache] is created. After that,
  /// it has no effect.
  bool get isOffline => false;

  PubCommand() {
    // Allow "--help" after a command to get command help.
    commandParser.addFlag('help', abbr: 'h', negatable: false,
        help: 'Print usage information for this command.');
  }

  void run(String cacheDir, ArgResults options) {
    commandOptions = options.command;

    if (commandOptions['help']) {
      this.printUsage();
      return;
    }

    cache = new SystemCache.withSources(cacheDir, isOffline: isOffline);

    handleError(error) {
      var trace = getAttachedStackTrace(error);

      // This is basically the top-level exception handler so that we don't
      // spew a stack trace on our users.
      var message;

      try {
        // Most exception types have a "message" property. We prefer this since
        // it skips the "Exception:", "HttpException:", etc. prefix that calling
        // toString() adds. But, alas, "message" isn't actually defined in the
        // base Exception type so there's no easy way to know if it's available
        // short of a giant pile of type tests for each known exception type.
        //
        // So just try it. If it throws, default to toString().
        message = error.message;
      } on NoSuchMethodError catch (_) {
        message = error.toString();
      }

      log.error(message);

      if (trace != null) {
        if (options['trace'] || !isUserFacingException(error)) {
          log.error(trace);
        } else {
          log.fine(trace);
        }
      }

      if (options['trace']) {
        log.dumpTranscript();
      } else if (!isUserFacingException(error)) {
        log.error("""
This is an unexpected error. Please run

    pub --trace ${new Options().arguments.map((arg) => "'$arg'").join(' ')}

and include the results in a bug report on http://dartbug.com/new.
""");
      }

      exit(_chooseExitCode(error));
    }

    new Future.sync(() {
      if (requiresEntrypoint) {
        // TODO(rnystrom): Will eventually need better logic to walk up
        // subdirectories until we hit one that looks package-like. For now,
        // just assume the cwd is it.
        entrypoint = new Entrypoint(path.current, cache);
      }

      var commandFuture = onRun();
      if (commandFuture == null) return true;

      return commandFuture;
    }).whenComplete(() => cache.deleteTempDir()).catchError((e) {
      if (e is PubspecNotFoundException && e.name == null) {
        e = new ApplicationException('Could not find a file named '
            '"pubspec.yaml" in the directory ${path.current}.');
      } else if (e is PubspecHasNoNameException && e.name == null) {
        e = new ApplicationException('pubspec.yaml is missing the required '
            '"name" field (e.g. "name: ${path.basename(path.current)}").');
      }

      handleError(e);
    }).then((_) {
      // Explicitly exit on success to ensure that any dangling dart:io handles
      // don't cause the process to never terminate.
      exit(0);
    });
  }

  /// Override this to perform the specific command. Return a future that
  /// completes when the command is done or fails if the command fails. If the
  /// command is synchronous, it may return `null`.
  Future onRun();

  /// Displays usage information for this command.
  void printUsage([String description]) {
    if (description == null) description = this.description;

    var buffer = new StringBuffer();
    buffer.write('$description\n\nUsage: $usage');

    var commandUsage = commandParser.getUsage();
    if (!commandUsage.isEmpty) {
      buffer.write('\n');
      buffer.write(commandUsage);
    }

    log.message(buffer.toString());
  }

  /// Returns the appropriate exit code for [exception], falling back on 1 if no
  /// appropriate exit code could be found.
  int _chooseExitCode(exception) {
    if (exception is HttpException || exception is HttpException ||
        exception is SocketException || exception is PubHttpException) {
      return exit_codes.UNAVAILABLE;
    } else if (exception is FormatException) {
      return exit_codes.DATA;
    } else {
      return 1;
    }
  }
}

_initCommands() {
  var commands = {
    'cache': new CacheCommand(),
    'deploy': new DeployCommand(),
    'help': new HelpCommand(),
    'install': new InstallCommand(),
    'publish': new LishCommand(),
    'update': new UpdateCommand(),
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
