// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.set.subscriptions;

import 'dart:async';

import '../../reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_setSubscriptions() {
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
        return sendServerSetSubscriptions(['STATUS']).then((_) {
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

main() {
  runReflectiveTests(Test);
}
