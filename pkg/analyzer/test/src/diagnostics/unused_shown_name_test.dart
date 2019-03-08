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
  test_unreferenced() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
''');
    assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
A a;
''', [HintCode.UNUSED_SHOWN_NAME]);
  }

  test_unusedShownName_as() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
''');
    assertErrorsInCode(r'''
import 'lib1.dart' as p show A, B;
p.A a;
''', [HintCode.UNUSED_SHOWN_NAME]);
  }

  test_unusedShownName_duplicates() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
class C {}
class D {}
''');
    assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
import 'lib1.dart' show C, D;
A a;
C c;
''', [HintCode.UNUSED_SHOWN_NAME, HintCode.UNUSED_SHOWN_NAME]);
  }

  test_unusedShownName_topLevelVariable() async {
    newFile('/test/lib/lib1.dart', content: r'''
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;
''');
    assertErrorsInCode(r'''
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
int a = var1;
int b = var2;
int c = var3;
''', [HintCode.UNUSED_SHOWN_NAME]);
  }
}
