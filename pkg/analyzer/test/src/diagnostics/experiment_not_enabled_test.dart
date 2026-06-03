// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentNotEnabledTest);
  });
}

@reflectiveTest
class ExperimentNotEnabledTest extends PubPackageResolutionTest {
  test_constructor_tearoffs_disabled_grammar() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.12
class Foo<X> {
  const Foo.bar();
  int get baz => 0;
}
main() {
  Foo<int>.bar.baz();
//   ^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
//             ^^^
// [diag.undefinedMethod] The method 'baz' isn't defined for the type 'Function'.
}
''');
  }

  test_dotShorthands_disabled() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.8
void main() {
  Object c = .hash(1, 2);
//           ^
// [diag.experimentNotEnabled] This requires the 'dot-shorthands' language feature to be enabled.
  print(c);
}
''');
  }

  test_nonFunctionTypeAliases_disabled() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.12
typedef A = int;
//        ^
// [diag.experimentNotEnabled] This requires the 'nonfunction-type-aliases' language feature to be enabled.
''');
  }

  test_nonFunctionTypeAliases_disabled_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.12
typedef A = int?;
//        ^
// [diag.experimentNotEnabled] This requires the 'nonfunction-type-aliases' language feature to be enabled.
''');
  }

  test_privateNamedParameters_disabled() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.8
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
//        ^^
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
}
''');
  }
}
