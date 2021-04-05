// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  Future<void> test_setSubscriptions() async {
    // This test times out on the bots and has been disabled to keep them green.
    // We need to discover the cause and re-enable it.

    _fail(
        'This test times out on the bots and has been disabled to keep them green.'
        'We need to discover the cause and re-enable it.');

    var statusReceived = false;
    var analysisBegun = Completer();
    onServerStatus.listen((_) {
      statusReceived = true;
    });
    onAnalysisErrors.listen((_) {
      if (!analysisBegun.isCompleted) {
        analysisBegun.complete();
      }
    });
    await sendServerSetSubscriptions([]);

    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
main() {
  var x;
}''');
    standardAnalysisSetup(subscribeStatus: false);
    // Analysis should begin, but no server.status notification should be
    // received.
    await analysisBegun.future;

    expect(statusReceived, isFalse);
    await sendServerSetSubscriptions([ServerService.STATUS]);

    // Tickle test.dart just in case analysis has already completed.
    writeFile(pathname, '''
main() {
  var y;
}''');
    // Analysis should eventually complete, and we should be notified
    // about it.
    await analysisFinished;
  }
}
