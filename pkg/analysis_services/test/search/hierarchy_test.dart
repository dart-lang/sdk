// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.src.search.hierarchy;

import 'dart:async';

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/search/hierarchy.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(HierarchyTest);
}


@ReflectiveTestCase()
class HierarchyTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }

  void test_getClassMembers() {
    _indexTestUnit('''
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

  Future test_getHierarchyMembers_constructors() {
    _indexTestUnit('''
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

  Future test_getHierarchyMembers_fields() {
    _indexTestUnit('''
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
    ClassElement classE = findElement("E");
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

  Future test_getHierarchyMembers_methods() {
    _indexTestUnit('''
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

  Future test_getHierarchyMembers_withInterfaces() {
    _indexTestUnit('''
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
    ClassElement classC = findElement("C");
    ClassElement classD = findElement("D");
    ClassElement classE = findElement("E");
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

  void test_getMembers() {
    _indexTestUnit('''
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
      expect(members.map((e) => e.name), unorderedEquals(['ma1', 'ma2']));
    }
    {
      ClassElement classB = findElement('B');
      List<Element> members = getMembers(classB);
      expect(
          members.map((e) => e.name),
          unorderedEquals(['mb1', 'mb2', 'ma1', 'ma2']));
    }
  }

  Future test_getSubClasses() {
    _indexTestUnit('''
class A {}
class B extends A {}
class C extends B {}
class D extends B implements A {}
class M {}
class E extends A with M {}
''');
    ClassElement classA = findElement("A");
    ClassElement classB = findElement("B");
    ClassElement classC = findElement("C");
    ClassElement classD = findElement("D");
    ClassElement classM = findElement("M");
    ClassElement classE = findElement("E");
    var futureA = getSubClasses(searchEngine, classA).then((subs) {
      expect(subs, unorderedEquals([classB, classC, classD, classE]));
    });
    var futureB = getSubClasses(searchEngine, classB).then((subs) {
      expect(subs, unorderedEquals([classC, classD]));
    });
    var futureC = getSubClasses(searchEngine, classC).then((subs) {
      expect(subs, isEmpty);
    });
    var futureM = getSubClasses(searchEngine, classM).then((subs) {
      expect(subs, unorderedEquals([classE]));
    });
    return Future.wait([futureA, futureB, futureC, futureM]);
  }

  void test_getSuperClasses() {
    _indexTestUnit('''
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

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }
}
