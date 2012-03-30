// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The main entrypoint for the pub command line application.
 */
#library('pub');

#import('utils.dart');

List<String, PubCommand> commands;

main() {
  final args = new Options().arguments;

  // TODO(rnystrom): In addition to explicit "help" and "version" commands,
  // should also add special-case support for --help and --version arguments to
  // be consistent with other Unix apps.
  commands = {
    'version': new PubCommand('print Pub version', showVersion)
  };

  if (args.length == 0) {
    showUsage();
    return;
  }

  // Select the command.
  final command = commands[args[0]];
  if (command == null) {
    print('Unknown command "${args[0]}".');
    print('Run "pub help" to see available commands.');
    exit(64); // see http://www.freebsd.org/cgi/man.cgi?query=sysexits.
    return;
  }

  args.removeRange(0, 1);
  command.function(args);
}

/** Displays usage information for the app. */
void showUsage() {
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
  final names = <String>[];
  for (final command in commands.getKeys()) {
    length = Math.max(length, command.length);
    names.add(command);
  }

  names.sort((a, b) => a.compareTo(b));

  for (final name in names) {
    print('  ${padRight(name, length)}   ${commands[name].description}');
  }

  print('');
  print('Use "pub help [command]" for more information about a command.');
}

/** Displays pub version information. */
void showVersion(List<String> args) {
  // TODO(rnystrom): Store some place central.
  print('Pub 0.0.0');
}

typedef void CommandFunction(List<String> args);

class PubCommand {
  final String description;
  final CommandFunction function;

  PubCommand(this.description, this.function);
}
