// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.reanalyze;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ReanalyzeTest);
}


@ReflectiveTestCase()
class ReanalyzeTest extends AbstractAnalysisTest {
  test_reanalyze() {
    createProject();
    List<AnalysisContext> contexts = server.folderMap.values.toList();
    expect(contexts, hasLength(1));
    AnalysisContext oldContext = contexts[0];
    // Reanalyze should cause a brand new context to be built.
    Request request = new Request("0", ANALYSIS_REANALYZE);
    handleSuccessfulRequest(request);
    contexts = server.folderMap.values.toList();
    expect(contexts, hasLength(1));
    AnalysisContext newContext = contexts[0];
    expect(newContext, isNot(same(oldContext)));
  }
}