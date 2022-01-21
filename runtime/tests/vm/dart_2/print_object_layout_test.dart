// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// OtherResources=print_object_layout_script.dart

// Test for --print-object-layout-to option of gen_snapshot.

import 'dart:convert' show jsonDecode;
import 'dart:math' show max;
import 'dart:io' show File, Platform;

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'use_flag_test_helper.dart';

verifyObjectLayout(String path) {
  final classes = jsonDecode(File(path).readAsStringSync());
  var sizeA, fieldsA;
  var sizeB, fieldsB;
  for (var cls in classes) {
    if (cls['class'] == 'ClassA') {
      sizeA = cls['size'].toInt();
      fieldsA = cls['fields'];
      print(cls);
    } else if (cls['class'] == 'ClassB') {
      sizeB = cls['size'].toInt();
      fieldsB = cls['fields'];
      print(cls);
    }
  }
  Expect.isNotNull(sizeA);
  Expect.isTrue(sizeA > 0);
  Expect.isTrue(fieldsA.length == 2);
  int maxOffsetA = 0;
  for (var field in fieldsA) {
    String fieldName = field['field'];
    Expect.isTrue(fieldName == 'fieldA1' || fieldName == 'fieldA2');
    int offset = field['offset'].toInt();
    Expect.isTrue((offset > 0) && (offset < sizeA));
    maxOffsetA = max(offset, maxOffsetA);
  }

  Expect.isNotNull(sizeB);
  Expect.isTrue(sizeB > 0);
  Expect.isTrue(sizeA <= sizeB);
  Expect.isTrue(fieldsB.length == 3);
  for (var field in fieldsB) {
    String fieldName = field['field'];
    if (fieldName == 'staticB4') {
      Expect.isTrue(field['static']);
    } else {
      Expect.isTrue(fieldName == 'fieldB1' || fieldName == 'fieldB2');
      int offset = field['offset'].toInt();
      Expect.isTrue((offset > 0) && (offset < sizeB));
      Expect.isTrue(offset > maxOffsetA);
    }
  }
}

main() async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }

  final testScriptUri =
      Platform.script.resolve('print_object_layout_script.dart');

  await withTempDir('print-object-layout-test', (String temp) async {
    final appDillPath = path.join(temp, 'app.dill');
    final snapshotPath = path.join(temp, 'aot.snapshot');
    final objectLayoutPath = path.join(temp, 'layout.json');

    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '--output=$appDillPath',
      testScriptUri.toFilePath(),
    ]);

    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-elf',
      '--elf=$snapshotPath',
      '--print-object-layout-to=$objectLayoutPath',
      appDillPath,
    ]);

    verifyObjectLayout(objectLayoutPath);
  });
}
