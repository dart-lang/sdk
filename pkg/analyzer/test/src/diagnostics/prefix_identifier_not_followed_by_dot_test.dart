// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixIdentifierNotFollowedByDotTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixIdentifierNotFollowedByDotTest extends PubPackageResolutionTest {
  test_assignment_compound_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
//  ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
  }
}
''');
  }

  test_assignment_compound_not_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  p += 1;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_assignment_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
//  ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
  }
}
''');
  }

  test_assignment_in_method_hasSuperField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

class A {
  var p;
}

class B extends A {
  void f() {
    p = 1;
//  ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
  }
}
''');
  }

  test_assignment_not_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  p = 1;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_compoundAssignment() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  p += 1;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalMethodInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
g() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  p?.g();
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalPropertyAccess_call_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalPropertyAccess_get() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var x;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  return p?.x;
//       ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalPropertyAccess_get_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
//       ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalPropertyAccess_set() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var x;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  p?.x = null;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_conditionalPropertyAccess_set_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_prefix_not_followed_by_dot() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
f() {
  return p;
//       ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }
}
