// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  /// Whether to rewrite line endings in test code based on platform.
  bool useLineEndingsForPlatform = false;

  late String testCode;
  late ParsedUnitResult testParsedResult;
  late ResolvedUnitResult testAnalysisResult;
  late CompilationUnit testUnit;
  late CompilationUnitElement testUnitElement;
  late LibraryElement testLibraryElement;
  late FindNode findNode;
  late FindElement findElement;

  void addTestSource(String code) {
    code = normalizeSource(code);
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
    var result = await super.getParsedUnit(file);
    testParsedResult = result;
    testCode = result.content;
    testUnit = result.unit;
    findNode = FindNode(testCode, testUnit);
    findElement = FindElement(testUnit);
    return result;
  }

  @override
  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var result = await super.getResolvedUnit(file);
    testAnalysisResult = result;
    testCode = result.content;
    testUnit = result.unit;
    if (verifyNoTestUnitErrors) {
      expect(result.errors.where((AnalysisError error) {
        return error.errorCode != WarningCode.DEAD_CODE &&
            error.errorCode != WarningCode.UNUSED_CATCH_CLAUSE &&
            error.errorCode != WarningCode.UNUSED_CATCH_STACK &&
            error.errorCode != WarningCode.UNUSED_ELEMENT &&
            error.errorCode != WarningCode.UNUSED_FIELD &&
            error.errorCode != WarningCode.UNUSED_IMPORT &&
            error.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE;
      }), isEmpty);
    }
    testUnitElement = testUnit.declaredElement!;
    testLibraryElement = testUnitElement.library;
    findNode = FindNode(testCode, testUnit);
    findElement = FindElement(testUnit);
    return result;
  }

  @override
  File newFile(String path, String content) {
    content = normalizeSource(content);
    return super.newFile(path, content);
  }

  /// Convenient function to normalize newlines in [code] for the current
  /// platform if [useLineEndingsForPlatform] is `true`.
  String normalizeSource(String code) =>
      useLineEndingsForPlatform ? normalizeNewlinesForPlatform(code) : code;

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
