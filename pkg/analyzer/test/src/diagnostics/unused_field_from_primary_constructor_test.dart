// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldFromPrimaryConstructorTest);
  });
}

@reflectiveTest
class UnusedFieldFromPrimaryConstructorTest extends PubPackageResolutionTest {
  test_isUsed() async {
    await assertNoErrorsInCode(r'''
class Foo(final int _i) {
  int get x => _i;
}
''');
  }

  test_isUsed_extensionType() async {
    // The representation is not actually used, but we don't report unused
    // extension type representation types.
    await assertNoErrorsInCode(r'''
extension type Foo(final int _i) {}
''');
  }

  test_isUsed_extensionType_underscore() async {
    await assertNoErrorsInCode(r'''
extension type Foo(final int _) {}
''');
  }

  test_isUsed_public() async {
    await assertNoErrorsInCode(r'''
class Foo(final int i) {}
''');
  }

  test_notUsed() async {
    await assertErrorsInCode(
      r'''
class Foo(final int _i) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 20, 2)],
    );
  }

  test_notUsed_underscore() async {
    await assertErrorsInCode(
      r'''
class Foo(final int _) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 20, 1)],
    );
  }
}
