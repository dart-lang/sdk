// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:dtd_impl/dart_tooling_daemon.dart' as dtd
    show DartToolingDaemonOptions;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

class ToolingDaemonCommand extends DartdevCommand {
  static const String commandName = 'tooling-daemon';

  static const String commandDescription = "Start Dart's tooling daemon.";

  ToolingDaemonCommand({bool verbose = false})
      : super(
          commandName,
          commandDescription,
          verbose,
          // TODO: this should be set to !verbose once DTD is ready for
          // production.
          hidden: true,
        );

  @override
  ArgParser createArgParser() {
    return dtd.DartToolingDaemonOptions.createArgParser(
      usageLineLength: dartdevUsageLineLength,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!.arguments;

    if (!Sdk.checkArtifactExists(sdk.dtdSnapshot)) return 255;

    VmInteropHandler.run(
      sdk.dtdSnapshot,
      args,
      packageConfigOverride: null,
    );

    // The daemon will continue to run past the return from this method.
    //
    // On an error on startup, the daemon will set the dart:io exitCode value
    // (or, call exit() directly).
    return io.exitCode;
  }
}
