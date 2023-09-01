// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoSelfAssignmentsTest);
  });
}

@reflectiveTest
class NoSelfAssignmentsTest extends LintRuleTest {
  @override
  String get lintRule => 'no_self_assignments';

  test_classMemberAssignment() async {
    await assertDiagnostics(r'''
class C {
  static String foo = "foo";
}

void main() {
  C.foo = C.foo;
}
''', [lint(58, 13)]);
  }

  test_classMemberAssignmentUnrelated() async {
    await assertNoDiagnostics(r'''
class C {
  static String foo = "foo";
}

void main() {
  String foo;
  foo = C.foo; // OK
  print(foo);
}
''');
  }

  test_fieldAssignment() async {
    await assertDiagnostics(r'''
class C {
  int x = 5;

  C(int x) {
    x = x;
  }
}
''', [lint(41, 5)]);
  }

  test_fieldAssignmentDifferentTargets() async {
    await assertNoDiagnostics(r'''
class C {
  String hello = 'ok';
}

void test(C one, C two) {
  one.hello = two.hello;
}
''');
  }

  test_fieldAssignmentDifferentVar() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 5;

  C(int y) {
    x = y;
  }
}
''');
  }

  test_fieldAssignmentExplicit() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 5;

  C(int x) {
    this.x = x;
  }
}
''');
  }

  test_fieldAssignmentExplicitSameVar() async {
    await assertDiagnostics(r'''
class C {
  int x = 5;

  void update(C other) {
    other.x = other.x;
  }
}
''', [lint(53, 17)]);
  }

  test_fieldAssignmentThisAndDifferentTarget() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 5;

  void update(C other) {
    this.x = other.x;
  }
}
''');
  }

  test_fieldInitialization() async {
    await assertNoDiagnostics(r'''
class C {
  int x;

  C(int x) : x = x;
}
''');
  }

  test_propertyAssignment() async {
    await assertDiagnostics(r'''
class C {
  int _x = 5;

  int get x => _x;

  set x(int x) {
    _x = x;
  }

  void example() {
    x = x;
  }
}
''', [lint(102, 5)]);
  }
}
