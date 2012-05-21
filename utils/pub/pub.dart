// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The main entrypoint for the pub command line application.
 */
#library('pub');

#import('io.dart');
#import('pubspec.dart');
#import('source.dart');
#import('utils.dart');
#import('version.dart');

#source('command_list.dart');
#source('command_install.dart');
#source('command_update.dart');
#source('command_version.dart');
#source('entrypoint.dart');
#source('package.dart');
#source('system_cache.dart');

Version get pubVersion() => new Version(0, 0, 0);

main() {
  var args = new Options().arguments;

  // TODO(rnystrom): In addition to explicit "help" and "version" commands,
  // should also add special-case support for --help and --version arguments to
  // be consistent with other Unix apps.
  var commands = {
    'list': new ListCommand(),
    'install': new InstallCommand(),
    'update': new UpdateCommand(),
    'version': new VersionCommand()
  };

  // TODO(rnystrom): Hack. This is temporary code to allow the pub tests to
  // pass in relevant paths. Eventually these should be either environment
  // variables or at least a cleaner arg parser.
  var cacheDir, sdkDir;
  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--cachedir=')) {
      cacheDir = args[i].substring('--cachedir='.length);
      args.removeRange(i, 1);
      i--;
    } else if (args[i].startsWith('--sdkdir=')) {
      sdkDir = args[i].substring('--sdkdir='.length);
      args.removeRange(i, 1);
      i--;
    }
  }

  if (args.length == 0) {
    printUsage(commands);
    return;
  }

  // For consistency with expected unix idioms, support --help, -h, and
  // --version in addition to the regular commands.
  if (args.length == 1) {
    if (args[0] == '--help' || args[0] == '-h') {
      printUsage(commands);
      return;
    }

    if (args[0] == '--version') {
      printVersion();
      return;
    }
  }

  var cache = new SystemCache(cacheDir);
  cache.sources.register(new SdkSource(sdkDir));
  cache.sources.register(new GitSource());
  cache.sources.setDefault('sdk');

  // Select the command.
  var command = commands[args[0]];
  if (command == null) {
    print('Unknown command "${args[0]}".');
    print('Run "pub help" to see available commands.');
    exit(64); // See http://www.freebsd.org/cgi/man.cgi?query=sysexits.
    return;
  }

  args.removeRange(0, 1);
  command.run(cache, args);
}

/** Displays usage information for the app. */
void printUsage(Map<String, PubCommand> commands) {
  print('Pub is a package manager for Dart.');
  print('');
  print('Usage:');
  print('');
  print('  pub command [arguments]');
  print('');
  print('The commands are:');
  print('');

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

  void run(SystemCache cache_, List<String> args) {
    cache = cache_;

    // TODO(rnystrom): Each command should define the arguments it expects and
    // we can handle them generically here.

    // TODO(rnystrom): Will eventually need better logic to walk up
    // subdirectories until we hit one that looks package-like. For now, just
    // assume the cwd is it.
    Package.load(workingDir, cache.sources).then((package) {
      entrypoint = new Entrypoint(package, cache);
      onRun();
    });
  }

  abstract void onRun();
}
