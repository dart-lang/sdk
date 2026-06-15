// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainHasTooManyRequiredPositionalParametersTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MainHasTooManyRequiredPositionalParametersTest
    extends PubPackageResolutionTest {
  test_namedOptional_1() async {
    await resolveTestCodeWithDiagnostics('''
void main({int a = 0}) {}
''');
  }

  test_positionalOptional_1() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a = 0]) {}
''');
  }

  test_positionalRequired_0() async {
    await resolveTestCodeWithDiagnostics('''
void main() {}
''');
  }

  test_positionalRequired_1() async {
    await resolveTestCodeWithDiagnostics('''
void main(args) {}
''');
  }

  test_positionalRequired_2() async {
    await resolveTestCodeWithDiagnostics('''
void main(args, int a) {}
''');
  }

  test_positionalRequired_2_positionalOptional_1() async {
    await resolveTestCodeWithDiagnostics('''
void main(args, int a, [int b = 0]) {}
''');
  }

  test_positionalRequired_3() async {
    await resolveTestCodeWithDiagnostics('''
void main(args, int a, int b) {}
//   ^^^^
// [diag.mainHasTooManyRequiredPositionalParameters] The function 'main' can't have more than two required positional parameters.
''');
  }

  test_positionalRequired_3_namedOptional_1() async {
    await resolveTestCodeWithDiagnostics('''
void main(args, int a, int b, {int c = 0}) {}
//   ^^^^
// [diag.mainHasTooManyRequiredPositionalParameters] The function 'main' can't have more than two required positional parameters.
''');
  }

  test_positionalRequired_3_namedRequired_1() async {
    await resolveTestCodeWithDiagnostics('''
void main(args, int a, int b, {required int c}) {}
//   ^^^^
// [diag.mainHasTooManyRequiredPositionalParameters] The function 'main' can't have more than two required positional parameters.
// [diag.mainHasRequiredNamedParameters] The function 'main' can't have any required named parameters.
''');
  }
}
