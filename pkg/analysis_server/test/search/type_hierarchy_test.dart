// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_type_hierarhy;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(GetTypeHierarchyTest);
}


@reflectiveTest
class GetTypeHierarchyTest extends AbstractAnalysisTest {
  static const String requestId = 'test-getTypeHierarchy';

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  @override
  void setUp() {
    super.setUp();
    server.handlers = [new SearchDomainHandler(server),];
    createProject();
  }

  test_bad_function() async {
    addTestFile('''
main() {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('main() {');
    expect(items, isNull);
  }

  test_bad_noElement() async {
    addTestFile('''
main() {
  /* target */
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('/* target */');
    expect(items, isNull);
  }

  test_bad_recursion() async {
    addTestFile('''
class A extends B {
}
class B extends A {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('B extends A');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'B',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'A',
          'location': anything,
          'flags': 0
        },
        'superclass': 0,
        'interfaces': [],
        'mixins': [],
        'subclasses': [1]
      }]);
  }

  test_class_displayName() async {
    addTestFile('''
class A<T> {
}
class B extends A<int> {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('B extends');
    var itemB = items[0];
    var itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.displayName, 'A<int>');
  }

  test_class_extends_fileAndPackageUris() async {
    // prepare packages
    String pkgFile = '/packages/pkgA/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
class B extends A {}
''');
    packageMapProvider.packageMap['pkgA'] =
        [resourceProvider.getResource('/packages/pkgA')];
    // reference the package from a project
    addTestFile('''
import 'package:pkgA/libA.dart';
class C extends A {}
''');
    // configure roots
    Request request = new AnalysisSetAnalysisRootsParams(
        [projectPath, '/packages/pkgA'],
        []).toRequest('0');
    handleSuccessfulRequest(request);
    // test A type hierarchy
    List<TypeHierarchyItem> items = await _getTypeHierarchy('A {}');
    Set<String> names = _toClassNames(items);
    expect(names, contains('A'));
    expect(names, contains('B'));
    expect(names, contains('C'));
  }

  test_class_extendsTypeA() async {
    addTestFile('''
class A {}
class B extends A {
}
class C extends B {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('A {}');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'A',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': [2]
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'B',
          'location': anything,
          'flags': 0
        },
        'superclass': 0,
        'interfaces': [],
        'mixins': [],
        'subclasses': [3]
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'C',
          'location': anything,
          'flags': 0
        },
        'superclass': 2,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }]);
  }

  test_class_extendsTypeB() async {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('B extends');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'B',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': [3]
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'A',
          'location': anything,
          'flags': 0
        },
        'superclass': 2,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'C',
          'location': anything,
          'flags': 0
        },
        'superclass': 0,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }]);
  }

  test_class_extendsTypeC() async {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('C extends');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'C',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'B',
          'location': anything,
          'flags': 0
        },
        'superclass': 2,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'A',
          'location': anything,
          'flags': 0
        },
        'superclass': 3,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }]);
  }

  test_class_implementsTypes() async {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T implements MA, MB {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('T implements');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'T',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [2, 3],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'MA',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'MB',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }]);
  }

  test_class_withTypes() async {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T extends Object with MA, MB {
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('T extends Object');
    expect(_toJson(items), [{
        'classElement': {
          'kind': 'CLASS',
          'name': 'T',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [2, 3],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'MA',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }, {
        'classElement': {
          'kind': 'CLASS',
          'name': 'MB',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }]);
  }

  test_member_getter() async {
    addTestFile('''
class A {
  get test => null; // in A
}
class B extends A {
  get test => null; // in B
}
class C extends B {
}
class D extends C {
  get test => null; // in D
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('test => null; // in B');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    TypeHierarchyItem itemC = items[itemB.subclasses[0]];
    TypeHierarchyItem itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(
        itemA.memberElement.location.offset,
        findOffset('test => null; // in A'));
    expect(
        itemB.memberElement.location.offset,
        findOffset('test => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset,
        findOffset('test => null; // in D'));
  }

  test_member_method() async {
    addTestFile('''
class A {
  test() {} // in A
}
class B extends A {
  test() {} // in B
}
class C extends B {
}
class D extends C {
  test() {} // in D
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('test() {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(
        itemA.memberElement.location.offset,
        findOffset('test() {} // in A'));
    expect(
        itemB.memberElement.location.offset,
        findOffset('test() {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset,
        findOffset('test() {} // in D'));
  }

  test_member_operator() async {
    addTestFile('''
class A {
  operator ==(x) => null; // in A
}
class B extends A {
  operator ==(x) => null; // in B
}
class C extends B {
}
class D extends C {
  operator ==(x) => null; // in D
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('==(x) => null; // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(
        itemA.memberElement.location.offset,
        findOffset('==(x) => null; // in A'));
    expect(
        itemB.memberElement.location.offset,
        findOffset('==(x) => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset,
        findOffset('==(x) => null; // in D'));
  }

  test_member_setter() async {
    addTestFile('''
class A {
  set test(x) {} // in A
}
class B extends A {
  set test(x) {} // in B
}
class C extends B {
}
class D extends C {
  set test(x) {} // in D
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('test(x) {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(
        itemA.memberElement.location.offset,
        findOffset('test(x) {} // in A'));
    expect(
        itemB.memberElement.location.offset,
        findOffset('test(x) {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset,
        findOffset('test(x) {} // in D'));
  }

  Request _createGetTypeHierarchyRequest(String search) {
    return new SearchGetTypeHierarchyParams(
        testFile,
        findOffset(search)).toRequest(requestId);
  }

  Future<List<TypeHierarchyItem>> _getTypeHierarchy(String search) async {
    await waitForTasksFinished();
    Request request = _createGetTypeHierarchyRequest(search);
    Response response = await serverChannel.sendRequest(request);
    expect(serverErrors, isEmpty);
    return new SearchGetTypeHierarchyResult.fromResponse(
        response).hierarchyItems;
  }

  List _toJson(List<TypeHierarchyItem> items) {
    return items.map((item) => item.toJson()).toList();
  }

  static Set<String> _toClassNames(List<TypeHierarchyItem> items) {
    return items.map((TypeHierarchyItem item) {
      return item.classElement.name;
    }).toSet();
  }
}
