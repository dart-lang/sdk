// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedReferencedParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'undef')
//                                    ^^^^^^^
// [diag.undefinedReferencedParameter] The parameter 'undef' isn't defined by 'foo'.
  int foo([int? value]) => value ?? 0;
}
''');
  }

  test_messageText_stringReference() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

const s = 'undef';

class Foo {
  @UseResult.unless(parameterDefined: s)
//                                    ^
// [diag.undefinedReferencedParameter] The parameter 's' isn't defined by 'foo'.
  int foo([int? value]) => value ?? 0;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'undef')
//                                    ^^^^^^^
// [diag.undefinedReferencedParameter] The parameter 'undef' isn't defined by 'foo'.
  int foo([int? value]) => value ?? 0;
}
''');
  }

  test_method_parameterDefined() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class Foo {
  @UseResult.unless(parameterDefined: 'value')
  int foo([int? value]) => value ?? 0;
}
''');
  }

  test_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'undef')
//                                  ^^^^^^^
// [diag.undefinedReferencedParameter] The parameter 'undef' isn't defined by 'foo'.
int foo([int? value]) => value ?? 0;
''');
  }
}
