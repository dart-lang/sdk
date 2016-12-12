// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_errors.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsBeforeTest);
    defineReflectiveTests(GetErrorsBeforeTest_Driver);
  });
}

class AbstractGetErrorsBeforeTest extends AnalysisDomainGetErrorsTest {
  AbstractGetErrorsBeforeTest() : super(false);
}

@reflectiveTest
class GetErrorsBeforeTest extends AbstractGetErrorsBeforeTest {}

@reflectiveTest
class GetErrorsBeforeTest_Driver extends AbstractGetErrorsBeforeTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  test_getErrors() {
    //   UnimplementedError: Server responded with an error:
    // {"error":{"code":"SERVER_ERROR","message":"Bad state: Should not be used with the new analysis driver","stackTrace":"
    // #0      ContextManagerImpl.folderMap (package:analysis_server/src/context_manager.dart:550:7)
    // #1      ContextManagerImpl.analysisContexts (package:analysis_server/src/context_manager.dart:546:53)
    // #2      AnalysisServer.analysisContexts (package:analysis_server/src/analysis_server.dart:453:22)
    // #3      AnalysisServer.getContextSourcePair (package:analysis_server/src/analysis_server.dart:722:37)
    // #4      AnalysisServer.getAnalysisContext (package:analysis_server/src/analysis_server.dart:590:12)
    // #5      AnalysisServer.onFileAnalysisComplete (package:analysis_server/src/analysis_server.dart:948:31)
    // #6      AnalysisDomainHandler.getErrors (package:analysis_server/src/domain_analysis.dart:54:16)
    // #7      AnalysisDomainHandler.handleRequest (package:analysis_server/src/domain_analysis.dart:201:16)
    // #8      AnalysisServer.handleRequest.<anonymous closure>.<anonymous closure> (package:analysis_server/src/analysis_server.dart:873:45)
    // #9      _PerformanceTagImpl.makeCurrentWhile (package:analyzer/src/generated/utilities_general.dart:189:15)
    // #10     AnalysisServer.handleRequest.<anonymous closure> (package:analysis_server/src/analysis_server.dart:869:50)
    // #11     _rootRun (dart:async/zone.dart:1150)
    // #12     _CustomZone.run (dart:async/zone.dart:1026)
    // #13     _CustomZone.runGuarded (dart:async/zone.dart:924)
    // #14     runZoned (dart:async/zone.dart:1501)
    // #15     AnalysisServer.handleRequest (package:analysis_server/src/analysis_server.dart:868:5)
    return super.test_getErrors();
  }
}
