// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'resolution.dart';

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final bool implicitDynamic;
  final List<String> lints;
  final bool strictInference;
  final bool strictRawTypes;

  AnalysisOptionsFileConfig({
    this.experiments,
    this.implicitCasts,
    this.implicitDynamic,
    this.lints,
    this.strictInference,
    this.strictRawTypes,
  });

  String toContent() {
    var buffer = StringBuffer();

    if (experiments != null ||
        implicitCasts != null ||
        implicitDynamic != null ||
        strictRawTypes != null ||
        strictInference != null) {
      buffer.writeln('analyzer:');

      if (experiments != null) {
        buffer.writeln('  enable-experiment:');
        for (var experiment in experiments) {
          buffer.writeln('    - $experiment');
        }
      }

      buffer.writeln('  language:');
      if (strictRawTypes != null) {
        buffer.writeln('    strict-raw-types: $strictRawTypes');
      }
      if (strictInference != null) {
        buffer.writeln('    strict-inference: $strictInference');
      }

      if (implicitCasts != null || implicitDynamic != null) {
        buffer.writeln('  strong-mode:');
        if (implicitCasts != null) {
          buffer.writeln('    implicit-casts: $implicitCasts');
        }
        if (implicitDynamic != null) {
          buffer.writeln('    implicit-dynamic: $implicitDynamic');
        }
      }
    }

    if (lints != null) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    return buffer.toString();
  }
}

class BazelWorkspaceResolutionTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  @override
  String get testFilePath => '$myPackageLibPath/my.dart';

  String get workspaceRootPath => '/workspace';

  String get workspaceThirdPartyDartPath {
    return '$workspaceRootPath/third_party/dart';
  }

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/WORKSPACE', content: '');
    newFile('$myPackageRootPath/BUILD', content: '');
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertBazelWorkspaceFor(testFilePath);
  }
}

/// [AnalysisContextCollection] based implementation of [ResolutionTest].
abstract class ContextResolutionTest
    with ResourceProviderMixin, ResolutionTest {
  static bool _lintRulesAreRegistered = false;

  final ByteStore _byteStore = MemoryByteStore();

  Map<String, String> _declaredVariables = {};
  AnalysisContextCollection _analysisContextCollection;

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  List<String> get collectionIncludedPaths;

  set declaredVariables(Map<String, String> map) {
    if (_analysisContextCollection != null) {
      throw StateError('Declared variables cannot be changed after analysis.');
    }

    _declaredVariables = map;
  }

  void assertBasicWorkspaceFor(String path) {
    var workspace = contextFor(path).workspace;
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void assertBazelWorkspaceFor(String path) {
    var workspace = contextFor(path).workspace;
    expect(workspace, TypeMatcher<BazelWorkspace>());
  }

  void assertGnWorkspaceFor(String path) {
    var workspace = contextFor(path).workspace;
    expect(workspace, TypeMatcher<GnWorkspace>());
  }

  void assertPackageBuildWorkspaceFor(String path) {
    var workspace = contextFor(path).workspace;
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void assertPubWorkspaceFor(String path) {
    var workspace = contextFor(path).workspace;
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  AnalysisContext contextFor(String path) {
    _createAnalysisContexts();

    path = convertPath(path);
    return _analysisContextCollection.contextFor(path);
  }

  void disposeAnalysisContextCollection() {
    if (_analysisContextCollection != null) {
      _analysisContextCollection = null;
    }
  }

  /// TODO(scheglov) Replace this with a method that changes a file in
  /// [AnalysisContextCollectionImpl].
  AnalysisDriver driverFor(String path) {
    var context = contextFor(path) as DriverBasedAnalysisContext;
    return context.driver;
  }

  @override
  File newFile(String path, {String content = ''}) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content: content);
  }

  @override
  Future<ResolvedUnitResult> resolveFile(String path) {
    var analysisContext = contextFor(path);
    var session = analysisContext.currentSession;
    return session.getResolvedUnit(path);
  }

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

  void verifyCreatedCollection() {}

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: _declaredVariables,
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    verifyCreatedCollection();
  }
}

class PubPackageResolutionTest extends ContextResolutionTest {
  AnalysisOptionsImpl get analysisOptions {
    var path = convertPath(testPackageRootPath);
    return contextFor(path).analysisOptions;
  }

  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  @override
  String get testFilePath => '$testPackageLibPath/test.dart';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig({});
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      content: config.toContent(),
    );
  }

  void writeTestPackageConfig(Map<String, String> nameToRootPath) {
    nameToRootPath = {'test': testPackageRootPath, ...nameToRootPath};

    var packagesFileBuffer = StringBuffer();
    for (var entry in nameToRootPath.entries) {
      var name = entry.key;
      var rootPath = entry.value;
      packagesFileBuffer.writeln(name + ':' + toUriStr('$rootPath/lib'));
    }
    // TODO(scheglov) Use package_config.json
    newFile(
      '$testPackageRootPath/.packages',
      content: '$packagesFileBuffer',
    );
  }

  void writeTestPackageConfigWith(
    Map<String, String> nameToRootPath, {
    bool meta = false,
  }) {
    var metaPath = '/packages/meta';
    PackagesContent.addMetaPackageFiles(
      getFolder(metaPath),
    );

    writeTestPackageConfig({
      if (meta) 'meta': metaPath,
      ...nameToRootPath,
    });
  }

  void writeTestPackageConfigWithMeta() {
    writeTestPackageConfigWith({}, meta: true);
  }

  void writeTestPackagePubspecYamlFile(PubspecYamlFileConfig config) {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      content: config.toContent(),
    );
  }
}

class PubspecYamlFileConfig {
  final String sdkVersion;

  PubspecYamlFileConfig({this.sdkVersion});

  String toContent() {
    var buffer = StringBuffer();

    if (sdkVersion != null) {
      buffer.writeln('environment:');
      buffer.writeln("  sdk: '$sdkVersion'");
    }

    return buffer.toString();
  }
}

mixin WithNullSafetyMixin on PubPackageResolutionTest {
  @override
  bool get typeToStringWithNullability => true;

  @nonVirtual
  @override
  void setUp() {
    super.setUp();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: [EnableString.non_nullable],
      ),
    );
  }
}
