// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateDiagnosticInformationTest);
  });
}

@reflectiveTest
class UpdateDiagnosticInformationTest extends AbstractLspAnalysisServerTest {
  var sampleInfo1 = {
    'a': {'b': true, 'c': 1},
  };

  var sampleInfo2 = {
    'x': {'y': false, 'z': 1.234},
  };

  Future<void> test_set_object() async {
    await initialize();
    await updateDiagnosticInformation(sampleInfo1);
    expect(server.clientDiagnosticInformation, equals(sampleInfo1));
  }

  Future<void> test_update() async {
    await initialize();

    // First set.
    await updateDiagnosticInformation(sampleInfo1);
    expect(server.clientDiagnosticInformation, equals(sampleInfo1));

    // Then update.
    await updateDiagnosticInformation(sampleInfo2);
    expect(server.clientDiagnosticInformation, equals(sampleInfo2));
  }

  Future<void> test_update_null() async {
    await initialize();

    // First set.
    await updateDiagnosticInformation(sampleInfo1);
    expect(server.clientDiagnosticInformation, equals(sampleInfo1));

    // Then update.
    await updateDiagnosticInformation(null);
    expect(server.clientDiagnosticInformation, null);
  }
}
