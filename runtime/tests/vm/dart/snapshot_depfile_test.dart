// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

import 'snapshot_test_helper.dart';

Future<void> main(List<String> args) async {
  if (!Platform.script.toFilePath().endsWith('.dart')) {
    print('This test must run from source');
    return;
  }

  await withTempDir((String temp) async {
    final snapshotPath = p.join(temp, 'snapshot_depfile_test.snapshot');
    final depfilePath = p.join(temp, 'snapshot_depfile_test.snapshot.d');

    await runDart('GENERATE SNAPSHOT', [
      '--snapshot=$snapshotPath',
      '--snapshot-depfile=$depfilePath',
      Platform.script.toFilePath(),
      '--child',
    ]);

    var depfileContents = await new File(depfilePath).readAsString();
    print(depfileContents);
    Expect.isTrue(depfileContents.contains('snapshot_depfile_test.snapshot:'),
        'depfile contains output');
    Expect.isTrue(depfileContents.contains('snapshot_depfile_test.dart'),
        'depfile contains input');
  });
}
