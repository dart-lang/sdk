// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/resolved_ast_printer.dart';
import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
    defineReflectiveTests(MetadataResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class MetadataResolutionTest extends PubPackageResolutionTest {
  test_genericClass_instanceGetter() async {
    await resolveTestCode(r'''
class A<T> {
  T get foo {}
}

@A.foo
void f() {}
''');

    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@getter::foo
    staticType: null
''');
  }

  test_genericClass_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A.named();
}

@A.named()
void f() {}
''');

    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  arguments: ArgumentList
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: dynamic}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: dynamic}
    staticType: null
''');
  }

  test_genericClass_staticGetter() async {
    await resolveTestCode(r'''
class A<T> {
  static T get foo {}
}

@A.foo
void f() {}
''');

    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@getter::foo
    staticType: null
''');
  }

  test_genericClass_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A();
}

@A()
void f() {}
''');

    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  arguments: ArgumentList
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: dynamic}
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
''');
  }

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
          staticElement: self::@class::A::@constructor::•
          type: TypeName
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A
            type: A
        staticType: A
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
''');
  }

  test_otherLibrary_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

B b;
''');

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    assertType(value.type, 'A');
    expect(value.getField('f').toIntValue(), 42);
  }

  test_otherLibrary_constructor_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
import 'a.dart';

@A(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

B b;
''');

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    assertType(value.type, 'A');
    expect(value.getField('f').toIntValue(), 42);
  }

  test_otherLibrary_implicitConst() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    await assertNoErrorsInCode(r'''
import 'a.dart';

C c;
''');

    var classC = findNode.typeName('C c;').name.staticElement;
    var annotation = classC.metadata.single;
    var value = annotation.computeConstantValue();
    assertType(value.type, 'B');
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
    assertType(value.type, 'A<int>');
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

@reflectiveTest
class MetadataResolutionWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_optIn_fromOptOut_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A(0)
void f() {}
''');

    assertElement2(
      findNode.simple('A('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.unnamedConstructor('A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int a;
  const A.named(this.a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.named(42)
void f() {}
''');

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );

    _assertConstantValue(
      findElement.function('f').metadata[0].computeConstantValue(),
      type: 'A*',
      fieldMap: {'a': 42},
    );
  }

  test_optIn_fromOptOut_class_constructor_withDefault() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int a;
  const A.named({this.a = 42});
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.named()
void f() {}
''');

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );

    _assertConstantValue(
      findElement.function('f').metadata[0].computeConstantValue(),
      type: 'A*',
      fieldMap: {'a': 42},
    );
  }

  test_optIn_fromOptOut_class_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const foo = 42;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.foo
void f() {}
''');

    assertElement2(
      findNode.simple('A.foo'),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A.foo'),
      declaration: import_a.getter('foo'),
      isLegacy: true,
    );

    _assertIntValue(findElement.function('f').metadata[0], 42);
  }

  test_optIn_fromOptOut_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const foo = 42;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@foo
void f() {}
''');

    assertElement2(
      findNode.annotation('@foo'),
      declaration: import_a.topGet('foo'),
      isLegacy: true,
    );

    _assertIntValue(findElement.function('f').metadata[0], 42);
  }

  test_optIn_fromOptOut_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A(0)
void f() {}
''');

    assertElement2(
      findNode.simple('A('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.unnamedConstructor('A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A.named(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A.named(0)
void f() {}
''');

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_class_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A.foo
void f() {}
''');

    assertElement2(
      findNode.simple('A.foo'),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.getter('foo'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const foo = 0;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.foo
void f() {}
''');

    assertElement2(
      findNode.annotation('@a.foo'),
      declaration: import_a.topGet('foo'),
      isLegacy: true,
    );
  }

  void _assertConstantValue(
    DartObject object, {
    @required String type,
    Map<String, Object> fieldMap,
    int intValue,
  }) {
    assertType(object.type, type);
    if (fieldMap != null) {
      for (var entry in fieldMap.entries) {
        var actual = object.getField(entry.key);
        var expected = entry.value;
        if (expected is int) {
          expect(actual.toIntValue(), expected);
        } else {
          fail('Unsupported expected type: ${expected.runtimeType} $expected');
        }
      }
    } else if (intValue != null) {
      expect(object.toIntValue(), intValue);
    } else {
      fail('No expectations.');
    }
  }

  void _assertIntValue(ElementAnnotation annotation, int intValue) {
    _assertConstantValue(
      annotation.computeConstantValue(),
      type: 'int',
      intValue: intValue,
    );
  }
}
