// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.upgrade;

import 'dart:async';

import '../command.dart';
import '../entrypoint.dart';
import '../log.dart' as log;

/// Handles the `upgrade` pub command.
class UpgradeCommand extends PubCommand {
  String get description =>
    "Upgrade the current package's dependencies to latest versions.";
  String get usage => 'pub upgrade [dependencies...]';
  final aliases = const ["update"];

  bool get isOffline => commandOptions['offline'];

  UpgradeCommand() {
    commandParser.addFlag('offline',
        help: 'Use cached packages instead of accessing the network.');
  }

  Future onRun() {
    var future;
    if (commandOptions.rest.isEmpty) {
      future = entrypoint.upgradeAllDependencies();
    } else {
      future = entrypoint.upgradeDependencies(commandOptions.rest);
    }

    return future.then((_) {
      log.message("Dependencies upgraded!");
      if (isOffline) {
        log.warning("Warning: Upgrading when offline may not update you to the "
                    "latest versions of your dependencies.");
      }
    });
  }
}
