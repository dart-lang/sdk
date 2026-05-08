// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedReferencedParameterTest);
  });
}

@reflectiveTest
class UndefinedReferencedParameterTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_messageText_literalString() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'undef')
  int foo([int? value]) => value ?? 0;
}
''',
      [
        error(
          diag.undefinedReferencedParameter,
          84,
          7,
          messageContains: ["The parameter 'undef'", "isn't defined by 'foo'"],
        ),
      ],
    );
  }

  test_messageText_stringReference() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

const s = 'undef';

class Foo {
  @UseResult.unless(parameterDefined: s)
  int foo([int? value]) => value ?? 0;
}
''',
      [
        error(
          diag.undefinedReferencedParameter,
          104,
          1,
          messageContains: ["The parameter 's'", "isn't defined by 'foo'"],
        ),
      ],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'undef')
  int foo([int? value]) => value ?? 0;
}
''',
      [error(diag.undefinedReferencedParameter, 84, 7)],
    );
  }

  test_method_parameterDefined() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'value')
  int foo([int? value]) => value ?? 0;
}
''');
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'undef')
int foo([int? value]) => value ?? 0;
''',
      [error(diag.undefinedReferencedParameter, 70, 7)],
    );
  }
}
