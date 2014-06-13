// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.upgrade;

import 'dart:async';

import '../command.dart';
import '../log.dart' as log;

/// Handles the `upgrade` pub command.
class UpgradeCommand extends PubCommand {
  String get description =>
      "Upgrade the current package's dependencies to latest versions.";
  String get usage => "pub upgrade [dependencies...]";
  List<String> get aliases => const ["update"];
  bool get takesArguments => true;

  bool get isOffline => commandOptions['offline'];

  UpgradeCommand() {
    commandParser.addFlag('offline',
        help: 'Use cached packages instead of accessing the network.');

    commandParser.addFlag('dry-run', abbr: 'n', negatable: false,
        help: 'Report what dependencies would change but do not change any.');
  }

  Future onRun() {
    var upgradeAll = commandOptions.rest.isEmpty;
    var dryRun = commandOptions['dry-run'];
    return entrypoint.acquireDependencies(useLatest: commandOptions.rest,
        upgradeAll: upgradeAll, dryRun: dryRun).then((numChanged) {
      if (dryRun) {
        if (numChanged == 0) {
          log.message("No dependencies would change.");
        } else if (numChanged == 1) {
          log.message("Would change $numChanged dependency.");
        } else {
          log.message("Would change $numChanged dependencies.");
        }
      } else {
        if (numChanged == 0) {
          log.message("No dependencies changed.");
        } else if (numChanged == 1) {
          log.message("Changed $numChanged dependency!");
        } else {
          log.message("Changed $numChanged dependencies!");
        }
      }

      if (isOffline) {
        log.warning("Warning: Upgrading when offline may not update you to the "
                    "latest versions of your dependencies.");
      }
    });
  }
}
