// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.domain;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';
import 'protocol_matchers.dart';

@ReflectiveTestCase()
class ServerDomainIntegrationTest extends AbstractAnalysisServerIntegrationTest
    {
  test_getVersion() {
    return server.send(SERVER_GET_VERSION, null).then((response) {
      expect(response, isServerGetVersionResult);
    });
  }

  test_shutdown() {
    return server.send(SERVER_SHUTDOWN, null).then((response) {
      expect(response, isNull);
      return new Future.delayed(new Duration(seconds: 1)).then((_) {
        server.send(SERVER_GET_VERSION, null).then((_) {
          fail('Server still alive after server.shutdown');
        });
        // Give the server time to respond before terminating the test.
        return new Future.delayed(new Duration(seconds: 1));
      });
    });
  }

  fail_test_setSubscriptions() {
    // TODO(paulberry): fix the server so that it passes this test.
    bool statusReceived = false;
    Completer analysisBegun = new Completer();
    server.onNotification(SERVER_STATUS).listen((_) {
      statusReceived = true;
    });
    server.onNotification(ANALYSIS_ERRORS).listen((_) {
      if (!analysisBegun.isCompleted) {
        analysisBegun.complete();
      }
    });
    return server_setSubscriptions([]).then((response) {
      expect(response, isNull);
      writeFile('test.dart', '''
main() {
  var x;
}''');
      setAnalysisRoots(['']);
      // Analysis should begin, but no server.status notification should be
      // received.
      return analysisBegun.future.then((_) {
        expect(statusReceived, isFalse);
        return server_setSubscriptions(['STATUS']).then((_) {
          // Tickle test.dart just in case analysis has already completed.
          writeFile('test.dart', '''
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

  test_setSubscriptions_invalidService() {
    // TODO(paulberry): verify that if an invalid service is specified, the
    // current subscriptions are unchanged.
    return server_setSubscriptions(['bogus']).then((_) {
      fail('setSubscriptions should have produced an error');
    }, onError: (error) {
      // The expected error occurred.
    });
  }

  test_connected() {
    expect(serverConnectedParams, isNull);
  }

  test_error() {
    // TODO(paulberry): how do we test the 'server.error' notification given
    // that this notification should only occur in the event of a server bug?
  }

  test_status() {
    // TODO(paulberry): spec says that server.status is not subscribed to by
    // default, but currently it's behaving as though it is.

    // After we kick off analysis, we should get one server.status message with
    // analyzing=true, and another server.status message after that with
    // analyzing=false.
    Completer analysisBegun = new Completer();
    Completer analysisFinished = new Completer();
    server.onNotification(SERVER_STATUS).listen((params) {
      expect(params, isServerStatusParams);
      if (params['analysis'] != null) {
        if (params['analysis']['analyzing']) {
          expect(analysisBegun.isCompleted, isFalse);
          analysisBegun.complete();
        } else {
          expect(analysisFinished.isCompleted, isFalse);
          analysisFinished.complete();
        }
      }
    });
    writeFile('test.dart', '''
main() {
  var x;
}''');
    setAnalysisRoots(['']);
    expect(analysisBegun.isCompleted, isFalse);
    expect(analysisFinished.isCompleted, isFalse);
    return analysisBegun.future.then((_) {
      expect(analysisFinished.isCompleted, isFalse);
      return analysisFinished.future;
    });
  }
}

main() {
  runReflectiveTests(ServerDomainIntegrationTest);
}
