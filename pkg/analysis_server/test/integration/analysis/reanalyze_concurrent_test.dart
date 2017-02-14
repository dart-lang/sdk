// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This test verifies that if reanalysis is performed while reanalysis is in
 * progress, no problems occur.
 *
 * See dartbug.com/21448.
 */
import 'dart:async';

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReanalyzeTest);
    defineReflectiveTests(ReanalyzeTest_Driver);
  });
}

class AbstractReanalyzeTest extends AbstractAnalysisServerIntegrationTest {
  test_reanalyze_concurrent() {
    String pathname = sourcePath('test.dart');
    String text = '''
// Do a bunch of imports so that analysis has some work to do.
import 'dart:io';
import 'dart:convert';
import 'dart:async';

main() {}''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    return analysisFinished.then((_) {
      sendAnalysisReanalyze();
      // Wait for reanalysis to start.
      return onServerStatus.first.then((_) {
        sendAnalysisReanalyze();
        return analysisFinished.then((_) {
          // Now that reanalysis has finished, give the server an extra second
          // to make sure it doesn't crash.
          return new Future.delayed(new Duration(seconds: 1));
        });
      });
    });
  }
}

@reflectiveTest
class ReanalyzeTest extends AbstractReanalyzeTest {}

@reflectiveTest
class ReanalyzeTest_Driver extends AbstractReanalyzeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
