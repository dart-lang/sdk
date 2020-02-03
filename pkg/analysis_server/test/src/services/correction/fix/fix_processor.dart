// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';

import '../../../../abstract_single_unit.dart';

/// A base class defining support for writing fix processor tests that are
/// specific to fixes associated with lints that use the FixKind.
abstract class FixProcessorLintTest extends FixProcessorTest {
  /// The marker used to indicate where the lint is expected to be found.
  static const lintMarker = '/*LINT*/';

  /// The offset of the lint marker in the code being analyzed.
  int lintOffset = -1;

  /// Return the lint code being tested.
  String get lintCode;

  @override
  Future<void> resolveTestUnit(String code) async {
    createAnalysisOptionsFile(lints: [lintCode]);
    lintOffset = code.indexOf(lintMarker);
    if (lintOffset < 0) {
      return super.resolveTestUnit(code);
    }
    var endOffset = lintOffset + lintMarker.length;
    code = code.substring(0, lintOffset) + code.substring(endOffset);
    return super.resolveTestUnit(code);
  }

  /// Find the error that is to be fixed by computing the errors in the file,
  /// using the [errorFilter] to filter out errors that should be ignored, and
  /// expecting that there is a single remaining error. The error filter should
  /// return `true` if the error should not be ignored.
  @override
  Future<AnalysisError> _findErrorToFix(
      bool Function(AnalysisError) errorFilter,
      {int length}) async {
    if (lintOffset < 0) {
      return super._findErrorToFix(errorFilter, length: 0);
    }
    return AnalysisError(
        testSource, lintOffset, length ?? 0, LintCode(lintCode, '<ignored>'));
  }
}

/// A base class defining support for writing fix processor tests.
abstract class FixProcessorTest extends AbstractSingleUnitTest {
  /// The errors in the file for which fixes are being computed.
  List<AnalysisError> _errors;

  /// The source change associated with the fix that was found, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  SourceChange change;

  /// The result of applying the [change] to the file content, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  String resultCode;

  /// Return the kind of fixes being tested by this test class.
  FixKind get kind;

  /// The workspace in which fixes contributor operates.
  ChangeWorkspace get workspace {
    return DartChangeWorkspace([session]);
  }

  Future<void> assertHasFix(String expected,
      {bool Function(AnalysisError) errorFilter,
      int length,
      String target,
      int expectedNumberOfFixesForKind,
      String matchFixMessage}) async {
    AnalysisError error = await _findErrorToFix(errorFilter, length: length);
    Fix fix = await _assertHasFix(error,
        expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
        matchFixMessage: matchFixMessage);
    change = fix.change;

    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    String fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  void assertHasFixAllFix(ErrorCode errorCode, String expected,
      {String target}) async {
    AnalysisError error = await _findErrorToFixOfType(errorCode);
    Fix fix = await _assertHasFixAllFix(error);
    change = fix.change;

    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    String fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  Future<void> assertHasFixWithoutApplying(
      {bool Function(AnalysisError) errorFilter}) async {
    AnalysisError error = await _findErrorToFix(errorFilter);
    Fix fix = await _assertHasFix(error);
    change = fix.change;
  }

  void assertLinkedGroup(LinkedEditGroup group, List<String> expectedStrings,
      [List<LinkedEditSuggestion> expectedSuggestions]) {
    List<Position> expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Compute fixes for all of the errors in the test file to effectively assert
  /// that no exceptions will be thrown by doing so.
  Future<void> assertNoExceptions() async {
    List<AnalysisError> errors = await _computeErrors();
    for (var error in errors) {
      await _computeFixes(error);
    }
  }

  /// Compute fixes and ensure that there is no fix of the [kind] being tested by
  /// this class.
  Future<void> assertNoFix({bool Function(AnalysisError) errorFilter}) async {
    AnalysisError error = await _findErrorToFix(errorFilter);
    await _assertNoFix(error);
  }

  List<LinkedEditSuggestion> expectedSuggestions(
      LinkedEditSuggestionKind kind, List<String> values) {
    return values.map((value) {
      return LinkedEditSuggestion(value, kind);
    }).toList();
  }

  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
  }

  /// Computes fixes and verifies that there is a fix for the given [error] of the appropriate kind.
  /// Optionally, if a [matchFixMessage] is passed, then the kind as well as the fix message must
  /// match to be returned.
  Future<Fix> _assertHasFix(AnalysisError error,
      {int expectedNumberOfFixesForKind, String matchFixMessage}) async {
    // Compute the fixes for this AnalysisError
    final List<Fix> fixes = await _computeFixes(error);

    if (expectedNumberOfFixesForKind != null) {
      int actualNumberOfFixesForKind = 0;
      for (Fix fix in fixes) {
        if (fix.kind == kind) {
          actualNumberOfFixesForKind++;
        }
      }
      if (actualNumberOfFixesForKind != expectedNumberOfFixesForKind) {
        fail('Expected $expectedNumberOfFixesForKind fixes of kind $kind,'
            ' but found $actualNumberOfFixesForKind:\n${fixes.join('\n')}');
      }
    }

    // If a matchFixMessage was provided,
    if (matchFixMessage != null) {
      for (Fix fix in fixes) {
        if (matchFixMessage == fix?.change?.message) {
          return fix;
        }
      }
      if (fixes.isEmpty) {
        fail('Expected to find fix $kind with name $matchFixMessage'
            ' but there were no fixes.');
      } else {
        fail('Expected to find fix $kind with name $matchFixMessage'
            ' in\n${fixes.join('\n')}');
      }
    }

    // Assert that none of the fixes are a fix-all fix.
    Fix foundFix;
    for (Fix fix in fixes) {
      if (fix.isFixAllFix()) {
        fail('A fix-all fix was found for the error: $error '
            'in the computed set of fixes:\n${fixes.join('\n')}');
      } else if (fix.kind == kind) {
        foundFix ??= fix;
      }
    }
    if (foundFix == null) {
      fail('Expected to find fix $kind in\n${fixes.join('\n')}');
    }
    return foundFix;
  }

  /// Computes fixes and verifies that there is a fix for the given [error] of
  /// the appropriate kind.
  Future<Fix> _assertHasFixAllFix(AnalysisError error) async {
    if (!kind.canBeAppliedTogether()) {
      fail('Expected to find and return fix-all FixKind for $kind, '
          'but kind.canBeAppliedTogether is ${kind.canBeAppliedTogether}');
    }

    // Compute the fixes for the error.
    List<Fix> fixes = await _computeFixes(error);

    // Assert that there exists such a fix in the list.
    Fix foundFix;
    for (Fix fix in fixes) {
      if (fix.kind == kind && fix.isFixAllFix()) {
        foundFix = fix;
        break;
      }
    }
    if (foundFix == null) {
      fail('No fix-all fix was found for the error: $error '
          'in the computed set of fixes:\n${fixes.join('\n')}');
    }
    return foundFix;
  }

  Future<void> _assertNoFix(AnalysisError error) async {
    List<Fix> fixes = await _computeFixes(error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Future<List<AnalysisError>> _computeErrors() async {
    if (_errors == null) {
      if (testAnalysisResult != null) {
        _errors = testAnalysisResult.errors;
      }
      if (_errors == null) {
        var result = await session.getResolvedUnit(testFile);
        _errors = result.errors;
      }
    }
    return _errors;
  }

  /// Computes fixes for the given [error] in [testUnit].
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    tracker.addContext(driver.analysisContext);

    var context = DartFixContextImpl(
      workspace,
      testAnalysisResult,
      error,
      (name) {
        var provider = TopLevelDeclarationsProvider(tracker);
        provider.doTrackerWork();
        return provider.get(driver.analysisContext, testFile, name);
      },
    );
    return await DartFixContributor().computeFixes(context);
  }

  /// Find the error that is to be fixed by computing the errors in the file,
  /// using the [errorFilter] to filter out errors that should be ignored, and
  /// expecting that there is a single remaining error. The error filter should
  /// return `true` if the error should not be ignored.
  Future<AnalysisError> _findErrorToFix(
      bool Function(AnalysisError) errorFilter,
      {int length}) async {
    List<AnalysisError> errors = await _computeErrors();
    if (errorFilter != null) {
      if (errors.length == 1) {
        fail('Unnecessary error filter');
      }
      errors = errors.where(errorFilter).toList();
    }
    if (errors.isEmpty) {
      fail('Expected one error, found: none');
    } else if (errors.length > 1) {
      StringBuffer buffer = StringBuffer();
      buffer.writeln('Expected one error, found:');
      for (AnalysisError error in errors) {
        buffer.writeln('  $error [${error.errorCode}]');
      }
      fail(buffer.toString());
    }
    return errors[0];
  }

  Future<AnalysisError> _findErrorToFixOfType(ErrorCode errorCode) async {
    List<AnalysisError> errors = await _computeErrors();
    for (AnalysisError error in errors) {
      if (error.errorCode == errorCode) {
        return error;
      }
    }
    return null;
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    List<Position> positions = <Position>[];
    for (String search in searchStrings) {
      int offset = resultCode.indexOf(search);
      positions.add(Position(testFile, offset));
    }
    return positions;
  }
}
