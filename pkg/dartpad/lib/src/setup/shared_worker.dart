// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';

/// Command to write the `shared-worker.js` bootstrap script from
/// `package:dartpad`.
final class SetupSharedWorkerCommand extends Command<void> {
  @override
  final String name = 'shared-worker';

  @override
  final String description =
      'Write the shared-worker.js bootstrap script for '
      'DartPadSdk.sharedWorker.';

  SetupSharedWorkerCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      mandatory: true,
      valueHelp: 'file',
      help: 'Output file path for shared-worker.js.',
    );
  }

  @override
  void run() {
    final uri = Isolate.resolvePackageUriSync(
      Uri.parse('package:dartpad/src/asset/shared-worker.js'),
    );
    if (uri == null) {
      throw StateError(
        'Unable to resolve package:dartpad/src/asset/shared-worker.js.',
      );
    }
    final outFile = File(argResults!.option('output')!);
    outFile.parent.createSync(recursive: true);
    try {
      File.fromUri(uri).copySync(outFile.path);
    } on PathNotFoundException {
      throw StateError('Missing asset at ${uri.toFilePath()}');
    }
    print('Successfully wrote shared-worker.js to ${outFile.path}');
  }
}
