// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_in_file_processor.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../../../abstract_context.dart';
import '../../../../abstract_single_unit.dart';
import '../../../../utils/test_instrumentation_service.dart';

typedef DiagnosticFilter = bool Function(Diagnostic diagnostic);

abstract class BaseFixProcessorTest extends AbstractSingleUnitTest {
  /// The source change associated with the fix that was found.
  late SourceChange change;

  /// The result of applying the [change] to the file content.
  late String resultCode;

  /// The workspace in which fixes contributor operates.
  Future<ChangeWorkspace> get workspace async {
    return DartChangeWorkspace([await session]);
  }

  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
  }

  /// Computes fixes for the given [diagnostic] in [testUnit].
  Future<List<Fix>> _computeFixes(Diagnostic diagnostic) async {
    var libraryResult = testLibraryResult;
    if (libraryResult == null) {
      return const [];
    }
    var context = DartFixContext(
      instrumentationService: TestInstrumentationService(),
      workspace: await workspace,
      libraryResult: libraryResult,
      unitResult: testAnalysisResult,
      error: diagnostic,
    );
    return await computeFixes(context);
  }

  /// Finds the diagnostic that is to be fixed by computing the diagnostics in
  /// the file, using the [filter] to filter out diagnostics that should be
  /// ignored, and expecting that there is a single remaining diagnostic. The
  /// diagnostic filter should return `true` if the diagnostic should not be
  /// ignored.
  Future<Diagnostic> _findDiagnosticToFix({DiagnosticFilter? filter}) async {
    var diagnostics = testAnalysisResult.diagnostics;
    if (filter != null) {
      if (diagnostics.length == 1) {
        fail('Unnecessary error filter');
      }
      diagnostics = diagnostics.where(filter).toList();
    }
    if (diagnostics.isEmpty) {
      fail('Expected one diagnostic, found: none');
    } else if (diagnostics.length > 1) {
      var buffer = StringBuffer();
      buffer.writeln('Expected one diagnostic, found:');
      for (var diagnostic in diagnostics) {
        buffer.writeln('  $diagnostic [${diagnostic.diagnosticCode}]');
      }
      fail(buffer.toString());
    }
    return diagnostics[0];
  }

  Future<Diagnostic> _findDiagnosticToFixOfType(DiagnosticCode code) async {
    var diagnostics = testAnalysisResult.diagnostics;
    for (var diagnostic in diagnostics) {
      if (diagnostic.diagnosticCode == code) {
        return diagnostic;
      }
    }
    fail('Expected to find a diagnostic with the code: $code');
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
  List<String> get experiments => experimentsForTests;

  /// The name of the lint code being tested.
  String? get lintCode => null;

  /// The workspace in which fixes contributor operates.
  Future<DartChangeWorkspace> get workspace async {
    return DartChangeWorkspace([await session]);
  }

  /// Computes fixes for the pubspecs in the given contexts.
  Future<void> assertFixPubspec(
    String original,
    String expected, {
    File? file,
  }) async {
    var analysisContext = contextFor(file ?? testFile);
    var processor = BulkFixProcessor(
      TestInstrumentationService(),
      await workspace,
    );
    var fixes = (await processor.fixPubspec([analysisContext])).edits;
    var edits = [for (var fix in fixes) ...fix.edits];
    var result = SourceEdit.applySequence(normalizeSource(original), edits);
    expect(result, normalizeSource(expected));
  }

  Future<void> assertFormat(String expectedCode) async {
    var analysisContext = contextFor(testFile);
    processor = BulkFixProcessor(TestInstrumentationService(), await workspace);
    await processor.formatCode([analysisContext]);
    var change = processor.builder.sourceChange;
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    expect(resultCode, normalizeSource(expectedCode));
  }

  Future<void> assertHasFix(String expected, {bool isParse = false}) async {
    change = await _computeSourceChange(isParse: isParse);

    // apply to "file"
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, normalizeSource(expected));
  }

  Future<void> assertNoFix() async {
    change = await _computeSourceChange();
    var fileEdits = change.edits;
    expect(fileEdits, isEmpty);
  }

  Future<void> assertOrganize(String expectedCode) async {
    var analysisContext = contextFor(testFile);
    processor = BulkFixProcessor(TestInstrumentationService(), await workspace);
    await processor.organizeDirectives([analysisContext]);
    var change = processor.builder.sourceChange;
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    expect(resultCode, normalizeSource(expectedCode));
  }

  /// Computes fixes for the specified [testUnit].
  Future<BulkFixProcessor> computeFixes({bool isParse = false}) async {
    var analysisContext = contextFor(testFile);
    var processor = BulkFixProcessor(
      TestInstrumentationService(),
      await workspace,
    );
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
    var analysisContext = contextFor(testFile);
    processor = BulkFixProcessor(TestInstrumentationService(), await workspace);
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

  Future<List<Fix>> getFixesForAllErrors(Set<String>? alreadyCalculated) async {
    var diagnostics = testAnalysisResult.diagnostics;
    expect(diagnostics, isNotEmpty);
    List<Fix> fixes = [];
    for (var diagnostic in diagnostics) {
      fixes.addAll(
        await _computeFixes(diagnostic, alreadyCalculated: alreadyCalculated),
      );
    }
    return fixes;
  }

  Future<List<Fix>> getFixesForFirst(DiagnosticFilter test) async {
    var diagnostics = testAnalysisResult.diagnostics.where(test);
    expect(diagnostics, isNotEmpty);
    String? diagnosticCode;
    for (var diagnostic in diagnostics) {
      diagnosticCode ??= diagnostic.diagnosticCode.lowerCaseName;
      if (diagnosticCode != diagnostic.diagnosticCode.lowerCaseName) {
        fail('Expected only errors of one type but found: $diagnostics');
      }
    }

    var fixes = await _computeFixes(diagnostics.first);
    return fixes;
  }

  Future<List<Fix>> getFixesForFirstError() async {
    var diagnostics = testAnalysisResult.diagnostics;
    expect(diagnostics, isNotEmpty);
    String? diagnosticCode;
    for (var diagnostic in diagnostics) {
      diagnosticCode ??= diagnostic.diagnosticCode.lowerCaseName;
      if (diagnosticCode != diagnostic.diagnosticCode.lowerCaseName) {
        fail('Expected only errors of one type but found: $diagnostics');
      }
    }

    var fixes = await _computeFixes(diagnostics.first);
    return fixes;
  }

  /// Computes fixes for the given [diagnostic] in [testUnit].
  @override
  Future<List<Fix>> _computeFixes(
    Diagnostic diagnostic, {
    Set<String>? alreadyCalculated,
  }) async {
    var libraryResult = testLibraryResult;
    if (libraryResult == null) {
      return const [];
    }
    var context = DartFixContext(
      instrumentationService: TestInstrumentationService(),
      workspace: await workspace,
      libraryResult: libraryResult,
      unitResult: testAnalysisResult,
      error: diagnostic,
    );

    return await FixInFileProcessor(
      context,
      alreadyCalculated: alreadyCalculated,
    ).compute();
  }
}

abstract class FixPriorityTest extends BaseFixProcessorTest {
  Future<void> assertFixPriorityOrder(
    List<FixKind> fixKinds, {
    DiagnosticFilter? filter,
  }) async {
    var diagnostic = await _findDiagnosticToFix(filter: filter);
    var computedFixes = await _computeFixes(diagnostic);
    var kinds = computedFixes.map((fix) => fix.kind).toList();
    kinds.sort((a, b) => b.priority.compareTo(a.priority));
    expect(kinds, containsAllInOrder(fixKinds));
  }
}

/// A base class defining support for writing fix processor tests that are
/// specific to fixes associated with the [diagnosticCode] that use the FixKind.
abstract class FixProcessorErrorCodeTest extends FixProcessorTest {
  /// The diagnostic code being tested.
  DiagnosticCode get diagnosticCode;
}

/// A base class defining support for writing fix processor tests that are
/// specific to fixes associated with lints that use the FixKind.
abstract class FixProcessorLintTest extends FixProcessorTest {
  /// Return the lint code being tested.
  String get lintCode;

  /// Returns the [LintCode] for the [lintCode] (which is actually a name).
  Future<LintCode> lintCodeByName(String name) async {
    var diagnostics = testAnalysisResult.diagnostics;
    var lintCodeSet = diagnostics
        .map((d) => d.diagnosticCode)
        .whereType<LintCode>()
        .where((lintCode) => lintCode.lowerCaseName == name)
        .toSet();
    if (lintCodeSet.length != 1) {
      fail('Expected exactly one LintCode, actually: $lintCodeSet');
    }
    return lintCodeSet.single;
  }

  DiagnosticFilter lintNameFilter(String name) {
    return (e) {
      return e.diagnosticCode is LintCode &&
          e.diagnosticCode.lowerCaseName == name;
    };
  }

  @override
  void setUp() {
    super.setUp();
    createAnalysisOptionsFile(experiments: experiments, lints: [lintCode]);
  }
}

/// A base class defining support for writing fix processor tests.
abstract class FixProcessorTest extends BaseFixProcessorTest {
  late TestCode parsedExpectedCode;

  /// The kind of fixes being tested by this test class.
  FixKind get kind;

  /// Asserts that the resolved compilation unit has a fix which produces
  /// [expectedContent] output.
  ///
  /// [expectedContent] will have newlines normalized and be parsed with
  /// [TestCode.parse], with the resulting code stored in [parsedExpectedCode].
  Future<void> assertHasFix(
    String expectedContent, {
    DiagnosticFilter? filter,
    String? target,
    int? expectedNumberOfFixesForKind,
    String? matchFixMessage,
    bool allowFixAllFixes = false,
  }) async {
    parsedExpectedCode = TestCode.parseNormalized(
      expectedContent,
      positionShorthand: allowTestCodeShorthand,
      rangeShorthand: allowTestCodeShorthand,
    );
    var diagnostic = await _findDiagnosticToFix(filter: filter);
    var fix = await _assertHasFix(
      diagnostic,
      expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
      matchFixMessage: matchFixMessage,
      allowFixAllFixes: allowFixAllFixes,
    );
    change = fix.change;

    // Apply to file.
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, parsedExpectedCode.code);
  }

  Future<void> assertHasFixAllFix(
    DiagnosticCode diagnosticCode,
    String expected, {
    String? target,
  }) async {
    expected = normalizeSource(expected);
    var diagnostic = await _findDiagnosticToFixOfType(diagnosticCode);
    var fix = await _assertHasFixAllFix(diagnostic);
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

  /// Computes an error from [filter], and verifies that
  /// [expectedNumberOfFixesForKind] fixes of the appropriate kind are found,
  /// and that they have messages equal to [matchFixMessages].
  Future<void> assertHasFixesWithoutApplying({
    DiagnosticFilter? filter,
    required int expectedNumberOfFixesForKind,
    required List<String> matchFixMessages,
  }) async {
    var diagnostic = await _findDiagnosticToFix(filter: filter);
    await _assertHasFixes(
      diagnostic,
      expectedNumberOfFixesForKind: expectedNumberOfFixesForKind,
      matchFixMessages: matchFixMessages,
    );
  }

  Future<void> assertHasFixWithoutApplying({DiagnosticFilter? filter}) async {
    var diagnostic = await _findDiagnosticToFix(filter: filter);
    var fix = await _assertHasFix(diagnostic);
    change = fix.change;
  }

  void assertLinkedGroup(
    LinkedEditGroup group,
    List<String> expectedStrings, [
    List<LinkedEditSuggestion>? expectedSuggestions,
  ]) {
    var expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Compute fixes for all of the diagnostics in the test file to effectively
  /// assert that no exceptions will be thrown by doing so.
  Future<void> assertNoExceptions() async {
    for (var diagnostic in testAnalysisResult.diagnostics) {
      await _computeFixes(diagnostic);
    }
  }

  /// Compute fixes and ensure that there is no fix of the [kind] being tested by
  /// this class.
  Future<void> assertNoFix({DiagnosticFilter? filter}) async {
    var diagnostic = await _findDiagnosticToFix(filter: filter);
    await _assertNoFix(diagnostic);
  }

  Future<void> assertNoFixAllFix(DiagnosticCode diagnosticCode) async {
    var diagnostic = await _findDiagnosticToFixOfType(diagnosticCode);
    await _assertNoFixAllFix(diagnostic);
  }

  List<LinkedEditSuggestion> expectedSuggestions(
    LinkedEditSuggestionKind kind,
    List<String> values,
  ) {
    return values.map((value) {
      return LinkedEditSuggestion(value, kind);
    }).toList();
  }

  /// Computes fixes, verifies that there is a fix for the given [diagnostic] of
  /// the appropriate kind, and returns the fix.
  ///
  /// If a [matchFixMessage] is passed, then the kind as well as the fix message
  /// must match to be returned.
  ///
  /// If [expectedNumberOfFixesForKind] is non-null, then the number of fixes
  /// for [kind] is verified to be [expectedNumberOfFixesForKind].
  Future<Fix> _assertHasFix(
    Diagnostic diagnostic, {
    int? expectedNumberOfFixesForKind,
    String? matchFixMessage,
    bool allowFixAllFixes = false,
  }) async {
    // Compute the fixes for this AnalysisError
    var fixes = await _computeFixes(diagnostic);

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
        fail(
          'Expected to find fix $kind with name $matchFixMessage'
          ' but there were no fixes.',
        );
      } else {
        fail(
          'Expected to find fix $kind with name $matchFixMessage'
          ' in\n${fixes.join('\n')}',
        );
      }
    }

    // Assert that none of the fixes are a fix-all fix.
    Fix? foundFix;
    for (var fix in fixes) {
      if (!allowFixAllFixes && fix.isFixAllFix()) {
        fail(
          'A fix-all fix was found for the error: $diagnostic '
          'in the computed set of fixes:\n${fixes.join('\n')}',
        );
      } else if (fix.kind == kind) {
        foundFix ??= fix;
      }
    }
    if (foundFix == null) {
      fail('Expected to find fix $kind in\n${fixes.join('\n')}');
    }
    return foundFix;
  }

  /// Computes fixes and verifies that there is a fix for the given [diagnostic]
  /// of the appropriate kind.
  Future<Fix> _assertHasFixAllFix(Diagnostic diagnostic) async {
    if (!kind.canBeAppliedTogether()) {
      fail(
        'Expected to find and return fix-all FixKind for $kind, '
        'but kind.canBeAppliedTogether is ${kind.canBeAppliedTogether}',
      );
    }

    // Compute the fixes for the error.
    var fixes = await _computeFixes(diagnostic);

    // Assert that there exists such a fix in the list.
    Fix? foundFix;
    for (var fix in fixes) {
      if (fix.kind == kind && fix.isFixAllFix()) {
        foundFix = fix;
        break;
      }
    }
    if (foundFix == null) {
      fail(
        'No fix-all fix was found for the error: $diagnostic '
        'in the computed set of fixes:\n${fixes.join('\n')}',
      );
    }
    return foundFix;
  }

  /// Computes fixes and verifies that there are [expectedNumberOfFixesForKind]
  /// fixes for the given [diagnostic] of the appropriate kind, and that the
  /// messages of the fixes are equal to [matchFixMessages].
  Future<void> _assertHasFixes(
    Diagnostic diagnostic, {
    required int expectedNumberOfFixesForKind,
    required List<String> matchFixMessages,
  }) async {
    // Compute the fixes for this Diagnostic.
    var fixes = await _computeFixes(diagnostic);
    _assertNumberOfFixesForKind(fixes, expectedNumberOfFixesForKind);
    var actualFixMessages = [for (var fix in fixes) fix.change.message];
    expect(actualFixMessages, containsAllInOrder(matchFixMessages));
  }

  Future<void> _assertNoFix(Diagnostic diagnostic) async {
    var fixes = await _computeFixes(diagnostic);
    for (var fix in fixes) {
      if (fix.kind == kind) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Future<void> _assertNoFixAllFix(Diagnostic diagnostic) async {
    if (!kind.canBeAppliedTogether()) {
      fail(
        'Expected to find and return fix-all FixKind for $kind, '
        'but kind.canBeAppliedTogether is ${kind.canBeAppliedTogether}',
      );
    }
    var fixes = await _computeFixes(diagnostic);
    for (var fix in fixes) {
      if (fix.kind == kind && fix.isFixAllFix()) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  void _assertNumberOfFixesForKind(
    List<Fix> fixes,
    int expectedNumberOfFixesForKind,
  ) {
    var actualNumberOfFixesForKind = fixes
        .where((fix) => fix.kind == kind)
        .length;
    if (actualNumberOfFixesForKind != expectedNumberOfFixesForKind) {
      fail(
        'Expected $expectedNumberOfFixesForKind fixes of kind $kind,'
        ' but found $actualNumberOfFixesForKind:\n${fixes.join('\n')}',
      );
    }
  }

  /// Computes fixes for the given [diagnostic] in [testUnit].
  @override
  Future<List<Fix>> _computeFixes(Diagnostic diagnostic) async {
    var libraryResult = testLibraryResult;
    if (libraryResult == null) {
      return const [];
    }
    var context = DartFixContext(
      instrumentationService: TestInstrumentationService(),
      workspace: await workspace,
      libraryResult: libraryResult,
      unitResult: testAnalysisResult,
      error: diagnostic,
    );
    return await computeFixes(context);
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
    createAnalysisOptionsFile(lints: [lintCode]);
  }
}

// TODO(pq): temporary
extension FixExtension on Fix {
  bool isFixAllFix() => kind.canBeAppliedTogether();
}

extension FixKindExtension on FixKind {
  // TODO(pq): temporary
  bool canBeAppliedTogether() => priority == DartFixKindPriority.inFile;
}
