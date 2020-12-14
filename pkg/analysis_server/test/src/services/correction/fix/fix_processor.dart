// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../../../abstract_context.dart';
import '../../../../abstract_single_unit.dart';
import '../../../../utils/test_instrumentation_service.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

/// A base class defining support for writing fix processor tests that are
/// specific to fixes associated with lints that use the FixKind.
abstract class FixProcessorLintTest extends FixProcessorTest {
  /// Return the lint code being tested.
  String get lintCode;

  bool Function(AnalysisError) lintNameFilter(String name) {
    return (e) {
      return e.errorCode is LintCode && e.errorCode.name == name;
    };
  }

  @override
  void setUp() {
    super.setUp();
    createAnalysisOptionsFile(
      lints: [lintCode],
    );
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
    if (useLineEndingsForPlatform) {
      expected = normalizeNewlinesForPlatform(expected);
    }
    var error = await _findErrorToFix(errorFilter, length: length);
    var fix = await _assertHasFix(error,
        expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
        matchFixMessage: matchFixMessage);
    change = fix.change;

    // apply to "file"
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  Future<void> assertHasFixAllFix(ErrorCode errorCode, String expected,
      {String target}) async {
    if (useLineEndingsForPlatform) {
      expected = normalizeNewlinesForPlatform(expected);
    }
    var error = await _findErrorToFixOfType(errorCode);
    var fix = await _assertHasFixAllFix(error);
    change = fix.change;

    // apply to "file"
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  Future<void> assertHasFixWithoutApplying(
      {bool Function(AnalysisError) errorFilter}) async {
    var error = await _findErrorToFix(errorFilter);
    var fix = await _assertHasFix(error);
    change = fix.change;
  }

  void assertLinkedGroup(LinkedEditGroup group, List<String> expectedStrings,
      [List<LinkedEditSuggestion> expectedSuggestions]) {
    var expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Compute fixes for all of the errors in the test file to effectively assert
  /// that no exceptions will be thrown by doing so.
  Future<void> assertNoExceptions() async {
    var errors = await _computeErrors();
    for (var error in errors) {
      await _computeFixes(error);
    }
  }

  /// Compute fixes and ensure that there is no fix of the [kind] being tested by
  /// this class.
  Future<void> assertNoFix({bool Function(AnalysisError) errorFilter}) async {
    var error = await _findErrorToFix(errorFilter);
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
    useLineEndingsForPlatform = true;
  }

  /// Computes fixes and verifies that there is a fix for the given [error] of the appropriate kind.
  /// Optionally, if a [matchFixMessage] is passed, then the kind as well as the fix message must
  /// match to be returned.
  Future<Fix> _assertHasFix(AnalysisError error,
      {int expectedNumberOfFixesForKind, String matchFixMessage}) async {
    // Compute the fixes for this AnalysisError
    var fixes = await _computeFixes(error);

    if (expectedNumberOfFixesForKind != null) {
      var actualNumberOfFixesForKind = 0;
      for (var fix in fixes) {
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
      for (var fix in fixes) {
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
    for (var fix in fixes) {
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
    var fixes = await _computeFixes(error);

    // Assert that there exists such a fix in the list.
    Fix foundFix;
    for (var fix in fixes) {
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
    var fixes = await _computeFixes(error);
    for (var fix in fixes) {
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
    var analysisContext = contextFor(testFile);

    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    tracker.addContext(analysisContext);

    var context = DartFixContextImpl(
      TestInstrumentationService(),
      workspace,
      testAnalysisResult,
      error,
      (name) {
        var provider = TopLevelDeclarationsProvider(tracker);
        provider.doTrackerWork();
        return provider.get(analysisContext, testFile, name);
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
    var errors = await _computeErrors();
    if (errorFilter != null) {
      if (errors.length == 1) {
        fail('Unnecessary error filter');
      }
      errors = errors.where(errorFilter).toList();
    }
    if (errors.isEmpty) {
      fail('Expected one error, found: none');
    } else if (errors.length > 1) {
      var buffer = StringBuffer();
      buffer.writeln('Expected one error, found:');
      for (var error in errors) {
        buffer.writeln('  $error [${error.errorCode}]');
      }
      fail(buffer.toString());
    }
    return errors[0];
  }

  Future<AnalysisError> _findErrorToFixOfType(ErrorCode errorCode) async {
    var errors = await _computeErrors();
    for (var error in errors) {
      if (error.errorCode == errorCode) {
        return error;
      }
    }
    return null;
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    var positions = <Position>[];
    for (var search in searchStrings) {
      var offset = resultCode.indexOf(search);
      positions.add(Position(testFile, offset));
    }
    return positions;
  }
}

mixin WithNullSafetyLintMixin on AbstractContextTest {
  /// Return the lint code being tested.
  String get lintCode;

  @override
  String get testPackageLanguageVersion => '2.12';

  @nonVirtual
  @override
  void setUp() {
    super.setUp();
    createAnalysisOptionsFile(
      lints: [lintCode],
    );
  }
}
