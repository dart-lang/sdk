// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
// @dart = 2.12
class Foo<X> {
  const Foo.bar();
  int get baz => 0;
}
main() {
  Foo<int>.bar.baz();
}
''',
      [
        error(diag.experimentNotEnabled, 86, 5),
        error(diag.undefinedMethod, 96, 3),
      ],
    );
  }

  test_dotShorthands_disabled() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.8
void main() {
  Object c = .hash(1, 2);
  print(c);
}
''',
      [error(diag.experimentNotEnabled, 42, 1)],
    );
  }

  test_nonFunctionTypeAliases_disabled() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.12
typedef A = int;
''',
      [error(diag.experimentNotEnabled, 26, 1)],
    );
  }

  test_nonFunctionTypeAliases_disabled_nullable() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.12
typedef A = int?;
''',
      [error(diag.experimentNotEnabled, 26, 1)],
    );
  }

  test_privateNamedParameters_disabled() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.8
class C {
  int? _x;
  C({this._x});
}
''',
      [error(diag.unusedField, 32, 2), error(diag.experimentNotEnabled, 46, 2)],
    );
  }
}
