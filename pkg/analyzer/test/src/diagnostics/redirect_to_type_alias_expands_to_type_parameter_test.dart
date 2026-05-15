// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_generic_typeParameter_withArgument_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements C {
  A.named();
}

typedef B<T> = T;

class C {
  factory C() = B<A>.named;
//              ^
// [diag.redirectToTypeAliasExpandsToTypeParameter] A redirecting constructor can't redirect to a type alias that expands to a type parameter.
}
''');
  }

  test_generic_typeParameter_withArgument_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements C {}

typedef B<T> = T;

class C {
  factory C() = B<A>;
//              ^
// [diag.redirectToTypeAliasExpandsToTypeParameter] A redirecting constructor can't redirect to a type alias that expands to a type parameter.
}
''');
  }

  test_generic_typeParameter_withoutArgument_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements C {}

typedef B<T> = T;

class C {
  factory C() = B;
//              ^
// [diag.redirectToTypeAliasExpandsToTypeParameter] A redirecting constructor can't redirect to a type alias that expands to a type parameter.
}
''');
  }

  test_notGeneric_class_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements C {
  A.named();
}

typedef B = A;

class C {
  factory C() = B.named;
}
''');
  }

  test_notGeneric_class_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements C {}

typedef B = A;

class C {
  factory C() = B;
}
''');
  }
}
