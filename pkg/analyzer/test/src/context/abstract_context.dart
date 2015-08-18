// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.abstract_context_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisCache, AnalysisContextImpl, AnalysisTask;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import 'mock_sdk.dart';

class AbstractContextTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  DartSdk sdk = new MockSdk();
  SourceFactory sourceFactory;
  AnalysisContextImpl context;
  AnalysisCache analysisCache;
  AnalysisDriver analysisDriver;

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
  void computeResult(AnalysisTarget target, ResultDescriptor result) {
    oldOutputs = outputs;
    task = analysisDriver.computeResult(target, result);
    expect(task, isNotNull);
    expect(task.caughtException, isNull);
    outputs = task.outputs;
  }

  AnalysisContextImpl createAnalysisContext() {
    return new AnalysisContextImpl();
  }

  Source newSource(String path, [String content = '']) {
    File file = resourceProvider.newFile(path, content);
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
    sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ]);
    context = createAnalysisContext();
    if (options != null) {
      context.analysisOptions = options;
    }
    context.sourceFactory = sourceFactory;
    analysisCache = context.analysisCache;
    analysisDriver = context.driver;
  }

  void setUp() {
    prepareAnalysisContext();
  }

  void tearDown() {}
}
