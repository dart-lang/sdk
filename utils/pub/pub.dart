// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The main entrypoint for the pub command line application.
 */
#library('pub');

#import('../../pkg/args/lib/args.dart');
#import('dart:io');
#import('dart:math');
#import('io.dart');
#import('command_help.dart');
#import('command_install.dart');
#import('command_update.dart');
#import('command_version.dart');
#import('entrypoint.dart');
#import('exit_codes.dart', prefix: 'exit_codes');
#import('git_source.dart');
#import('hosted_source.dart');
#import('package.dart');
#import('pubspec.dart');
#import('sdk_source.dart');
#import('source.dart');
#import('source_registry.dart');
#import('system_cache.dart');
#import('utils.dart');
#import('version.dart');

Version get pubVersion => new Version(0, 0, 0);

/**
 * The commands that Pub understands.
 */
Map<String, PubCommand> get pubCommands => {
  'help': new HelpCommand(),
  'install': new InstallCommand(),
  'update': new UpdateCommand(),
  'version': new VersionCommand()
};

/**
 * The parser for arguments that are global to Pub rather than specific to a
 * single command.
 */
ArgParser get pubArgParser {
  var parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false,
    help: 'Prints this usage information');
  parser.addFlag('version', negatable: false,
    help: 'Prints the version of Pub');
  parser.addFlag('trace', help: 'Prints a stack trace when an error occurs');
  return parser;
}

main() {
  var globalOptions;
  try {
    globalOptions = pubArgParser.parse(new Options().arguments);
  } on FormatException catch (e) {
    printUsage(description: e.message);
    return;
  }

  if (globalOptions['version']) {
    printVersion();
    return;
  }

  if (globalOptions['help'] || globalOptions.rest.isEmpty()) {
    printUsage();
    return;
  }

  // TODO(nweiz): Have a fallback for this this out automatically once 1145 is
  // fixed.
  var sdkDir = Platform.environment['DART_SDK'];
  var cacheDir;
  if (Platform.environment.containsKey('PUB_CACHE')) {
    cacheDir = Platform.environment['PUB_CACHE'];
  } else if (Platform.operatingSystem == 'windows') {
    var appData = Platform.environment['APPDATA'];
    cacheDir = join(appData, 'Pub', 'Cache');
  } else {
    cacheDir = '${Platform.environment['HOME']}/.pub-cache';
  }

  var cache = new SystemCache(cacheDir);
  cache.register(new SdkSource(sdkDir));
  cache.register(new GitSource());
  cache.register(new HostedSource());
  cache.sources.setDefault('hosted');

  // Select the command.
  var command = pubCommands[globalOptions.rest[0]];
  if (command == null) {
    printError('Unknown command "${globalOptions.rest[0]}".');
    printError('Run "pub help" to see available commands.');
    exit(exit_codes.USAGE);
    return;
  }

  var commandArgs =
    globalOptions.rest.getRange(1, globalOptions.rest.length - 1);
  command.run(cache, globalOptions, commandArgs);
}

/** Displays usage information for the app. */
void printUsage([String description = 'Pub is a package manager for Dart.']) {
  print(description);
  print('');
  print('Usage: pub command [arguments]');
  print('');
  print('Global options:');
  print(pubArgParser.getUsage());
  print('');
  print('The commands are:');

  // Show the commands sorted.
  // TODO(rnystrom): A sorted map would be nice.
  int length = 0;
  var names = <String>[];
  for (var command in pubCommands.getKeys()) {
    length = max(length, command.length);
    names.add(command);
  }

  names.sort((a, b) => a.compareTo(b));

  for (var name in names) {
    print('  ${padRight(name, length)}   ${pubCommands[name].description}');
  }

  print('');
  print('Use "pub help [command]" for more information about a command.');
}

void printVersion() {
  print('Pub $pubVersion');
}

abstract class PubCommand {
  SystemCache cache;
  ArgResults globalOptions;
  ArgResults commandOptions;

  Entrypoint entrypoint;

  /**
   * A one-line description of this command.
   */
  abstract String get description;

  /**
   * How to invoke this command (e.g. `"pub install [package]"`).
   */
  abstract String get usage;

  /// Whether or not this command requires [entrypoint] to be defined. If false,
  /// Pub won't look for a pubspec and [entrypoint] will be null when the
  /// command runs.
  bool get requiresEntrypoint => true;

  /**
   * Override this to define command-specific options. The results will be made
   * available in [commandOptions].
   */
  ArgParser get commandParser => new ArgParser();

  void run(SystemCache cache_, ArgResults globalOptions_,
      List<String> commandArgs) {
    cache = cache_;
    globalOptions = globalOptions_;

    try {
     commandOptions = commandParser.parse(commandArgs);
    } on FormatException catch (e) {
      this.printUsage(description: e.message);
      exit(exit_codes.USAGE);
    }

    handleError(error, trace) {
      // This is basically the top-level exception handler so that we don't
      // spew a stack trace on our users.
      var message = error.toString();

      // TODO(rnystrom): The default exception implementation class puts
      // "Exception:" in the output, so strip that off.
      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }

      printError(message);
      if (globalOptions['trace'] && trace != null) {
        printError(trace);
      }

      exit(_chooseExitCode(error));
    }

    var future = new Future.immediate(null);
    if (requiresEntrypoint) {
      // TODO(rnystrom): Will eventually need better logic to walk up
      // subdirectories until we hit one that looks package-like. For now, just
      // assume the cwd is it.
      future = Package.load(null, workingDir, cache.sources)
          .transform((package) => new Entrypoint(package, cache));
    }

    future = future.chain((entrypoint) {
      this.entrypoint = entrypoint;
      try {
        var commandFuture = onRun();
        if (commandFuture == null) return new Future.immediate(true);

        return commandFuture;
      } catch (error, trace) {
        handleError(error, trace);
        return new Future.immediate(null);
      }
    });

    future.handleException((e) {
      if (e is PubspecNotFoundException && e.name == null) {
        e = 'Could not find a file named "pubspec.yaml" in the directory '
          '$workingDir.';
      } else if (e is PubspecHasNoNameException && e.name == null) {
        e = 'pubspec.yaml is missing the required "name" field (e.g. "name: '
          '${basename(workingDir)}").';
      }

      handleError(e, future.stackTrace);
    });
    // Explicitly exit on success to ensure that any dangling dart:io handles
    // don't cause the process to never terminate.
    future.then((_) => exit(0));
  }

  /**
   * Override this to perform the specific command. Return a future that
   * completes when the command is done or fails if the command fails. If the
   * command is synchronous, it may return `null`.
   */
  abstract Future onRun();

  /** Displays usage information for this command. */
  void printUsage([String description]) {
    if (description == null) description = this.description;
    print(description);
    print('');
    print('Usage: $usage');

    var commandUsage = commandParser.getUsage();
    if (!commandUsage.isEmpty()) {
      print('');
      print(commandUsage);
    }
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
