// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetHierarchyMembersTest);
    defineReflectiveTests(HierarchyTest);
  });
}

@reflectiveTest
class GetHierarchyMembersTest extends AbstractSingleUnitTest {
  late SearchEngineImpl searchEngine;

  @override
  void setUp() {
    super.setUp();
    searchEngine = SearchEngineImpl([driverFor(testFile)]);
  }

  Future<void> test_constructors() async {
    await resolveTestCode('''
class A {
  A() {}
}
class B extends A {
  B() {}
}
''');
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var memberA = classA.constructors2[0];
    var memberB = classB.constructors2[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberB]));
    });
    await Future.wait([futureA, futureB]);
  }

  Future<void> test_fields() async {
    await resolveTestCode('''
class A {
  int? foo;
}
class B extends A {
  get foo => null;
}
class C extends B {
  set foo(x) {}
}
class D {
  int? foo;
}
''');
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var classC = findElement2.class_('C');
    var classD = findElement2.class_('D');
    var memberA = classA.fields2[0];
    var memberB = classB.fields2[0];
    var memberC = classC.fields2[0];
    var memberD = classD.fields2[0];
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
    await Future.wait([futureA, futureB, futureC, futureD]);
  }

  Future<void> test_fields_static() async {
    await resolveTestCode('''
class A {
  static int? foo;
}
class B extends A {
  static get foo => null;
}
class C extends B {
  static set foo(x) {}
}
''');
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var classC = findElement2.class_('C');
    var memberA = classA.fields2[0];
    var memberB = classB.fields2[0];
    var memberC = classC.fields2[0];
    {
      var members = await getHierarchyMembers(searchEngine, memberA);
      expect(members, unorderedEquals([memberA]));
    }
    {
      var members = await getHierarchyMembers(searchEngine, memberB);
      expect(members, unorderedEquals([memberB]));
    }
    {
      var members = await getHierarchyMembers(searchEngine, memberC);
      expect(members, unorderedEquals([memberC]));
    }
  }

  Future<void> test_linear_number_of_calls() async {
    const count = 150;
    const last = count - 1;
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < count; i++) {
      if (i == 0) {
        sb.writeln("class X0 { void foo() { print('hello'); } }");
      } else {
        sb.writeln(
          "class X$i extends X${i - 1} { void foo() { print('hello'); } }",
        );
      }
    }

    await resolveTestCode(sb.toString());
    var classLast = findElement2.class_('X$last');
    var member =
        classLast.methods2.where((element) => element.name3 == 'foo').single;
    OperationPerformanceImpl performance = OperationPerformanceImpl('<root>');
    var result = await performance.runAsync(
      'getHierarchyMembers',
      (performance) =>
          getHierarchyMembers(searchEngine, member, performance: performance),
    );
    expect(result, hasLength(count));

    var worklist = <OperationPerformance>[];
    worklist.add(performance);
    while (worklist.isNotEmpty) {
      var performance = worklist.removeLast();
      expect(
        performance.count,
        lessThanOrEqualTo(count + 1),
        reason: performance.toString(),
      );
      worklist.addAll(performance.children);
    }
  }

  Future<void> test_methods() async {
    await resolveTestCode('''
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
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var classC = findElement2.class_('C');
    var classD = findElement2.class_('D');
    var classE = findElement2.class_('E');
    var memberA = classA.methods2[0];
    var memberB = classB.methods2[0];
    var memberC = classC.methods2[0];
    var memberD = classD.methods2[0];
    var memberE = classE.methods2[0];
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
    await Future.wait([futureA, futureB, futureC, futureD, futureE]);
  }

  Future<void> test_methods_private_superOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _test() {}
}
''');

    newFile('$testPackageLibPath/c.dart', r'''
import 'test.dart';

class E extends B {
  void _test() {}
}
''');

    await resolveTestCode('''
import 'a.dart';

class B extends A {
  void _test() {}
}

class C extends A {
  void _test() {}
}

class D extends B {
  void _test() {}
}
''');

    var methodB = findElement2.method('_test', of: 'B');
    var methodD = findElement2.method('_test', of: 'D');

    var members = await getHierarchyMembers(searchEngine, methodB);
    expect(members, unorderedEquals([methodB, methodD]));
  }

  Future<void> test_methods_private_superSameLibrary() async {
    newFile('$testPackageLibPath/c.dart', r'''
import 'test.dart';

class E extends B {
  void _test() {}
}
''');

    await resolveTestCode('''
class A {
  void _test() {}
}

class B extends A {
  void _test() {}
}

class C extends A {
  void _test() {}
}

class D extends B {
  void _test() {}
}
''');

    var methodA = findElement2.method('_test', of: 'A');
    var methodB = findElement2.method('_test', of: 'B');
    var methodC = findElement2.method('_test', of: 'C');
    var methodD = findElement2.method('_test', of: 'D');

    var members = await getHierarchyMembers(searchEngine, methodB);
    expect(members, unorderedEquals([methodA, methodB, methodC, methodD]));
  }

  Future<void> test_methods_static() async {
    await resolveTestCode('''
class A {
  static foo() {}
}
class B extends A {
  static foo() {}
}
''');
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var memberA = classA.methods2[0];
    var memberB = classB.methods2[0];
    {
      var members = await getHierarchyMembers(searchEngine, memberA);
      expect(members, unorderedEquals([memberA]));
    }
    {
      var members = await getHierarchyMembers(searchEngine, memberB);
      expect(members, unorderedEquals([memberB]));
    }
  }

  Future<void> test_withInterfaces() async {
    await resolveTestCode('''
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
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var classD = findElement2.class_('D');
    var memberA = classA.methods2[0];
    var memberB = classB.methods2[0];
    var memberD = classD.methods2[0];
    var futureA = getHierarchyMembers(searchEngine, memberA).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    var futureB = getHierarchyMembers(searchEngine, memberB).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    var futureD = getHierarchyMembers(searchEngine, memberD).then((members) {
      expect(members, unorderedEquals([memberA, memberB, memberD]));
    });
    await Future.wait([futureA, futureB, futureD]);
  }
}

@reflectiveTest
class HierarchyTest extends AbstractSingleUnitTest {
  late SearchEngineImpl searchEngine;

  @override
  void setUp() {
    super.setUp();
    searchEngine = SearchEngineImpl([driverFor(testFile)]);
  }

  Future<void> test_getClassMembers() async {
    await resolveTestCode('''
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
      var classA = findElement2.class_('A');
      var members = getClassMembers(classA);
      expect(members.map((e) => e.name3), unorderedEquals(['ma1', 'ma2']));
    }
    {
      var classB = findElement2.class_('B');
      var members = getClassMembers(classB);
      expect(members.map((e) => e.name3), unorderedEquals(['mb1', 'mb2']));
    }
  }

  Future<void> test_getHierarchyNamedParameters() async {
    await resolveTestCode('''
class A {
  foo({p}) {}
}
class B extends A {
  foo({p}) {}
}
class C extends B {
  foo({p}) {}
}
class D {
  foo({p}) {}
}
class E extends D {
  foo({p}) {}
}
''');
    var classA = findElement2.class_('A');
    var classB = findElement2.class_('B');
    var classC = findElement2.class_('C');
    var classD = findElement2.class_('D');
    var classE = findElement2.class_('E');
    var parameterA = classA.methods2[0].formalParameters[0];
    var parameterB = classB.methods2[0].formalParameters[0];
    var parameterC = classC.methods2[0].formalParameters[0];
    var parameterD = classD.methods2[0].formalParameters[0];
    var parameterE = classE.methods2[0].formalParameters[0];

    {
      var result = await getHierarchyNamedParameters(searchEngine, parameterA);
      expect(result, unorderedEquals([parameterA, parameterB, parameterC]));
    }

    {
      var result = await getHierarchyNamedParameters(searchEngine, parameterB);
      expect(result, unorderedEquals([parameterA, parameterB, parameterC]));
    }

    {
      var result = await getHierarchyNamedParameters(searchEngine, parameterC);
      expect(result, unorderedEquals([parameterA, parameterB, parameterC]));
    }

    {
      var result = await getHierarchyNamedParameters(searchEngine, parameterD);
      expect(result, unorderedEquals([parameterD, parameterE]));
    }

    {
      var result = await getHierarchyNamedParameters(searchEngine, parameterE);
      expect(result, unorderedEquals([parameterD, parameterE]));
    }
  }

  Future<void> test_getHierarchyNamedParameters_invalid_missing() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  foo({p}) {}
}
class B extends A {
  foo() {}
}
''');
    var classA = findElement2.class_('A');
    var parameterA = classA.methods2[0].formalParameters[0];

    var result = await getHierarchyNamedParameters(searchEngine, parameterA);
    expect(result, unorderedEquals([parameterA]));
  }

  Future<void> test_getHierarchyNamedParameters_invalid_notNamed() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  foo({p}) {}
}
class B extends A {
  foo(p) {}
}
''');
    var classA = findElement2.class_('A');
    var parameterA = classA.methods2[0].formalParameters[0];

    var result = await getHierarchyNamedParameters(searchEngine, parameterA);
    expect(result, unorderedEquals([parameterA]));
  }

  Future<void> test_getMembers() async {
    await resolveTestCode('''
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
      var classA = findElement2.class_('A');
      var members = getMembers(classA);
      expect(
        members.map((e) => e.name3),
        unorderedEquals([
          'ma1',
          'ma2',
          '==',
          'toString',
          'hashCode',
          'noSuchMethod',
          'runtimeType',
          'hash',
          'hashAll',
          'hashAllUnordered',
        ]),
      );
    }
    {
      var classB = findElement2.class_('B');
      var members = getMembers(classB);
      expect(
        members.map((e) => e.name3),
        unorderedEquals([
          'mb1',
          'mb2',
          'ma1',
          'ma2',
          '==',
          'toString',
          'hashCode',
          'noSuchMethod',
          'runtimeType',
          'hash',
          'hashAll',
          'hashAllUnordered',
        ]),
      );
    }
  }
}
