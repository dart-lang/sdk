// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';

import 'src/utilities/mock_packages.dart';

/// Finds an [Element] with the given [name].
Element findChildElement(Element root, String name, [ElementKind kind]) {
  Element result;
  root.accept(_ElementVisitorFunctionWrapper((Element element) {
    if (element.name != name) {
      return;
    }
    if (kind != null && element.kind != kind) {
      return;
    }
    result = element;
  }));
  return result;
}

/// A function to be called for every [Element].
typedef _ElementVisitorFunction = void Function(Element element);

class AbstractContextTest with ResourceProviderMixin {
  static bool _lintRulesAreRegistered = false;

  final ByteStore _byteStore = MemoryByteStore();

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollection _analysisContextCollection;

  /// The file system specific `/home/test/analysis_options.yaml` path.
  String get analysisOptionsPath =>
      convertPath('/home/test/analysis_options.yaml');

  List<String> get collectionIncludedPaths => [workspaceRootPath];

  @deprecated
  AnalysisDriver get driver {
    throw 0;
  }

  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  AnalysisSession get session => contextFor('/home/test').currentSession;

  String get testPackageLanguageVersion => '2.9';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  /// The file system specific `/home/test/pubspec.yaml` path.
  String get testPubspecPath => convertPath('/home/test/pubspec.yaml');

  String get workspaceRootPath => '/home';

  void addSource(String path, String content) {
    newFile(path, content: content);
  }

  Future<void> analyzeTestPackageFiles() async {
    var analysisContext = contextFor(testPackageRootPath);
    var files = analysisContext.contextRoot.analyzedFiles().toList();
    for (var path in files) {
      await analysisContext.currentSession.getResolvedUnit(path);
    }
  }

  void changeFile(String path) {
    path = convertPath(path);
    driverFor(path).changeFile(path);
  }

  AnalysisContext contextFor(String path) {
    _createAnalysisContexts();

    path = convertPath(path);
    return _analysisContextCollection.contextFor(path);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({
    List<String> experiments,
    bool implicitCasts,
    List<String> lints,
  }) {
    var buffer = StringBuffer();

    if (experiments != null || implicitCasts != null) {
      buffer.writeln('analyzer:');
    }

    if (experiments != null) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    if (implicitCasts != null) {
      buffer.writeln('  strong-mode:');
      buffer.writeln('    implicit-casts: $implicitCasts');
    }

    if (lints != null) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    newFile(analysisOptionsPath, content: buffer.toString());
  }

  AnalysisDriver driverFor(String path) {
    var context = contextFor(path) as DriverBasedAnalysisContext;
    return context.driver;
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext getContext(String path) {
    path = convertPath(path);
    return _analysisContextCollection.contextFor(path);
  }

  /// Return the existing analysis driver that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver getDriver(String path) {
    DriverBasedAnalysisContext context = getContext(path);
    return context.driver;
  }

  @override
  File newFile(String path, {String content = ''}) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content: content);
  }

  Future<ResolvedUnitResult> resolveFile(String path) async {
    path = convertPath(path);
    return contextFor(path).currentSession.getResolvedUnit(path);
  }

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }

    setupResourceProvider();

    MockSdk(
      resourceProvider: resourceProvider,
    );

    writeTestPackageConfig();
  }

  void setupResourceProvider() {}

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
  }

  /// Update `/home/test/pubspec.yaml` and create the driver.
  void updateTestPubspecFile(String content) {
    newFile(testPubspecPath, content: content);
  }

  void verifyCreatedCollection() {}

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, content: config.toContent(toUriStr: toUriStr));
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder config,
    String languageVersion,
    bool flutter = false,
    bool meta = false,
    bool vector_math = false,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (meta || flutter) {
      var libFolder = MockPackages.instance.addMeta(resourceProvider);
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = MockPackages.instance.addUI(resourceProvider);
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = MockPackages.instance.addFlutter(resourceProvider);
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    if (vector_math) {
      var libFolder = MockPackages.instance.addVectorMath(resourceProvider);
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, config);
  }

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

mixin WithNullSafetyMixin on AbstractContextTest {
  @override
  String get testPackageLanguageVersion => '2.12';
}

/// Wraps the given [_ElementVisitorFunction] into an instance of
/// [engine.GeneralizingElementVisitor].
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor<void> {
  final _ElementVisitorFunction function;
  _ElementVisitorFunctionWrapper(this.function);

  @override
  void visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}
