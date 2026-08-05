// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueAlreadySpecifiedInAugmentationChainTest);
  });
}

@reflectiveTest
class DefaultValueAlreadySpecifiedInAugmentationChainTest
    extends PubPackageResolutionTest {
  test_constructor_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
//       ^
// [context 1] The previous formal parameter with default value is here.

  augment A({int x = 0});
//                 ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
}
''');
  }

  test_constructor_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int x = 0]);
//       ^
// [context 1] The previous formal parameter with default value is here.

  augment A([int x = 0]);
//                 ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
}
''');
  }

  test_method_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo({int x = 0});
//              ^
// [context 1] The previous formal parameter with default value is here.

  augment void foo({int x = 0}) {}
//                        ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
}
''');
  }

  test_method_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo([int x = 0]);
//              ^
// [context 1] The previous formal parameter with default value is here.

  augment void foo([int x = 0]) {}
//                        ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
}
''');
  }

  test_topLevelFunction_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int x = 0]);
//          ^
// [context 1] The previous formal parameter with default value is here.

augment void f([int x = 0]) {}
//                    ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
''');
  }

  test_topLevelFunction_optionalPositional_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

void f([int x = 0]);
//          ^
// [context 1] The previous formal parameter with default value is here.
''',
      b: r'''
part of 'a.dart';

augment void f([int x = 0]) {}
//                    ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
''',
    });
  }

  test_topLevelFunction_optionalPositional_secondAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int x]);

augment void f([int x = 0]);
//                  ^
// [context 1] The previous formal parameter with default value is here.

augment void f([int x = 1]) {}
//                    ^
// [diag.defaultValueAlreadySpecifiedInAugmentationChain][context 1] The default value for this optional parameter was already specified in the augmentation chain.
''');
  }
}
