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
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

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

abstract class LintRuleTest extends PubPackageResolutionTest {
  String? get lintRule;

  @override
  List<String> get _lintRules => [if (lintRule != null) lintRule!];

  Future<void> assertLint(String code) async {
    addTestFile(code);
    await resolveTestFile();

    for (var error in errors) {
      if (error.errorCode.name == lintRule) {
        return;
      }
    }

    fail('Expected: $lintRule, found none');
  }

  Future<void> assertNoLint(String code) async {
    addTestFile(code);
    await resolveTestFile();

    for (var error in errors) {
      if (error.errorCode.name == lintRule) {
        fail(error.message);
      }
    }
  }
}

class PubPackageResolutionTest extends _ContextResolutionTest {
  final List<String> _lintRules = const [];

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
    writeTestPackageConfig(
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

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    String? languageVersion,
    bool js = false,
    bool meta = false,
  }) {
    var configCopy = config.copy();

    configCopy.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (js) {
      var jsPath = '/packages/js';
      MockPackages.addJsPackageFiles(
        getFolder(jsPath),
      );
      configCopy.add(name: 'js', rootPath: jsPath);
    }

    if (meta) {
      var metaPath = '/packages/meta';
      MockPackages.addMetaPackageFiles(
        getFolder(metaPath),
      );
      configCopy.add(name: 'meta', rootPath: metaPath);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, configCopy);
  }

  void writeTestPackageConfigWithMeta() {
    writeTestPackageConfig(PackageConfigFileBuilder(), meta: true);
  }

  void writeTestPackagePubspecYamlFile(PubspecYamlFileConfig config) {
    newPubspecYamlFile(testPackageRootPath, config.toContent());
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

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  List<String> get collectionIncludedPaths;

  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors => result.errors;

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

    MockSdk(
      resourceProvider: resourceProvider,
      additionalLibraries: additionalMockSdkLibraries,
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
      sdkPath: convertPath('/sdk'),
    );
  }

  /// Resolve the file with the [path] into [result].
  Future<void> _resolveFile(String path) async {
    var convertedPath = convertPath(path);

    result = await resolveFile(convertedPath);
    expect(result.state, ResultState.VALID);
  }
}
