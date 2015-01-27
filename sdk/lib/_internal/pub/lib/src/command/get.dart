// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.get;

import 'dart:async';

import '../command.dart';
import '../solver/version_solver.dart';

/// Handles the `get` pub command.
class GetCommand extends PubCommand {
  String get name => "get";
  String get description => "Get the current package's dependencies.";
  String get invocation => "pub get";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-get.html";
  List<String> get aliases => const ["install"];
  bool get isOffline => argResults["offline"];

  GetCommand() {
    argParser.addFlag('offline',
        help: 'Use cached packages instead of accessing the network.');

    argParser.addFlag('dry-run', abbr: 'n', negatable: false,
        help: "Report what dependencies would change but don't change any.");
  }

  Future run() {
    return entrypoint.acquireDependencies(SolveType.GET,
        dryRun: argResults['dry-run']);
  }
}
