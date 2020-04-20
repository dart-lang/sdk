// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixIdentifierNotFollowedByDotTest);
  });
}

@reflectiveTest
class PrefixIdentifierNotFollowedByDotTest extends DriverResolutionTest {
  test_assignment_compound_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_assignment_compound_not_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_assignment_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_assignment_not_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p = 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_compoundAssignment() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalMethodInvocation() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
g() {}
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalPropertyAccess_call_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_conditionalPropertyAccess_get() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p?.x;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }

  test_conditionalPropertyAccess_get_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 48, 1),
    ]);
  }

  test_conditionalPropertyAccess_set() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.x = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalPropertyAccess_set_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_prefix_not_followed_by_dot() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }
}
