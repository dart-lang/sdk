// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:analyzer_testing/src/abstract_context.dart';
import 'package:test/test.dart';

/// A base test class for tests operating on a single test unit ([testFile]).
///
/// Builds on [AbstractContextTest] by providing convenience properties and
/// methods for parsing or resolving [testFile], tracking test code markers,
/// verifying diagnostics, and accessing AST nodes and resolved elements.
class AbstractSingleUnitTest extends AbstractContextTest {
  /// Whether to verify that the resolved unit has no unexpected diagnostics.
  ///
  /// Defaults to `true`. When `true`, [getResolvedUnit] asserts that the unit
  /// has no diagnostics other than a short list of innocuous ignored diagnostic
  /// codes (such as unused elements and unused imports).
  bool verifyNoTestUnitErrors = true;

  TestCode? _parsedTestCode;

  /// The [ParsedUnitResult] obtained from parsing [testFile].
  ///
  /// Populated by [parseTestCode]. Note that this is _not_ populated by
  /// [resolveTestCode].
  late ParsedUnitResult testParsedResult;

  /// The [ResolvedLibraryResult] for the library containing [testFile].
  ///
  /// Populated when resolving [testFile] via [getResolvedUnit],
  /// [resolveTestFile], or [resolveTestCode]. May be `null` if the library
  /// could not be resolved.
  ///
  /// Typically used by intermediate test classes (such as `FixProcessorTest`
  /// and `AssistProcessorTest`) rather than individual test cases to access
  /// the containing library context when computing fixes or assists.
  late ResolvedLibraryResult? testLibraryResult;

  /// The [ResolvedUnitResult] for [testFile].
  ///
  /// Populated when resolving [testFile] via [getResolvedUnit],
  /// [resolveTestFile], or [resolveTestCode].
  late ResolvedUnitResult testAnalysisResult;

  /// The [CompilationUnit] of [testFile].
  ///
  /// Populated when parsing [testFile] via [parseTestCode], or when resolving
  /// [testFile] via [getResolvedUnit], [resolveTestFile], or [resolveTestCode].
  late CompilationUnit testUnit;

  /// The [TestCode] representation of the test source code.
  ///
  /// Contains the raw [testCode] stripped of test markers, as well as parsed
  /// positions and ranges embedded in the test source.
  TestCode get parsedTestCode {
    if (_parsedTestCode case var parsedTestCode?) {
      return parsedTestCode;
    }
    throw StateError(
      "'parsedTestCode' has not yet been set; this is set by 'addTestSource'.",
    );
  }

  /// The source code of [testFile] without test markers.
  ///
  /// Setting this property parses the code into [parsedTestCode] using
  /// [TestCode.parseNormalized].
  String get testCode => parsedTestCode.code;

  /// Sets the test source [code] for [testFile] and creates the file on disk.
  ///
  /// Normalizes and parses [code] with test markers (such as positions or
  /// ranges), updates [testCode] and [parsedTestCode], and writes the source to
  /// [testFile].
  ///
  /// Does not resolve [testFile]. Use [resolveTestCode] to add source and
  /// resolve in a single step, or call [resolveTestFile] after configuring
  /// additional files or test options.
  void addTestSource(String code) {
    _setParsedTestCode(TestCode.parseNormalized(code));
    newFile(testFile.path, testCode);
  }

  /// Parses the given [file] and returns its [ParsedUnitResult].
  ///
  /// Pending file changes in the file's analysis context are applied before
  /// parsing.
  Future<ParsedUnitResult> getParsedUnit(File file) async {
    var path = file.path;
    var analysisContext = contextFor2(file);
    await analysisContext.applyPendingFileChanges();
    var result = analysisContext.currentSession.getParsedUnit(path);
    return result as ParsedUnitResult;
  }

  /// Resolves the given [file] and returns its [ResolvedUnitResult].
  ///
  /// If [file] matches [testFile], this also populates [testLibraryResult],
  /// [testAnalysisResult], [testUnit], [findNode], and [findElement].
  ///
  /// If [verifyNoTestUnitErrors] is `true`, verifies that [file] has no
  /// diagnostics other than standard ignored diagnostics and any additional
  /// diagnostic codes specified in [ignore].
  @override
  Future<ResolvedUnitResult> getResolvedUnit(
    File file, {
    List<DiagnosticCode>? ignore,
  }) async {
    var session = await this.session;
    var libraryResult = await session.getResolvedContainingLibrary(file.path);
    var unitResult = libraryResult?.unitWithPath(file.path);
    unitResult ??= await super.getResolvedUnit(file);

    if (file.path == convertPath(testFilePath)) {
      testLibraryResult = libraryResult;
      testAnalysisResult = unitResult;
      testUnit = unitResult.unit;
    }

    if (verifyNoTestUnitErrors) {
      var allIgnored = const <DiagnosticCode>{
        diag.deadCode,
        diag.unusedCatchClause,
        diag.unusedCatchStack,
        diag.unusedElement,
        diag.unusedField,
        diag.unusedImport,
        diag.unusedLocalVariable,
      };

      if (ignore != null) {
        allIgnored = {...allIgnored, ...ignore};
      }

      expect(
        unitResult.diagnostics.where(
          (d) => !allIgnored.contains(d.diagnosticCode),
        ),
        isEmpty,
      );
    }
    return unitResult;
  }

  /// Sets [code] as the test source and parses [testFile] without resolving it.
  ///
  /// Writes [code] to [testFile] via [addTestSource], parses it using
  /// [getParsedUnit], and initializes [testParsedResult], [testUnit],
  /// [findNode], and [findElement].
  ///
  /// Typically used by tests that only require syntactic information (such as
  /// directive ordering or member sorting tests) where full semantic resolution
  /// is not needed.
  Future<void> parseTestCode(String code) async {
    addTestSource(code);
    testParsedResult = await getParsedUnit(testFile);
    testUnit = testParsedResult.unit;
  }

  /// Adds the given [code] as the test source and resolves [testFile].
  ///
  /// Convenience method that combines [addTestSource] and [resolveTestFile].
  /// Optionally pass [ignore], a list of diagnostic codes to be ignored.
  Future<void> resolveTestCode(
    String code, {
    List<DiagnosticCode>? ignore,
  }) async {
    addTestSource(code);
    await resolveTestFile(ignore: ignore);
  }

  /// Resolves [testFile] using [getResolvedUnit].
  ///
  /// Assumes the test source has already been added via [addTestSource] or
  /// written to [testFile]. Optionally pass [ignore], a list of diagnostic
  /// codes to be ignored.
  Future<void> resolveTestFile({List<DiagnosticCode>? ignore}) async {
    await getResolvedUnit(testFile, ignore: ignore);
  }

  void _setParsedTestCode(TestCode value) {
    if (_parsedTestCode case var parsedTestCode?) {
      throw ArgumentError(
        "'parsedTestCode' is already set to '${parsedTestCode.code}'",
      );
    }
    _parsedTestCode = value;
  }
}

mixin FindElementMixin on AbstractSingleUnitTest {
  /// A helper for finding declared elements within [testUnit].
  ///
  /// Populated when parsing [testFile] via [parseTestCode], or when resolving
  /// [testFile] via [getResolvedUnit], [resolveTestFile], or [resolveTestCode].
  late FindElement findElement;

  @override
  Future<ResolvedUnitResult> getResolvedUnit(
    File file, {
    List<DiagnosticCode>? ignore,
  }) async {
    var unitResult = await super.getResolvedUnit(file, ignore: ignore);
    if (file.path == convertPath(testFilePath)) {
      findElement = FindElement(testUnit);
    }
    return unitResult;
  }

  @override
  Future<void> parseTestCode(String code) async {
    await super.parseTestCode(code);
    findElement = FindElement(testUnit);
  }
}

mixin FindNodeMixin on AbstractSingleUnitTest {
  /// A helper for finding [AstNode]s within [testUnit].
  ///
  /// Populated when parsing [testFile] via [parseTestCode], or when resolving
  /// [testFile] via [getResolvedUnit], [resolveTestFile], or [resolveTestCode].
  late FindNode findNode;

  @override
  Future<ResolvedUnitResult> getResolvedUnit(
    File file, {
    List<DiagnosticCode>? ignore,
  }) async {
    var unitResult = await super.getResolvedUnit(file, ignore: ignore);
    if (file.path == convertPath(testFilePath)) {
      findNode = FindNode(unitResult.content, testUnit);
    }
    return unitResult;
  }

  @override
  Future<void> parseTestCode(String code) async {
    await super.parseTestCode(code);
    findNode = FindNode(testCode, testUnit);
  }
}
