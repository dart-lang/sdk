// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dtd_impl/dtd.dart' as dtd show DartToolingDaemonOptions;

import '../core.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

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
  String get category => 'Tools';

  @override
  Future<int> run() async {
    var script = sdk.dartAotRuntime;
    var snapshot = sdk.dtdAotSnapshot;
    var useExecProcess = true;
    final args = argResults!.arguments;

    if (!Sdk.checkArtifactExists(sdk.dtdAotSnapshot, logError: false)) {
      // On ia32 platforms we do not have an AOT snapshot and so we need
      // to run the JIT snapshot.
      useExecProcess = false;
      script = sdk.dtdSnapshot;
    }
    final dtdCommand = [
      if (useExecProcess) snapshot,
      // Add the remaining args.
      if (args.isNotEmpty) ...args,
    ];
    try {
      VmInteropHandler.run(
        script,
        dtdCommand,
        packageConfigOverride: null,
        useExecProcess: useExecProcess,
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: launching tooling daemon failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return 255;
    }
  }
}
