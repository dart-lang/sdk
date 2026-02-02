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
    : super(commandName, commandDescription, verbose, hidden: !verbose) {
    dtd.DartToolingDaemonOptions.populateArgOptions(
      argParser,
      verbose: verbose,
    );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  Future<int> run() async {
    var snapshot = sdk.dtdAotSnapshot;
    final args = argResults!.arguments;
    if (!checkArtifactExists(sdk.dtdAotSnapshot, logError: false)) {
      log.stderr(
        'Error: launching dart tooling daemon failed : '
        'Unable to find snapshot for the tooling daemon',
      );
      return 255;
    }
    try {
      VmInteropHandler.run(
        snapshot,
        args,
        packageConfigOverride: null,
        useExecProcess: false,
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
