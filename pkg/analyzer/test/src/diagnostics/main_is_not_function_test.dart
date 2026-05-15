// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainIsNotFunctionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MainIsNotFunctionTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics('''
class main {}
//    ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_classAlias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin M {}
class main = A with M;
//    ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics('''
enum main {
//   ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
  v
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics('''
void main() {}
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics('''
int get main => 0;
//      ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin main on A {}
//    ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_typedef() async {
    await resolveTestCodeWithDiagnostics('''
typedef main = void Function();
//      ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_typedef_legacy() async {
    await resolveTestCodeWithDiagnostics('''
typedef void main();
//           ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }

  test_variable() async {
    await resolveTestCodeWithDiagnostics('''
var main = 0;
//  ^^^^
// [diag.mainIsNotFunction] The declaration named 'main' must be a function.
''');
  }
}
