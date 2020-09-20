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
  test_functionTypeAlias() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
typedef p();
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 32, 1),
    ]);
  }

  test_no_collision() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
class A {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
typedef P();
p2() {}
var p3;
class p4 {}
p.A a;
''');
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
p() {}
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 24, 1),
    ]);
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
var p = null;
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 28, 1),
    ]);
  }

  test_type() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
class p {}
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 30, 1),
    ]);
  }
}
