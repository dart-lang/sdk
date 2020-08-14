// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclaresConstructorTest);
  });
}

@reflectiveTest
class MixinDeclaresConstructorTest extends PubPackageResolutionTest {
  test_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
mixin M {
  final int f;
  M(this.f);
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 27, 1),
      // TODO(srawlins): Don't report this from within a mixin.
      error(
          CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, 29, 6),
    ]);

    var element = findElement.mixin('M');
    var constructorElement = element.constructors.single;

    var fpNode = findNode.fieldFormalParameter('f);');
    assertElement(fpNode.identifier, constructorElement.parameters[0]);

    FieldFormalParameterElement fpElement = fpNode.declaredElement;
    assertElement(fpElement.field, findElement.field('f'));
  }

  test_resolved() async {
    await assertErrorsInCode(r'''
mixin M {
  M(int a) {
    a; // read
  }
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
    ]);

    // Even though it is an error for a mixin to declare a constructor,
    // we still build elements for constructors, and resolve them.

    var element = findElement.mixin('M');
    var constructorElement = element.constructors.single;

    var constructorNode = findNode.constructor('M(int a)');
    assertElement(constructorNode, constructorElement);

    var aElement = constructorElement.parameters[0];
    var aNode = constructorNode.parameters.parameters[0];
    assertElement(aNode, aElement);

    var aRef = findNode.simple('a; // read');
    assertElement(aRef, aElement);
    assertType(aRef, 'int');
  }
}
