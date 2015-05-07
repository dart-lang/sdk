// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.abstract_context_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisContextImpl, AnalysisTask;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:plugin/manager.dart';
import 'package:unittest/unittest.dart';

import 'mock_sdk.dart';

class AbstractContextTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  ExtensionManager extensionManager = new ExtensionManager();

  DartSdk sdk = new MockSdk();
  SourceFactory sourceFactory;
  AnalysisContextImpl context;

  TaskManager taskManager = new TaskManager();
  AnalysisDriver analysisDriver;

  Source addSource(String path, String contents) {
    Source source = newSource(path, contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    context.setContents(source, contents);
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

  void setUp() {
    // configure TaskManager
    {
      EnginePlugin plugin = AnalysisEngine.instance.enginePlugin;
      if (plugin.taskExtensionPoint == null) {
        extensionManager.processPlugins([plugin]);
      }
      taskManager.addTaskDescriptors(plugin.taskDescriptors);
    }
    // prepare AnalysisContext
    sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ]);
    context = createAnalysisContext();
    context.sourceFactory = sourceFactory;
    // prepare AnalysisDriver
    analysisDriver = new AnalysisDriver(taskManager, context);
  }

  void tearDown() {}
}
