// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationSyntaxTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnnotationSyntaxTest extends PubPackageResolutionTest {
  test_annotation_on_type_argument() async {
    await resolveTestCodeWithDiagnostics(r'''
const annotation = null;

class Annotation {
  final String message;
  const Annotation(this.message);
}

class A<E> {}

class C {
  m() => new A<@annotation @Annotation("test") C>();
//             ^^^^^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                         ^^^^^^^^^^^^^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
}
''');
  }
}
