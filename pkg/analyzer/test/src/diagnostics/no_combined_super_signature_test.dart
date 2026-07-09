// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoCombinedSuperSignatureTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NoCombinedSuperSignatureTest extends PubPackageResolutionTest {
  test_conflictingParameter() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  void foo(int x);
}

abstract class B {
  void foo(double x);
}

abstract class C implements A, B {
  foo(num x);
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (void Function(int)), B.foo (void Function(double)).
}
''');
  }

  /// If the method is subject to override inference, it is already an error
  /// when no combined super signature exist.
  ///
  /// It does not matter that the conflicting component (the return type here)
  /// was resolved.
  test_conflictingReturnType() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  int foo(int x);
}

abstract class B {
  double foo(int x);
}

abstract class C implements A, B {
  Never foo(x);
//      ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (int Function(int)), B.foo (double Function(int)).
}
''');
  }

  test_noInvalidOverrideErrors() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  String foo(String a);
}

abstract class B {
  int foo(int a);
}

abstract class C implements A, B {
  foo(a);
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (String Function(String)), B.foo (int Function(int)).
}
''');
  }
}
