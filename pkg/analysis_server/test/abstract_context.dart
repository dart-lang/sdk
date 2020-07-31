// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
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
  OverlayResourceProvider overlayResourceProvider;

  AnalysisContextCollection _analysisContextCollection;
  AnalysisDriver _driver;

  /// The file system specific `/home/test/analysis_options.yaml` path.
  String get analysisOptionsPath =>
      convertPath('/home/test/analysis_options.yaml');

  AnalysisDriver get driver => _driver;

  AnalysisSession get session => driver.currentSession;

  /// The file system specific `/home/test/pubspec.yaml` path.
  String get testPubspecPath => convertPath('/home/test/pubspec.yaml');

  void addFlutterPackage() {
    addMetaPackage();

    addTestPackageDependency(
      'ui',
      MockPackages.instance.addUI(resourceProvider).parent.path,
    );

    addTestPackageDependency(
      'flutter',
      MockPackages.instance.addFlutter(resourceProvider).parent.path,
    );
  }

  void addMetaPackage() {
    var libFolder = MockPackages.instance.addMeta(resourceProvider);
    addTestPackageDependency('meta', libFolder.parent.path);
  }

  /// Add a new file with the given [pathInLib] to the package with the
  /// given [packageName].  Then ensure that the test package depends on the
  /// [packageName].
  File addPackageFile(String packageName, String pathInLib, String content) {
    var packagePath = '/.pub-cache/$packageName';
    addTestPackageDependency(packageName, packagePath);
    return newFile('$packagePath/lib/$pathInLib', content: content);
  }

  Source addSource(String path, String content, [Uri uri]) {
    var file = newFile(path, content: content);
    var source = file.createSource(uri);
    driver.addFile(file.path);
    driver.changeFile(file.path);
    return source;
  }

  void addTestPackageDependency(String name, String rootPath) {
    var packagesFile = getFile('/home/test/.packages');
    var packagesContent =
        packagesFile.exists ? packagesFile.readAsStringSync() : '';

    // Ignore if there is already the same package dependency.
    if (packagesContent.contains('$name:file://')) {
      return;
    }

    rootPath = convertPath(rootPath);
    packagesContent += '$name:${toUri('$rootPath/lib')}\n';

    packagesFile.writeAsStringSync(packagesContent);

    createAnalysisContexts();
  }

  void addVectorMathPackage() {
    var libFolder = MockPackages.instance.addVectorMath(resourceProvider);
    addTestPackageDependency('vector_math', libFolder.parent.path);
  }

  /// Create all analysis contexts in `/home`.
  void createAnalysisContexts() {
    _analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath('/home')],
      enableIndex: true,
      resourceProvider: overlayResourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    var testPath = convertPath('/home/test');
    _driver = getDriver(testPath);
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
    if (_driver != null) {
      createAnalysisContexts();
    }
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

  Future<CompilationUnit> resolveLibraryUnit(Source source) async {
    var resolveResult = await session.getResolvedUnit(source.fullName);
    return resolveResult.unit;
  }

  @mustCallSuper
  void setUp() {
    registerLintRules();

    setupResourceProvider();
    overlayResourceProvider = OverlayResourceProvider(resourceProvider);

    MockSdk(resourceProvider: resourceProvider);

    newFolder('/home/test');
    newFile('/home/test/.packages', content: '''
test:${toUriStr('/home/test/lib')}
''');

    createAnalysisContexts();
  }

  void setupResourceProvider() {}

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
  }

  /// Update `/home/test/pubspec.yaml` and create the driver.
  void updateTestPubspecFile(String content) {
    newFile(testPubspecPath, content: content);
    createAnalysisContexts();
  }
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
