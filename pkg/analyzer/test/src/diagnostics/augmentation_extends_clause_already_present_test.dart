// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationExtendsClauseAlreadyPresentTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationExtendsClauseAlreadyPresentTest
    extends PubPackageResolutionTest {
  test_alreadyPresent() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {}
//    ^
// [context 1] The declaration being augmented.
augment class B extends A {}
//              ^^^^^^^
// [diag.augmentationExtendsClauseAlreadyPresent][context 1] The augmentation has an 'extends' clause, but an augmentation target already includes an 'extends' clause and it isn't allowed to be repeated or changed.
''');
  }

  test_alreadyPresent2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {}
//    ^
// [context 1] The declaration being augmented.
augment class B {}
augment class B extends A {}
//              ^^^^^^^
// [diag.augmentationExtendsClauseAlreadyPresent][context 1] The augmentation has an 'extends' clause, but an augmentation target already includes an 'extends' clause and it isn't allowed to be repeated or changed.
''');
  }

  test_alreadyPresent2_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}

class B extends A {}
//    ^
// [context 1] The declaration being augmented.

augment class B {}
''',
      b: r'''
part of 'a.dart';

augment class B extends A {}
//              ^^^^^^^
// [diag.augmentationExtendsClauseAlreadyPresent][context 1] The augmentation has an 'extends' clause, but an augmentation target already includes an 'extends' clause and it isn't allowed to be repeated or changed.
''',
    });
  }

  test_alreadyPresent_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}

class B extends A {}
//    ^
// [context 1] The declaration being augmented.
''',
      b: r'''
part of 'a.dart';

augment class B extends A {}
//              ^^^^^^^
// [diag.augmentationExtendsClauseAlreadyPresent][context 1] The augmentation has an 'extends' clause, but an augmentation target already includes an 'extends' clause and it isn't allowed to be repeated or changed.
''',
    });
  }

  test_notPresent() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B {}
augment class B extends A {}
''');
  }
}
