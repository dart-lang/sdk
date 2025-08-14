// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeAsTypeArgumentTest);
  });
}

@reflectiveTest
class NonTypeAsTypeArgumentTest extends PubPackageResolutionTest {
  test_issue54388() async {
    await assertErrorsInCode(
      r'''
sealed class Option<A> {}

final class None implements Option<A> {
  const None();
}

A doOption<A>(
  A Function(B Function<B>(Option<B>)) eval,
) {
  return eval(
    <B>(option) => switch (option) {
      None() => throw 7,
    },
  );
}
''',
      [error(CompileTimeErrorCode.nonTypeAsTypeArgument, 62, 1)],
    );
  }

  test_notAType() async {
    await assertErrorsInCode(
      r'''
int A = 0;
class B<E> {}
f(B<A> b) {}
''',
      [error(CompileTimeErrorCode.nonTypeAsTypeArgument, 29, 1)],
    );
  }

  test_undefinedIdentifier() async {
    await assertErrorsInCode(
      r'''
class B<E> {}
f(B<A> b) {}
''',
      [error(CompileTimeErrorCode.nonTypeAsTypeArgument, 18, 1)],
    );
  }
}
