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
  String get name => "upgrade";
  String get description =>
      "Upgrade the current package's dependencies to latest versions.";
  String get invocation => "pub upgrade [dependencies...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-upgrade.html";
  List<String> get aliases => const ["update"];

  bool get isOffline => argResults['offline'];

  UpgradeCommand() {
    argParser.addFlag(
        'offline',
        help: 'Use cached packages instead of accessing the network.');

    argParser.addFlag(
        'dry-run',
        abbr: 'n',
        negatable: false,
        help: "Report what dependencies would change but don't change any.");
  }

  Future run() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var dryRun = argResults['dry-run'];
        new Future.value(
            entrypoint.acquireDependencies(
                SolveType.UPGRADE,
                useLatest: argResults.rest,
                dryRun: dryRun)).then((x0) {
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
