// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void main() {
  final snapshotDir = Directory(
    Platform.script.resolve('../.dart_tool/pub/bin/observatory').toFilePath(),
  );
  if (snapshotDir.existsSync()) {
    print('Deleting previous observatory script snapshot at $snapshotDir');
    snapshotDir.deleteSync(recursive: true);
  }

  print('Globally activating observatory...');
  Process.runSync(Platform.resolvedExecutable, <String>[
    'pub',
    'global',
    'activate',
    '--source',
    'path',
    Platform.script.resolve('..').toFilePath(),
  ]);
  print('observatory has been globally activated.');

  try {
    Process.runSync('observatory', const <String>['--help']);
  } on ProcessException {
    stderr.writeln('''
WARNING: observatory is globally activated but not available on your path.
Be sure to add \$PUB_CACHE/bin/ to your path.
      ''');
  }
}
