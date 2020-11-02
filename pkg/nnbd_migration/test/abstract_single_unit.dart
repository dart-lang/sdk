// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

/// TODO(paulberry): this logic is duplicated from other packages.  Find a way
/// share it, or avoid relying on it.
class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  String testCode;
  String testFile;
  Uri testUri;
  Source testSource;
  ResolvedUnitResult testAnalysisResult;
  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;
  FindNode findNode;
  FindElement findElement;

  void addTestSource(String code, [Uri uri]) {
    testCode = code;
    testSource = addSource(testFile, code, uri);
  }

  Future<void> resolveTestUnit(String code) async {
    addTestSource(code, testUri);
    testAnalysisResult = await session.getResolvedUnit(testFile);
    testUnit = testAnalysisResult.unit;
    if (verifyNoTestUnitErrors) {
      expect(testAnalysisResult.errors.where((AnalysisError error) {
        return error.errorCode != HintCode.DEAD_CODE &&
            error.errorCode != HintCode.UNUSED_CATCH_CLAUSE &&
            error.errorCode != HintCode.UNUSED_CATCH_STACK &&
            error.errorCode != HintCode.UNUSED_ELEMENT &&
            error.errorCode != HintCode.UNUSED_ELEMENT_PARAMETER &&
            error.errorCode != HintCode.UNUSED_FIELD &&
            error.errorCode != HintCode.UNUSED_IMPORT &&
            error.errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
      }), isEmpty);
    }
    testUnitElement = testUnit.declaredElement;
    testLibraryElement = testUnitElement.library;
    findNode = FindNode(code, testUnit);
    findElement = FindElement(testUnit);
  }

  @override
  void setUp() {
    var testRoot = testsPath;
    if (analyzeWithNnbd) {
      newFile('$testRoot/analysis_options.yaml', content: '''
analyzer:
  enable-experiment:
    - non-nullable
''');
    }
    if (analyzeWithNnbd) {
      newFile('$testRoot/pubspec.yaml', content: '''
name: tests
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
    }
    super.setUp();
    testFile = convertPath('$testRoot/lib/test.dart');
    testUri = Uri.parse('package:tests/test.dart');
  }
}
