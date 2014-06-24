// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index;

import 'dart:async';
import 'dart:io' show Directory;

import 'package:analysis_server/src/index/index.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/index.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../mocks.dart';
import '../reflective_tests.dart';
import 'store/single_source_container.dart';


main() {
  groupSep = ' | ';
  group('ServerIndex', () {
    runReflectiveTests(_LocalSplitIndexTest);
  });
}


void _assertElementNames(List<Location> locations, List expected) {
  expect(_toElementNames(locations), unorderedEquals(expected));
}


Iterable<String> _toElementNames(List<Location> locations) {
  return locations.map((loc) => loc.element.name);
}


@ReflectiveTestCase()
class _LocalSplitIndexTest {
  static final DartSdk SDK = new MockSdk();

  AnalysisContext context;
  LocalSplitIndex index;
  Directory indexDirectory;
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void setUp() {
    // prepare Index
    indexDirectory = Directory.systemTemp.createTempSync(
        'AnalysisServer_index');
    index = new LocalSplitIndex(indexDirectory);
    // prepare AnalysisContext
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory(<UriResolver>[new DartUriResolver(
        SDK), new ResourceUriResolver(provider)]);
  }

  void tearDown() {
    indexDirectory.delete(recursive: true);
    index = null;
    context = null;
    provider = null;
  }

  Future test_clear() {
    _indexTest('main() {}');
    return _getDefinedFunctions().then((locations) {
      _assertElementNames(locations, ['main']);
      // clear
      index.clear();
      return _getDefinedFunctions().then((locations) {
        expect(locations, isEmpty);
      });
    });
  }

  void test_getRelationships() {
    var callback = new _RecordingRelationshipCallback();
    Element element = UniverseElement.INSTANCE;
    index.getRelationships(element, IndexConstants.DEFINES_CLASS, callback);
    expect(callback.locations, isEmpty);
  }

  void test_indexHtmlUnit_nullUnit() {
    index.indexHtmlUnit(context, null);
  }

  void test_indexHtmlUnit_nullUnitElement() {
    HtmlUnit unit = new HtmlUnit(null, [], null);
    index.indexHtmlUnit(context, unit);
  }

  Future test_indexUnit() {
    _indexTest('main() {}');
    return _getDefinedFunctions().then((locations) {
      _assertElementNames(locations, ['main']);
    });
  }

  void test_indexUnit_nullUnit() {
    index.indexUnit(context, null);
  }

  void test_indexUnit_nullUnitElement() {
    CompilationUnit unit = new CompilationUnit(null, null, [], [], null);
    index.indexUnit(context, unit);
  }

  Future test_removeContext() {
    _indexTest('main() {}');
    return _getDefinedFunctions().then((locations) {
      // OK, there is a location
      _assertElementNames(locations, ['main']);
      // remove context
      index.removeContext(context);
      return _getDefinedFunctions().then((locations) {
        expect(locations, isEmpty);
      });
    });
  }

  Future test_removeSource() {
    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
    _indexLibraryUnit('/testB.dart', 'fb() {}');
    return _getDefinedFunctions().then((locations) {
      // OK, there are 2 functions
      _assertElementNames(locations, ['fa', 'fb']);
      // remove source
      index.removeSource(context, sourceA);
      return _getDefinedFunctions().then((locations) {
        _assertElementNames(locations, ['fb']);
      });
    });
  }

  Future test_removeSources() {
    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
    _indexLibraryUnit('/testB.dart', 'fb() {}');
    return _getDefinedFunctions().then((locations) {
      // OK, there are 2 functions
      _assertElementNames(locations, ['fa', 'fb']);
      // remove source(s)
      index.removeSources(context, new SingleSourceContainer(sourceA));
      return _getDefinedFunctions().then((locations) {
        _assertElementNames(locations, ['fb']);
      });
    });
  }

  void test_statistics() {
    expect(index.statistics, '[0 locations, 0 sources, 0 names]');
  }

  Source _addSource(String path, String content) {
    File file = provider.newFile(path, content);
    Source source = file.createSource(UriKind.FILE_URI);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    context.setContents(source, content);
    return source;
  }

  Future<List<Location>> _getDefinedFunctions() {
    return index.getRelationshipsAsync(UniverseElement.INSTANCE,
        IndexConstants.DEFINES_FUNCTION);
  }

  Source _indexLibraryUnit(String path, String content) {
    Source source = _addSource(path, content);
    CompilationUnit dartUnit = _resolveLibraryUnit(source);
    index.indexUnit(context, dartUnit);
    return source;
  }

  void _indexTest(String content) {
    _indexLibraryUnit('/test.dart', content);
  }

  CompilationUnit _resolveLibraryUnit(Source source) {
    return context.resolveCompilationUnit2(source, source);
  }
}


/**
 * A [RelationshipCallback] that remembers [Location]s.
 */
class _RecordingRelationshipCallback extends RelationshipCallback {
  List<Location> locations;

  @override
  void hasRelationships(Element element, Relationship relationship,
      List<Location> locations) {
    this.locations = locations;
  }
}
