// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';

import 'mock_sdk.dart';
import 'src/utilities/flutter_util.dart';

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

class AbstractContextTest extends Object with ResourceProviderMixin {
  DartSdk sdk;
  Map<String, List<Folder>> packageMap;
  UriResolver resourceResolver;

  StringBuffer _logBuffer = new StringBuffer();
  FileContentOverlay fileContentOverlay = new FileContentOverlay();
  AnalysisDriver _driver;

  AnalysisDriver get driver => _driver;

  bool get previewDart2 => driver.analysisOptions.previewDart2;

  void addFlutterPackage() {
    addMetaPackageSource();
    Folder libFolder = configureFlutterPackage(resourceProvider);
    packageMap['flutter'] = [libFolder];
  }

  Source addMetaPackageSource() => addPackageSource('meta', 'meta.dart', r'''
library meta;

const _IsTest isTest = const _IsTest();

const _IsTestGroup isTestGroup = const _IsTestGroup();

const Required required = const Required();

class Required {
  final String reason;
  const Required([this.reason]);
}

class _IsTest {
  const _IsTest();
}

class _IsTestGroup {
  const _IsTestGroup();
}
''');

  Source addPackageSource(String packageName, String filePath, String content) {
    packageMap[packageName] = [newFolder('/pubcache/$packageName/lib')];
    File file =
        newFile('/pubcache/$packageName/lib/$filePath', content: content);
    return file.createSource();
  }

  Source addSource(String path, String content, [Uri uri]) {
    File file = newFile(path, content: content);
    Source source = file.createSource(uri);
    driver.addFile(file.path);
    driver.changeFile(file.path);
    fileContentOverlay[file.path] = content;
    return source;
  }

  void configurePreviewDart2() {
    driver.configure(
        analysisOptions: new AnalysisOptionsImpl.from(driver.analysisOptions)
          ..previewDart2 = true);
  }

  void processRequiredPlugins() {
    AnalysisEngine.instance.processRequiredPlugins();
  }

  Future<CompilationUnit> resolveLibraryUnit(Source source) async {
    return (await driver.getResult(source.fullName))?.unit;
  }

  void setUp() {
    processRequiredPlugins();
    setupResourceProvider();
    sdk = new MockSdk(resourceProvider: resourceProvider);
    resourceResolver = new ResourceUriResolver(resourceProvider);
    packageMap = new Map<String, List<Folder>>();
    PackageMapUriResolver packageResolver =
        new PackageMapUriResolver(resourceProvider, packageMap);
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), packageResolver, resourceResolver]);
    PerformanceLog log = new PerformanceLog(_logBuffer);
    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);
    _driver = new AnalysisDriver(
        scheduler,
        log,
        resourceProvider,
        new MemoryByteStore(),
        fileContentOverlay,
        new ContextRoot(resourceProvider.convertPath('/project'), []),
        sourceFactory,
        new AnalysisOptionsImpl()..strongMode = true);
    scheduler.start();
    AnalysisEngine.instance.logger = PrintLogger.instance;
  }

  void setupResourceProvider() {}

  void tearDown() {
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

/**
 * Wraps the given [_ElementVisitorFunction] into an instance of
 * [engine.GeneralizingElementVisitor].
 */
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;
  _ElementVisitorFunctionWrapper(this.function);
  visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}
