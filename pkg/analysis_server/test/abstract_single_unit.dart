// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  /// Whether the test code should parse with position and range shorthands.
  ///
  /// Set this to `false` when the test code contains a legitimate carret
  /// or contains `[!` or `!]`.
  bool allowTestCodeShorthand = true;

  TestCode? _parsedTestCode;
  late ParsedUnitResult testParsedResult;
  late ResolvedLibraryResult? testLibraryResult;
  late ResolvedUnitResult testAnalysisResult;
  late CompilationUnit testUnit;
  late FindNode findNode;
  late FindElement2 findElement2;
  late LibraryElement testLibraryElement;
  TestCode get parsedTestCode => _parsedTestCode!;
  set parsedTestCode(TestCode value) {
    if (_parsedTestCode != null) {
      throw ArgumentError(
        'parsedTestCode is already set to ${_parsedTestCode!.code}',
      );
    }
    _parsedTestCode = value;
  }

  String get testCode => parsedTestCode.code;
  set testCode(String value) {
    parsedTestCode = TestCode.parseNormalized(
      value,
      positionShorthand: allowTestCodeShorthand,
      rangeShorthand: allowTestCodeShorthand,
    );
  }

  void addTestSource(String code) {
    testCode = code;
    newFile(testFile.path, testCode);
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
  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var session = await this.session;
    var libraryResult = await session.getResolvedContainingLibrary(file.path);
    var unitResult = libraryResult?.unitWithPath(file.path);
    unitResult ??= await super.getResolvedUnit(file);

    if (file.path == convertPath(testFilePath)) {
      testLibraryResult = libraryResult;
      testAnalysisResult = unitResult;
      testUnit = unitResult.unit;
      testLibraryElement = testUnit.declaredFragment!.element;
      findNode = FindNode(unitResult.content, testUnit);
      findElement2 = FindElement2(testUnit);
    }
    if (verifyNoTestUnitErrors) {
      expect(
        unitResult.diagnostics.where((d) {
          return d.diagnosticCode != WarningCode.deadCode &&
              d.diagnosticCode != WarningCode.unusedCatchClause &&
              d.diagnosticCode != WarningCode.unusedCatchStack &&
              d.diagnosticCode != WarningCode.unusedElement &&
              d.diagnosticCode != WarningCode.unusedField &&
              d.diagnosticCode != WarningCode.unusedImport &&
              d.diagnosticCode != WarningCode.unusedLocalVariable;
        }),
        isEmpty,
      );
    }
    return unitResult;
  }

  Future<void> parseTestCode(String code) async {
    addTestSource(code);
    testParsedResult = await getParsedUnit(testFile);
    testUnit = testParsedResult.unit;
    findNode = FindNode(testCode, testUnit);
    findElement2 = FindElement2(testUnit);
  }

  void putTestFileInTestDir() {
    testFilePath = '$testPackageTestPath/test.dart';
  }

  Future<void> resolveTestCode(String code) async {
    addTestSource(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    await getResolvedUnit(testFile);
  }

  void updateTestSource(String code) {
    if (_parsedTestCode == null) {
      throw StateError('testCode is not set');
    }
    _parsedTestCode = null;
    addTestSource(code);
  }
}
