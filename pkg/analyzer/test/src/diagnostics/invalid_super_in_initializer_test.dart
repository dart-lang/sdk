// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidSuperInInitializerTest);
  });
}

@reflectiveTest
class InvalidSuperInInitializerTest extends PubPackageResolutionTest {
  test_constructor_name_is_keyword() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C() : super.const();
//      ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
//            ^^^^^
// [diag.expectedIdentifierButGotKeyword] 'const' can't be used as an identifier because it's a keyword.
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }
}
