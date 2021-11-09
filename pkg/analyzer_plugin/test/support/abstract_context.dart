// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
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
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

/// Finds an [Element] with the given [name].
Element? findChildElement(Element root, String name, [ElementKind? kind]) {
  Element? result;
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
  final ByteStore _byteStore = MemoryByteStore();

  final Map<String, String> _declaredVariables = {};

  AnalysisContextCollection? _analysisContextCollection;

  List<String> get collectionIncludedPaths => [workspaceRootPath];

  Folder get sdkRoot => newFolder('/sdk');

  AnalysisSession get session => contextFor(testPackageRootPath).currentSession;

  /// The file system-specific `analysis_options.yaml` path.
  String get testPackageAnalysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  String? get testPackageLanguageVersion => null;

  /// The file system-specific `pubspec.yaml` path.
  String get testPackagePubspecPath =>
      convertPath('$testPackageRootPath/pubspec.yaml');

  String get testPackageRootPath => convertPath('/home/test');

  String get workspaceRootPath => convertPath('/home');

  void addSource(String path, String content) {
    newFile(path, content: content);
  }

  AnalysisContext contextFor(String path) {
    _createAnalysisContexts();

    path = convertPath(path);
    return _analysisContextCollection!.contextFor(path);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({List<String>? experiments}) {
    var buffer = StringBuffer();
    buffer.writeln('analyzer:');

    if (experiments != null) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    newFile(testPackageAnalysisOptionsPath, content: buffer.toString());
  }

  @override
  File newFile(String path, {String content = ''}) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content: content);
  }

  Future<ResolvedUnitResult> resolveFile(String path) async {
    var session = contextFor(path).currentSession;
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    newFolder(testPackageRootPath);
    writeTestPackageConfig();
  }

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, content: config.toContent(toUriStr: toUriStr));
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool meta = false,
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
      sdkPath: sdkRoot.path,
    );
  }
}

mixin WithoutNullSafetyMixin on AbstractContextTest {
  @override
  String? get testPackageLanguageVersion => '2.9';
}

/// Wraps the given [_ElementVisitorFunction] into an instance of
/// [engine.GeneralizingElementVisitor].
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;

  _ElementVisitorFunctionWrapper(this.function);

  @override
  void visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}
