// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../core.dart';
import '../sdk.dart';

class FormatCommand extends DartdevCommand {
  FormatCommand({bool verbose = false})
      : super('format', 'Format one or more Dart files.') {
    // TODO(jwren) add all options and flags
  }

  @override
  FutureOr<int> run() async {
    // TODO(jwren) implement verbose in dart_style
    // dartfmt doesn't have '-v' or '--verbose', so remove from the argument list
    var args = List.from(argResults.arguments)
      ..remove('-v')
      ..remove('--verbose');
    var process = await startProcess(sdk.dartfmt, args);
    routeToStdout(process);
    return process.exitCode;
  }
}
