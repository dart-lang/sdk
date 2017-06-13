// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine_internal2.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HierarchyTest);
  });
}

@reflectiveTest
class HierarchyTest extends AbstractSingleUnitTest {
  SearchEngineImpl2 searchEngine;

  void setUp() {
    super.setUp();
    searchEngine = new SearchEngineImpl2([driver]);
  }

  test_getClassMembers() async {
    await _indexTestUnit('''
class A {
  A() {}
  var ma1;
  ma2() {}
}
class B extends A {
  B() {}
  B.named() {}
  var mb1;
  mb2() {}
}
''');
    {
      ClassElement classA = findElement('A');
      List<Element> members = getClassMembers(classA);
      expect(members.map((e) => e.name), unorderedEquals(['ma1', 'ma2']));
    }
    {
      ClassElement classB = findElement('B');
      List<Element> members = getClassMembers(classB);
      expect(members.map((e) => e.name), unorderedEquals(['mb1', 'mb2']));
    }
  }

  test_getHierarchyMembers_constructors() async {
    await _indexTestUnit('''
class A {
  A() {}
}
class B extends A {
  B() {}
}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassMemberElement memberA = classA.constructors[0];
    ClassMemberElement memberB = classB.constructors[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberB]));
    });
    return Future.wait([futureA, futureB]);
  }

  test_getHierarchyMembers_fields() async {
    await _indexTestUnit('''
class A {
  int foo;
}
class B extends A {
  get foo => null;
}
class C extends B {
  set foo(x) {}
}
class D {
  int foo;
}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassElement classC = findElement("C");
    ClassElement classD = findElement("D");
    ClassMemberElement memberA = classA.fields[0];
    ClassMemberElement memberB = classB.fields[0];
    ClassMemberElement memberC = classC.fields[0];
    ClassMemberElement memberD = classD.fields[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureC = getHierarchyMembers(searchEngine, memberC).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureD = getHierarchyMembers(searchEngine, memberD).then((members) {
      expect(members, unorderedEquals([memberD]));
    });
    return Future.wait([futureA, futureB, futureC, futureD]);
  }

  test_getHierarchyMembers_fields_static() async {
    await _indexTestUnit('''
class A {
  static int foo;
}
class B extends A {
  static get foo => null;
}
class C extends B {
  static set foo(x) {}
}
''');
    ClassElement classA = findElement('A');
    ClassElement classB = findElement('B');
    ClassElement classC = findElement('C');
    ClassMemberElement memberA = classA.fields[0];
    ClassMemberElement memberB = classB.fields[0];
    ClassMemberElement memberC = classC.fields[0];
    {
      Set<ClassMemberElement> members =
          await getHierarchyMembers(searchEngine, memberA);
      expect(members, unorderedEquals([memberA]));
    }
    {
      Set<ClassMemberElement> members =
          await getHierarchyMembers(searchEngine, memberB);
      expect(members, unorderedEquals([memberB]));
    }
    {
      Set<ClassMemberElement> members =
          await getHierarchyMembers(searchEngine, memberC);
      expect(members, unorderedEquals([memberC]));
    }
  }

  test_getHierarchyMembers_methods() async {
    await _indexTestUnit('''
class A {
  foo() {}
}
class B extends A {
  foo() {}
}
class C extends B {
  foo() {}
}
class D {
  foo() {}
}
class E extends D {
  foo() {}
}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassElement classC = findElement("C");
    ClassElement classD = findElement("D");
    ClassElement classE = findElement("E");
    ClassMemberElement memberA = classA.methods[0];
    ClassMemberElement memberB = classB.methods[0];
    ClassMemberElement memberC = classC.methods[0];
    ClassMemberElement memberD = classD.methods[0];
    ClassMemberElement memberE = classE.methods[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureC = getHierarchyMembers(searchEngine, memberC).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberC]));
    });
    var futureD = getHierarchyMembers(searchEngine, memberD).then((members) {
      expect(members, unorderedEquals([memberD, memberE]));
    });
    var futureE = getHierarchyMembers(searchEngine, memberE).then((members) {
      expect(members, unorderedEquals([memberD, memberE]));
    });
    return Future.wait([futureA, futureB, futureC, futureD, futureE]);
  }

  test_getHierarchyMembers_methods_static() async {
    await _indexTestUnit('''
class A {
  static foo() {}
}
class B extends A {
  static foo() {}
}
''');
    ClassElement classA = findElement('A');
    ClassElement classB = findElement('B');
    ClassMemberElement memberA = classA.methods[0];
    ClassMemberElement memberB = classB.methods[0];
    {
      Set<ClassMemberElement> members =
          await getHierarchyMembers(searchEngine, memberA);
      expect(members, unorderedEquals([memberA]));
    }
    {
      Set<ClassMemberElement> members =
          await getHierarchyMembers(searchEngine, memberB);
      expect(members, unorderedEquals([memberB]));
    }
  }

  test_getHierarchyMembers_withInterfaces() async {
    await _indexTestUnit('''
class A {
  foo() {}
}
class B implements A {
  foo() {}
}
abstract class C implements A {
}
class D extends C {
  foo() {}
}
class E {
  foo() {}
}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassElement classD = findElement("D");
    ClassMemberElement memberA = classA.methods[0];
    ClassMemberElement memberB = classB.methods[0];
    ClassMemberElement memberD = classD.methods[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    var futureD = getHierarchyMembers(searchEngine, memberD).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    return Future.wait([futureA, futureB, futureD]);
  }

  test_getMembers() async {
    await _indexTestUnit('''
class A {
  A() {}
  var ma1;
  ma2() {}
}
class B extends A {
  B() {}
  B.named() {}
  var mb1;
  mb2() {}
}
''');
    {
      ClassElement classA = findElement('A');
      List<Element> members = getMembers(classA);
      expect(
          members.map((e) => e.name),
          unorderedEquals([
            'ma1',
            'ma2',
            '==',
            'toString',
            'hashCode',
            'noSuchMethod',
            'runtimeType'
          ]));
    }
    {
      ClassElement classB = findElement('B');
      List<Element> members = getMembers(classB);
      expect(
          members.map((e) => e.name),
          unorderedEquals([
            'mb1',
            'mb2',
            'ma1',
            'ma2',
            '==',
            'toString',
            'hashCode',
            'noSuchMethod',
            'runtimeType'
          ]));
    }
  }

  test_getSuperClasses() async {
    await _indexTestUnit('''
class A {}
class B extends A {}
class C extends B {}
class D extends B implements A {}
class M {}
class E extends A with M {}
class F implements A {}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassElement classC = findElement("C");
    ClassElement classD = findElement("D");
    ClassElement classE = findElement("E");
    ClassElement classF = findElement("F");
    ClassElement objectElement = classA.supertype.element;
    // Object
    {
      Set<ClassElement> supers = getSuperClasses(objectElement);
      expect(supers, isEmpty);
    }
    // A
    {
      Set<ClassElement> supers = getSuperClasses(classA);
      expect(supers, unorderedEquals([objectElement]));
    }
    // B
    {
      Set<ClassElement> supers = getSuperClasses(classB);
      expect(supers, unorderedEquals([objectElement, classA]));
    }
    // C
    {
      Set<ClassElement> supers = getSuperClasses(classC);
      expect(supers, unorderedEquals([objectElement, classA, classB]));
    }
    // D
    {
      Set<ClassElement> supers = getSuperClasses(classD);
      expect(supers, unorderedEquals([objectElement, classA, classB]));
    }
    // E
    {
      Set<ClassElement> supers = getSuperClasses(classE);
      expect(supers, unorderedEquals([objectElement, classA]));
    }
    // F
    {
      Set<ClassElement> supers = getSuperClasses(classF);
      expect(supers, unorderedEquals([objectElement, classA]));
    }
  }

  Future<Null> _indexTestUnit(String code) async {
    await resolveTestUnit(code);
  }
}
