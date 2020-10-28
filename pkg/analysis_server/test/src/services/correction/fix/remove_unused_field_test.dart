// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedFieldTest);
  });
}

@reflectiveTest
class RemoveUnusedFieldTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_FIELD;

  @FailingTest(reason: 'Unimplemented')
  Future<void> test_enumValue_notUsed_noReference() async {
    await resolveTestCode(r'''
enum _E { a, b, c }
bool f(_E e) => e == _E.a || e == _E.b;
''');
    await assertHasFix(r'''
enum _E { a, b }
bool f(_E e) => e == _E.a || e == _E.b;
''');
  }

  Future<void> test_parameter_optional_first() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A([this._f, int x]);
}
''');
    await assertHasFix(r'''
class A {
  A([int x]);
}
''');
  }

  Future<void> test_parameter_optional_first_hasRequired() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A(int x, [this._f, int y]);
}
''');
    await assertHasFix(r'''
class A {
  A(int x, [int y]);
}
''');
  }

  Future<void> test_parameter_optional_last() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A([int x, this._f]);
}
''');
    await assertHasFix(r'''
class A {
  A([int x]);
}
''');
  }

  Future<void> test_parameter_optional_middle() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A([int x, this._f, int y]);
}
''');
    await assertHasFix(r'''
class A {
  A([int x, int y]);
}
''');
  }

  Future<void> test_parameter_optional_only() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A([this._f]);
}
''');
    await assertHasFix(r'''
class A {
  A();
}
''');
  }

  Future<void> test_parameter_optional_only_hasRequired() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A(int x, [this._f]);
}
''');
    await assertHasFix(r'''
class A {
  A(int x);
}
''');
  }

  Future<void> test_parameter_required_beforeOptional() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A(this._f, [int x]);
}
''');
    await assertHasFix(r'''
class A {
  A([int x]);
}
''');
  }

  Future<void> test_parameter_required_first() async {
    await resolveTestCode(r'''
class A {
  int _f;
  int x;
  A(this._f, this.x);
}
''');
    await assertHasFix(r'''
class A {
  int x;
  A(this.x);
}
''');
  }

  Future<void> test_parameter_required_last() async {
    await resolveTestCode(r'''
class A {
  int x;
  int _f;
  A(this.x, this._f);
}
''');
    await assertHasFix(r'''
class A {
  int x;
  A(this.x);
}
''');
  }

  Future<void> test_parameter_required_only() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A(this._f);
}
''');
    await assertHasFix(r'''
class A {
  A();
}
''');
  }

  Future<void> test_unusedField_notUsed_assign() async {
    await resolveTestCode(r'''
class A {
  int _f;
  main() {
    _f = 2;
  }
}
''');
    await assertHasFix(r'''
class A {
  main() {
  }
}
''');
  }

  Future<void> test_unusedField_notUsed_compoundAssign() async {
    await resolveTestCode(r'''
class A {
  int _f;
  main() {
    _f += 2;
  }
}
''');
    await assertHasFix(r'''
class A {
  main() {
  }
}
''');
  }

  Future<void> test_unusedField_notUsed_constructorFieldInitializers() async {
    await resolveTestCode(r'''
class A {
  int _f;
  A() : _f = 0;
}
''');
    await assertHasFix(r'''
class A {
  A();
}
''');
  }

  Future<void> test_unusedField_notUsed_constructorFieldInitializers1() async {
    await resolveTestCode(r'''
class A {
  int _f;
  int y;
  A() : _f = 0, y = 1;
}
''');
    await assertHasFix(r'''
class A {
  int y;
  A() : y = 1;
}
''');
  }

  Future<void> test_unusedField_notUsed_constructorFieldInitializers2() async {
    await resolveTestCode(r'''
class A {
  int _f;
  int y;
  A() : y = 1, _f = 0;
}
''');
    await assertHasFix(r'''
class A {
  int y;
  A() : y = 1;
}
''');
  }

  Future<void> test_unusedField_notUsed_declarationList_first() async {
    await resolveTestCode(r'''
class A {
  int _f, x;
  A(this._f) {
    print(x);
  }
}
''');
    await assertHasFix(r'''
class A {
  int x;
  A() {
    print(x);
  }
}
''');
  }

  Future<void> test_unusedField_notUsed_declarationList_last() async {
    await resolveTestCode(r'''
class A {
  int x, _f;
  A(this._f) {
    print(x);
  }
}
''');
    await assertHasFix(r'''
class A {
  int x;
  A() {
    print(x);
  }
}
''');
  }
}
