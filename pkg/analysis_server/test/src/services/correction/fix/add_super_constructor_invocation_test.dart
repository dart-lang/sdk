// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddSuperConstructorInvocationTest);
  });
}

@reflectiveTest
class AddSuperConstructorInvocationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION;

  Future<void> test_hasInitializers() async {
    await resolveTestCode('''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42 {}
}
''');
    await assertHasFix('''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42, super(0) {}
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class A {
  A.named(int p);
}
class B extends A {
  B() {}
}
''');
    await assertHasFix('''
class A {
  A.named(int p);
}
class B extends A {
  B() : super.named(0) {}
}
''');
  }

  Future<void> test_named_private() async {
    await resolveTestCode('''
class A {
  A._named(int p);
}
class B extends A {
  B() {}
}
''');
    await assertNoFix();
  }

  Future<void> test_requiredAndNamed() async {
    await resolveTestCode('''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() {}
}
''');
    await assertHasFix('''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() : super(false, 0, 0.0, '') {}
}
''');
  }

  Future<void> test_typeArgument() async {
    await resolveTestCode('''
class A<T> {
  A(T p);
}
class B extends A<int> {
  B();
}
''');
    await assertHasFix('''
class A<T> {
  A(T p);
}
class B extends A<int> {
  B() : super(0);
}
''');
  }
}
