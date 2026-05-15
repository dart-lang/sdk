// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_notEnclosingClassName_inAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  factory B() => throw 0;
}
''');

    await resolveFile2(b);
    assertErrorsInResult([error(diag.invalidFactoryNameNotAClass, 47, 1)]);
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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}

class B implements A {
  const B();
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  const factory A() = B;
}
''');

    await resolveFile2(b);
    assertNoErrorsInResult();
  }
}
