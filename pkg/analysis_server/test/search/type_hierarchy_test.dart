// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_type_hierarhy;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
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
      return _getTypeHierarchy('main() {').then((jsons) {
        expect(jsons, isEmpty);
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
      return _getTypeHierarchy('B extends A').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('B extends').then((jsons) {
        var jsonB = jsons[0];
        var jsonA = jsons[jsonB[SUPERCLASS]];
        expect(jsonA[CLASS_ELEMENT][NAME], 'A');
        expect(jsonB[CLASS_ELEMENT][NAME], 'B');
        expect(jsonA[DISPLAY_NAME], 'A<int>');
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
      return _getTypeHierarchy('A {}').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('B extends').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('C extends').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('T implements').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('T extends Object').then((jsons) {
        expect(jsons, [{
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
      return _getTypeHierarchy('test => null; // in B').then((jsons) {
        Map jsonB = jsons[0];
        Map jsonA = jsons[jsonB[SUPERCLASS]];
        Map jsonC = jsons[jsonB[SUBCLASSES][0]];
        Map jsonD = jsons[jsonC[SUBCLASSES][0]];
        expect(jsonA[CLASS_ELEMENT][NAME], 'A');
        expect(jsonB[CLASS_ELEMENT][NAME], 'B');
        expect(jsonC[CLASS_ELEMENT][NAME], 'C');
        expect(jsonD[CLASS_ELEMENT][NAME], 'D');
        expect(
            jsonA[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test => null; // in A'));
        expect(
            jsonB[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test => null; // in B'));
        expect(jsonC['memberElement'], isNull);
        expect(
            jsonD[MEMBER_ELEMENT][LOCATION][OFFSET],
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
      return _getTypeHierarchy('test() {} // in B').then((jsons) {
        var jsonB = jsons[0];
        var jsonA = jsons[jsonB[SUPERCLASS]];
        var jsonC = jsons[jsonB[SUBCLASSES][0]];
        var jsonD = jsons[jsonC[SUBCLASSES][0]];
        expect(jsonA[CLASS_ELEMENT][NAME], 'A');
        expect(jsonB[CLASS_ELEMENT][NAME], 'B');
        expect(jsonC[CLASS_ELEMENT][NAME], 'C');
        expect(jsonD[CLASS_ELEMENT][NAME], 'D');
        expect(
            jsonA[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test() {} // in A'));
        expect(
            jsonB[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test() {} // in B'));
        expect(jsonC['memberElement'], isNull);
        expect(
            jsonD[MEMBER_ELEMENT][LOCATION][OFFSET],
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
      return _getTypeHierarchy('==(x) => null; // in B').then((jsons) {
        var jsonB = jsons[0];
        var jsonA = jsons[jsonB[SUPERCLASS]];
        var jsonC = jsons[jsonB[SUBCLASSES][0]];
        var jsonD = jsons[jsonC[SUBCLASSES][0]];
        expect(jsonA[CLASS_ELEMENT][NAME], 'A');
        expect(jsonB[CLASS_ELEMENT][NAME], 'B');
        expect(jsonC[CLASS_ELEMENT][NAME], 'C');
        expect(jsonD[CLASS_ELEMENT][NAME], 'D');
        expect(
            jsonA[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('==(x) => null; // in A'));
        expect(
            jsonB[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('==(x) => null; // in B'));
        expect(jsonC['memberElement'], isNull);
        expect(
            jsonD[MEMBER_ELEMENT][LOCATION][OFFSET],
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
      return _getTypeHierarchy('test(x) {} // in B').then((jsons) {
        var jsonB = jsons[0];
        var jsonA = jsons[jsonB[SUPERCLASS]];
        var jsonC = jsons[jsonB[SUBCLASSES][0]];
        var jsonD = jsons[jsonC[SUBCLASSES][0]];
        expect(jsonA[CLASS_ELEMENT][NAME], 'A');
        expect(jsonB[CLASS_ELEMENT][NAME], 'B');
        expect(jsonC[CLASS_ELEMENT][NAME], 'C');
        expect(jsonD[CLASS_ELEMENT][NAME], 'D');
        expect(
            jsonA[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test(x) {} // in A'));
        expect(
            jsonB[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test(x) {} // in B'));
        expect(jsonC['memberElement'], isNull);
        expect(
            jsonD[MEMBER_ELEMENT][LOCATION][OFFSET],
            findOffset('test(x) {} // in D'));
      });
    });
  }

  Request _createGetTypeHierarchyRequest(String search) {
    int offset = findOffset(search);
    Request request = new Request(requestId, SEARCH_GET_TYPE_HIERARCHY);
    request.setParameter(FILE, testFile);
    request.setParameter(OFFSET, offset);
    return request;
  }

  Future<List<Map<String, Object>>> _getTypeHierarchy(String search) {
    Request request = _createGetTypeHierarchyRequest(search);
    return serverChannel.sendRequest(request).then((Response response) {
      return response.getResult(HIERARCHY_ITEMS) as List<Map<String, Object>>;
    });
  }
}
