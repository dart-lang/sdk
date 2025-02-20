// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/src/arg_parser.dart';

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

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
  Future<int> run() async {
    // Need to make a copy as argResults!.arguments is an
    // UnmodifiableListView object which cannot be passed as
    // the args for spawnUri.
    final args = [...argResults!.arguments];
    return await runFromSnapshot(
      snapshot: sdk.ddsSnapshot,
      args: args,
      verbose: verbose,
    );
  }
}
