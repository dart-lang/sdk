// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/arg_parser.dart';
import 'package:path/path.dart';

import '../core.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

class DevelopmentServiceCommand extends DartdevCommand {
  static const String commandName = 'development-service';

  static const String commandDescription = "Start Dart's development service.";

  DevelopmentServiceCommand({bool verbose = false})
      : super(
          commandName,
          commandDescription,
          verbose,
          hidden: !verbose,
        ) {
    DartDevelopmentServiceOptions.populateArgParser(
      argParser: argParser,
      verbose: verbose,
    );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  Future<int> run() async {
    final sdkDir = dirname(sdk.dart);
    final fullSdk = sdkDir.endsWith('bin');
    var script = fullSdk
        ? sdk.dartAotRuntime
        : absolute(sdkDir, 'dartaotruntime${Platform.isWindows ? '.exe' : ''}');
    var snapshot = fullSdk
        ? sdk.ddsAotSnapshot
        : absolute(sdkDir, 'dds_aot.dart.snapshot');
    var useExecProcess = true;
    final args = argResults!.arguments;

    if (!Sdk.checkArtifactExists(snapshot, logError: false)) {
      // On ia32 platforms we do not have an AOT snapshot and so we need
      // to run the JIT snapshot.
      useExecProcess = false;
      script =
          fullSdk ? sdk.ddsSnapshot : absolute(sdkDir, 'dds.dart.snapshot');
      if (!Sdk.checkArtifactExists(script, logError: false)) {
        log.stderr('Error: launching development server failed : '
            'Unable to find snapshot for the development server');
        return 255;
      }
    }
    final ddsCommand = [
      if (useExecProcess) snapshot,
      // Add the remaining args.
      if (args.isNotEmpty) ...args,
    ];
    try {
      VmInteropHandler.run(
        script,
        ddsCommand,
        packageConfigOverride: null,
        useExecProcess: useExecProcess,
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: launching development server failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return 255;
    }
  }
}
