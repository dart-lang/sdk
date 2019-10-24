// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedElementTest);
  });
}

@reflectiveTest
class RemoveUnusedElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  test_class_notUsed_inClassMember() async {
    await resolveTestUnit(r'''
class _A {
  static staticMethod() {
    new _A();
  }
}
''');
    // todo (pq): consider supporting the case where references are limited to within the class.
    await assertNoFix();
  }

  test_class_notUsed_isExpression() async {
    await resolveTestUnit(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''');
    // We don't know what to do  with the reference.
    await assertNoFix();
  }

  test_class_notUsed_noReference() async {
    await resolveTestUnit(r'''
class _A {
}
''');
    await assertHasFix(r'''
''');
  }

  test_enum_notUsed_noReference() async {
    await resolveTestUnit(r'''
enum _MyEnum {A, B, C}
''');
    await assertHasFix(r'''
''');
  }

  test_functionLocal_notUsed_noReference() async {
    await resolveTestUnit(r'''
main() {
  f() {}
}
''');
    await assertHasFix(r'''
main() {
}
''');
  }

  test_functionTop_notUsed_noReference() async {
    await resolveTestUnit(r'''
_f() {}
main() {
}
''');
    await assertHasFix(r'''
main() {
}
''');
  }

  test_functionTypeAlias_notUsed_noReference() async {
    await resolveTestUnit(r'''
typedef _F(a, b);
main() {
}
''');
    await assertHasFix(r'''
main() {
}
''');
  }

  test_getter_notUsed_noReference() async {
    await resolveTestUnit(r'''
class A {
  get _g => null;
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  test_method_notUsed_noReference() async {
    await resolveTestUnit(r'''
class A {
  static _m() {}
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  test_setter_notUsed_noReference() async {
    await resolveTestUnit(r'''
class A {
  set _s(x) {}
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  test_topLevelVariable_notUsed() async {
    await resolveTestUnit(r'''
int _a = 1;
main() {
  _a = 2;
}
''');
    // Reference.
    await assertNoFix();
  }

  test_topLevelVariable_notUsed_noReference() async {
    await resolveTestUnit(r'''
int _a = 1;
main() {
}
''');
    await assertHasFix(r'''
main() {
}
''');
  }
}
