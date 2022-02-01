// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDisallowedClassTest);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDisallowedClassTest
    extends PubPackageResolutionTest {
  test_int() async {
    await assertErrorsInCode(r'''
mixin M on int {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
          11, 3),
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, ['int']);

    var typeRef = findNode.namedType('int {}');
    assertNamedType(typeRef, intElement, 'int');
  }
}
