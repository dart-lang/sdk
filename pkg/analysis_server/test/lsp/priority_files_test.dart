// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PriorityFilesTest);
  });
}

@reflectiveTest
class PriorityFilesTest extends AbstractLspAnalysisServerTest {
  Future<void> test_close() async {
    await initialize();
    await openFile(mainFileUri, '');
    await closeFile(mainFileUri);

    expect(server.priorityFiles, isNot(contains(mainFilePath)));
    server.driverMap.values.forEach((driver) {
      expect(driver.priorityFiles, isNot(contains(mainFilePath)));
    });
  }

  Future<void> test_open() async {
    await initialize();
    await openFile(mainFileUri, '');

    expect(server.priorityFiles, contains(mainFilePath));
    server.driverMap.values.forEach((driver) {
      expect(driver.priorityFiles, contains(mainFilePath));
    });
  }
}
