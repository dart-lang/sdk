// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetDartfixInfoTest);
  });
}

@reflectiveTest
class GetDartfixInfoTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_getDartfixInfo() async {
    standardAnalysisSetup();
    var info = await sendEditGetDartfixInfo();
    expect(info.fixes.length, greaterThanOrEqualTo(3));
  }
}
