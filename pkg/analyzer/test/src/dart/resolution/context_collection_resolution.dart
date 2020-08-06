// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';

import 'resolution.dart';

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final List<String> lints;
  final bool strictInference;
  final bool strictRawTypes;

  AnalysisOptionsFileConfig({
    this.experiments,
    this.implicitCasts,
    this.lints,
    this.strictInference,
    this.strictRawTypes,
  });

  String toContent() {
    var buffer = StringBuffer();

    if (experiments != null ||
        strictRawTypes != null ||
        strictInference != null ||
        implicitCasts != null) {
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

      if (implicitCasts != null) {
        buffer.writeln('  strong-mode:');
        buffer.writeln('    implicit-casts: $implicitCasts');
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

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/WORKSPACE', content: '');
  }
}

/// [AnalysisContextCollection] based implementation of [ResolutionTest].
abstract class ContextResolutionTest
    with ResourceProviderMixin, ResolutionTest {
  static bool _lintRulesAreRegistered = false;

  AnalysisContextCollection _analysisContextCollection;

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  List<String> get collectionIncludedPaths;

  AnalysisContext contextFor(String path) {
    if (_analysisContextCollection == null) {
      _createAnalysisContexts();
    }

    path = convertPath(path);
    return _analysisContextCollection.contextFor(path);
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

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    _analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      enableIndex: true,
      resourceProvider: resourceProvider,
      sdkPath: convertPath('/sdk'),
    );
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

  void writeTestPackageAnalysisOptionsFile(
    AnalysisOptionsFileConfig builder,
  ) {
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      content: builder.toContent(),
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

  void writeTestPackageConfigWithMeta() {
    var path = '/packages/meta';
    PackagesContent.addMetaPackageFiles(
      getFolder(path),
    );
    writeTestPackageConfig({'meta': path});
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
