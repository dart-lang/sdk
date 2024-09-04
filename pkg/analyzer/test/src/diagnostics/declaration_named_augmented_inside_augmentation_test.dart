// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclarationNamedAugmentedInsideAugmentationTest);
  });
}

@reflectiveTest
class DeclarationNamedAugmentedInsideAugmentationTest
    extends PubPackageResolutionTest {
  test_insideClassMethodAugmentation_localVariable_noInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void f() {}
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment void f() {
    int augmented;
  }
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 66,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 66, 9),
    ]);
  }

  test_insideFunctionAugmentation_declaredVariablePattern_assignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f() {
  var (augmented,) = (0,);
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 45,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 45, 9),
    ]);
  }

  test_insideFunctionAugmentation_declaredVariablePattern_match() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f() {
  if ((0,) case (var augmented,)) {}
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 59,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 59, 9),
    ]);
  }

  test_insideFunctionAugmentation_formalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f(int a) {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f(int augmented) {}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 38,
          9),
    ]);
  }

  test_insideFunctionAugmentation_localFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f() {
  void augmented() {}
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 45,
          9),
      error(WarningCode.UNUSED_ELEMENT, 45, 9),
    ]);
  }

  test_insideFunctionAugmentation_localVariable_noInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f() {
  int augmented;
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 44,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 44, 9),
    ]);
  }

  test_insideFunctionAugmentation_localVariable_withInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment void f() {
  var augmented = 0;
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 44,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 44, 9),
    ]);
  }
}
