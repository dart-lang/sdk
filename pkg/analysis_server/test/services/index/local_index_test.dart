// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.local_index;

import 'package:analysis_server/src/services/index/index_contributor.dart';
import 'package:analysis_server/src/services/index/local_index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';
import '../../utils.dart';
import 'store/single_source_container.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(LocalIndexTest);
}

void _assertElementNames(List<Element> elements, List expected) {
  expect(_toElementNames(elements), unorderedEquals(expected));
}

Iterable<String> _toElementNames(List<Element> elements) {
  return elements.map((element) => element.name);
}

@reflectiveTest
class LocalIndexTest extends AbstractContextTest {
  LocalIndex index;

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    index.contributors = [new DartIndexContributor()];
  }

  void tearDown() {
    super.tearDown();
    index = null;
  }

  void test_clear() {
    _indexTest('main() {}');
    _assertElementNames(_getTopElements(), ['main']);
    // clear
    index.clear();
    expect(_getTopElements(), isEmpty);
  }

  void test_index() {
    _indexTest('main() {}');
    _assertElementNames(_getTopElements(), ['main']);
  }

  void test_index_nullObject() {
    index.index(context, null);
  }

  void test_index_nullUnitElement() {
    CompilationUnit unit = new CompilationUnit(null, null, [], [], null);
    index.index(context, unit);
  }

  void test_removeContext() {
    _indexTest('main() {}');
    // OK, there is an element
    _assertElementNames(_getTopElements(), ['main']);
    // remove context
    index.removeContext(context);
    expect(_getTopElements(), isEmpty);
  }

  void test_removeSource() {
    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
    _indexLibraryUnit('/testB.dart', 'fb() {}');
    // OK, there are 2 functions
    _assertElementNames(_getTopElements(), ['fa', 'fb']);
    // remove source
    index.removeSource(context, sourceA);
    _assertElementNames(_getTopElements(), ['fb']);
  }

  void test_removeSources() {
    Source sourceA = _indexLibraryUnit('/testA.dart', 'fa() {}');
    _indexLibraryUnit('/testB.dart', 'fb() {}');
    // OK, there are 2 functions
    _assertElementNames(_getTopElements(), ['fa', 'fb']);
    // remove source(s)
    index.removeSources(context, new SingleSourceContainer(sourceA));
    _assertElementNames(_getTopElements(), ['fb']);
  }

  void test_statistics() {
    expect(index.statistics, '[0 locations, 0 sources, 0 names]');
  }

  List<Element> _getTopElements() {
    return index.getTopLevelDeclarations((_) => true);
  }

  Source _indexLibraryUnit(String path, String content) {
    Source source = addSource(path, content);
    CompilationUnit dartUnit = resolveLibraryUnit(source);
    index.index(context, dartUnit);
    return source;
  }

  void _indexTest(String content) {
    _indexLibraryUnit('/test.dart', content);
  }
}
