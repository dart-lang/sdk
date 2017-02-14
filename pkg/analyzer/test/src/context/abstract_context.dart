// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.abstract_context;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/model.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';

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
 * A function to be called for every [Element].
 */
typedef void _ElementVisitorFunction(Element element);

class AbstractContextTest {
  static final MockSdk SHARED_MOCK_SDK = new MockSdk();
  static final MockSdk SHARED_STRONG_MOCK_SDK = new MockSdk();

  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  DartSdk sdk;
  SourceFactory sourceFactory;
  AnalysisContextImpl context;
  AnalysisCache analysisCache;
  AnalysisDriver analysisDriver;

  UriResolver sdkResolver;
  UriResolver resourceResolver;

  AnalysisTask task;
  Map<ResultDescriptor<dynamic>, dynamic> oldOutputs;
  Map<ResultDescriptor<dynamic>, dynamic> outputs;

  Source addSource(String path, String contents) {
    Source source = newSource(path, contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    return source;
  }

  /**
   * Assert that the given [elements] has the same number of items as the number
   * of specified [names], and that for each specified name, a corresponding
   * element can be found in the given collection with that name.
   */
  void assertNamedElements(List<Element> elements, List<String> names) {
    for (String elemName in names) {
      bool found = false;
      for (Element elem in elements) {
        if (elem.name == elemName) {
          found = true;
          break;
        }
      }
      if (!found) {
        StringBuffer buffer = new StringBuffer();
        buffer.write("Expected element named: ");
        buffer.write(elemName);
        buffer.write("\n  but found: ");
        for (Element elem in elements) {
          buffer.write(elem.name);
          buffer.write(", ");
        }
        fail(buffer.toString());
      }
    }
    expect(elements, hasLength(names.length));
  }

  /**
   * Compute the given [result] for the given [target].
   */
  void computeResult(AnalysisTarget target, ResultDescriptor result,
      {isInstanceOf matcher: null}) {
    oldOutputs = outputs;
    task = analysisDriver.computeResult(target, result);
    if (matcher == null) {
      expect(task, isNotNull);
    } else {
      expect(task, matcher);
    }
    expect(task.caughtException, isNull);
    outputs = task.outputs;
    for (ResultDescriptor descriptor in task.descriptor.results) {
      expect(outputs, contains(descriptor));
    }
  }

  AnalysisContextImpl createAnalysisContext() {
    return new AnalysisContextImpl();
  }

  DartSdk createDartSdk() => new MockSdk(resourceProvider: resourceProvider);

  Source newSource(String path, [String content = '']) {
    File file =
        resourceProvider.newFile(resourceProvider.convertPath(path), content);
    return file.createSource();
  }

  List<Source> newSources(Map<String, String> sourceMap) {
    List<Source> sources = <Source>[];
    sourceMap.forEach((String path, String content) {
      Source source = newSource(path, content);
      sources.add(source);
    });
    return sources;
  }

  void prepareAnalysisContext([AnalysisOptions options]) {
    sdk = createDartSdk();
    sdkResolver = new DartUriResolver(sdk);
    resourceResolver = new ResourceUriResolver(resourceProvider);
    sourceFactory = new SourceFactory(
        <UriResolver>[sdkResolver, resourceResolver], null, resourceProvider);
    context = createAnalysisContext();
    if (options != null) {
      context.analysisOptions = options;
    }
    context.sourceFactory = sourceFactory;
    analysisCache = context.analysisCache;
    analysisDriver = context.driver;
  }

  CompilationUnit resolveLibraryUnit(Source source) {
    return context.resolveCompilationUnit2(source, source);
  }

  void setUp() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);

    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);

    prepareAnalysisContext();
  }

  void tearDown() {}
}

/**
 * Wraps the given [_ElementVisitorFunction] into an instance of
 * [GeneralizingElementVisitor].
 */
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;

  _ElementVisitorFunctionWrapper(this.function);

  visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}
