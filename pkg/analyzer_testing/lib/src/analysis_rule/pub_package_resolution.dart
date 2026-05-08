// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/byte_store.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/experiments.dart'; // ignore: implementation_imports
import 'package:analyzer/src/diagnostic/diagnostic.dart' // ignore: implementation_imports
    as diag;
import 'package:analyzer/src/test_utilities/mock_sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/spelunker.dart';
import 'package:analyzer_testing/utilities/extensions/diagnostic_code.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

typedef DiagnosticMatcher = bool Function(Diagnostic diagnostic);

/// A description of a message that is expected to be reported with an error.
class ExpectedContextMessage {
  /// The path of the file with which the message is associated.
  final File file;

  /// The offset of the beginning of the error's region.
  final int offset;

  /// The offset of the beginning of the error's region.
  final int length;

  /// The message text for the error.
  final String? text;

  /// A list of patterns that should be contained in the message test; empty if
  /// the message contents should not be checked.
  final List<Pattern> textContains;

  ExpectedContextMessage(
    this.file,
    this.offset,
    this.length, {
    @Deprecated('Use textContains instead') this.text,
    this.textContains = const [],
  }) : assert(
         text == null || textContains.isEmpty,
         'Use only one of text or textContains',
       );

  /// Return `true` if the [message] matches this description of what it's
  /// expected to be.
  bool matches(DiagnosticMessage message) {
    if (message.filePath != file.path) {
      return false;
    }
    if (message.offset != offset) {
      return false;
    }
    if (message.length != length) {
      return false;
    }
    var messageText = message.messageText(includeUrl: true);
    List<Pattern> textContains;
    if (text != null) {
      textContains = [text!];
    } else {
      textContains = this.textContains;
    }
    for (var pattern in textContains) {
      if (!messageText.contains(pattern)) {
        return false;
      }
    }
    return true;
  }
}

/// A description of a diagnostic that is expected to be reported.
class ExpectedDiagnostic {
  final DiagnosticMatcher diagnosticMatcher;

  /// The offset of the beginning of the diagnostic's region.
  final int offset;

  /// The length of the diagnostic's region.
  final int length;

  /// A pattern that should be contained in the diagnostic message or `null` if
  /// the message contents should not be checked.
  final List<Pattern> _messageContains;

  /// A pattern that should be contained in the error's correction message, or
  /// `null` if the correction message contents should not be checked.
  final Pattern? _correctionContains;

  /// The list of context messages that are expected to be associated with the
  /// error, or `null` if the context messages should not be checked.
  final List<ExpectedContextMessage>? _contextMessages;
  ExpectedDiagnostic(
    this.diagnosticMatcher,
    this.offset,
    this.length, {
    @Deprecated('Use messageContainsAll instead') Pattern? messageContains,
    List<Pattern> messageContainsAll = const [],
    Pattern? correctionContains,
    List<ExpectedContextMessage>? contextMessages,
  }) : assert(
         messageContains == null || messageContainsAll.isEmpty,
         'Use only one of messageContains or messageContainsAll',
       ),
       _contextMessages = contextMessages,
       _messageContains = messageContains != null
           ? [messageContains]
           : messageContainsAll,
       _correctionContains = correctionContains;

  List<ExpectedContextMessage>? get contextMessages => _contextMessages;
  Pattern? get correctionContains => _correctionContains;

  List<Pattern> get messageContains => _messageContains;

  /// Whether the [diagnostic] matches this description of what it's expected to be.
  bool matches(Diagnostic diagnostic) {
    if (!diagnosticMatcher(diagnostic)) return false;
    if (diagnostic.offset != offset) return false;
    if (diagnostic.length != length) return false;
    for (var pattern in _messageContains) {
      if (!diagnostic.message.contains(pattern)) {
        return false;
      }
    }
    if (_correctionContains != null) {
      var correctionMessage = diagnostic.correctionMessage;
      if (correctionMessage == null ||
          !correctionMessage.contains(_correctionContains)) {
        return false;
      }
    }
    if (_contextMessages != null) {
      var actualContextMessages = diagnostic.contextMessages.toList();
      if (actualContextMessages.length != _contextMessages.length) {
        return false;
      }
      for (int i = 0; i < _contextMessages.length; i++) {
        if (!_contextMessages[i].matches(actualContextMessages[i])) {
          return false;
        }
      }
    }

    return true;
  }
}

/// A description of an expected error.
final class ExpectedError extends ExpectedDiagnostic {
  final DiagnosticCode _code;
  ExpectedError(
    this._code,
    int offset,
    int length, {
    @Deprecated('Use messageContainsAll instead') super.messageContains,
    super.messageContainsAll,
    super.correctionContains,
    super.contextMessages,
  }) : super(
         (diagnostic) => diagnostic.diagnosticCode == _code,
         offset,
         length,
       );

  DiagnosticCode get code => _code;
}

/// A description of an expected lint rule violation.
final class ExpectedLint extends ExpectedDiagnostic {
  final String _lintName;
  ExpectedLint(
    this._lintName,
    int offset,
    int length, {
    @Deprecated('Use messageContainsAll instead') super.messageContains,
    super.messageContainsAll,
    super.correctionContains,
    super.contextMessages,
  }) : super(
         (diagnostic) =>
             diagnostic.diagnosticCode.lowerCaseName == _lintName.toLowerCase(),
         offset,
         length,
       );

  String get lintName => _lintName;
}

/// A builder for package files (for example, mocks); generally accessed via
/// [PubPackageResolutionTest.newPackage].
class PackageBuilder {
  final String _packagePath;
  final PubPackageResolutionTest _test;

  PackageBuilder._(String packagePath, PubPackageResolutionTest test)
    : _packagePath = packagePath,
      _test = test;

  /// Adds a file to [PubPackageResolutionTest.resourceProvider].
  ///
  /// The file is added at [localPath] relative to the package path of this
  /// [PackageBuilder], with [content].
  void addFile(String localPath, String content) {
    _test.newFile('$_packagePath/$localPath', content);
  }
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

  /// The test file being analyzed.
  late File testFile = newFile(_testFilePath, '');

  /// The analysis result that is used in various `assertDiagnostics` methods.
  late ResolvedUnitResult result;

  /// The names of packages which should be added to the
  /// [PackageConfigFileBuilder].
  final Set<String> _packagesToAdd = {};

  /// Adds the 'fixnum' package as a dependency to the package-under-test.
  ///
  /// This allows `package:fixnum/fixnum.dart` imports to resolve.
  bool get addFixnumPackageDep => false;

  /// Adds the 'flutter' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:flutter/` imports to resolve.
  bool get addFlutterPackageDep => false;

  /// Adds the 'meta' package as a dependency to the package-under-test.
  ///
  /// This allows various `package:meta/` imports to resolve.
  bool get addMetaPackageDep => false;

  /// Adds the 'test_reflective_loader' package as a dependency to the
  /// package-under-test.
  ///
  /// This allows various `package:test_reflective_loader/` imports to resolve.
  bool get addTestReflectiveLoaderPackageDep => false;

  AnalysisContextCollection get contextCollection {
    _createAnalysisContexts();
    return _analysisContextCollection!;
  }

  /// Whether to print out the syntax tree being tested, on a test failure.
  bool get dumpAstOnFailures => true;

  /// The list of language experiments to be enabled for these tests.
  List<String> get experiments => experimentsForTests;

  /// Error codes that by default should be ignored in test expectations.
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    diag.unusedElement,
    diag.unusedField,
    diag.unusedLocalVariable,
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
  List<Diagnostic> get _diagnostics => result.diagnostics
      .where((e) => !ignoredDiagnosticCodes.any((c) => e.diagnosticCode == c))
      .toList();

  Folder get _sdkRoot => newFolder('/sdk');

  String get _testFilePath => '$testPackageLibPath/$testFileName';

  /// Asserts that the number of diagnostics reported in [content] matches the
  /// number of [expectedDiagnostics] and that they have the expected error
  /// descriptions and locations.
  ///
  /// The order in which the diagnostics were gathered is ignored.
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
  Future<void> assertDiagnostics(
    String content,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) async {
    _addTestFile(content);
    await _resolveTestFile();
    assertDiagnosticsIn(_diagnostics, expectedDiagnostics);
  }

  /// Asserts that the diagnostics in [diagnostics] match [expectedDiagnostics].
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
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
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
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
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
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
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
  Future<void> assertNoDiagnostics(String content) async =>
      assertDiagnostics(content, const []);

  /// Asserts that there are no diagnostics in the file at the given [path].
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
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
        buffer.write('  error(${actual.diagnosticCode.constantName}, ');
      }
      buffer.write('${actual.offset}, ${actual.length},');
      if (actual.contextMessages.isNotEmpty) {
        buffer.write(' contextMessages: [');
        for (var contextMessage in actual.contextMessages) {
          buffer.write('contextMessage(');
          buffer.write("newFile('${contextMessage.filePath}'), ");
          buffer.write('${contextMessage.offset}, ${contextMessage.length},');
          buffer.write('), ');
        }
        buffer.write('],');
      }
      buffer.write('),');
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
      buffer.write(' [${expected.offset}, ');
      buffer.write(expected.length);
      if (expected._messageContains.isNotEmpty) {
        buffer.write(', messageContains: ');
        buffer.write(
          json.encode([
            for (var pattern in expected._messageContains) pattern.toString(),
          ]),
        );
      }
      if (expected._correctionContains case Pattern correctionContains) {
        buffer.write(', correctionContains: ');
        buffer.write(json.encode(correctionContains.toString()));
      }

      if (expected._contextMessages
          case List(:var isNotEmpty) && var contextMessages when isNotEmpty) {
        buffer.write(', contextMessages: [');
        for (var i = 0; i < contextMessages.length; i++) {
          var contextMessage = contextMessages[i];
          if (i > 0) {
            buffer.write(', ');
          }
          buffer.write('message(');
          buffer.write(contextMessage.file.path);
          buffer.write(', ');
          buffer.write(contextMessage.offset);
          buffer.write(', ');
          buffer.write(contextMessage.length);
          if (contextMessage.text != null) {
            buffer.write(', text: ');
            buffer.write(json.encode(contextMessage.text));
          }
          if (contextMessage.textContains.isNotEmpty) {
            buffer.write(', textContains: ');
            buffer.write(
              json.encode([
                for (var pattern in contextMessage.textContains)
                  pattern.toString(),
              ]),
            );
          }
          buffer.write(')');
        }
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

  /// Registers a package named [name].
  ///
  /// The returned [PackageBuilder] can be used to add Dart source files in the
  /// package sources, via [PackageBuilder.addFile].
  PackageBuilder newPackage(String name) {
    var packagePath = convertPath('/package/$name');
    _packagesToAdd.add(name);
    return PackageBuilder._(packagePath, this);
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
    for (Diagnostic actual in unmatchedActual) {
      buffer.write('  ');
      buffer.write(actual.diagnosticCode);
      buffer.write(' [');
      buffer.write(actual.offset);
      buffer.write(', ');
      buffer.write(actual.length);
      buffer.write(', ');
      buffer.write(json.encode(actual.message));
      if (actual.correctionMessage != null) {
        buffer.write(', ');
        buffer.write(json.encode(actual.correctionMessage));
      }
      if (actual.contextMessages.isNotEmpty) {
        buffer.write(', contextMessages: [');
        for (var i = 0; i < actual.contextMessages.length; i++) {
          var message = actual.contextMessages[i];
          if (i > 0) {
            buffer.write(', ');
          }
          buffer.write('message(');
          // Special case for `testFile`, used very often.
          switch (message.filePath) {
            case '/home/test/lib/test.dart':
              buffer.write('testFile');
            case var filePath:
              buffer.write("'$filePath'");
          }
          buffer.write(', ');
          buffer.write(message.offset);
          buffer.write(', ');
          buffer.write(message.length);
          buffer.write(', ');
          buffer.write(json.encode(message.messageText(includeUrl: false)));
          buffer.write(')');
        }
      }
      buffer.writeln(']');
    }
    return buffer.toString();
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, config.toContent(pathContext: pathContext));
  }

  /// Writes a `package_config.json` file from [config], and for packages that
  /// have been added via [newPackage].
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
      var skyEnginePath = addSkyEngine(sdkPath: _sdkRoot.path).parent.path;
      configCopy.add(name: 'sky_engine', rootPath: skyEnginePath);

      var flutterPath = addFlutter().parent.path;
      configCopy.add(name: 'flutter', rootPath: flutterPath);
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

    for (var packageName in _packagesToAdd) {
      var packagePath = convertPath('/package/$packageName');
      configCopy.add(name: packageName, rootPath: packagePath);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, configCopy);
  }

  void _addTestFile(String content) {
    testFile.writeAsStringSync(content);
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
      withFineDependencies: true,
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
