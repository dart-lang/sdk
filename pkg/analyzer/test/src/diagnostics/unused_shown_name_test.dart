// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedShownNameTest);
  });
}

@reflectiveTest
class UnusedShownNameTest extends DriverResolutionTest {
  test_extension_instance_method_unused() async {
    newFile('/test/lib/lib1.dart', content: r'''
extension E on String {
  String empty() => '';
}
String s = '';
''');
    await assertErrorsInCode('''
import 'lib1.dart' show E, s;

f() {
  s.length;
}
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 24, 1),
    ]);
  }

  test_extension_instance_method_used() async {
    newFile('/test/lib/lib1.dart', content: r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' show E;

f() {
  ''.empty();
}
''');
  }

  test_unreferenced() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
A a;
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 27, 1),
    ]);
  }

  test_unresolved() async {
    await assertErrorsInCode(r'''
import 'dart:math' show max, FooBar;
main() {
  print(max(1, 2));
}
''', [
      error(HintCode.UNDEFINED_SHOWN_NAME, 29, 6),
    ]);
  }

  test_unusedShownName_as() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as p show A, B;
p.A a;
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 32, 1),
    ]);
  }

  test_unusedShownName_duplicates() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
class C {}
class D {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
import 'lib1.dart' show C, D;
A a;
C c;
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 27, 1),
      error(HintCode.UNUSED_SHOWN_NAME, 57, 1),
    ]);
  }

  test_unusedShownName_topLevelVariable() async {
    newFile('/test/lib/lib1.dart', content: r'''
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
int a = var1;
int b = var2;
int c = var3;
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 66, 4),
    ]);
  }
}
