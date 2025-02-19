// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  late String testCode;
  late ParsedUnitResult testParsedResult;
  late ResolvedLibraryResult? testLibraryResult;
  late ResolvedUnitResult testAnalysisResult;
  late CompilationUnit testUnit;
  late FindNode findNode;
  late FindElement2 findElement2;

  late LibraryElement2 testLibraryElement;

  void addTestSource(String code) {
    testCode = code;
    newFile(testFile.path, code);
  }

  int findEnd(String search) {
    return findOffset(search) + search.length;
  }

  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNonNegative, reason: "Not found '$search' in\n$testCode");
    return offset;
  }

  @override
  Future<ParsedUnitResult> getParsedUnit(File file) async {
    var unitResult = await super.getParsedUnit(file);
    testParsedResult = unitResult;
    testCode = unitResult.content;
    testUnit = unitResult.unit;
    findNode = FindNode(testCode, testUnit);
    findElement2 = FindElement2(testUnit);
    return unitResult;
  }

  @override
  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var session = await this.session;
    testLibraryResult = await session.getResolvedContainingLibrary(file.path);
    var unitResult = testLibraryResult?.unitWithPath(file.path);
    unitResult ??= await super.getResolvedUnit(file);
    testAnalysisResult = unitResult;
    testCode = testAnalysisResult.content;
    testUnit = testAnalysisResult.unit;
    if (verifyNoTestUnitErrors) {
      expect(
        testAnalysisResult.errors.where((AnalysisError error) {
          return error.errorCode != WarningCode.DEAD_CODE &&
              error.errorCode != WarningCode.UNUSED_CATCH_CLAUSE &&
              error.errorCode != WarningCode.UNUSED_CATCH_STACK &&
              error.errorCode != WarningCode.UNUSED_ELEMENT &&
              error.errorCode != WarningCode.UNUSED_FIELD &&
              error.errorCode != WarningCode.UNUSED_IMPORT &&
              error.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE;
        }),
        isEmpty,
      );
    }

    testLibraryElement = testUnit.declaredFragment!.element;
    findNode = FindNode(testCode, testUnit);
    findElement2 = FindElement2(testUnit);
    return testAnalysisResult;
  }

  Future<void> parseTestCode(String code) async {
    addTestSource(code);
    await getParsedUnit(testFile);
  }

  Future<void> resolveTestCode(String code) async {
    addTestSource(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    await getResolvedUnit(testFile);
  }
}
