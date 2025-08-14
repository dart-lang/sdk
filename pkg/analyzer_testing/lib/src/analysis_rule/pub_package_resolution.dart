// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/byte_store.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/experiments.dart'; // ignore: implementation_imports
import 'package:analyzer/src/error/codes.dart'; // ignore: implementation_imports
import 'package:analyzer/src/test_utilities/mock_sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/spelunker.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

typedef DiagnosticMatcher = bool Function(Diagnostic diagnostic);

/// A description of a diagnostic that is expected to be reported.
class ExpectedDiagnostic {
  final DiagnosticMatcher _diagnosticMatcher;

  /// The offset of the beginning of the diagnostic's region.
  final int _offset;

  /// The length of the diagnostic's region.
  final int _length;

  /// A pattern that should be contained in the diagnostic message or `null` if
  /// the message contents should not be checked.
  final Pattern? _messageContains;

  /// A pattern that should be contained in the error's correction message, or
  /// `null` if the correction message contents should not be checked.
  final Pattern? _correctionContains;

  ExpectedDiagnostic(
    this._diagnosticMatcher,
    this._offset,
    this._length, {
    Pattern? messageContains,
    Pattern? correctionContains,
  }) : _messageContains = messageContains,
       _correctionContains = correctionContains;

  /// Whether the [diagnostic] matches this description of what it's expected to be.
  bool matches(Diagnostic diagnostic) {
    if (!_diagnosticMatcher(diagnostic)) return false;
    if (diagnostic.offset != _offset) return false;
    if (diagnostic.length != _length) return false;
    if (_messageContains != null &&
        !diagnostic.message.contains(_messageContains)) {
      return false;
    }
    if (_correctionContains != null) {
      var correctionMessage = diagnostic.correctionMessage;
      if (correctionMessage == null ||
          !correctionMessage.contains(_correctionContains)) {
        return false;
      }
    }

    return true;
  }
}

/// A description of an expected error.
final class ExpectedError extends ExpectedDiagnostic {
  final DiagnosticCode _code;

  ExpectedError(this._code, int offset, int length, {Pattern? messageContains})
    : super(
        (error) => error.diagnosticCode == _code,
        offset,
        length,
        messageContains: messageContains,
      );
}

/// A description of an expected lint rule violation.
final class ExpectedLint extends ExpectedDiagnostic {
  final String _lintName;

  ExpectedLint(
    this._lintName,
    int offset,
    int length, {
    super.messageContains,
    super.correctionContains,
  }) : super((error) => error.diagnosticCode.name == _lintName, offset, length);
}

class PubPackageResolutionTest with MockPackagesMixin, ResourceProviderMixin {
  /// The byte store that is reused between tests.
  ///
  /// This allows reusing all unlinked and linked summaries for SDK, so that
  /// tests run much faster. However nothing is preserved between Dart VM runs,
  /// so changes to the implementation are still fully verified.
  static final MemoryByteStore _sharedByteStore = MemoryByteStore();

  final MemoryByteStore _byteStore = _sharedByteStore;

  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// The analysis result that is used in various `assertDiagnostics` methods.
  late ResolvedUnitResult result;

  /// Adds the 'fixnum' package as a dependency to the package-under-test.
  ///
  /// This allows `package:fixnum/fixnum.dart` imports to resolve.
  bool get addFixnumPackageDep => false;

  /// Adds the 'flutter' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:flutter/` imports to resolve.
  bool get addFlutterPackageDep => false;

  /// Adds the 'js' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:js/` imports to resolve.
  bool get addJsPackageDep => false;

  /// Adds the 'kernel' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:kernel/` imports to resolve.
  bool get addKernelPackageDep => false;

  /// Adds the 'meta' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:meta/` imports to resolve.
  bool get addMetaPackageDep => false;

  /// Adds the 'test_reflective_loader' package as a dependency to the
  /// package-under-test.
  ///
  /// This allows various `package:test_reflective_loader/` imports to resolve.
  bool get addTestReflectiveLoaderPackageDep => false;

  /// Whether to print out the syntax tree being tested, on a test failure.
  bool get dumpAstOnFailures => true;

  /// The list of language experiments to be enabled for these tests.
  List<String> get experiments => experimentsForTests;

  /// Error codes that by default should be ignored in test expectations.
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    WarningCode.unusedElement,
    WarningCode.unusedField,
    WarningCode.unusedLocalVariable,
  ];

  /// The path to the root of the external packages.
  @override
  String get packagesRootPath => '/packages';

  /// The name of the test file.
  String get testFileName => 'test.dart';

  /// The language version for the package-under-test.
  ///
  /// Used for writing out a package config file. A `null` value means no
  /// 'languageVersion' is written to the package config file.
  String? get testPackageLanguageVersion => null;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackagePubspecPath => '$testPackageRootPath/pubspec.yaml';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  List<String> get _collectionIncludedPaths => [workspaceRootPath];

  /// The diagnostics that were computed during analysis.
  List<Diagnostic> get _diagnostics =>
      result.diagnostics
          .where(
            (e) => !ignoredDiagnosticCodes.any((c) => e.diagnosticCode == c),
          )
          .toList();

  Folder get _sdkRoot => newFolder('/sdk');

  String get _testFilePath => '$testPackageLibPath/$testFileName';

  /// Asserts that the number of diagnostics reported in [content] matches the
  /// number of [expectedDiagnostics] and that they have the expected error
  /// descriptions and locations.
  ///
  /// The order in which the diagnostics were gathered is ignored.
  Future<void> assertDiagnostics(
    String content,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) async {
    _addTestFile(content);
    await _resolveTestFile();
    assertDiagnosticsIn(_diagnostics, expectedDiagnostics);
  }

  /// Asserts that the diagnostics in [diagnostics] match [expectedDiagnostics].
  void assertDiagnosticsIn(
    List<Diagnostic> diagnostics,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) {
    // Match actual diagnostics to expected diagnostics.
    var unmatchedActual = diagnostics.toList();
    var unmatchedExpected = expectedDiagnostics.toList();
    var actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      var matchFound = false;
      var expectedIndex = 0;
      while (expectedIndex < unmatchedExpected.length) {
        if (unmatchedExpected[expectedIndex].matches(
          unmatchedActual[actualIndex],
        )) {
          matchFound = true;
          unmatchedActual.removeAt(actualIndex);
          unmatchedExpected.removeAt(expectedIndex);
          break;
        }
        expectedIndex++;
      }
      if (!matchFound) {
        actualIndex++;
      }
    }

    // Print the results to the terminal.
    var buffer = StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.write(missingExpectedMessage(unmatchedExpected));
    }
    if (unmatchedActual.isNotEmpty) {
      buffer.write(unexpectedMessage(unmatchedActual));
    }
    if (unmatchedExpected.isNotEmpty || unmatchedActual.isNotEmpty) {
      buffer.write(correctionMessage(diagnostics));

      if (dumpAstOnFailures) {
        buffer.writeln();
        buffer.writeln();

        try {
          Spelunker(
            result.unit.toSource(),
            sink: buffer,
            featureSet: result.unit.featureSet,
          ).spelunk();
        } on ArgumentError catch (_) {
          // Perhaps we encountered a parsing error while spelunking.
        }

        buffer.writeln();
      }

      fail(buffer.toString());
    }
  }

  /// Asserts that the number of diagnostics that have been gathered at [path]
  /// matches the number of [expectedDiagnostics] and that they have the
  /// expected error descriptions and locations.
  ///
  /// The order in which the diagnostics were gathered is ignored.
  Future<void> assertDiagnosticsInFile(
    String path,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) async {
    await _resolveFile(path);
    assertDiagnosticsIn(_diagnostics, expectedDiagnostics);
  }

  /// Asserts that the diagnostics for each `path` match those in the paired
  /// `expectedDiagnostics`.
  ///
  /// The unit at each path needs to have already been written to the file
  /// system before calling this method.
  Future<void> assertDiagnosticsInUnits(
    List<(String path, List<ExpectedDiagnostic> expectedDiagnostics)>
    unitsAndDiagnostics,
  ) async {
    for (var (path, expectedDiagnostics) in unitsAndDiagnostics) {
      result = await resolveFile(convertPath(path));
      assertDiagnosticsIn(result.diagnostics, expectedDiagnostics);
    }
  }

  /// Asserts that there are no diagnostics in the given [content].
  Future<void> assertNoDiagnostics(String content) async =>
      assertDiagnostics(content, const []);

  /// Asserts that there are no diagnostics in the file at the given [path].
  Future<void> assertNoDiagnosticsInFile(String path) async =>
      assertDiagnosticsInFile(path, const []);

  /// Text to display upon failure, which indicates possible corrections.
  @visibleForOverriding
  String correctionMessage(List<Diagnostic> diagnostics) {
    var buffer = StringBuffer();
    diagnostics.sort((first, second) => first.offset.compareTo(second.offset));
    buffer.writeln();
    buffer.writeln('To accept the current state, expect:');
    for (var actual in diagnostics) {
      if (actual.diagnosticCode is LintCode) {
        buffer.write('  lint(');
      } else {
        buffer.write('  error(${actual.diagnosticCode}, ');
      }
      buffer.write('${actual.offset}, ${actual.length}),');
    }

    return buffer.toString();
  }

  /// Text to display upon failure, indicating that [unmatchedExpected]
  /// diagnostics were expected, but not found.
  @visibleForOverriding
  String missingExpectedMessage(List<ExpectedDiagnostic> unmatchedExpected) {
    var buffer = StringBuffer();
    buffer.writeln('Expected but did not find:');
    for (var expected in unmatchedExpected) {
      buffer.write('  ');
      if (expected is ExpectedError) {
        buffer.write(expected._code);
      }
      if (expected is ExpectedLint) {
        buffer.write(expected._lintName);
      }
      buffer.write(' [${expected._offset}, ');
      buffer.write(expected._length);
      if (expected._messageContains case Pattern messageContains) {
        buffer.write(', messageContains: ');
        buffer.write(json.encode(messageContains.toString()));
      }
      if (expected._correctionContains case Pattern correctionContains) {
        buffer.write(', correctionContains: ');
        buffer.write(json.encode(correctionContains.toString()));
      }
      buffer.writeln(']');
    }
    return buffer.toString();
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content);
  }

  /// Resolves a Dart source file at [path].
  ///
  /// [path] must be converted for this file system.
  Future<ResolvedUnitResult> resolveFile(String path) async {
    var analysisContext = _contextFor(path);
    var session = analysisContext.currentSession;
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  @mustCallSuper
  void setUp() {
    createMockSdk(resourceProvider: resourceProvider, root: _sdkRoot);

    // Check for any needlessly enabled experiments.
    for (var experiment in experiments) {
      var feature = ExperimentStatus.knownFeatures[experiment];
      if (feature?.isEnabledByDefault ?? false) {
        fail(
          "The '$experiment' experiment is enabled by default, "
          'try removing it from `experiments`.',
        );
      }
    }

    writeTestPackageConfig(PackageConfigFileBuilder());
    _writeTestPackagePubspecYamlFile(pubspecYamlContent(name: 'test'));
  }

  @mustCallSuper
  Future<void> tearDown() async {
    await _analysisContextCollection?.dispose();
    _analysisContextCollection = null;
  }

  /// Text to display upon failure, indicating that [unmatchedActual]
  /// diagnostics were found, but unexpected.
  @visibleForOverriding
  String unexpectedMessage(List<Diagnostic> unmatchedActual) {
    var buffer = StringBuffer();
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln('Found but did not expect:');
    for (var actual in unmatchedActual) {
      buffer.write('  ${actual.diagnosticCode} [');
      buffer.write('${actual.offset}, ${actual.length}, ${actual.message}');
      if (actual.correctionMessage case Pattern correctionMessage) {
        buffer.write(', ');
        buffer.write(json.encode(correctionMessage));
      }
      buffer.writeln(']');
    }
    return buffer.toString();
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, config.toContent(pathContext: pathContext));
  }

  void writeTestPackageConfig(PackageConfigFileBuilder config) {
    var configCopy = config.copy();

    configCopy.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: testPackageLanguageVersion,
    );

    if (addFixnumPackageDep) {
      var fixnumPath = addFixnum().parent.path;
      configCopy.add(name: 'fixnum', rootPath: fixnumPath);
    }

    if (addFlutterPackageDep) {
      var uiPath = addUI().parent.path;
      configCopy.add(name: 'ui', rootPath: uiPath);

      var flutterPath = addFlutter().parent.path;
      configCopy.add(name: 'flutter', rootPath: flutterPath);
    }

    if (addJsPackageDep) {
      var jsPath = addJs().parent.path;
      configCopy.add(name: 'js', rootPath: jsPath);
    }

    if (addKernelPackageDep) {
      var kernelPath = addKernel().parent.path;
      configCopy.add(name: 'kernel', rootPath: kernelPath);
    }

    if (addMetaPackageDep) {
      var metaPath = addMeta().parent.path;
      configCopy.add(name: 'meta', rootPath: metaPath);
    }

    if (addTestReflectiveLoaderPackageDep) {
      var testReflectiveLoaderPath = addTestReflectiveLoader().parent.path;
      configCopy.add(
        name: 'test_reflective_loader',
        rootPath: testReflectiveLoaderPath,
      );
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, configCopy);
  }

  void _addTestFile(String content) {
    newFile(_testFilePath, content);
  }

  DriverBasedAnalysisContext _contextFor(String path) {
    _createAnalysisContexts();

    var convertedPath = convertPath(path);
    return _analysisContextCollection!.contextFor(convertedPath);
  }

  /// Creates all analysis contexts in [_collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: {},
      enableIndex: true,
      includedPaths: _collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: _sdkRoot.path,
    );
  }

  /// Resolves the file with the [path] into [result].
  Future<void> _resolveFile(String path) async {
    var convertedPath = convertPath(path);

    result = await resolveFile(convertedPath);
  }

  Future<void> _resolveTestFile() => _resolveFile(_testFilePath);

  void _writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }
}
