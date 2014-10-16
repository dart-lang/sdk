// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.upgrade;

import 'dart:async';

import '../command.dart';
import '../log.dart' as log;
import '../solver/version_solver.dart';

/// Handles the `upgrade` pub command.
class UpgradeCommand extends PubCommand {
  String get description =>
      "Upgrade the current package's dependencies to latest versions.";
  String get usage => "pub upgrade [dependencies...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-upgrade.html";
  List<String> get aliases => const ["update"];
  bool get takesArguments => true;

  bool get isOffline => commandOptions['offline'];

  UpgradeCommand() {
    commandParser.addFlag(
        'offline',
        help: 'Use cached packages instead of accessing the network.');

    commandParser.addFlag(
        'dry-run',
        abbr: 'n',
        negatable: false,
        help: "Report what dependencies would change but don't change any.");
  }

  Future onRun() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var dryRun = commandOptions['dry-run'];
        entrypoint.acquireDependencies(
            SolveType.UPGRADE,
            useLatest: commandOptions.rest,
            dryRun: dryRun).then((x0) {
          try {
            x0;
            join0() {
              completer0.complete();
            }
            if (isOffline) {
              log.warning(
                  "Warning: Upgrading when offline may not update you to the "
                      "latest versions of your dependencies.");
              join0();
            } else {
              join0();
            }
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }
}
