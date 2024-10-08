// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixCollidesWithTopLevelMemberTest);
  });
}

@reflectiveTest
class PrefixCollidesWithTopLevelMemberTest extends PubPackageResolutionTest {
  test_library_functionTypeAlias() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
typedef foo = void Function();
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 35, 3)]),
    ]);
  }

  test_library_no_collision() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
void bar() {}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_library_topLevelFunction() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
void foo() {}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 32, 3)]),
    ]);
  }

  test_library_topLevelGetter() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
int get foo => 0;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 35, 3)]),
    ]);
  }

  test_library_topLevelSetter() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
set foo(int _) {}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 31, 3)]),
    ]);
  }

  test_library_topLevelVariable() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
var foo = 0;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 31, 3)]),
    ]);
  }

  test_library_type() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;
class foo {}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 22, 3,
          contextMessages: [message(testFile, 33, 3)]),
    ]);
  }

  test_part_topLevelFunction_inLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
void foo() {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';
import 'dart:math' as foo;
''', [
      error(WarningCode.UNUSED_IMPORT, 25, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 40, 3,
          contextMessages: [message(a, 23, 3)]),
    ]);
  }

  test_part_topLevelFunction_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertErrorsInCode(r'''
part of 'a.dart';
import 'dart:math' as foo;
void foo() {}
''', [
      error(WarningCode.UNUSED_IMPORT, 25, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 40, 3,
          contextMessages: [message(testFile, 50, 3)]),
    ]);
  }

  test_part_topLevelFunction_inPart2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
void foo() {}
''');

    await assertErrorsInCode(r'''
part of 'a.dart';
import 'dart:math' as foo;
''', [
      error(WarningCode.UNUSED_IMPORT, 25, 11),
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 40, 3,
          contextMessages: [message(b, 23, 3)]),
    ]);
  }
}
