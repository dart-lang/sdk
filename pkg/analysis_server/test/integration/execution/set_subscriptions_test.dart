// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_subscribe() async {
    standardAnalysisSetup();
    // ignore: deprecated_member_use_from_same_package
    await sendExecutionSetSubscriptions([ExecutionService.LAUNCH_DATA]);
  }
}
