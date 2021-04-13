// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateConstructorSuperTest);
  });
}

@reflectiveTest
class CreateConstructorSuperTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_SUPER;

  Future<void> test_fieldInitializer() async {
    await resolveTestCode('''
class A {
  int _field;
  A(this._field);
  int get field => _field;
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  int _field;
  A(this._field);
  int get field => _field;
}
class B extends A {
  int existingField;

  B(int field) : super(field);

  void existingMethod() {}
}
''');
  }

  Future<void> test_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
''');
    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

class B {
  B(A a);
}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

class C extends B {
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

class C extends B {
  C(A a) : super(a);
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  B.named(p1, int p2) : super.named(p1, p2);

  void existingMethod() {}
}
''');
  }

  Future<void> test_optional() async {
    await resolveTestCode('''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  B(p1, int p2, List<String> p3) : super(p1, p2, p3);

  void existingMethod() {}
}
''');
  }

  Future<void> test_private() async {
    await resolveTestCode('''
class A {
  A._named(p);
}
class B extends A {
}
''');
    await assertNoFix();
  }

  Future<void> test_typeArgument() async {
    await resolveTestCode('''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
}''');
    await assertHasFix('''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
  D(int x) : super(x);
}''');
  }
}
