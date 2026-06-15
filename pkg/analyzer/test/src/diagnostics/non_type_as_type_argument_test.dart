// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeAsTypeArgumentTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonTypeAsTypeArgumentTest extends PubPackageResolutionTest {
  test_issue54388() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class Option<A> {}

final class None implements Option<A> {
//                                 ^
// [diag.nonTypeAsTypeArgument] The name 'A' isn't a type, so it can't be used as a type argument.
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
''');
  }

  test_notAType() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 0;
class B<E> {}
f(B<A> b) {}
//  ^
// [diag.nonTypeAsTypeArgument] The name 'A' isn't a type, so it can't be used as a type argument.
''');
  }

  test_undefinedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
class B<E> {}
f(B<A> b) {}
//  ^
// [diag.nonTypeAsTypeArgument] The name 'A' isn't a type, so it can't be used as a type argument.
''');
  }
}
