// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The main entrypoint for the pub command line application.
library pub;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:pathos/path.dart' as path;

import 'command_help.dart';
import 'command_install.dart';
import 'command_lish.dart';
import 'command_update.dart';
import 'command_uploader.dart';
import 'command_version.dart';
import 'command_cache.dart';
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'package.dart';
import 'pubspec.dart';
import 'sdk.dart' as sdk;
import 'source.dart';
import 'source_registry.dart';
import 'system_cache.dart';
import 'utils.dart';
import 'version.dart';

/// The commands that Pub understands.
Map<String, PubCommand> get pubCommands {
  var commands = {
    'cache': new CacheCommand(),
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

/// The parser for arguments that are global to Pub rather than specific to a
/// single command.
ArgParser get pubArgParser {
  var parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false,
      help: 'Print this usage information.');
  parser.addFlag('version', negatable: false,
      help: 'Print pub version.');
  parser.addFlag('trace',
       help: 'Print debugging information when an error occurs.');
  parser.addOption('verbosity',
      help: 'Control output verbosity.',
      allowed: ['normal', 'io', 'solver', 'all'],
      allowedHelp: {
        'normal': 'Show errors, warnings, and user messages.',
        'io':     'Also show IO operations.',
        'solver': 'Show steps during version resolution.',
        'all':    'Show all output including internal tracing messages.'
      });
  parser.addFlag('verbose', abbr: 'v', negatable: false,
      help: 'Shortcut for "--verbosity=all"');
  return parser;
}

main() {
  var globalOptions;
  try {
    globalOptions = pubArgParser.parse(new Options().arguments);
  } on FormatException catch (e) {
    log.error(e.message);
    log.error('Run "pub help" to see available options.');
    exit(exit_codes.USAGE);
  }

  if (globalOptions['version']) {
    printVersion();
    return;
  }

  if (globalOptions['help'] || globalOptions.rest.isEmpty) {
    printUsage();
    return;
  }

  if (globalOptions['trace']) {
    log.recordTranscript();
  }

  switch (globalOptions['verbosity']) {
    case 'normal': log.showNormal(); break;
    case 'io': log.showIO(); break;
    case 'solver': log.showSolver(); break;
    case 'all': log.showAll(); break;
    default:
      // No specific verbosity given, so check for the shortcut.
      if (globalOptions['verbose']) {
        log.showAll();
      } else {
        log.showNormal();
      }
      break;
  }

  SecureSocket.initialize(database: relativeToPub('resource/certs'));

  var cacheDir;
  if (Platform.environment.containsKey('PUB_CACHE')) {
    cacheDir = Platform.environment['PUB_CACHE'];
  } else if (Platform.operatingSystem == 'windows') {
    var appData = Platform.environment['APPDATA'];
    cacheDir = path.join(appData, 'Pub', 'Cache');
  } else {
    cacheDir = '${Platform.environment['HOME']}/.pub-cache';
  }

  validatePlatform().then((_) {
    var cache = new SystemCache.withSources(cacheDir);

    // Select the command.
    var command = pubCommands[globalOptions.rest[0]];
    if (command == null) {
      log.error('Could not find a command named "${globalOptions.rest[0]}".');
      log.error('Run "pub help" to see available commands.');
      exit(exit_codes.USAGE);
      return;
    }

    var commandArgs = globalOptions.rest.sublist(1);
    command.run(cache, globalOptions, commandArgs);
  });
}

/// Checks that pub is running on a supported platform. If it isn't, it prints
/// an error message and exits. Completes when the validation is done.
Future validatePlatform() {
  return new Future.sync(() {
    if (Platform.operatingSystem != 'windows') return;

    return runProcess('ver', []).then((result) {
      if (result.stdout.join('\n').contains('XP')) {
        log.error('Sorry, but pub is not supported on Windows XP.');
        exit(exit_codes.USAGE);
      }
    });
  });
}

/// Displays usage information for the app.
void printUsage([String description = 'Pub is a package manager for Dart.']) {
  // Build up a buffer so it shows up as a single log entry.
  var buffer = new StringBuffer();
  buffer.write(description);
  buffer.write('\n\n');
  buffer.write('Usage: pub command [arguments]\n\n');
  buffer.write('Global options:\n');
  buffer.write('${pubArgParser.getUsage()}\n\n');

  // Show the commands sorted.
  buffer.write('Available commands:\n');

  // TODO(rnystrom): A sorted map would be nice.
  int length = 0;
  var names = <String>[];
  for (var command in pubCommands.keys) {
    // Hide aliases.
    if (pubCommands[command].aliases.indexOf(command) >= 0) continue;
    length = max(length, command.length);
    names.add(command);
  }

  names.sort((a, b) => a.compareTo(b));

  for (var name in names) {
    buffer.write('  ${padRight(name, length)}   '
        '${pubCommands[name].description}\n');
  }

  buffer.write('\n');
  buffer.write(
      'Use "pub help [command]" for more information about a command.');
  log.message(buffer.toString());
}

void printVersion() {
  log.message('Pub ${sdk.version}');
}

abstract class PubCommand {
  SystemCache cache;
  ArgResults globalOptions;
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

  /// Override this to define command-specific options. The results will be made
  /// available in [commandOptions].
  ArgParser get commandParser => new ArgParser();

  void run(SystemCache cache_, ArgResults globalOptions_,
      List<String> commandArgs) {
    cache = cache_;
    globalOptions = globalOptions_;

    try {
      commandOptions = commandParser.parse(commandArgs);
    } on FormatException catch (e) {
      log.error(e.message);
      log.error('Use "pub help" for more information.');
      exit(exit_codes.USAGE);
    }

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
      if (globalOptions['trace'] && trace != null) {
        log.error(trace);
        log.dumpTranscript();
      } else {
        log.fine(trace);
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
    }).whenComplete(() => cache_.deleteTempDir()).catchError((e) {
      if (e is PubspecNotFoundException && e.name == null) {
        e = 'Could not find a file named "pubspec.yaml" in the directory '
          '${path.current}.';
      } else if (e is PubspecHasNoNameException && e.name == null) {
        e = 'pubspec.yaml is missing the required "name" field (e.g. "name: '
          '${path.basename(path.current)}").';
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
    if (exception is HttpException || exception is HttpParserException ||
        exception is SocketIOException || exception is PubHttpException) {
      return exit_codes.UNAVAILABLE;
    } else if (exception is FormatException) {
      return exit_codes.DATA;
    } else {
      return 1;
    }
  }
}
