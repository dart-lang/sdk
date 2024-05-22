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
import augment 'test.dart';

class A {
  void f() {}
}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment void f() {
    int augmented;
  }
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 74,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 74, 9),
    ]);
  }

  test_insideFunctionAugmentation_declaredVariablePattern_assignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f() {
  var (augmented,) = (0,);
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 53,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 53, 9),
    ]);
  }

  test_insideFunctionAugmentation_declaredVariablePattern_match() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f() {
  if ((0,) case (var augmented,)) {}
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 67,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 67, 9),
    ]);
  }

  test_insideFunctionAugmentation_formalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f(int a) {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f(int augmented) {}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 46,
          9),
    ]);
  }

  test_insideFunctionAugmentation_localFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f() {
  void augmented() {}
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 53,
          9),
      error(WarningCode.UNUSED_ELEMENT, 53, 9),
    ]);
  }

  test_insideFunctionAugmentation_localVariable_noInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f() {
  int augmented;
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 52,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 52, 9),
    ]);
  }

  test_insideFunctionAugmentation_localVariable_withInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void f() {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void f() {
  var augmented = 0;
}
''', [
      error(ParserErrorCode.DECLARATION_NAMED_AUGMENTED_INSIDE_AUGMENTATION, 52,
          9),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 52, 9),
    ]);
  }
}
