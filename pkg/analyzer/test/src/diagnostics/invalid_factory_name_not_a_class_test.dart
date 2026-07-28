// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFactoryNameNotAClassTest);
  });
}

@reflectiveTest
class InvalidFactoryNameNotAClassTest extends PubPackageResolutionTest {
  test_notClassName_withoutPrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
int B = 0;
class A {
  factory B() => throw 0;
//        ^
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_notEnclosingClassName_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  factory B() => throw 0;
//        ^
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
}
''');
  }

  test_notEnclosingClassName_withoutPrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  factory B() => throw 0;
//        ^
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
}
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_valid_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B implements A {
  const B();
}

augment class A {
  const factory A() = B;
}
''');
  }
}
