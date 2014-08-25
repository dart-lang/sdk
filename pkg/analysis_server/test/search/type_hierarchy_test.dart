// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_type_hierarhy;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(GetTypeHierarchyTest);
}


@ReflectiveTestCase()
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

  test_bad_function() {
    addTestFile('''
main() {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('main() {').then((items) {
        expect(items, isEmpty);
      });
    });
  }

  test_bad_recursion() {
    addTestFile('''
class A extends B {
}
class B extends A {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('B extends A').then((items) {
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
      });
    });
  }

  test_class_displayName() {
    addTestFile('''
class A<T> {
}
class B extends A<int> {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('B extends').then((items) {
        var itemB = items[0];
        var itemA = items[itemB.superclass];
        expect(itemA.classElement.name, 'A');
        expect(itemB.classElement.name, 'B');
        expect(itemA.displayName, 'A<int>');
      });
    });
  }

  test_class_extendsTypeA() {
    addTestFile('''
class A {}
class B extends A {
}
class C extends B {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('A {}').then((items) {
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
      });
    });
  }

  test_class_extendsTypeB() {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('B extends').then((items) {
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
      });
    });
  }

  test_class_extendsTypeC() {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('C extends').then((items) {
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
      });
    });
  }

  test_class_implementsTypes() {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T implements MA, MB {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('T implements').then((items) {
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
      });
    });
  }

  test_class_withTypes() {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T extends Object with MA, MB {
}
''');
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('T extends Object').then((items) {
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
      });
    });
  }

  test_member_getter() {
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
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('test => null; // in B').then((items) {
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
      });
    });
  }

  test_member_method() {
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
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('test() {} // in B').then((items) {
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
      });
    });
  }

  test_member_operator() {
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
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('==(x) => null; // in B').then((items) {
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
      });
    });
  }

  test_member_setter() {
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
    return waitForTasksFinished().then((_) {
      return _getTypeHierarchy('test(x) {} // in B').then((items) {
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
      });
    });
  }

  Request _createGetTypeHierarchyRequest(String search) {
    return new SearchGetTypeHierarchyParams(
        testFile,
        findOffset(search)).toRequest(requestId);
  }

  Future<List<TypeHierarchyItem>> _getTypeHierarchy(String search) {
    Request request = _createGetTypeHierarchyRequest(search);
    return serverChannel.sendRequest(request).then((Response response) {
      return new SearchGetTypeHierarchyResult.fromResponse(
          response).hierarchyItems;
    });
  }

  List _toJson(List<TypeHierarchyItem> items) {
    return items.map((item) => item.toJson()).toList();
  }
}
