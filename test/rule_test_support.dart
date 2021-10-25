// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

export 'package:analyzer/src/dart/error/syntactic_errors.dart';
export 'package:analyzer/src/error/codes.dart';
export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

ExpectedError error(ErrorCode code, int offset, int length,
        {Pattern? messageContains}) =>
    ExpectedError(code, offset, length, messageContains: messageContains);

ExpectedLint lint(String lintName, int offset, int length,
        {Pattern? messageContains}) =>
    ExpectedLint(lintName, offset, length, messageContains: messageContains);

typedef DiagnosticMatcher = bool Function(AnalysisError error);

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final List<String> lints;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.lints = const [],
  });

  String toContent() {
    var buffer = StringBuffer();

    if (experiments.isNotEmpty) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

/// A description of a diagnostic that is expected to be reported.
class ExpectedDiagnostic {
  final DiagnosticMatcher diagnosticMatcher;

  /// The offset of the beginning of the diagnostic's region.
  final int offset;

  /// The offset of the beginning of the diagnostic's region.
  final int length;

  /// A pattern that should be contained in the diagnostic message or `null` if
  /// the message contents should not be checked.
  final Pattern? messageContains;

  /// Initialize a newly created diagnostic description.
  ExpectedDiagnostic(this.diagnosticMatcher, this.offset, this.length,
      {this.messageContains});

  /// Return `true` if the [error] matches this description of what it's
  /// expected to be.
  bool matches(AnalysisError error) {
    if (!diagnosticMatcher(error)) return false;
    if (error.offset != offset) return false;
    if (error.length != length) return false;
    if (messageContains != null && error.message.contains(messageContains!)) {
      return false;
    }

    return true;
  }
}

class ExpectedError extends ExpectedDiagnostic {
  final ErrorCode code;

  /// Initialize a newly created error description.
  ExpectedError(this.code, int offset, int length, {Pattern? messageContains})
      : super((AnalysisError error) => error.errorCode == code, offset, length,
            messageContains: messageContains);
}

class ExpectedLint extends ExpectedDiagnostic {
  final String lintName;

  /// Initialize a newly created lint description.
  ExpectedLint(this.lintName, int offset, int length,
      {Pattern? messageContains})
      : super((AnalysisError error) => error.errorCode.name == lintName, offset,
            length,
            messageContains: messageContains);
}

abstract class LintRuleTest extends PubPackageResolutionTest {
  String? get lintRule;

  @override
  List<String> get _lintRules => [if (lintRule != null) lintRule!];

  /// Assert that the number of diagnostics that have been gathered matches the
  /// number of [expectedDiagnostics] and that they have the expected error
  /// descriptions and locations. The order in which the diagnostics were
  /// gathered is ignored.
  Future<void> assertDiagnostics(
      String code, List<ExpectedDiagnostic> expectedDiagnostics) async {
    addTestFile(code);
    await resolveTestFile();

    //
    // Match actual diagnostics to expected diagnostics.
    //
    var unmatchedActual = errors.toList();
    var unmatchedExpected = expectedDiagnostics.toList();
    var actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      var matchFound = false;
      var expectedIndex = 0;
      while (expectedIndex < unmatchedExpected.length) {
        if (unmatchedExpected[expectedIndex]
            .matches(unmatchedActual[actualIndex])) {
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
    //
    // Write the results.
    //
    var buffer = StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.writeln('Expected but did not find:');
      for (var expected in unmatchedExpected) {
        buffer.write('  ');
        if (expected is ExpectedError) {
          buffer.write(expected.code);
        }
        if (expected is ExpectedLint) {
          buffer.write(expected.lintName);
        }
        buffer.write(' [');
        buffer.write(expected.offset);
        buffer.write(', ');
        buffer.write(expected.length);
        buffer.writeln(']');
      }
    }
    if (unmatchedActual.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Found but did not expect:');
      for (var actual in unmatchedActual) {
        buffer.write('  ');
        buffer.write(actual.errorCode);
        buffer.write(' [');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.write(', ');
        buffer.write(actual.message);
        buffer.writeln(']');
      }
    }
    if (buffer.isNotEmpty) {
      errors.sort((first, second) => first.offset.compareTo(second.offset));
      buffer.writeln();
      buffer.writeln('To accept the current state, expect:');
      for (var actual in errors) {
        late String diagnosticKind;
        late Object description;
        if (actual.errorCode is LintCode) {
          diagnosticKind = 'lint';
          description = "'${actual.errorCode.name}'";
        } else {
          diagnosticKind = 'error';
          description = actual.errorCode;
        }
        buffer.write('  $diagnosticKind(');
        buffer.write(description);
        buffer.write(', ');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.writeln('),');
      }
      fail(buffer.toString());
    }
  }

  /// Assert that there are no diagnostics in the given [code].
  Future<void> assertNoDiagnostics(String code) async =>
      assertDiagnostics(code, const []);
}

class PubPackageResolutionTest extends _ContextResolutionTest {
  final List<String> _lintRules = const [];

  bool get addJsPackageDep => false;

  bool get addMetaPackageDep => false;

  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  List<String> get experiments => [
        EnableString.constructor_tearoffs,
      ];

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  @override
  String get testFilePath => '$testPackageLibPath/test.dart';

  String? get testPackageLanguageVersion => null;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  @override
  @mustCallSuper
  void setUp() {
    super.setUp();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
        lints: _lintRules,
      ),
    );
    _writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(
      path,
      content: config.toContent(
        toUriStr: toUriStr,
      ),
    );
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      content: config.toContent(),
    );
  }

  void writeTestPackagePubspecYamlFile(PubspecYamlFileConfig config) {
    newPubspecYamlFile(testPackageRootPath, config.toContent());
  }

  void _writeTestPackageConfig(PackageConfigFileBuilder config) {
    var configCopy = config.copy();

    configCopy.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: testPackageLanguageVersion,
    );

    if (addJsPackageDep) {
      var jsPath = '/packages/js';
      MockPackages.addJsPackageFiles(
        getFolder(jsPath),
      );
      configCopy.add(name: 'js', rootPath: jsPath);
    }

    if (addMetaPackageDep) {
      var metaPath = '/packages/meta';
      MockPackages.addMetaPackageFiles(
        getFolder(metaPath),
      );
      configCopy.add(name: 'meta', rootPath: metaPath);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, configCopy);
  }
}

class PubspecYamlFileConfig {
  final String? name;
  final String? sdkVersion;
  final List<PubspecYamlFileDependency> dependencies;

  PubspecYamlFileConfig({
    this.name,
    this.sdkVersion,
    this.dependencies = const [],
  });

  String toContent() {
    var buffer = StringBuffer();

    if (name != null) {
      buffer.writeln('name: $name');
    }

    if (sdkVersion != null) {
      buffer.writeln('environment:');
      buffer.writeln("  sdk: '$sdkVersion'");
    }

    if (dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (var dependency in dependencies) {
        buffer.writeln('  ${dependency.name}: ${dependency.version}');
      }
    }

    return buffer.toString();
  }
}

class PubspecYamlFileDependency {
  final String name;
  final String version;

  PubspecYamlFileDependency({
    required this.name,
    this.version = 'any',
  });
}

abstract class _ContextResolutionTest with ResourceProviderMixin {
  static bool _lintRulesAreRegistered = false;

  final ByteStore _byteStore = MemoryByteStore();

  AnalysisContextCollectionImpl? _analysisContextCollection;

  late ResolvedUnitResult result;

  List<String> get collectionIncludedPaths;

  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors => result.errors;

  Folder get sdkRoot => newFolder('/sdk');

  String get testFilePath => '/test/lib/test.dart';

  void addTestFile(String content) {
    newFile(testFilePath, content: content);
  }

  @override
  File newFile(String path, {String content = ''}) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content: content);
  }

  Future<ResolvedUnitResult> resolveFile(String path) async {
    var analysisContext = _contextFor(path);
    var session = analysisContext.currentSession;
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  Future<void> resolveTestFile() => _resolveFile(testFilePath);

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
  }

  DriverBasedAnalysisContext _contextFor(String path) {
    _createAnalysisContexts();

    var convertedPath = convertPath(path);
    return _analysisContextCollection!.contextFor(convertedPath);
  }

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: {},
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
  }

  /// Resolve the file with the [path] into [result].
  Future<void> _resolveFile(String path) async {
    var convertedPath = convertPath(path);

    result = await resolveFile(convertedPath);
  }
}
