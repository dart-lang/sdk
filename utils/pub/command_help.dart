// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_help;

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
      pubCommands[commandOptions.rest[0]].printUsage();
    }
  }
}
