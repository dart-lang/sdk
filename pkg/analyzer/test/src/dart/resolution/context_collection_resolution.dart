// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'context_collection_resolution_caching.dart';
import 'resolution.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final bool implicitDynamic;
  final List<String> lints;
  final bool strictInference;
  final bool strictRawTypes;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.implicitCasts = true,
    this.implicitDynamic = true,
    this.lints = const [],
    this.strictInference = false,
    this.strictRawTypes = false,
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

  ByteStore _byteStore = getContextResolutionTestByteStore();

  Map<String, String> _declaredVariables = {};
  AnalysisContextCollection _analysisContextCollection;

  /// If not `null`, [resolveFile] will use the context that corresponds
  /// to this path, instead of the given path.
  String pathForContextSelection;

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  List<String> get collectionIncludedPaths;

  set declaredVariables(Map<String, String> map) {
    if (_analysisContextCollection != null) {
      throw StateError('Declared variables cannot be changed after analysis.');
    }

    _declaredVariables = map;
  }

  bool get retainDataForTesting => false;

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
    var analysisContext = contextFor(pathForContextSelection ?? path);
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

  /// Call this method if the test needs to use the empty byte store, without
  /// any information cached.
  void useEmptyByteStore() {
    _byteStore = MemoryByteStore();
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
      retainDataForTesting: retainDataForTesting,
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

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  @override
  String get testFilePath => '$testPackageLibPath/test.dart';

  /// The language version to use by default for `package:test`.
  String get testPackageLanguageVersion => '2.9';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  @override
  void setUp() {
    super.setUp();
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
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      content: config.toContent(),
    );
  }

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    String languageVersion,
    bool js = false,
    bool meta = false,
  }) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (js) {
      var jsPath = '/packages/js';
      MockPackages.addJsPackageFiles(
        getFolder(jsPath),
      );
      config.add(name: 'js', rootPath: jsPath);
    }

    if (meta) {
      var metaPath = '/packages/meta';
      MockPackages.addMetaPackageFiles(
        getFolder(metaPath),
      );
      config.add(name: 'meta', rootPath: metaPath);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, config);
  }

  void writeTestPackageConfigWithMeta() {
    writeTestPackageConfig(PackageConfigFileBuilder(), meta: true);
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

mixin WithNonFunctionTypeAliasesMixin on PubPackageResolutionTest {
  @override
  String get testPackageLanguageVersion => null;

  @override
  bool get typeToStringWithNullability => true;

  @nonVirtual
  @override
  void setUp() {
    super.setUp();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: [EnableString.nonfunction_type_aliases],
      ),
    );
  }
}

mixin WithNullSafetyMixin on PubPackageResolutionTest {
  @override
  String get testPackageLanguageVersion => null;

  @override
  bool get typeToStringWithNullability => true;
}
