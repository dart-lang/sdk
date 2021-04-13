// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeArgumentNameTest);
  });
}

@reflectiveTest
class ChangeArgumentNameTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_ARGUMENT_NAME;

  Future<void> test_child_constructor() async {
    await resolveTestCode('''
f() => new A(children: 2);
class A {
  A({int child});
}
''');
    await assertHasFix('''
f() => new A(child: 2);
class A {
  A({int child});
}
''');
  }

  Future<void> test_child_function() async {
    await resolveTestCode('''
f() {
  g(children: 0);
}
void g({int child}) {}
''');
    await assertHasFix('''
f() {
  g(child: 0);
}
void g({int child}) {}
''');
  }

  Future<void> test_child_method() async {
    await resolveTestCode('''
f(A a) {
  a.m(children: 0);
}
class A {
  void m({int child}) {}
}
''');
    await assertHasFix('''
f(A a) {
  a.m(child: 0);
}
class A {
  void m({int child}) {}
}
''');
  }

  Future<void> test_children_constructor() async {
    await resolveTestCode('''
f() => new A(child: 2);
class A {
  A({int children});
}
''');
    await assertHasFix('''
f() => new A(children: 2);
class A {
  A({int children});
}
''');
  }

  Future<void> test_children_function() async {
    await resolveTestCode('''
f() {
  g(child: 0);
}
void g({int children}) {}
''');
    await assertHasFix('''
f() {
  g(children: 0);
}
void g({int children}) {}
''');
  }

  Future<void> test_children_method() async {
    await resolveTestCode('''
f(A a) {
  a.m(child: 0);
}
class A {
  void m({int children}) {}
}
''');
    await assertHasFix('''
f(A a) {
  a.m(children: 0);
}
class A {
  void m({int children}) {}
}
''');
  }

  Future<void> test_default_annotation() async {
    await resolveTestCode('''
@A(boot: 2)
f() => null;
class A {
  const A({int boat});
}
''');
    await assertHasFix('''
@A(boat: 2)
f() => null;
class A {
  const A({int boat});
}
''');
  }

  Future<void> test_default_constructor() async {
    await resolveTestCode('''
f() => new A(boot: 2);
class A {
  A({int boat});
}
''');
    await assertHasFix('''
f() => new A(boat: 2);
class A {
  A({int boat});
}
''');
  }

  Future<void> test_default_function() async {
    await resolveTestCode('''
f() {
  g(boot: 0);
}
void g({int boat}) {}
''');
    await assertHasFix('''
f() {
  g(boat: 0);
}
void g({int boat}) {}
''');
  }

  Future<void> test_default_method() async {
    await resolveTestCode('''
f(A a) {
  a.m(boot: 0);
}
class A {
  void m({int boat}) {}
}
''');
    await assertHasFix('''
f(A a) {
  a.m(boat: 0);
}
class A {
  void m({int boat}) {}
}
''');
  }

  Future<void> test_default_redirectingConstructor() async {
    await resolveTestCode('''
class A {
  A.one() : this.two(boot: 3);
  A.two({int boat});
}
''');
    await assertHasFix('''
class A {
  A.one() : this.two(boat: 3);
  A.two({int boat});
}
''');
  }

  Future<void> test_default_superConstructor() async {
    await resolveTestCode('''
class A {
  A.a({int boat});
}
class B extends A {
  B.b() : super.a(boot: 3);
}
''');
    await assertHasFix('''
class A {
  A.a({int boat});
}
class B extends A {
  B.b() : super.a(boat: 3);
}
''');
  }

  Future<void> test_tooDistant_constructor() async {
    await resolveTestCode('''
f() => new A(bbbbb: 2);
class A {
  A({int aaaaaaa});
}
''');
    await assertNoFix();
  }

  Future<void> test_tooDistant_function() async {
    await resolveTestCode('''
f() {
  g(bbbbb: 0);
}
void g({int aaaaaaa}) {}
''');
    await assertNoFix();
  }

  Future<void> test_tooDistant_method() async {
    await resolveTestCode('''
f(A a) {
  a.m(bbbbb: 0);
}
class A {
  void m({int aaaaaaa}) {}
}
''');
    await assertNoFix();
  }
}
