// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.status;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_status() {
    // After we kick off analysis, we should get one server.status message with
    // analyzing=true, and another server.status message after that with
    // analyzing=false.
    Completer analysisBegun = new Completer();
    Completer analysisFinished = new Completer();
    onServerStatus.listen((ServerStatusParams params) {
      if (params.analysis != null) {
        if (params.analysis.isAnalyzing) {
          expect(analysisBegun.isCompleted, isFalse);
          analysisBegun.complete();
        } else {
          expect(analysisFinished.isCompleted, isFalse);
          analysisFinished.complete();
        }
      }
    });
    writeFile(sourcePath('test.dart'), '''
main() {
  var x;
}''');
    standardAnalysisSetup();
    expect(analysisBegun.isCompleted, isFalse);
    expect(analysisFinished.isCompleted, isFalse);
    return analysisBegun.future.then((_) {
      expect(analysisFinished.isCompleted, isFalse);
      return analysisFinished.future;
    });
  }
}

main() {
  runReflectiveTests(Test);
}
