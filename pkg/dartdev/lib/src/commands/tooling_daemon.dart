// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dtd_impl/dtd.dart' as dtd show DartToolingDaemonOptions;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class ToolingDaemonCommand extends DartdevCommand {
  static const String commandName = 'tooling-daemon';

  static const String commandDescription = "Start Dart's tooling daemon.";

  ToolingDaemonCommand({bool verbose = false})
      : super(
          commandName,
          commandDescription,
          verbose,
          hidden: !verbose,
        ) {
    dtd.DartToolingDaemonOptions.populateArgOptions(
      argParser,
      verbose: verbose,
    );
  }

  @override
  Future<int> run() async {
    // Need to make a copy as argResults!.arguments is an
    // UnmodifiableListView object which cannot be passed as
    // the args for spawnUri.
    final args = [...argResults!.arguments];
    return await runFromSnapshot(
      snapshot: sdk.dtdSnapshot,
      args: args,
      verbose: verbose,
    );
  }
}
