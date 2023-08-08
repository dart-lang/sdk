// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/services/available_declarations.dart';
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

abstract class BaseFixProcessorTest extends AbstractSingleUnitTest {
  /// The source change associated with the fix that was found.
  late SourceChange change;

  /// The result of applying the [change] to the file content.
  late String resultCode;

  /// The workspace in which fixes contributor operates.
  Future<ChangeWorkspace> get workspace async {
    return DartChangeWorkspace([await session]);
  }

  /// Find the error that is to be fixed by computing the errors in the file,
  /// using the [errorFilter] to filter out errors that should be ignored, and
  /// expecting that there is a single remaining error. The error filter should
  /// return `true` if the error should not be ignored.
  Future<AnalysisError> _findErrorToFix(
      {bool Function(AnalysisError)? errorFilter, int? length}) async {
    var errors = testAnalysisResult.errors;
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
    var errors = testAnalysisResult.errors;
    for (var error in errors) {
      if (error.errorCode == errorCode) {
        return error;
      }
    }
    fail('Expected to find an error with the code: $errorCode');
  }
}

/// A base class defining support for writing bulk fix processor tests.
abstract class BulkFixProcessorTest extends AbstractSingleUnitTest {
  /// The source change associated with the fix that was found, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  late SourceChange change;

  /// The result of applying the [change] to the file content, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  late String resultCode;

  /// The processor used to compute bulk fixes.
  late BulkFixProcessor processor;

  @override
  List<String> get experiments => const [];

  /// Return the lint code being tested.
  String? get lintCode => null;

  /// Return `true` if this test uses config files.
  bool get useConfigFiles => false;

  /// The workspace in which fixes contributor operates.
  Future<DartChangeWorkspace> get workspace async {
    return DartChangeWorkspace([await session]);
  }

  Future<void> assertHasFix(String expected, {bool isParse = false}) async {
    change = await _computeSourceChange(isParse: isParse);

    // apply to "file"
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  Future<void> assertNoFix() async {
    change = await _computeSourceChange();
    var fileEdits = change.edits;
    expect(fileEdits, isEmpty);
  }

  Future<void> assertOrganize(String expectedCode) async {
    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    var analysisContext = contextFor(testFile);
    tracker.addContext(analysisContext);
    processor = BulkFixProcessor(TestInstrumentationService(), await workspace,
        useConfigFiles: useConfigFiles);
    await processor.organizeDirectives([analysisContext]);
    var change = processor.builder.sourceChange;
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    expect(resultCode, expectedCode);
  }

  /// Computes fixes for the specified [testUnit].
  Future<BulkFixProcessor> computeFixes({bool isParse = false}) async {
    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    var analysisContext = contextFor(testFile);
    tracker.addContext(analysisContext);
    var processor = BulkFixProcessor(
        TestInstrumentationService(), await workspace,
        useConfigFiles: useConfigFiles);
    if (isParse) {
      await processor.fixErrorsUsingParsedResult([analysisContext]);
    } else {
      await processor.fixErrors([analysisContext]);
    }
    return processor;
  }

  /// Computes whether there are bulk fixes for the context containing
  /// [testFile].
  Future<bool> computeHasFixes() async {
    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    var analysisContext = contextFor(testFile);
    tracker.addContext(analysisContext);
    processor = BulkFixProcessor(TestInstrumentationService(), await workspace,
        useConfigFiles: useConfigFiles);
    return processor.hasFixes([analysisContext]);
  }

  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
    _createAnalysisOptionsFile();
  }

  /// Returns the source change for computed fixes in the specified [testUnit].
  Future<SourceChange> _computeSourceChange({bool isParse = false}) async {
    processor = await computeFixes(isParse: isParse);
    return processor.builder.sourceChange;
  }

  /// Create the analysis options file needed in order to correctly analyze the
  /// test file.
  void _createAnalysisOptionsFile() {
    var code = lintCode;
    if (code == null) {
      createAnalysisOptionsFile(experiments: experiments);
    } else {
      createAnalysisOptionsFile(experiments: experiments, lints: [code]);
    }
  }
}

/// A base class defining support for writing fix-in-file processor tests.
abstract class FixInFileProcessorTest extends BaseFixProcessorTest {
  void assertProduces(Fix fix, String expected) {
    var fileEdits = fix.change.edits;
    expect(fileEdits, hasLength(1));

    expected = normalizeSource(expected);

    var fileContent = testCode;
    resultCode = SourceEdit.applySequence(fileContent, fileEdits[0].edits);
    expect(resultCode, expected);
  }

  Future<List<Fix>> getFixesForFirstError() async {
    var errors = testAnalysisResult.errors;
    expect(errors, isNotEmpty);
    String? errorCode;
    for (var error in errors) {
      errorCode ??= error.errorCode.name;
      if (errorCode != error.errorCode.name) {
        fail('Expected only errors of one type but found: $errors');
      }
    }

    var fixes = await _computeFixes(errors.first);
    return fixes;
  }

  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
    useLineEndingsForPlatform = true;
  }

  /// Computes fixes for the given [error] in [testUnit].
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    var context = DartFixContextImpl(
      TestInstrumentationService(),
      await workspace,
      testAnalysisResult,
      error,
    );

    var fixes = await FixInFileProcessor(context).compute();
    return fixes;
  }
}

/// A base class defining support for writing fix processor tests that are
/// specific to fixes associated with lints that use the FixKind.
abstract class FixProcessorLintTest extends FixProcessorTest {
  /// Return the lint code being tested.
  String get lintCode;

  /// Return the [LintCode] for the [lintCode] (which is actually a name).
  Future<LintCode> lintCodeByName(String name) async {
    var errors = testAnalysisResult.errors;
    var lintCodeSet = errors
        .map((error) => error.errorCode)
        .whereType<LintCode>()
        .where((errorCode) => errorCode.name == name)
        .toSet();
    if (lintCodeSet.length != 1) {
      fail('Expected exactly one LintCode, actually: $lintCodeSet');
    }
    return lintCodeSet.single;
  }

  bool Function(AnalysisError) lintNameFilter(String name) {
    return (e) {
      return e.errorCode is LintCode && e.errorCode.name == name;
    };
  }

  @override
  void setUp() {
    super.setUp();
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [lintCode],
    );
  }
}

/// A base class defining support for writing fix processor tests.
abstract class FixProcessorTest extends BaseFixProcessorTest {
  /// Return the kind of fixes being tested by this test class.
  FixKind get kind;

  /// Asserts that the resolved compilation unit has a fix which produces [expected] output.
  Future<void> assertHasFix(String expected,
      {bool Function(AnalysisError)? errorFilter,
      int? length,
      String? target,
      int? expectedNumberOfFixesForKind,
      String? matchFixMessage,
      bool allowFixAllFixes = false}) async {
    expected = normalizeSource(expected);
    var error = await _findErrorToFix(
      errorFilter: errorFilter,
      length: length,
    );
    var fix = await _assertHasFix(error,
        expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
        matchFixMessage: matchFixMessage,
        allowFixAllFixes: allowFixAllFixes);
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
      {String? target}) async {
    expected = normalizeSource(expected);
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

  /// Computes an error from [errorFilter], and verifies that
  /// [expectedNumberOfFixesForKind] fixes of the appropriate kind are found,
  /// and that they have messages equal to [matchFixMessages].
  Future<void> assertHasFixesWithoutApplying({
    bool Function(AnalysisError)? errorFilter,
    required int expectedNumberOfFixesForKind,
    required List<String> matchFixMessages,
  }) async {
    var error = await _findErrorToFix(errorFilter: errorFilter);
    await _assertHasFixes(
      error,
      expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
      matchFixMessages: matchFixMessages,
    );
  }

  Future<void> assertHasFixWithoutApplying(
      {bool Function(AnalysisError)? errorFilter}) async {
    var error = await _findErrorToFix(errorFilter: errorFilter);
    var fix = await _assertHasFix(error);
    change = fix.change;
  }

  void assertLinkedGroup(LinkedEditGroup group, List<String> expectedStrings,
      [List<LinkedEditSuggestion>? expectedSuggestions]) {
    var expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Compute fixes for all of the errors in the test file to effectively assert
  /// that no exceptions will be thrown by doing so.
  Future<void> assertNoExceptions() async {
    var errors = testAnalysisResult.errors;
    for (var error in errors) {
      await _computeFixes(error);
    }
  }

  /// Compute fixes and ensure that there is no fix of the [kind] being tested by
  /// this class.
  Future<void> assertNoFix({bool Function(AnalysisError)? errorFilter}) async {
    var error = await _findErrorToFix(errorFilter: errorFilter);
    await _assertNoFix(error);
  }

  Future<void> assertNoFixAllFix(ErrorCode errorCode) async {
    var error = await _findErrorToFixOfType(errorCode);
    await _assertNoFixAllFix(error);
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

  /// Computes fixes, verifies that there is a fix for the given [error] of
  /// the appropriate kind, and returns the fix.
  ///
  /// If a [matchFixMessage] is passed, then the kind as well as the fix message
  /// must match to be returned.
  ///
  /// If [expectedNumberOfFixesForKind] is non-null, then the number of fixes
  /// for [kind] is verified to be [expectedNumberOfFixesForKind].
  Future<Fix> _assertHasFix(AnalysisError error,
      {int? expectedNumberOfFixesForKind,
      String? matchFixMessage,
      bool allowFixAllFixes = false}) async {
    // Compute the fixes for this AnalysisError
    var fixes = await _computeFixes(error);

    if (expectedNumberOfFixesForKind != null) {
      _assertNumberOfFixesForKind(fixes, expectedNumberOfFixesForKind);
    }

    // If a matchFixMessage was provided,
    if (matchFixMessage != null) {
      for (var fix in fixes) {
        if (matchFixMessage == fix.change.message) {
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
    Fix? foundFix;
    for (var fix in fixes) {
      if (!allowFixAllFixes && fix.isFixAllFix()) {
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
    Fix? foundFix;
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

  /// Computes fixes and verifies that there are [expectedNumberOfFixesForKind]
  /// fixes for the given [error] of the appropriate kind, and that the messages
  /// of the fixes are equal to [matchFixMessages].
  Future<void> _assertHasFixes(
    AnalysisError error, {
    required int expectedNumberOfFixesForKind,
    required List<String> matchFixMessages,
  }) async {
    // Compute the fixes for this AnalysisError
    var fixes = await _computeFixes(error);
    _assertNumberOfFixesForKind(fixes, expectedNumberOfFixesForKind);
    var actualFixMessages = [for (var fix in fixes) fix.change.message];
    expect(actualFixMessages, containsAllInOrder(matchFixMessages));
  }

  Future<void> _assertNoFix(AnalysisError error) async {
    var fixes = await _computeFixes(error);
    for (var fix in fixes) {
      if (fix.kind == kind) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Future<void> _assertNoFixAllFix(AnalysisError error) async {
    if (!kind.canBeAppliedTogether()) {
      fail('Expected to find and return fix-all FixKind for $kind, '
          'but kind.canBeAppliedTogether is ${kind.canBeAppliedTogether}');
    }
    var fixes = await _computeFixes(error);
    for (var fix in fixes) {
      if (fix.kind == kind && fix.isFixAllFix()) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  void _assertNumberOfFixesForKind(
      List<Fix> fixes, int expectedNumberOfFixesForKind) {
    var actualNumberOfFixesForKind =
        fixes.where((fix) => fix.kind == kind).length;
    if (actualNumberOfFixesForKind != expectedNumberOfFixesForKind) {
      fail('Expected $expectedNumberOfFixesForKind fixes of kind $kind,'
          ' but found $actualNumberOfFixesForKind:\n${fixes.join('\n')}');
    }
  }

  /// Computes fixes for the given [error] in [testUnit].
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    var context = DartFixContextImpl(
      TestInstrumentationService(),
      await workspace,
      testAnalysisResult,
      error,
    );
    return await DartFixContributor().computeFixes(context);
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    var positions = <Position>[];
    for (var search in searchStrings) {
      var offset = resultCode.indexOf(search);
      positions.add(Position(testFile.path, offset));
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

/// todo (pq): temporary
extension FixExtension on Fix {
  bool isFixAllFix() => kind.canBeAppliedTogether();
}

extension FixKindExtension on FixKind {
  /// todo (pq): temporary
  bool canBeAppliedTogether() => priority == DartFixKindPriority.IN_FILE;
}
