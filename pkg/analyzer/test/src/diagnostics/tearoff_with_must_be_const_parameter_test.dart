// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearoffWithMustBeConstParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TearoffWithMustBeConstParameterTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_method_commentReference_threeNames() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import '' as self;
/// Reference to [self.C.f].
var a = 1;
class C {
  // ignore: experimental_member_use
  void f(@mustBeConst int x) {}
}
''');
  }

  test_class_method_commentReference_twoNames() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
/// Reference to [C.f].
var a = 1;
class C {
  // ignore: experimental_member_use
  void f(@mustBeConst int x) {}
}
''');
  }

  test_class_method_implicitThis_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  Object get n => m;
//                ^
// [diag.tearoffWithMustBeConstParameter] The function 'm' has a parameter marked as '@mustBeConst' and can't be torn off.
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''');
  }

  test_class_method_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C().m(1);
class C {
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''');
  }

  test_class_method_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C().m;
//          ^
// [diag.tearoffWithMustBeConstParameter] The function 'm' has a parameter marked as '@mustBeConst' and can't be torn off.
class C {
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''');
  }

  test_class_primaryConstructor_named_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C.named;
//      ^^^^^^^
// [diag.tearoffWithMustBeConstParameter] The function 'named' has a parameter marked as '@mustBeConst' and can't be torn off.
// ignore: experimental_member_use
class C.named(@mustBeConst int x);
''');
  }

  test_class_primaryConstructor_unnamed_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C(1);
// ignore: experimental_member_use
class C(@mustBeConst int x);
''');
  }

  test_class_primaryConstructor_unnamed_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C.new;
//      ^^^^^
// [diag.tearoffWithMustBeConstParameter] The function 'new' has a parameter marked as '@mustBeConst' and can't be torn off.
// ignore: experimental_member_use
class C(@mustBeConst int x);
''');
  }

  test_class_secondaryConstructor_named_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C.named;
//      ^^^^^^^
// [diag.tearoffWithMustBeConstParameter] The function 'named' has a parameter marked as '@mustBeConst' and can't be torn off.
class C {
  // ignore: experimental_member_use
  C.named(@mustBeConst int x);
}
''');
  }

  test_class_secondaryConstructor_unnamed_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C.new(1);
class C {
  // ignore: experimental_member_use
  C(@mustBeConst int x);
}
''');
  }

  test_class_secondaryConstructor_unnamed_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = C.new;
//      ^^^^^
// [diag.tearoffWithMustBeConstParameter] The function 'new' has a parameter marked as '@mustBeConst' and can't be torn off.
class C {
  // ignore: experimental_member_use
  C(@mustBeConst int x);
}
''');
  }

  test_topLevelFunction_commentReference() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
/// Reference to [f].
var a = 1;
// ignore: experimental_member_use
void f(@mustBeConst int x) {}
''');
  }

  test_topLevelFunction_instantiated_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = f<int>;
//      ^
// [diag.tearoffWithMustBeConstParameter] The function 'f' has a parameter marked as '@mustBeConst' and can't be torn off.
// ignore: experimental_member_use
void f<T>(@mustBeConst T x) {}
''');
  }

  test_topLevelFunction_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = f(1);
// ignore: experimental_member_use
void f(@mustBeConst int x) {}
''');
  }

  test_topLevelFunction_tearoff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
var g = f;
//      ^
// [diag.tearoffWithMustBeConstParameter] The function 'f' has a parameter marked as '@mustBeConst' and can't be torn off.
// ignore: experimental_member_use
void f(@mustBeConst int x) {}
''');
  }
}
