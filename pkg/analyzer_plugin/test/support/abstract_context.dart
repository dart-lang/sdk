// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/element_search.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

/**
 * Finds an [Element] with the given [name].
 */
Element findChildElement(Element root, String name, [ElementKind kind]) {
  Element result = null;
  root.accept(new _ElementVisitorFunctionWrapper((Element element) {
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

/**
 * A function to be called for every [Element].
 */
typedef void _ElementVisitorFunction(Element element);

class AbstractContextTest with ResourceProviderMixin {
  AnalysisDriver _driver;

  AnalysisDriver get driver => _driver;

  AnalysisSession get session => driver.currentSession;

  /// The file system specific `/home/test/pubspec.yaml` path.
  String get testPubspecPath => convertPath('/home/test/pubspec.yaml');

  void addMetaPackage() {
    addPackageFile('meta', 'meta.dart', r'''
library meta;

const Required required = const Required();

class Required {
  final String reason;
  const Required([this.reason]);
}
''');
  }

  /// Add a new file with the given [pathInLib] to the package with the
  /// given [packageName].  Then ensure that the test package depends on the
  /// [packageName].
  File addPackageFile(String packageName, String pathInLib, String content) {
    var packagePath = '/.pub-cache/$packageName';
    _addTestPackageDependency(packageName, packagePath);
    return newFile('$packagePath/lib/$pathInLib', content: content);
  }

  Source addSource(String path, String content, [Uri uri]) {
    File file = newFile(path, content: content);
    Source source = file.createSource(uri);
    driver.addFile(file.path);
    driver.changeFile(file.path);
    return source;
  }

  Element findElementInUnit(CompilationUnit unit, String name,
      [ElementKind kind]) {
    return findElementsByName(unit, name)
        .where((e) => kind == null || e.kind == kind)
        .single;
  }

  Future<CompilationUnit> resolveLibraryUnit(Source source) async {
    return (await driver.getResult(source.fullName))?.unit;
  }

  void setUp() {
    new MockSdk(resourceProvider: resourceProvider);

    newFolder('/home/test');
    newFile('/home/test/.packages', content: r'''
test:file:///home/test/lib
''');

    _createDriver();
  }

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
    AnalysisEngine.instance.logger = null;
  }

  void _addTestPackageDependency(String name, String rootPath) {
    var packagesFile = getFile('/home/test/.packages');
    var packagesContent = packagesFile.readAsStringSync();

    // Ignore if there is already the same package dependency.
    if (packagesContent.contains('$name:file://')) {
      return;
    }

    packagesContent += '$name:${toUri('$rootPath/lib')}\n';

    packagesFile.writeAsStringSync(packagesContent);

    _createDriver();
  }

  void _createDriver() {
    var collection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath('/home')],
      enableIndex: true,
      resourceProvider: resourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    var testPath = convertPath('/home/test');
    var context = collection.contextFor(testPath) as DriverBasedAnalysisContext;

    _driver = context.driver;
  }
}

/**
 * Instances of the class [PrintLogger] print all of the errors.
 */
class PrintLogger implements Logger {
  static final Logger instance = new PrintLogger();

  @override
  void logError(String message, [CaughtException exception]) {
    print(message);
    if (exception != null) {
      print(exception);
    }
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    print(message);
    if (exception != null) {
      print(exception);
    }
  }
}

/**
 * Wraps the given [_ElementVisitorFunction] into an instance of
 * [engine.GeneralizingElementVisitor].
 */
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;

  _ElementVisitorFunctionWrapper(this.function);

  @override
  visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}
