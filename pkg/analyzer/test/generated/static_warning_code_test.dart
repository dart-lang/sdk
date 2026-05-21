// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StaticWarningCodeTest extends PubPackageResolutionTest {
  // TODO(brianwilkerson): Figure out what to do with the rest of these tests.
  //  The names do not correspond to diagnostic codes, so it isn't clear what
  //  they're testing.
  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    // 15028
    await resolveTestCodeWithDiagnostics(
      '''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}
//    ^
// [diag.invalidImplementationOverride] 'C.foo' ('dynamic Function(int)') isn't a valid concrete implementation of 'D.foo' ('dynamic Function(dynamic, [dynamic])').''',
    );
  }

  test_typePromotion_functionType_arg_InterToDyn() async {
    await resolveTestCodeWithDiagnostics('''
typedef FuncDyn(x);
typedef FuncA(A a);
class A {}
class B {}
f(FuncA f) {
  if (f is FuncDyn) {
    f(new B());
  }
}''');
  }

  test_voidReturnForGetter() async {
    await resolveTestCodeWithDiagnostics('''
class S {
  void get value {}
}''');
  }
}
