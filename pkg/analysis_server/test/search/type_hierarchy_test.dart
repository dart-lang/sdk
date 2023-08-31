// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetTypeHierarchyTest);
  });
}

@reflectiveTest
class GetTypeHierarchyTest extends PubPackageAnalysisServerTest {
  static const String requestId = 'test-getTypeHierarchy';

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_bad_function() async {
    addTestFile('''
void f() {
}
''');
    var items = await _getTypeHierarchyOrNull('f() {');
    expect(items, isNull);
  }

  Future<void> test_bad_noElement() async {
    addTestFile('''
void f() {
  /* target */
}
''');
    var items = await _getTypeHierarchyOrNull('/* target */');
    expect(items, isNull);
  }

  Future<void> test_bad_recursion() async {
    addTestFile('''
class A extends B {
}
class B extends A {
}
''');
    var items = await _getTypeHierarchy('B extends A');
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
        'subclasses': [1]
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
        'subclasses': []
      }
    ]);
  }

  Future<void> test_class_displayName() async {
    addTestFile('''
class A<T> {
}
class B extends A<int> {
}
''');
    var items = await _getTypeHierarchy('B extends');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemA.displayName, 'A<int>');
  }

  Future<void> test_class_double_subclass() async {
    addTestFile('''
class AAA {} // A

class BBB extends AAA {}

class CCC extends BBB implements AAA {}
''');
    var items = await _getTypeHierarchy('AAA {} // A');
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'AAA',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [],
        'subclasses': [2, 3]
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
          'name': 'BBB',
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
          'name': 'CCC',
          'location': anything,
          'flags': 0
        },
        'superclass': 0,
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      },
    ]);
  }

  Future<void> test_class_extends_fileAndPackageUris() async {
    // prepare packages
    newFile('$packagesRootPath/pkgA/lib/libA.dart', '''
library lib_a;
class A {}
class B extends A {}
''');
    newPackageConfigJsonFile(
      '$packagesRootPath/pkgA',
      (PackageConfigFileBuilder()
            ..add(name: 'pkgA', rootPath: '$packagesRootPath/pkgA'))
          .toContent(toUriStr: toUriStr),
    );
    // reference the package from a project
    newPackageConfigJsonFile(
      testPackageRootPath,
      (PackageConfigFileBuilder()
            ..add(name: 'pkgA', rootPath: '$packagesRootPath/pkgA'))
          .toContent(toUriStr: toUriStr),
    );
    addTestFile('''
import 'package:pkgA/libA.dart';
class C extends A {}
''');
    await waitForTasksFinished();
    // configure roots
    await setRoots(
      included: [workspaceRootPath, '$packagesRootPath/pkgA'],
      excluded: [],
    );
    // test A type hierarchy
    var items = await _getTypeHierarchy('A {}');
    var names = _toClassNames(items);
    expect(names, contains('A'));
    expect(names, contains('B'));
    expect(names, contains('C'));
  }

  Future<void> test_class_extendsTypeA() async {
    addTestFile('''
class A {}
class B extends A {
}
class C extends B {
}
''');
    var items = await _getTypeHierarchy('A {}');
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

  Future<void> test_class_extendsTypeB() async {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    var items = await _getTypeHierarchy('B extends');
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

  Future<void> test_class_extendsTypeC() async {
    addTestFile('''
class A {
}
class B extends A {
}
class C extends B {
}
''');
    var items = await _getTypeHierarchy('C extends');
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

  Future<void> test_class_fromField_toMixinGetter() async {
    addTestFile('''
abstract class A {
  var test = 1;
}
class Mixin {
  get test => 2;
}
class B extends A with Mixin {}
''');
    var items = await _getTypeHierarchy('test = 1;');
    var itemA = items.firstWhere((e) => e.classElement.name == 'A');
    var itemB = items.firstWhere((e) => e.classElement.name == 'B');
    var memberA = itemA.memberElement!;
    var memberB = itemB.memberElement!;
    expect(memberA.location!.offset, findOffset('test = 1;'));
    expect(memberB.location!.offset, findOffset('test => 2;'));
  }

  Future<void> test_class_fromField_toMixinSetter() async {
    addTestFile('''
abstract class A {
  var test = 1;
}
class Mixin {
  set test(m) {}
}
class B extends A with Mixin {}
''');
    var items = await _getTypeHierarchy('test = 1;');
    var itemA = items.firstWhere((e) => e.classElement.name == 'A');
    var itemB = items.firstWhere((e) => e.classElement.name == 'B');
    var memberA = itemA.memberElement!;
    var memberB = itemB.memberElement!;
    expect(memberA.location!.offset, findOffset('test = 1;'));
    expect(memberB.location!.offset, findOffset('test(m) {}'));
  }

  Future<void> test_class_implementsTypes() async {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T implements MA, MB {
}
''');
    var items = await _getTypeHierarchy('T implements');
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

  Future<void> test_class_member_fromField_toField() async {
    addTestFile('''
class A {
  var test = 1;
}
class B extends A {
  var test = 2;
}
''');

    void checkItems(List<TypeHierarchyItem> items) {
      var itemA = items.firstWhere((e) => e.classElement.name == 'A');
      var itemB = items.firstWhere((e) => e.classElement.name == 'B');
      var memberA = itemA.memberElement!;
      var memberB = itemB.memberElement!;
      expect(memberA.location!.offset, findOffset('test = 1;'));
      expect(memberB.location!.offset, findOffset('test = 2;'));
    }

    checkItems(await _getTypeHierarchy('test = 1;'));
    checkItems(await _getTypeHierarchy('test = 2;'));
  }

  Future<void> test_class_member_fromField_toGetter() async {
    addTestFile('''
class A {
  get test => 1;
}
class B extends A {
  var test = 2;
}
''');

    void checkItems(List<TypeHierarchyItem> items) {
      var itemA = items.firstWhere((e) => e.classElement.name == 'A');
      var itemB = items.firstWhere((e) => e.classElement.name == 'B');
      var memberA = itemA.memberElement!;
      var memberB = itemB.memberElement!;
      expect(memberA.location!.offset, findOffset('test => 1'));
      expect(memberB.location!.offset, findOffset('test = 2;'));
    }

    checkItems(await _getTypeHierarchy('test => 1;'));
    checkItems(await _getTypeHierarchy('test = 2;'));
  }

  Future<void> test_class_member_fromField_toSetter() async {
    addTestFile('''
class A {
  set test(a) {}
}
class B extends A {
  var test = 2;
}
''');

    void checkItems(List<TypeHierarchyItem> items) {
      var itemA = items.firstWhere((e) => e.classElement.name == 'A');
      var itemB = items.firstWhere((e) => e.classElement.name == 'B');
      var memberA = itemA.memberElement!;
      var memberB = itemB.memberElement!;
      expect(memberA.location!.offset, findOffset('test(a) {}'));
      expect(memberB.location!.offset, findOffset('test = 2;'));
    }

    checkItems(await _getTypeHierarchy('test(a) {}'));
    checkItems(await _getTypeHierarchy('test = 2;'));
  }

  Future<void> test_class_member_fromFinalField_toGetter() async {
    addTestFile('''
class A {
  get test => 1;
}
class B extends A {
  final test = 2;
}
''');

    void checkItems(List<TypeHierarchyItem> items) {
      var itemA = items.firstWhere((e) => e.classElement.name == 'A');
      var itemB = items.firstWhere((e) => e.classElement.name == 'B');
      var memberA = itemA.memberElement!;
      var memberB = itemB.memberElement!;
      expect(memberA.location!.offset, findOffset('test => 1'));
      expect(memberB.location!.offset, findOffset('test = 2;'));
    }

    checkItems(await _getTypeHierarchy('test => 1;'));
    checkItems(await _getTypeHierarchy('test = 2;'));
  }

  Future<void> test_class_member_fromFinalField_toSetter() async {
    addTestFile('''
class A {
  set test(x) {}
}
class B extends A {
  final test = 2;
}
''');
    var items = await _getTypeHierarchy('test = 2;');
    var itemA = items.firstWhere((e) => e.classElement.name == 'A');
    var itemB = items.firstWhere((e) => e.classElement.name == 'B');
    expect(itemA.memberElement, isNull);
    expect(itemB.memberElement!.location!.offset, findOffset('test = 2;'));
  }

  Future<void> test_class_member_getter() async {
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
    var items = await _getTypeHierarchy('test => null; // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(itemA.memberElement!.location!.offset,
        findOffset('test => null; // in A'));
    expect(itemB.memberElement!.location!.offset,
        findOffset('test => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(itemD.memberElement!.location!.offset,
        findOffset('test => null; // in D'));
  }

  Future<void> test_class_member_method() async {
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
    var items = await _getTypeHierarchy('test() {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(
        itemA.memberElement!.location!.offset, findOffset('test() {} // in A'));
    expect(
        itemB.memberElement!.location!.offset, findOffset('test() {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(
        itemD.memberElement!.location!.offset, findOffset('test() {} // in D'));
  }

  Future<void> test_class_member_method_private_differentLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
import 'test.dart';
class A {
  void _m() {}
}
class C extends B {
  void _m() {}
}
''');
    addTestFile('''
import 'lib.dart';
class B extends A {
  _m() {} // in B
}
class D extends C {
  _m() {} // in D
}
''');
    var items = await _getTypeHierarchy('_m() {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemB.classElement.name, 'B');
    expect(itemA.classElement.name, 'A');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(itemA.memberElement, isNull);
    expect(itemC.memberElement, isNull);
    expect(itemB.memberElement, isNotNull);
    expect(itemD.memberElement, isNotNull);
  }

  Future<void> test_class_member_method_private_sameLib() async {
    addTestFile('''
class A {
  _m() {} // in A
}
class B extends A {
  _m() {} // in B
}
class C extends B {
  _m() {} // in C
}
''');
    var items = await _getTypeHierarchy('_m() {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(
        itemA.memberElement!.location!.offset, findOffset('_m() {} // in A'));
    expect(
        itemB.memberElement!.location!.offset, findOffset('_m() {} // in B'));
    expect(
        itemC.memberElement!.location!.offset, findOffset('_m() {} // in C'));
  }

  Future<void> test_class_member_ofMixin2_method() async {
    addTestFile('''
class M1 {
  void test() {} // in M1
}
class M2 {
  void test() {} // in M2
}
class D1 extends Object with M1 {}
class D2 extends Object with M1, M2 {}
class D3 extends Object with M2, M1 {}
class D4 extends Object with M2, M1 {
  void test() {} // in D4
}
''');
    var items = await _getTypeHierarchy('test() {} // in M1');
    var itemM1 = items.firstWhere((e) => e.classElement.name == 'M1');
    var item1 = items.firstWhere((e) => e.classElement.name == 'D1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'D2');
    var item3 = items.firstWhere((e) => e.classElement.name == 'D3');
    var item4 = items.firstWhere((e) => e.classElement.name == 'D4');
    expect(itemM1, isNotNull);
    expect(item1, isNotNull);
    expect(item2, isNotNull);
    expect(item3, isNotNull);
    expect(item4, isNotNull);
    // D1 does not override
    {
      var member1 = item1.memberElement;
      expect(member1, isNull);
    }
    // D2 mixes-in M2 last, which overrides
    {
      var member2 = item2.memberElement!;
      expect(member2.location!.offset, findOffset('test() {} // in M2'));
    }
    // D3 mixes-in M1 last and does not override itself
    {
      var member3 = item3.memberElement;
      expect(member3, isNull);
    }
    // D4 mixes-in M1 last, but it also overrides
    {
      var member4 = item4.memberElement!;
      expect(member4.location!.offset, findOffset('test() {} // in D4'));
    }
  }

  Future<void> test_class_member_ofMixin_getter() async {
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
    var items = await _getTypeHierarchy('test; // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    var memberBase = itemBase.memberElement!;
    var member1 = item1.memberElement!;
    var member2 = item2.memberElement!;
    expect(memberBase.location!.offset, findOffset('test; // in Base'));
    expect(member1.location!.offset, findOffset('test => null; // in Mixin'));
    expect(
        member2.location!.offset, findOffset('test => null; // in Derived2'));
  }

  Future<void> test_class_member_ofMixin_method() async {
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
    var items = await _getTypeHierarchy('test(); // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    var memberBase = itemBase.memberElement!;
    var member1 = item1.memberElement!;
    var member2 = item2.memberElement!;
    expect(memberBase.location!.offset, findOffset('test(); // in Base'));
    expect(member1.location!.offset, findOffset('test() {} // in Mixin'));
    expect(member2.location!.offset, findOffset('test() {} // in Derived2'));
  }

  Future<void> test_class_member_ofMixin_setter() async {
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
    var items = await _getTypeHierarchy('test(x); // in Base');
    var itemBase = items.firstWhere((e) => e.classElement.name == 'Base');
    var item1 = items.firstWhere((e) => e.classElement.name == 'Derived1');
    var item2 = items.firstWhere((e) => e.classElement.name == 'Derived2');
    var memberBase = itemBase.memberElement!;
    var member1 = item1.memberElement!;
    var member2 = item2.memberElement!;
    expect(memberBase.location!.offset, findOffset('test(x); // in Base'));
    expect(member1.location!.offset, findOffset('test(x) {} // in Mixin'));
    expect(member2.location!.offset, findOffset('test(x) {} // in Derived2'));
  }

  Future<void> test_class_member_ofSuperclassConstraint_getter() async {
    addTestFile('''
class A {
  get test => 0; // in A
}

mixin M on A {
  get test => 0; // in M
}
''');
    var items = await _getTypeHierarchy('test => 0; // in A');

    var inA = items.firstWhere((e) => e.classElement.name == 'A');
    var inM = items.firstWhere((e) => e.classElement.name == 'M');

    _assertMember(inA, 'test => 0; // in A');
    _assertMember(inM, 'test => 0; // in M');
  }

  Future<void> test_class_member_ofSuperclassConstraint_method() async {
    addTestFile('''
class A {
  void test() {} // in A
}

mixin M on A {
  void test() {} // in M
}
''');
    var items = await _getTypeHierarchy('test() {} // in A');

    var inA = items.firstWhere((e) => e.classElement.name == 'A');
    var inM = items.firstWhere((e) => e.classElement.name == 'M');

    _assertMember(inA, 'test() {} // in A');
    _assertMember(inM, 'test() {} // in M');
  }

  Future<void> test_class_member_ofSuperclassConstraint_setter() async {
    addTestFile('''
class A {
  set test(x) {} // in A
}

mixin M on A {
  set test(x) {} // in M
}
''');
    var items = await _getTypeHierarchy('test(x) {} // in A');

    var inA = items.firstWhere((e) => e.classElement.name == 'A');
    var inM = items.firstWhere((e) => e.classElement.name == 'M');

    _assertMember(inA, 'test(x) {} // in A');
    _assertMember(inM, 'test(x) {} // in M');
  }

  Future<void> test_class_member_operator() async {
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
    var items = await _getTypeHierarchy('==(x) => null; // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(itemA.memberElement!.location!.offset,
        findOffset('==(x) => null; // in A'));
    expect(itemB.memberElement!.location!.offset,
        findOffset('==(x) => null; // in B'));
    expect(itemC.memberElement, isNull);
    expect(itemD.memberElement!.location!.offset,
        findOffset('==(x) => null; // in D'));
  }

  Future<void> test_class_member_setter() async {
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
    var items = await _getTypeHierarchy('test(x) {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemD = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemD.classElement.name, 'D');
    expect(itemA.memberElement!.location!.offset,
        findOffset('test(x) {} // in A'));
    expect(itemB.memberElement!.location!.offset,
        findOffset('test(x) {} // in B'));
    expect(itemC.memberElement, isNull);
    expect(itemD.memberElement!.location!.offset,
        findOffset('test(x) {} // in D'));
  }

  Future<void> test_class_superOnly() async {
    addTestFile('''
class A {}
class B {}
class C extends A implements B {}
class D extends C {}
''');
    var items = await _getTypeHierarchy('C extends', superOnly: true);
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'C',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [3],
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
          'name': 'B',
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

  Future<void> test_class_superOnly_fileDoesNotExist() async {
    var request = SearchGetTypeHierarchyParams(
            convertPath('/does/not/exist.dart'), 0,
            superOnly: true)
        .toRequest(requestId);
    var response = await serverChannel.simulateRequestFromClient(request);
    var items =
        SearchGetTypeHierarchyResult.fromResponse(response).hierarchyItems;
    expect(items, isNull);
  }

  Future<void> test_class_withTypes() async {
    addTestFile('''
class MA {}
class MB {}
class B extends A {
}
class T extends Object with MA, MB {
}
''');
    var items = await _getTypeHierarchy('T extends Object');
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

  Future<void> test_enum_displayName() async {
    addTestFile('''
mixin M<T> {}

enum E with M<int> {
  v;
}
''');
    var items = await _getTypeHierarchy('E with');

    var itemB = items[0];
    expect(itemB.classElement.name, 'E');

    var itemA = items[itemB.superclass!];
    expect(itemA.classElement.name, 'Enum');
    expect(itemA.displayName, isNull);

    expect(itemB.mixins, hasLength(1));
    var itemM = items[itemB.mixins[0]];
    expect(itemM.classElement.name, 'M');
    expect(itemM.displayName, 'M<int>');
  }

  Future<void> test_enum_implements() async {
    addTestFile('''
class A {}
class B {}
enum E implements A, B {
  v;
}
''');
    var items = await _getTypeHierarchy('E implements');
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'ENUM',
          'name': 'E',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [3, 4],
        'mixins': [],
        'subclasses': []
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Enum',
          'location': anything,
          'flags': 1
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
          'name': 'B',
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

  Future<void> test_enum_member_getter() async {
    addTestFile('''
class A {
  int get test => 0; // in A
}
class B extends A {
  int get test => 0; // in B
}
class C extends B {
}
enum E implements C {
  v;
  int get test => 0; // in D
}
''');
    var items = await _getTypeHierarchy('test => 0; // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemE = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemE.classElement.name, 'E');
    expect(
      itemA.memberElement!.location!.offset,
      findOffset('test => 0; // in A'),
    );
    expect(
      itemB.memberElement!.location!.offset,
      findOffset('test => 0; // in B'),
    );
    expect(itemC.memberElement, isNull);
    expect(
      itemE.memberElement!.location!.offset,
      findOffset('test => 0; // in D'),
    );
  }

  Future<void> test_enum_member_method() async {
    addTestFile('''
class A {
  void test() {} // in A
}
class B extends A {
  void test() {} // in B
}
class C extends B {
}
enum E implements C {
  v;
  void test() {} // in E
}
''');
    var items = await _getTypeHierarchy('test() {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemE = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemE.classElement.name, 'E');
    expect(
      itemA.memberElement!.location!.offset,
      findOffset('test() {} // in A'),
    );
    expect(
      itemB.memberElement!.location!.offset,
      findOffset('test() {} // in B'),
    );
    expect(itemC.memberElement, isNull);
    expect(
      itemE.memberElement!.location!.offset,
      findOffset('test() {} // in E'),
    );
  }

  Future<void> test_enum_member_setter() async {
    addTestFile('''
class A {
  set test(int x) {} // in A
}
class B extends A {
  set test(int x) {} // in B
}
class C extends B {
}
enum E implements C {
  v;
  set test(int x) {} // in E
}
''');
    var items = await _getTypeHierarchy('test(int x) {} // in B');
    var itemB = items[0];
    var itemA = items[itemB.superclass!];
    var itemC = items[itemB.subclasses[0]];
    var itemE = items[itemC.subclasses[0]];
    expect(itemA.classElement.name, 'A');
    expect(itemB.classElement.name, 'B');
    expect(itemC.classElement.name, 'C');
    expect(itemE.classElement.name, 'E');
    expect(
      itemA.memberElement!.location!.offset,
      findOffset('test(int x) {} // in A'),
    );
    expect(
      itemB.memberElement!.location!.offset,
      findOffset('test(int x) {} // in B'),
    );
    expect(itemC.memberElement, isNull);
    expect(
      itemE.memberElement!.location!.offset,
      findOffset('test(int x) {} // in E'),
    );
  }

  Future<void> test_enum_with() async {
    addTestFile('''
mixin M {}
enum E with M {
  v;
}
''');
    var items = await _getTypeHierarchy('E with');
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'ENUM',
          'name': 'E',
          'location': anything,
          'flags': 0
        },
        'superclass': 1,
        'interfaces': [],
        'mixins': [3],
        'subclasses': []
      },
      {
        'classElement': {
          'kind': 'CLASS',
          'name': 'Enum',
          'location': anything,
          'flags': 1
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
          'kind': 'MIXIN',
          'name': 'M',
          'location': anything,
          'flags': 1
        },
        'interfaces': [],
        'mixins': [],
        'subclasses': []
      }
    ]);
  }

  Future<void> test_extensionType_implements_class() async {
    addTestFile('''
class A {}
class B extends A {}
extension type E(B it) implements A {}
''');
    var items = await _getTypeHierarchy('E(B it)');
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'EXTENSION_TYPE',
          'name': 'E',
          'location': anything,
          'flags': 0
        },
        'interfaces': [1],
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
      }
    ]);
  }

  Future<void> test_extensionType_implements_class2() async {
    addTestFile('''
class A {}
extension type E(A it) implements A {}
''');
    var items = await _getTypeHierarchy('A {}');
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
          'kind': 'EXTENSION_TYPE',
          'name': 'E',
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

  Future<void> test_extensionType_implements_extensionType() async {
    addTestFile('''
class A {}
extension type E1(A it) {}
extension type E2(A it) implements E1 {}
''');
    var items = await _getTypeHierarchy('E2(A it)');
    expect(_toJson(items), [
      {
        'classElement': {
          'kind': 'EXTENSION_TYPE',
          'name': 'E2',
          'location': anything,
          'flags': 0
        },
        'interfaces': [1],
        'mixins': [],
        'subclasses': []
      },
      {
        'classElement': {
          'kind': 'EXTENSION_TYPE',
          'name': 'E1',
          'location': anything,
          'flags': 0
        },
        'interfaces': [2],
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

  Future<void> test_extensionType_member_method() async {
    addTestFile('''
class A {
  void test() {} // in A
}
extension type E(A it) implements A {
  void test() {} // in E
}
''');
    var items = await _getTypeHierarchy('test() {} // in E');
    var itemE = items[0];
    var itemA = items[itemE.interfaces.single];
    expect(itemA.classElement.name, 'A');
    expect(itemE.classElement.name, 'E');
    expect(itemA.memberElement, isNull);
    expect(itemE.memberElement, isNull);
  }

  Future<void> test_extensionType_member_method2() async {
    addTestFile('''
class A {
  void test() {} // in A
}
extension type E(A it) implements A {
  void test() {} // in E
}
''');
    var items = await _getTypeHierarchy('test() {} // in A');
    var itemA = items[0];
    var itemE = items[itemA.subclasses.single];
    expect(itemA.classElement.name, 'A');
    expect(itemE.classElement.name, 'E');
    expect(
        itemA.memberElement!.location!.offset, findOffset('test() {} // in A'));
    expect(itemE.memberElement, isNull);
  }

  void _assertMember(TypeHierarchyItem item, String search) {
    expect(item.memberElement!.location!.offset, findOffset(search));
  }

  Request _createGetTypeHierarchyRequest(String search, {bool? superOnly}) {
    return SearchGetTypeHierarchyParams(testFile.path, findOffset(search),
            superOnly: superOnly)
        .toRequest(requestId);
  }

  Future<List<TypeHierarchyItem>> _getTypeHierarchy(String search,
      {bool? superOnly}) async {
    return (await _getTypeHierarchyOrNull(search, superOnly: superOnly))!;
  }

  Future<List<TypeHierarchyItem>?> _getTypeHierarchyOrNull(String search,
      {bool? superOnly}) async {
    await waitForTasksFinished();
    var request = _createGetTypeHierarchyRequest(search, superOnly: superOnly);
    var response = await serverChannel.simulateRequestFromClient(request);
    return SearchGetTypeHierarchyResult.fromResponse(response).hierarchyItems;
  }

  List<Map<String, Object>> _toJson(List<TypeHierarchyItem> items) {
    return items.map((item) => item.toJson()).toList();
  }

  static Set<String> _toClassNames(List<TypeHierarchyItem> items) {
    return items.map((TypeHierarchyItem item) {
      return item.classElement.name;
    }).toSet();
  }
}
