// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_type_hierarhy;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(GetTypeHierarchyTest);
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
    expect(_toJson(items), [
      {
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
      },
      {
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
      }
    ]);
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
    resourceProvider.newFile(
        pkgFile,
        '''
library lib_a;
class A {}
class B extends A {}
''');
    packageMapProvider.packageMap['pkgA'] = [
      resourceProvider.getResource('/packages/pkgA')
    ];
    // reference the package from a project
    addTestFile('''
import 'package:pkgA/libA.dart';
class C extends A {}
''');
    // configure roots
    Request request = new AnalysisSetAnalysisRootsParams(
        [projectPath, '/packages/pkgA'], []).toRequest('0');
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
    expect(_toJson(items), [
      {
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
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      },
      {
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
      },
      {
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
      }
    ]);
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
    expect(_toJson(items), [
      {
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
      },
      {
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
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      },
      {
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
      }
    ]);
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
    expect(_toJson(items), [
      {
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
      },
      {
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
      },
      {
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
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }
    ]);
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
    expect(_toJson(items), [
      {
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
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      },
      {
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
      },
      {
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
      }
    ]);
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
    expect(_toJson(items), [
      {
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
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Object',
          'location': anything,
          'flags': 0
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      },
      {
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
      },
      {
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
      }
    ]);
  }

  test_fromField_toMixinGetter() async {
    addTestFile('''
abstract class A {
  var test = 1;
}
class Mixin {
  get test => 2;
}
class B extends A with Mixin {}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 1;');
    var itemA = items.firstWhere((e) => e.classElement.name == 'A');
    var itemB = items.firstWhere((e) => e.classElement.name == 'B');
    Element memberA = itemA.memberElement;
    Element memberB = itemB.memberElement;
    expect(memberA, isNotNull);
    expect(memberB, isNotNull);
    expect(memberA.location.offset, findOffset('test = 1;'));
    expect(memberB.location.offset, findOffset('test => 2;'));
  }

  test_fromField_toMixinSetter() async {
    addTestFile('''
abstract class A {
  var test = 1;
}
class Mixin {
  set test(m) {}
}
class B extends A with Mixin {}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 1;');
    var itemA = items.firstWhere((e) => e.classElement.name == 'A');
    var itemB = items.firstWhere((e) => e.classElement.name == 'B');
    Element memberA = itemA.memberElement;
    Element memberB = itemB.memberElement;
    expect(memberA, isNotNull);
    expect(memberB, isNotNull);
    expect(memberA.location.offset, findOffset('test = 1;'));
    expect(memberB.location.offset, findOffset('test(m) {}'));
  }

  test_member_fromField_toField() async {
    addTestFile('''
class A {
  var test = 1;
}
class B extends A {
  var test = 2;
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 2;');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.memberElement.location.offset, findOffset('test = 1;'));
    expect(itemB.memberElement.location.offset, findOffset('test = 2;'));
  }

  test_member_fromField_toGetter() async {
    addTestFile('''
class A {
  get test => 1;
}
class B extends A {
  var test = 2;
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 2;');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.memberElement.location.offset, findOffset('test => 1'));
    expect(itemB.memberElement.location.offset, findOffset('test = 2;'));
  }

  test_member_fromField_toSetter() async {
    addTestFile('''
class A {
  set test(a) {}
}
class B extends A {
  var test = 2;
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 2;');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.memberElement.location.offset, findOffset('test(a) {}'));
    expect(itemB.memberElement.location.offset, findOffset('test = 2;'));
  }

  test_member_fromFinalField_toGetter() async {
    addTestFile('''
class A {
  get test => 1;
}
class B extends A {
  final test = 2;
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 2;');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.memberElement.location.offset, findOffset('test => 1;'));
    expect(itemB.memberElement.location.offset, findOffset('test = 2;'));
  }

  test_member_fromFinalField_toSetter() async {
    addTestFile('''
class A {
  set test(x) {}
}
class B extends A {
  final test = 2;
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test = 2;');
    TypeHierarchyItem itemB = items[0];
    TypeHierarchyItem itemA = items[itemB.superclass];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.memberElement, isNull);
    expect(itemB.memberElement.location.offset, findOffset('test = 2;'));
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
    expect(itemA.memberElement.location.offset,
        findOffset('test => null; // in A'));
    expect(itemB.memberElement.location.offset,
        findOffset('test => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(itemD.memberElement.location.offset,
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
        itemA.memberElement.location.offset, findOffset('test() {} // in A'));
    expect(
        itemB.memberElement.location.offset, findOffset('test() {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset, findOffset('test() {} // in D'));
  }

  test_member_ofMixin_getter() async {
    addTestFile('''
abstract class Base {
  get test; // in Base
}
class Mixin {
  get test => null; // in Mixin
}
class Derived1 extends Base with Mixin {}
class Derived2 extends Base {
  get test => null; // in Derived2
}
''');
    List<TypeHierarchyItem> items = await _getTypeHierarchy('test; // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    Element memberBase = itemBase.memberElement;
    Element member1 = item1.memberElement;
    Element member2 = item2.memberElement;
    expect(memberBase, isNotNull);
    expect(member1, isNotNull);
    expect(member2, isNotNull);
    expect(memberBase.location.offset, findOffset('test; // in Base'));
    expect(member1.location.offset, findOffset('test => null; // in Mixin'));
    expect(member2.location.offset, findOffset('test => null; // in Derived2'));
  }

  test_member_ofMixin_method() async {
    addTestFile('''
abstract class Base {
  void test(); // in Base
}
class Mixin {
  void test() {} // in Mixin
}
class Derived1 extends Base with Mixin {}
class Derived2 extends Base {
  void test() {} // in Derived2
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('test(); // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    Element memberBase = itemBase.memberElement;
    Element member1 = item1.memberElement;
    Element member2 = item2.memberElement;
    expect(memberBase, isNotNull);
    expect(member1, isNotNull);
    expect(member2, isNotNull);
    expect(memberBase.location.offset, findOffset('test(); // in Base'));
    expect(member1.location.offset, findOffset('test() {} // in Mixin'));
    expect(member2.location.offset, findOffset('test() {} // in Derived2'));
  }

  test_member_ofMixin_setter() async {
    addTestFile('''
abstract class Base {
  set test(x); // in Base
}
class Mixin {
  set test(x) {} // in Mixin
}
class Derived1 extends Base with Mixin {}
class Derived2 extends Base {
  set test(x) {} // in Derived2
}
''');
    List<TypeHierarchyItem> items =
        await _getTypeHierarchy('test(x); // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    Element memberBase = itemBase.memberElement;
    Element member1 = item1.memberElement;
    Element member2 = item2.memberElement;
    expect(memberBase, isNotNull);
    expect(member1, isNotNull);
    expect(member2, isNotNull);
    expect(memberBase.location.offset, findOffset('test(x); // in Base'));
    expect(member1.location.offset, findOffset('test(x) {} // in Mixin'));
    expect(member2.location.offset, findOffset('test(x) {} // in Derived2'));
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
    expect(itemA.memberElement.location.offset,
        findOffset('==(x) => null; // in A'));
    expect(itemB.memberElement.location.offset,
        findOffset('==(x) => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(itemD.memberElement.location.offset,
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
        itemA.memberElement.location.offset, findOffset('test(x) {} // in A'));
    expect(
        itemB.memberElement.location.offset, findOffset('test(x) {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement.location.offset, findOffset('test(x) {} // in D'));
  }

  Request _createGetTypeHierarchyRequest(String search) {
    return new SearchGetTypeHierarchyParams(testFile, findOffset(search))
        .toRequest(requestId);
  }

  Future<List<TypeHierarchyItem>> _getTypeHierarchy(String search) async {
    await waitForTasksFinished();
    Request request = _createGetTypeHierarchyRequest(search);
    Response response = await serverChannel.sendRequest(request);
    expect(serverErrors, isEmpty);
    return new SearchGetTypeHierarchyResult.fromResponse(response)
        .hierarchyItems;
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
