// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedFieldTest);
  });
}

@reflectiveTest
class RemoveUnusedFieldTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_FIELD;

  test_unusedField_notUsed_assign() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_compoundAssign() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_constructorFieldInitializers() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_constructorFieldInitializers1() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_constructorFieldInitializers2() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_declarationList() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_declarationList2() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_fieldFormalParameter() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_fieldFormalParameter2() async {
    await resolveTestUnit(r'''
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

  test_unusedField_notUsed_fieldFormalParameter3() async {
    await resolveTestUnit(r'''
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
}
