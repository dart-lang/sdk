// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.help;

import 'dart:async';

import '../command.dart';

/// Handles the `help` pub command.
class HelpCommand extends PubCommand {
  String get description => "Display help information for Pub.";
  String get usage => "pub help [command]";
  bool get takesArguments => true;

  Future onRun() {
    // Show the default help if no command was specified.
    if (commandOptions.rest.isEmpty) {
      PubCommand.printGlobalUsage();
      return null;
    }

    // Walk the command tree to show help for the selected command or
    // subcommand.
    var commands = PubCommand.mainCommands;
    var command = null;
    var commandString = "pub";

    for (var name in commandOptions.rest) {
      if (commands.isEmpty) {
        command.usageError(
            'Command "$commandString" does not expect a subcommand.');
      }

      if (commands[name] == null) {
        if (command == null) {
          PubCommand.usageErrorWithCommands(commands,
              'Could not find a command named "$name".');
        }

        command.usageError(
            'Could not find a subcommand named "$name" for "$commandString".');
      }

      command = commands[name];
      commands = command.subcommands;
      commandString += " $name";
    }

    command.printUsage();
    return null;
  }
}
