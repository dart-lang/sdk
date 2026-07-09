// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInRedirectingFactoryConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DefaultValueInRedirectingFactoryConstructorTest
    extends PubPackageResolutionTest {
  test_default_value() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A([int x = 0]) = B;
//               ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}

class B implements A {
  B([int x = 1]) {}
}
''');
  }
}
