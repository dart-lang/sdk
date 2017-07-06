// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';

import 'mock_sdk.dart';

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
 * Search the [unit] for the [Element]s with the given [name].
 */
List<Element> findElementsByName(CompilationUnit unit, String name) {
  var finder = new _ElementsByNameFinder(name);
  unit.accept(finder);
  return finder.elements;
}

/**
 * A function to be called for every [Element].
 */
typedef void _ElementVisitorFunction(Element element);

class AbstractContextTest {
  MemoryResourceProvider provider;
  DartSdk sdk;
  Map<String, List<Folder>> packageMap;
  UriResolver resourceResolver;

  StringBuffer _logBuffer = new StringBuffer();
  FileContentOverlay _fileContentOverlay = new FileContentOverlay();
  AnalysisDriver _driver;

  AnalysisDriver get driver => _driver;

  /**
   * Return `true` if strong mode should be enabled for this test.
   */
  bool get enableStrongMode => false;

  /**
   * Return the analysis session associated with the driver.
   */
  AnalysisSession get session => driver.currentSession;

  Source addMetaPackageSource() => addPackageSource(
      'meta',
      'meta.dart',
      r'''
library meta;

const Required required = const Required();

class Required {
  final String reason;
  const Required([this.reason]);
}
''');

  Source addPackageSource(String packageName, String filePath, String content) {
    packageMap[packageName] = [(newFolder('/pubcache/$packageName'))];
    File file = newFile('/pubcache/$packageName/$filePath', content);
    return file.createSource();
  }

  Source addSource(String path, String content, [Uri uri]) {
    if (path.startsWith('/')) {
      path = provider.convertPath(path);
    }
    driver.addFile(path);
    driver.changeFile(path);
    _fileContentOverlay[path] = content;
    return provider.getFile(path).createSource();
  }

  Element findElementInUnit(CompilationUnit unit, String name,
      [ElementKind kind]) {
    return findElementsByName(unit, name)
        .where((e) => kind == null || e.kind == kind)
        .single;
  }

  File newFile(String path, [String content]) =>
      provider.newFile(provider.convertPath(path), content ?? '');

  Folder newFolder(String path) =>
      provider.newFolder(provider.convertPath(path));

  void processRequiredPlugins() {
    AnalysisEngine.instance.processRequiredPlugins();
  }

  Future<CompilationUnit> resolveLibraryUnit(Source source) async {
    return (await driver.getResult(source.fullName))?.unit;
  }

  void setUp() {
    processRequiredPlugins();
    setupResourceProvider();
    sdk = new MockSdk(resourceProvider: provider);
    resourceResolver = new ResourceUriResolver(provider);
    packageMap = new Map<String, List<Folder>>();
    PackageMapUriResolver packageResolver =
        new PackageMapUriResolver(provider, packageMap);
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), packageResolver, resourceResolver]);
    PerformanceLog log = new PerformanceLog(_logBuffer);
    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);
    AnalysisOptionsImpl options = new AnalysisOptionsImpl()
      ..strongMode = enableStrongMode;
    _driver = new AnalysisDriver(
        scheduler,
        log,
        provider,
        new MemoryByteStore(),
        _fileContentOverlay,
        null,
        sourceFactory,
        options);
    scheduler.start();
    AnalysisEngine.instance.logger = PrintLogger.instance;
  }

  void setupResourceProvider() {
    provider = new MemoryResourceProvider();
  }

  void tearDown() {
    provider = null;
    AnalysisEngine.instance.clearCaches();
    AnalysisEngine.instance.logger = null;
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

class _ElementsByNameFinder extends RecursiveAstVisitor<Null> {
  final String name;
  final List<Element> elements = [];

  _ElementsByNameFinder(this.name);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.inDeclarationContext()) {
      elements.add(node.staticElement);
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
