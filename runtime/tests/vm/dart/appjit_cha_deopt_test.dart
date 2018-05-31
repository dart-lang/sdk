// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=100

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

import 'snapshot_test_helper.dart';

const snapshotName = 'app.jit';

Future<void> main() async {
  final Directory temp = Directory.systemTemp.createTempSync();
  final snapshotPath = p.join(temp.path, 'app.jit');
  final testPath = Platform.script
      .toFilePath()
      .replaceAll(new RegExp(r'_test.dart$'), '_test_body.dart');

  await temp.create();
  try {
    final trainingResult = await runDartBinary('TRAINING RUN', [
      '--snapshot=$snapshotPath',
      '--snapshot-kind=app-jit',
      testPath,
      '--train'
    ]);
    expectOutput("OK(Trained)", trainingResult);
    final runResult = await runDartBinary('RUN FROM SNAPSHOT', [snapshotPath]);
    expectOutput("OK(Run)", runResult);
  } finally {
    await temp.delete(recursive: true);
  }
}
