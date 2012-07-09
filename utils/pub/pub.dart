// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The main entrypoint for the pub command line application.
 */
#library('pub');

#import('../../lib/args/args.dart');
#import('io.dart');
#import('command_install.dart');
#import('command_list.dart');
#import('command_update.dart');
#import('command_version.dart');
#import('entrypoint.dart');
#import('git_source.dart');
#import('package.dart');
#import('pubspec.dart');
#import('repo_source.dart');
#import('sdk_source.dart');
#import('source.dart');
#import('source_registry.dart');
#import('system_cache.dart');
#import('utils.dart');
#import('version.dart');

Version get pubVersion() => new Version(0, 0, 0);

main() {
  // TODO(rnystrom): In addition to explicit "help" and "version" commands,
  // should also add special-case support for --help and --version arguments to
  // be consistent with other Unix apps.
  var commands = {
    'list': new ListCommand(),
    'install': new InstallCommand(),
    'update': new UpdateCommand(),
    'version': new VersionCommand()
  };

  var parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false,
    help: 'Prints this usage information');
  parser.addFlag('version', negatable: false,
    help: 'Prints the version of Pub');
  // TODO(rnystrom): Hack. These are temporary options to allow the pub tests to
  // pass in relevant paths. Eventually these should be environment variables.
  parser.addOption('cachedir', help: 'The directory containing the system-wide '
    'Pub cache');
  parser.addOption('sdkdir', help: 'The directory containing the Dart SDK');
  parser.addFlag('trace', help: 'Prints a stack trace when an error occurs');

  var globalOptions;
  try {
    globalOptions = parser.parse(new Options().arguments);
  } catch (ArgFormatException e) {
    printUsage(parser, commands, description: e.message);
    return;
  }

  if (globalOptions['version']) {
    printVersion();
    return;
  }

  if (globalOptions['help'] || globalOptions.rest.isEmpty()) {
    printUsage(parser, commands);
    return;
  }

  var cache = new SystemCache(globalOptions['cachedir']);
  cache.sources.register(new SdkSource(globalOptions['sdkdir']));
  cache.sources.register(new GitSource());
  cache.sources.register(new RepoSource());
  // TODO(nweiz): Make 'repo' the default once pub.dartlang.org exists
  cache.sources.setDefault('sdk');

  // Select the command.
  var command = commands[globalOptions.rest[0]];
  if (command == null) {
    printError('Unknown command "${globalOptions.rest[0]}".');
    printError('Run "pub help" to see available commands.');
    exit(64); // See http://www.freebsd.org/cgi/man.cgi?query=sysexits.
    return;
  }

  var commandArgs =
    globalOptions.rest.getRange(1, globalOptions.rest.length - 1);
  command.run(cache, globalOptions, commandArgs);
}

/** Displays usage information for the app. */
void printUsage(ArgParser parser, Map<String, PubCommand> commands,
    [String description = 'Pub is a package manager for Dart.']) {
  print(description);
  print('');
  print('Usage: pub command [arguments]');
  print('');
  print('Global options:');
  print(parser.getUsage());
  print('');
  print('The commands are:');

  // Show the commands sorted.
  // TODO(rnystrom): A sorted map would be nice.
  int length = 0;
  var names = <String>[];
  for (var command in commands.getKeys()) {
    length = Math.max(length, command.length);
    names.add(command);
  }

  names.sort((a, b) => a.compareTo(b));

  for (var name in names) {
    print('  ${padRight(name, length)}   ${commands[name].description}');
  }

  print('');
  print('Use "pub help [command]" for more information about a command.');
}

void printVersion() {
  print('Pub $pubVersion');
}

class PubCommand {
  SystemCache cache;

  Entrypoint entrypoint;

  abstract String get description();

  void run(SystemCache cache_, ArgResults globalOptions,
      List<String> commandArgs) {
    cache = cache_;

    // TODO(rnystrom): Each command should define the arguments it expects and
    // we can handle them generically here.

    handleError(error, trace) {
      // This is basically the top-level exception handler so that we don't
      // spew a stack trace on our users.
      // TODO(rnystrom): Add --trace flag so stack traces can be enabled for
      // debugging.
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
      return true;
    }

    // TODO(rnystrom): Will eventually need better logic to walk up
    // subdirectories until we hit one that looks package-like. For now, just
    // assume the cwd is it.
    var future = Package.load(workingDir, cache.sources).chain((package) {
      entrypoint = new Entrypoint(package, cache);

      try {
        var commandFuture = onRun();
        if (commandFuture == null) return new Future.immediate(true);

        return commandFuture;
      } catch (var error, var trace) {
        handleError(error, trace);
        return new Future.immediate(null);
      }
    });
    future.handleException((e) => handleError(e, future.stackTrace));
  }

  /**
   * Override this to perform the specific command. Return a future that
   * completes when the command is done or fails if the command fails. If the
   * command is synchronous, it may return `null`.
   */
  abstract Future onRun();
}
