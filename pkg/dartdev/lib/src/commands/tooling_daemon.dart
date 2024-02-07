// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:dtd_impl/dart_tooling_daemon.dart' as dtd
    show DartToolingDaemonOptions;

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
        );

  @override
  ArgParser createArgParser() {
    return dtd.DartToolingDaemonOptions.createArgParser(
      usageLineLength: dartdevUsageLineLength,
    );
  }

  @override
  Future<int> run() async {
    // Need to make a copy as argResults!.arguments is an
    // UnmodifiableListView object which cannot be passed as
    // the args for spawnUri.
    final args = [...argResults!.arguments];

    if (!Sdk.checkArtifactExists(sdk.dtdSnapshot)) return 255;

    var retval = 0;
    final result = Completer<int>();
    final exitPort = ReceivePort()
      ..listen((msg) {
        result.complete(0);
      });
    final errorPort = ReceivePort()
      ..listen((error) {
        log.stderr(error.toString());
        result.complete(255);
      });
    try {
      await Isolate.spawnUri(Uri.file(sdk.dtdSnapshot), args, null,
          onExit: exitPort.sendPort, onError: errorPort.sendPort);
      retval = await result.future;
    } catch (e, st) {
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      retval = 255;
    }
    errorPort.close();
    exitPort.close();
    return retval;
  }
}
