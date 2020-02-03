// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../core.dart';
import '../sdk.dart';

class FormatCommand extends DartdevCommand {
  FormatCommand({bool verbose = false})
      : super('format', 'Format one or more Dart files.');

  @override
  FutureOr<int> run() async {
    // TODO(jwren) The verbose flag was added to dartfmt in version 1.3.4 with
    // https://github.com/dart-lang/dart_style/pull/887, this version is rolled
    // into the dart sdk build, we can remove the removal of '-v' and
    // '--verbose':
    List<String> args = List.from(argResults.arguments)
      ..remove('-v')
      ..remove('--verbose');

    if (args.isEmpty) {
      args.add('--help');
    }

    var process = await startProcess(sdk.dartfmt, args);
    routeToStdout(process);
    return process.exitCode;
  }

  @override
  void printUsage() {
    var processResult = runSync(sdk.dartfmt, ['--help']);
    String result = processResult.stdout;
    print(result);
  }
}
