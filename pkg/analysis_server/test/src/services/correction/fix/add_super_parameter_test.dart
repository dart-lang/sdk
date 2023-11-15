// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddSuperParameterTest);
  });
}

@reflectiveTest
class AddSuperParameterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_SUPER_PARAMETER;

  Future<void> test_named_first() async {
    await resolveTestCode('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.b, required super.c});
}
''');
    // TODO(asashour): consider inserting the named argument in the same
    // position as in the superclass.
    await assertHasFix('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.b, required super.c, required super.a});
}
''');
  }

  Future<void> test_named_first_existingPositional() async {
    await resolveTestCode('''
class A {
  A(int i, {required int a, required int b});
}
class B extends A {
  B(super.i);
}
''');
    await assertHasFix('''
class A {
  A(int i, {required int a, required int b});
}
class B extends A {
  B(super.i, {required super.a, required super.b});
}
''');
  }

  Future<void> test_named_first_existingPositional_comma() async {
    await resolveTestCode('''
class A {
  A(int i, {required int a, required int b});
}
class B extends A {
  B(super.i,);
}
''');
    // TODO(asashour): consider inserting the comma at the end
    await assertHasFix('''
class A {
  A(int i, {required int a, required int b});
}
class B extends A {
  B(super.i, {required super.a, required super.b});
}
''');
  }

  Future<void> test_named_last() async {
    await resolveTestCode('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.b});
}
''');
    await assertHasFix('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.b, required super.c});
}
''');
  }

  Future<void> test_named_last_comma() async {
    await resolveTestCode('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.b,});
}
''');
    await assertHasFix('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.b, required super.c,});
}
''');
  }

  Future<void> test_named_middle() async {
    await resolveTestCode('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.c});
}
''');
    await assertHasFix('''
class A {
  A({required int a, required int b, required int c});
}
class B extends A {
  B({required super.a, required super.c, required super.b});
}
''');
  }

  Future<void> test_named_single() async {
    await resolveTestCode('''
class A {
  A({required int i});
}
class B extends A {
  B();
}
''');
    await assertHasFix('''
class A {
  A({required int i});
}
class B extends A {
  B({required super.i});
}
''');
  }

  Future<void> test_named_single_existingPositional() async {
    await resolveTestCode('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a);
}
''');
    await assertHasFix('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a, {required super.b});
}
''');
  }

  Future<void> test_named_single_existingPositional_comma() async {
    await resolveTestCode('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a,);
}
''');
    await assertHasFix('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a, {required super.b});
}
''');
  }

  Future<void> test_named_used_named() async {
    await resolveTestCode('''
class A {
  A({required int i});
}
class B extends A {
  B({required int i});
}
''');
    await assertNoFix();
  }

  Future<void> test_named_used_positional() async {
    await resolveTestCode('''
class A {
  A({required int i});
}
class B extends A {
  B(int i);
}
''');
    await assertNoFix();
  }

  Future<void> test_positional_hasNamed() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B({required int b});
}
''');
    await assertHasFix('''
class A {
  A(int a);
}
class B extends A {
  B(super.a, {required int b});
}
''');
  }

  Future<void> test_positional_last() async {
    await resolveTestCode('''
class A {
  A(int a, int b);
}
class B extends A {
  B(super.a);
}
''');
    await assertHasFix('''
class A {
  A(int a, int b);
}
class B extends A {
  B(super.a, super.b);
}
''');
  }

  Future<void> test_positional_last_comma() async {
    await resolveTestCode('''
class A {
  A(int a, int b);
}
class B extends A {
  B(super.a,);
}
''');
    await assertHasFix('''
class A {
  A(int a, int b);
}
class B extends A {
  B(super.a, super.b,);
}
''');
  }

  Future<void> test_positional_last_existingNamed() async {
    await resolveTestCode('''
class A {
  A(int a, int b, {required int c});
}
class B extends A {
  B(super.a, {required super.c});
}
''');
    await assertHasFix('''
class A {
  A(int a, int b, {required int c});
}
class B extends A {
  B(super.a, super.b, {required super.c});
}
''');
  }

  Future<void> test_positional_last_previousNotSuper() async {
    await resolveTestCode('''
class A {
  A(int a, int b);
}
class B extends A {
  B(int a);
}
''');
    await assertNoFix();
  }

  Future<void> test_positional_named() async {
    await resolveTestCode('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B();
}
''');
    await assertHasFix('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a, {required super.b});
}
''');
  }

  Future<void> test_positional_named_existing() async {
    await resolveTestCode('''
class A {
  A(int a, int b, {required int c, required int d});
}
class B extends A {
  B(super.a, {required super.c});
}
''');
    await assertHasFix('''
class A {
  A(int a, int b, {required int c, required int d});
}
class B extends A {
  B(super.a, super.b, {required super.c, required super.d});
}
''', matchFixMessage: 'Add required parameters');
  }

  Future<void> test_positional_single() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B();
}
''');
    await assertHasFix('''
class A {
  A(int a);
}
class B extends A {
  B(super.a);
}
''');
  }

  Future<void> test_positional_single_existingNamed() async {
    await resolveTestCode('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B({required super.b});
}
''');
    await assertHasFix('''
class A {
  A(int a, {required int b});
}
class B extends A {
  B(super.a, {required super.b});
}
''');
  }

  Future<void> test_positional_single_usedIndex() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(int b);
}
''');
    await assertNoFix();
  }
}
