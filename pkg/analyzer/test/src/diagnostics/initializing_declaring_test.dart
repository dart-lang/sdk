// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializingDeclaringTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InitializingDeclaringTest extends PubPackageResolutionTest {
  test_const_initializing() async {
    await resolveTestCodeWithDiagnostics('''
class C(const this.str) {
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
  final str;
}
''');
  }

  test_const_superInitializing() async {
    await resolveTestCodeWithDiagnostics('''
class S(final str);
class C(const super.str) extends S;
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');
  }

  test_final_initializing() async {
    await resolveTestCodeWithDiagnostics('''
class C(final this.str) {
//            ^^^^
// [diag.initializingDeclaringParameter] Declaring parameters can't be initializing.
  final str;
}
''');
  }

  test_final_superInitializing() async {
    await resolveTestCodeWithDiagnostics('''
class S(final str);
class C(final super.str) extends S;
//            ^^^^^
// [diag.superInitializingDeclaringParameter] Declaring parameters can't be super parameters.
''');
  }

  test_var_initializing() async {
    await resolveTestCodeWithDiagnostics('''
class C(var this.str) {
//          ^^^^
// [diag.initializingDeclaringParameter] Declaring parameters can't be initializing.
  var str;
}
''');
  }

  test_var_superInitializing() async {
    await resolveTestCodeWithDiagnostics('''
class S(var str);
class C(var super.str) extends S;
//          ^^^^^
// [diag.superInitializingDeclaringParameter] Declaring parameters can't be super parameters.
''');
  }
}
