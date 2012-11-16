// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_help;

import 'dart:io' as io;
import 'exit_codes.dart' as exit_codes;
import 'io.dart';
import 'pub.dart';

/** Handles the `help` pub command. */
class HelpCommand extends PubCommand {
  String get description => "display help information for Pub";
  String get usage => 'pub help [command]';
  bool get requiresEntrypoint => false;

  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      printUsage();
    } else {
      var name = commandOptions.rest[0];
      var command = pubCommands[name];
      if (command == null) {
        printError('Could not find a command named "$name".');
        printError('Run "pub help" to see available commands.');
        io.exit(exit_codes.USAGE);
      }

      command.printUsage();
    }
  }
}
