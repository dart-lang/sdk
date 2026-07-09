// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberWithClassNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MemberWithClassNameTest extends PubPackageResolutionTest {
  test_class_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int A = 0;
//    ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_class_field_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int z = 0, A = 0, b = 0;
//           ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  get A => 0;
//    ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_class_getter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get A => 0;
//               ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_class_method() async {
    // No test because a method named the same as the enclosing class is
    // indistinguishable from a constructor.
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set A(_) {}
//    ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_class_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set A(_) {}
//           ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_enum_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int E = 0;
//          ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_enum_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get E => 0;
//        ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_enum_getter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get E => 0;
//               ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_enum_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set E(int _) {}
//    ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_enum_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set E(int _) {}
//           ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_mixin_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get M => 0;
//        ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_mixin_getter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get M => 0;
//               ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_mixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void set M(_) {}
//         ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }

  test_mixin_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void set M(_) {}
//                ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');
  }
}
