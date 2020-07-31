// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../core.dart';
import '../sdk.dart';

class FormatCommand extends DartdevCommand {
  FormatCommand() : super('format', 'Format Dart source code.') {
    // TODO(jwren) When https://github.com/dart-lang/dart_style/issues/889
    //  is resolved, have dart_style provide the ArgParser, instead of creating
    // one here.
    argParser
      ..addFlag('dry-run',
          abbr: 'n',
          help: 'Show which files would be modified but make no changes.')
      ..addFlag('set-exit-if-changed',
          help: 'Return exit code 1 if there are any formatting changes.')
      ..addFlag('machine',
          abbr: 'm', help: 'Produce machine-readable JSON output.')
      ..addOption('line-length',
          abbr: 'l',
          help:
              'Wrap lines longer than this length. Defaults to 80 characters.',
          defaultsTo: '80');
  }

  @override
  FutureOr<int> run() async {
    List<String> args = List.from(argResults.arguments);

    // By printing and returning if there are no arguments, this changes the
    // default unix-pipe behavior of dartfmt:
    if (args.isEmpty) {
      printUsage();
      return 0;
    }

    // By always adding '--overwrite', the default behavior of dartfmt by
    // is changed to have the UX of 'flutter format *'.  The flag is not added
    // if 'dry-run' has been passed as they are not compatible.
    if (!argResults['dry-run']) {
      args.add('--overwrite');
    }

    var process = await startProcess(sdk.dartfmt, args);
    routeToStdout(process);
    return process.exitCode;
  }
}
