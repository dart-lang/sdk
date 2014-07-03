// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.engine.src.index;

//import 'dart:async';
//import 'dart:io' show Directory;
//
//import 'package:analyzer/src/generated/ast.dart';
//import 'package:analyzer/src/generated/element.dart';
//import 'package:analyzer/src/generated/html.dart';
//import 'package:analyzer/src/generated/source_io.dart';
//import 'package:unittest/unittest.dart';
//
//import '../reflective_tests.dart';
//import 'store/memory_node_manager.dart';
//import 'store/single_source_container.dart';
//import 'package:analyzer/src/index/local_index.dart';
//import 'package:analyzer/index/index.dart';


main() {
//  groupSep = ' | ';
//  group('LocalIndex', () {
////    runReflectiveTests(LocalIndexTest);
//  });
}


//void _assertElementNames(List<Location> locations, List expected) {
//  expect(_toElementNames(locations), unorderedEquals(expected));
//}
//
//
//Iterable<String> _toElementNames(List<Location> locations) {
//  return locations.map((loc) => loc.element.name);
//}


/**
 * TODO(scheglov) Decide what what to do with AbstractContextTest, resource and
 * all other testing infrastructure existing in Server, but not in Engine.
 */
class LocalIndexTest {}
//@ReflectiveTestCase()
//class LocalIndexTest extends AbstractContextTest {
//  Directory indexDirectory;
//  LocalIndex index;
//
//  void setUp() {
//    super.setUp();
//    // prepare Index
//    indexDirectory = Directory.systemTemp.createTempSync(
//        'AnalysisServer_index');
//    index = new LocalIndex(new MemoryNodeManager());
//  }
//
//  void tearDown() {
//    super.tearDown();
//    indexDirectory.delete(recursive: true);
//    index = null;
//  }
//
//  Future test_clear() {
//    _indexTest('main() {}');
//    return _getDefinedFunctions().then((locations) {
//      _assertElementNames(locations, ['main']);
//      // clear
//      index.clear();
//      return _getDefinedFunctions().then((locations) {
//        expect(locations, isEmpty);
//      });
//    });
//  }
//
//  void test_indexHtmlUnit_nullUnit() {
//    index.indexHtmlUnit(context, null);
//  }
//
//  void test_indexHtmlUnit_nullUnitElement() {
//    HtmlUnit unit = new HtmlUnit(null, [], null);
//    index.indexHtmlUnit(context, unit);
//  }
//
//  Future test_indexUnit() {
//    _indexTest('main() {}');
//    return _getDefinedFunctions().then((locations) {
//      _assertElementNames(locations, ['main']);
//    });
//  }
//
//  void test_indexUnit_nullUnit() {
//    index.indexUnit(context, null);
//  }
//
//  void test_indexUnit_nullUnitElement() {
//    CompilationUnit unit = new CompilationUnit(null, null, [], [], null);
//    index.indexUnit(context, unit);
//  }
//
//  Future test_removeContext() {
//    _indexTest('main() {}');
//    return _getDefinedFunctions().then((locations) {
//      // OK, there is a location
//      _assertElementNames(locations, ['main']);
//      // remove context
//      index.removeContext(context);
//      return _getDefinedFunctions().then((locations) {
//        expect(locations, isEmpty);
//      });
//    });
//  }
//
//  Future test_removeSource() {
//    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
//    _indexLibraryUnit('/testB.dart', 'fb() {}');
//    return _getDefinedFunctions().then((locations) {
//      // OK, there are 2 functions
//      _assertElementNames(locations, ['fa', 'fb']);
//      // remove source
//      index.removeSource(context, sourceA);
//      return _getDefinedFunctions().then((locations) {
//        _assertElementNames(locations, ['fb']);
//      });
//    });
//  }
//
//  Future test_removeSources() {
//    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
//    _indexLibraryUnit('/testB.dart', 'fb() {}');
//    return _getDefinedFunctions().then((locations) {
//      // OK, there are 2 functions
//      _assertElementNames(locations, ['fa', 'fb']);
//      // remove source(s)
//      index.removeSources(context, new SingleSourceContainer(sourceA));
//      return _getDefinedFunctions().then((locations) {
//        _assertElementNames(locations, ['fb']);
//      });
//    });
//  }
//
//  void test_statistics() {
//    expect(index.statistics, '[0 locations, 0 sources, 0 names]');
//  }
//
//  Future<List<Location>> _getDefinedFunctions() {
//    return index.getRelationshipsAsync(UniverseElement.INSTANCE,
//        IndexConstants.DEFINES_FUNCTION);
//  }
//
//  Source _indexLibraryUnit(String path, String content) {
//    Source source = addSource(path, content);
//    CompilationUnit dartUnit = resolveLibraryUnit(source);
//    index.indexUnit(context, dartUnit);
//    return source;
//  }
//
//  void _indexTest(String content) {
//    _indexLibraryUnit('/test.dart', content);
//  }
//}
