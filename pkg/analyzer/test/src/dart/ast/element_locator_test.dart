// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementLocatorTest2);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ElementLocatorTest2 extends PubPackageResolutionTest {
  test_locate_AssignedVariablePattern() async {
    await resolveTestCode(r'''
void f() {
  int foo;
  (foo, _) = (0, 1);
}
''');
    var node = findNode.assignedVariablePattern('foo,');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
foo@17
''');
  }

  test_locate_AssignmentExpression() async {
    await resolveTestCode(r'''
int x = 0;
void main() {
  x += 1;
}
''');
    var node = findNode.assignment('+=');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_BinaryExpression() async {
    await resolveTestCode('var x = 3 + 4');
    var node = findNode.binary('+');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_CatchClauseParameter() async {
    await resolveTestCode(r'''
void f() {
  try {} catch (e, s) {}
}
''');
    var node = findNode.catchClauseParameter('e');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
e@27
''');
    node = findNode.catchClauseParameter('s');
    element = ElementLocator.locate(node);
    _assertElement(element, r'''
s@30
''');
  }

  test_locate_ClassDeclaration() async {
    await resolveTestCode('class A {}');
    var node = findNode.classDeclaration('class');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A
''');
  }

  test_locate_ConstructorDeclaration_named() async {
    await resolveTestCode(r'''
class A {
  A.foo();
}
''');
    var node = findNode.constructor('A.foo()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::foo
''');
  }

  test_locate_ConstructorDeclaration_unnamed() async {
    await resolveTestCode(r'''
class A {
  A();
}
''');
    var node = findNode.constructor('A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_ConstructorSelector_EnumConstantArguments_EnumConstantDeclaration() async {
    await resolveTestCode(r'''
enum E {
  v.named(); // 0
  const E.named();
}
''');
    var node = findNode.constructorSelector('named(); // 0');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@enum::E::@constructor::named
''');
  }

  test_locate_DeclaredVariablePattern() async {
    await resolveTestCode(r'''
void f(Object? x) {
  if (x case int foo) {}
}
''');
    var node = findNode.declaredVariablePattern('foo');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
foo@37
''');
  }

  test_locate_DotShorthandConstructorInvocation() async {
    await resolveTestCode(r'''
class A {}

void main() {
 A a = .new();
}
''');
    var node = findNode.singleDotShorthandConstructorInvocation;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_DotShorthandInvocation() async {
    await resolveTestCode(r'''
class A {
  static A foo() => A();
}

void main() {
 A a = .foo();
}
''');
    var node = findNode.singleDotShorthandInvocation;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_DotShorthandPropertyAccess() async {
    await resolveTestCode(r'''
class A {
  static A foo = A();
}

void main() {
 A a = .foo;
}
''');
    var node = findNode.singleDotShorthandPropertyAccess;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@getter::foo
''');
  }

  test_locate_EnumConstantDeclaration() async {
    await resolveTestCode(r'''
enum E {
  one
}
''');
    var node = findNode.enumConstantDeclaration('one');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@enum::E::@field::one
''');
  }

  test_locate_ExportDirective() async {
    await resolveTestCode("export 'dart:core';");
    var node = findNode.export('export');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core
''');
  }

  test_locate_ExtensionDeclaration() async {
    await resolveTestCode('extension A on int {}');
    var node = findNode.singleExtensionDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extension::A
''');
  }

  test_locate_ExtensionTypeDeclaration() async {
    await resolveTestCode('extension type A(int it) {}');
    var node = findNode.singleExtensionTypeDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A
''');
  }

  test_locate_FunctionDeclaration_local() async {
    await resolveTestCode(r'''
void f() {
  int g() => 3;
}
''');
    var node = findNode.functionDeclaration('g');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
g@17
''');
  }

  test_locate_FunctionDeclaration_topLevel() async {
    await resolveTestCode('int f() => 3;');
    var node = findNode.functionDeclaration('f');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_Identifier_annotationClass_namedConstructor() async {
    await resolveTestCode(r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {}
''');
    var node = findNode.simple('Class.name() parameter');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::Class
''');
  }

  test_locate_Identifier_annotationClass_unnamedConstructor() async {
    await resolveTestCode(r'''
class Class {
  const Class();
}
void main(@Class() parameter) {}
''');
    var node = findNode.simple('Class() parameter');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::Class::@constructor::new
''');
  }

  test_locate_Identifier_className() async {
    await resolveTestCode('class A {}');
    var node = findNode.classDeclaration('A');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A
''');
  }

  test_locate_Identifier_constructor_named() async {
    await resolveTestCode(r'''
class A {
  A.bar();
}
''');
    var node = findNode.constructor('bar');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::bar
''');
  }

  test_locate_Identifier_constructor_unnamed() async {
    await resolveTestCode(r'''
class A {
  A();
}
''');
    var node = findNode.simple('A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_Identifier_fieldName() async {
    await resolveTestCode('''
class A {
  var x;
}
''');
    var node = findNode.variableDeclaration('x;');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@field::x
''');
  }

  test_locate_Identifier_libraryDirective() async {
    await resolveTestCode('library foo.bar;');
    var node = findNode.simple('foo');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_Identifier_propertyAccess() async {
    await resolveTestCode(r'''
void main() {
 int x = 'foo'.length;
}
''');
    var node = findNode.simple('length');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::String::@getter::length
''');
  }

  test_locate_ImportDirective() async {
    await resolveTestCode("import 'dart:core';");
    var node = findNode.import('import');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core
''');
  }

  test_locate_IndexExpression() async {
    await resolveTestCode(r'''
void main() {
  var x = [1, 2];
  var y = x[0];
}
''');
    var node = findNode.index('[0]');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
MethodMember
  baseElement: dart:core::@class::List::@method::[]
  substitution: {E: int}
''');
  }

  test_locate_InstanceCreationExpression() async {
    await resolveTestCode(r'''
class A {}

void main() {
 new A();
}
''');
    var node = findNode.instanceCreation('new A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_InstanceCreationExpression_type_prefixedIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await resolveTestCode(r'''
import 'a.dart' as pref;

void main() {
 new pref.A();
}
''');
    var node = findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/a.dart::@class::A::@constructor::new
''');
  }

  test_locate_InstanceCreationExpression_type_simpleIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
''');
    await resolveTestCode(r'''
class A {}

void main() {
 new A();
}
''');
    var node = findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_LibraryDirective() async {
    await resolveTestCode('library foo;');
    var node = findNode.library('library');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_LibraryElement() async {
    await resolveTestCode('// only comment');

    var element = ElementLocator.locate(result.unit);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_MethodDeclaration() async {
    await resolveTestCode(r'''
class A {
  void foo() {}
}
''');
    var node = findNode.methodDeclaration('foo');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_MethodInvocation_class_callMethod_argument() async {
    await resolveTestCode(r'''
class A {
  void call(int i) {}
}
void f(A a) {
  a.call(1);
}
''');
    var node = findNode.methodInvocation('call(1)').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::call
''');
  }

  test_locate_MethodInvocation_class_callMethod_constructor() async {
    await resolveTestCode(r'''
class A {
  void call(int i) {}
}
void f() {
  A().call(1);
}
''');
    var node = findNode.methodInvocation('call(1)').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::call
''');
  }

  test_locate_MethodInvocation_function_callMethod() async {
    await resolveTestCode(r'''
void f(int i) {
  f.call(1);
}
''');
    var node = findNode.methodInvocation('call').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_MethodInvocation_method() async {
    await resolveTestCode(r'''
class A {
  void foo() {}
}

void main() {
 new A().foo();
}
''');
    var node = findNode.methodInvocation('foo();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_MethodInvocation_topLevel() async {
    await resolveTestCode(r'''
foo(x) {}

void main() {
 foo(0);
}
''');
    var node = findNode.methodInvocation('foo(0)');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::foo
''');
  }

  test_locate_MixinDeclaration() async {
    await resolveTestCode('mixin A {}');
    var node = findNode.singleMixinDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@mixin::A
''');
  }

  test_locate_PatternField() async {
    await resolveTestCode(r'''
void f(Object? x) {
  if (x case int(isEven: true)) {}
}
''');
    var node = findNode.patternField('isEven:');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::int::@getter::isEven
''');
  }

  test_locate_PostfixExpression() async {
    await resolveTestCode('int addOne(int x) => x++;');
    var node = findNode.postfix('x++');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_Prefix() async {
    await resolveTestCode(r'''
import 'dart:math' as math;

math.Random? r;
''');
    var node = findNode.importPrefixReference('math.Random');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibraryFragment>::@prefix2::math
''');
  }

  test_locate_PrefixedIdentifier() async {
    await resolveTestCode(r'''
void f(int a) {
  a.isEven;
}
''');
    var node = findNode.prefixed('a.isEven');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::int::@getter::isEven
''');
  }

  test_locate_PrefixExpression() async {
    await resolveTestCode('int addOne(int x) => ++x;');
    var node = findNode.prefix('++x');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_RepresentationDeclaration() async {
    await resolveTestCode('extension type A(int it) {}');
    var node = findNode.singleRepresentationDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A::@field::it
''');
  }

  test_locate_RepresentationDeclaration2() async {
    await resolveTestCode('extension type A.named(int it) {}');
    var node = findNode.singleRepresentationConstructorName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A::@constructor::named
''');
  }

  test_locate_StringLiteral_exportUri() async {
    newFile("$testPackageLibPath/foo.dart", '');
    await resolveTestCode("export 'foo.dart';");
    var node = findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/foo.dart
''');
  }

  test_locate_StringLiteral_expression() async {
    await resolveTestCode("var x = 'abc';");
    var node = findNode.stringLiteral('abc');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<null>
''');
  }

  test_locate_StringLiteral_importUri() async {
    newFile("$testPackageLibPath/foo.dart", '');
    await resolveTestCode("import 'foo.dart';");
    var node = findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/foo.dart
''');
  }

  test_locate_VariableDeclaration_Local() async {
    await resolveTestCode(r'''
f() {
  var x = 42;
}
''');
    var node = findNode.variableDeclaration('x =');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
x@12
''');
  }

  test_locate_VariableDeclaration_TopLevel() async {
    await resolveTestCode('var x = 42;');
    var node = findNode.variableDeclaration('x =');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@topLevelVariable::x
''');
  }

  void _assertElement(Element? element, String expected) {
    var buffer = StringBuffer();

    var sink = TreeStringSink(sink: buffer, indent: '');

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    sink.writeIndent();
    elementPrinter.writeElement2(element);

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }
}
