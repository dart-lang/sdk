// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.abstract_context;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';

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
  static final DartSdk SDK = new MockSdk();
  static final UriResolver SDK_RESOLVER = new DartUriResolver(SDK);

  MemoryResourceProvider provider = new MemoryResourceProvider();
  Map<String, List<Folder>> packageMap;
  UriResolver resourceResolver;
  AnalysisContext context;

  Source addPackageSource(String packageName, String filePath, String content) {
    packageMap[packageName] = [(provider.newFolder('/pubcache/$packageName'))];
    File file = provider.newFile('/pubcache/$packageName/$filePath', content);
    return file.createSource();
  }

  Source addSource(String path, String content, [Uri uri]) {
    File file = provider.newFile(path, content);
    Source source = file.createSource(uri);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    context.setContents(source, content);
    return source;
  }

  /**
   * Performs all analysis tasks in [context].
   */
  void performAllAnalysisTasks() {
    while (true) {
      AnalysisResult result = context.performAnalysisTask();
      if (!result.hasMoreWork) {
        break;
      }
    }
  }

  CompilationUnit resolveDartUnit(Source unitSource, Source librarySource) {
    return context.resolveCompilationUnit2(unitSource, librarySource);
  }

  CompilationUnit resolveLibraryUnit(Source source) {
    return context.resolveCompilationUnit2(source, source);
  }

  void setUp() {
    resourceResolver = new ResourceUriResolver(provider);
    packageMap = new Map<String, List<Folder>>();
    PackageMapUriResolver packageResolver =
        new PackageMapUriResolver(provider, packageMap);
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory =
        new SourceFactory([SDK_RESOLVER, packageResolver, resourceResolver]);
  }

  void tearDown() {
    context = null;
    provider = null;
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
