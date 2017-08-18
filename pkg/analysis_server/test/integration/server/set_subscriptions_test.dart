// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  test_setSubscriptions() {
    // This test times out on the bots and has been disabled to keep them green.
    // We need to discover the cause and re-enable it.

    fail(
        'This test times out on the bots and has been disabled to keep them green.'
        'We need to discover the cause and re-enable it.');

    bool statusReceived = false;
    Completer analysisBegun = new Completer();
    onServerStatus.listen((_) {
      statusReceived = true;
    });
    onAnalysisErrors.listen((_) {
      if (!analysisBegun.isCompleted) {
        analysisBegun.complete();
      }
    });
    return sendServerSetSubscriptions([]).then((_) {
      String pathname = sourcePath('test.dart');
      writeFile(pathname, '''
main() {
  var x;
}''');
      standardAnalysisSetup(subscribeStatus: false);
      // Analysis should begin, but no server.status notification should be
      // received.
      return analysisBegun.future.then((_) {
        expect(statusReceived, isFalse);
        return sendServerSetSubscriptions([ServerService.STATUS]).then((_) {
          // Tickle test.dart just in case analysis has already completed.
          writeFile(pathname, '''
main() {
  var y;
}''');
          // Analysis should eventually complete, and we should be notified
          // about it.
          return analysisFinished;
        });
      });
    });
  }
}
