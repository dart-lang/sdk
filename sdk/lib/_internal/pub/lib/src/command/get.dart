// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.get;

import 'dart:async';

import '../command.dart';
import '../log.dart' as log;

/// Handles the `get` pub command.
class GetCommand extends PubCommand {
  String get description => "Get the current package's dependencies.";
  String get usage => "pub get";
  List<String> get aliases => const ["install"];
  bool get isOffline => commandOptions["offline"];

  GetCommand() {
    commandParser.addFlag('offline',
        help: 'Use cached packages instead of accessing the network.');
  }

  Future onRun() {
    return entrypoint.getDependencies()
        .then((_) => log.message("Got dependencies!"));
  }
}
