// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show RefactoringProblemSeverity, SourceChange, SourceEdit;
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

import '../../../abstract_single_unit.dart';
import '../../../selection_mixin.dart';

int findIdentifierLength(String search) {
  var length = 0;
  while (length < search.length) {
    var c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
        c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
        c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}

/// The base class for all [Refactoring] tests.
abstract class RefactoringTest extends AbstractSingleUnitTest
    with SelectionMixin {
  late SourceChange refactoringChange;

  Refactoring get refactoring;

  RefactoringWorkspace get refactoringWorkspace =>
      RefactoringWorkspace([driverFor(testFile)], searchEngine);

  SearchEngine get searchEngine => SearchEngineImpl([driverFor(testFile)]);

  /// Asserts that [refactoringChange] contains a [FileEdit] for the file
  /// with the given [path], and it results the [expectedCode].
  void assertFileChangeResult(String path, String expectedCode) {
    expectedCode = normalizeSource(expectedCode);
    // prepare FileEdit
    var fileEdit = refactoringChange.getFileEdit(convertPath(path));
    if (fileEdit == null) {
      fail('No file edit for $path');
    }
    // validate resulting code
    var file = getFile(path);
    var ini = file.readAsStringSync();
    var actualCode = SourceEdit.applySequence(ini, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /// Asserts that [refactoringChange] does not contain a [FileEdit] for the
  /// file with the given [path].
  void assertNoFileChange(String path) {
    var fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNull);
  }

  /// Asserts that [refactoring] initial/final conditions status is OK.
  Future<void> assertRefactoringConditionsOK() async {
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /// Asserts that [refactoring] final conditions status is OK.
  Future<void> assertRefactoringFinalConditionsOK() async {
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /// Asserts that [status] has expected severity and message.
  void assertRefactoringStatus(
    RefactoringStatus status,
    RefactoringProblemSeverity? expectedSeverity, {
    String? expectedMessage,
    SourceRange? expectedContextRange,
    String? expectedContextSearch,
    int? rangeIndex,
  }) {
    expect(status.severity, expectedSeverity, reason: status.toString());
    if (expectedSeverity != null) {
      var problem = status.problem!;
      expect(problem.severity, expectedSeverity);
      if (expectedMessage != null) {
        expect(problem.message, expectedMessage);
      }
      if (expectedContextRange != null) {
        var location = problem.location!;
        expect(location.offset, expectedContextRange.offset);
        expect(location.length, expectedContextRange.length);
      }
      if (expectedContextSearch != null) {
        var location = problem.location!;
        var expectedOffset = findOffset(expectedContextSearch);
        var expectedLength = findIdentifierLength(expectedContextSearch);
        expect(location.offset, expectedOffset);
        expect(location.length, expectedLength);
      } else if (rangeIndex != null) {
        var location = problem.location!;
        setRange(rangeIndex);
        expect(location.offset, offset);
        expect(location.length, length);
      }
    }
  }

  /// Asserts that [refactoring] status is OK.
  void assertRefactoringStatusOK(RefactoringStatus status) {
    assertRefactoringStatus(status, null);
  }

  void assertSourceChange(SourceChange sourceChange, String expected) {
    var buffer = StringBuffer();
    _writeSourceChangeToBuffer(buffer: buffer, sourceChange: sourceChange);
    _assertTextExpectation(buffer.toString(), expected);
  }

  /// Checks that all conditions of [refactoring] are OK and the result of
  /// applying the [SourceChange] to [testUnit] is [expectedCode].
  Future<void> assertSuccessfulRefactoring(String expectedCode) async {
    expectedCode = normalizeSource(expectedCode);
    await assertRefactoringConditionsOK();
    var change = await refactoring.createChange();
    refactoringChange = change;
    assertTestChangeResult(expectedCode);
  }

  /// Checks that all conditions of [refactoring] are OK, and the computed
  /// [SourceChange] matches the expectations.
  Future<void> assertSuccessfulRefactoring2(String expected) async {
    expected = normalizeSource(expected);
    await assertRefactoringConditionsOK();
    var change = await refactoring.createChange();
    assertSourceChange(change, expected);
  }

  /// Asserts that [refactoringChange] contains a [FileEdit] for [testFile], and
  /// it results the [expectedCode].
  void assertTestChangeResult(String expectedCode) {
    expectedCode = normalizeSource(expectedCode);
    // prepare FileEdit
    var fileEdit = refactoringChange.getFileEdit(testFile.path);
    if (fileEdit == null) {
      fail('No file edit for $testFile');
    }
    // validate resulting code
    var actualCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    if (actualCode != expectedCode) {
      print(actualCode);
    }
    expect(actualCode, expectedCode);
  }

  /// Returns the existing analysis driver that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver driverFor(File file) {
    return contextFor(file).driver;
  }

  Future<void> indexTestUnit(
    String code, {
    List<DiagnosticCode>? ignore,
  }) async {
    // Make it priority, so the resolved unit stays in memory.
    // So, when we get a local element, and search for it, we use this unit.
    // This is important when local elements equality is identity.
    driverFor(testFile).priorityFiles2 = [testFile];

    await resolveTestCode(code, ignore: ignore);
  }

  Future<void> indexUnit(String file, String code) async {
    newFile(file, code);
  }

  @override
  void setUp() {
    registerLintRules();
    super.setUp();
  }

  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }

  void _writeSourceChangeToBuffer({
    required StringBuffer buffer,
    required SourceChange sourceChange,
  }) {
    for (var fileEdit in sourceChange.edits) {
      var file = getFile(fileEdit.file);
      buffer.write('>>>>>>>>>> ${file.posixPath}$eol');
      var current = file.readAsStringSync();
      var updated = SourceEdit.applySequence(current, fileEdit.edits);
      buffer.write(updated);
    }
  }
}
