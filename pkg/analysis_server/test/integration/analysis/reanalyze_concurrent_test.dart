// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This test verifies that if reanalysis is performed while reanalysis is in
 * progress, no problems occur.
 *
 * See dartbug.com/21448.
 */
library test.integration.analysis.reanalyze_concurrent;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(Test);
}

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
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
          // Now that reanalysis has finished, no further analysis should occur.
          onServerStatus.listen((ServerStatusParams data) {
            if (data.analysis != null) {
              if (data.analysis.isAnalyzing) {
                // Most likely what happened is that the first reanalyze
                // completed before the second reanalyze had a chance to start,
                // and we are just now starting the second reanalyze.  If this
                // is the case, then the test isn't testing what it's meant to
                // test (because we are trying to test what happens when one
                // reanalyze starts while another is in progress).  In which
                // case we will need to give the analyzer more work to do.
                fail('First reanalyze finished before second started.');
              }
            }
          });
          // Give the server an extra second to make sure it doesn't take any
          // more actions.
          return new Future.delayed(new Duration(seconds: 1));
        });
      });
    });
  }
}
