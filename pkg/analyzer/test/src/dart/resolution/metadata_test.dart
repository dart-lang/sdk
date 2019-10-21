// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/resolved_ast_printer.dart';
import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
  });
}

@reflectiveTest
class MetadataResolutionTest extends DriverResolutionTest {
  test_onFieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(_);
}

class B {
  final int f;
  B({@A( A(0) ) this.f});
}
''');
    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  arguments: ArgumentList
    arguments
      InstanceCreationExpression
        argumentList: ArgumentList
          arguments
            IntegerLiteral
              literal: 0
              staticType: int
        constructorName: ConstructorName
          type: TypeName
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A
            type: A
        staticElement: self::@class::A::@constructor::•
        staticType: A
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: Type
    token: A
''');
  }

  test_otherLibrary_constructor_named() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('/test/lib/b.dart', content: r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    await resolveTestCode(r'''
import 'b.dart';

B b;
''');
    assertNoTestErrors();

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    assertElementTypeString(value.type, 'A');
    expect(value.getField('f').toIntValue(), 42);
  }

  test_otherLibrary_constructor_unnamed() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('/test/lib/b.dart', content: r'''
import 'a.dart';

@A(42)
class B {}
''');

    await resolveTestCode(r'''
import 'b.dart';

B b;
''');
    assertNoTestErrors();

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    assertElementTypeString(value.type, 'A');
    expect(value.getField('f').toIntValue(), 42);
  }

  test_otherLibrary_implicitConst() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}

class B {
  final A a;
  const B(this.a);
}

@B( A(42) )
class C {}
''');

    await resolveTestCode(r'''
import 'a.dart';

C c;
''');
    assertNoTestErrors();

    var classC = findNode.typeName('C c;').name.staticElement;
    var annotation = classC.metadata.single;
    var value = annotation.computeConstantValue();
    assertElementTypeString(value.type, 'B');
    expect(value.getField('a').getField('f').toIntValue(), 42);
  }

  @FailingTest(reason: 'Reverted because of dartbug.com/38565')
  test_sameLibrary_genericClass_constructor_unnamed() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
class B {}
''');
    var annotation = findElement.class_('B').metadata.single;
    var value = annotation.computeConstantValue();
    assertElementTypeString(value.type, 'A<int>');
    expect(value.getField('f').toIntValue(), 42);
  }

  void _assertResolvedNodeText(AstNode node, String expected) {
    var actual = _resolvedNodeText(node);
    expect(actual, expected);
  }

  String _resolvedNodeText(AstNode node) {
    var buffer = StringBuffer();
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: result.uri.toString(),
        sink: buffer,
        indent: '',
      ),
    );
    return buffer.toString();
  }
}
