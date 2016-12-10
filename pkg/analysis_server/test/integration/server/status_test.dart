// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatusTest);
    defineReflectiveTests(StatusTest_Driver);
  });
}

class AbstractStatusTest extends AbstractAnalysisServerIntegrationTest {
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
    writeFile(
        sourcePath('test.dart'),
        '''
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

@reflectiveTest
class StatusTest extends AbstractStatusTest {}

@reflectiveTest
class StatusTest_Driver extends AbstractStatusTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
