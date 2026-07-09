// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int foo;
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
  (foo, _) = (0, 1);
}
''');
    var node = result.findNode.assignedVariablePattern('foo,');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
foo@17
''');
  }

  test_locate_AssignmentExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int x = 0;
void main() {
  x += 1;
}
''');
    var node = result.findNode.assignment('+=');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_BinaryExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 3 + 4;
''');
    var node = result.findNode.binary('+');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_CatchClauseParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e, s) {}
//                 ^
// [diag.unusedCatchStack] The stack trace variable 's' isn't used and can be removed.
}
''');
    var node = result.findNode.catchClauseParameter('e');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
e@27
''');
    node = result.findNode.catchClauseParameter('s');
    element = ElementLocator.locate(node);
    _assertElement(element, r'''
s@30
''');
  }

  test_locate_ClassDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
''');
    var node = result.findNode.classDeclaration('class');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A
''');
  }

  test_locate_ConstructorDeclaration_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}
''');
    var node = result.findNode.constructor('A.foo()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::foo
''');
  }

  test_locate_ConstructorDeclaration_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
''');
    var node = result.findNode.constructor('A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_ConstructorSelector_EnumConstantArguments_EnumConstantDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named(); // 0
  const E.named();
}
''');
    var node = result.findNode.constructorSelector('named(); // 0');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@enum::E::@constructor::named
''');
  }

  test_locate_DeclaredVariablePattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int foo) {}
//               ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    var node = result.findNode.declaredVariablePattern('foo');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
foo@37
''');
  }

  test_locate_DotShorthandConstructorInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void main() {
 A a = .new();
// ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleDotShorthandConstructorInvocation;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_DotShorthandInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static A foo() => A();
}

void main() {
 A a = .foo();
// ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleDotShorthandInvocation;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_DotShorthandPropertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static A foo = A();
}

void main() {
 A a = .foo;
// ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleDotShorthandPropertyAccess;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@getter::foo
''');
  }

  test_locate_DottedName_libraryDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library foo.bar;
''');
    var node = result.findNode.singleDottedName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_EnumConstantDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  one
}
''');
    var node = result.findNode.enumConstantDeclaration('one');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@enum::E::@field::one
''');
  }

  test_locate_ExportDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'dart:core';
''');
    var node = result.findNode.export('export');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core
''');
  }

  test_locate_ExtensionDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A on int {}
''');
    var node = result.findNode.singleExtensionDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extension::A
''');
  }

  test_locate_ExtensionTypeDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
''');
    var node = result.findNode.singleExtensionTypeDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A
''');
  }

  test_locate_FunctionDeclaration_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int g() => 3;
//    ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
    var node = result.findNode.functionDeclaration('g');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
g@17
''');
  }

  test_locate_FunctionDeclaration_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() => 3;
''');
    var node = result.findNode.functionDeclaration('f');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_Identifier_annotationClass_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {}
''');
    var node = result.findNode.simple('Class.name() parameter');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::Class
''');
  }

  test_locate_Identifier_annotationClass_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Class {
  const Class();
}
void main(@Class() parameter) {}
''');
    var node = result.findNode.simple('Class() parameter');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::Class::@constructor::new
''');
  }

  test_locate_Identifier_className() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
''');
    var node = result.findNode.classDeclaration('A');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A
''');
  }

  test_locate_Identifier_constructor_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A.bar();
}
''');
    var node = result.findNode.constructor('bar');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::bar
''');
  }

  test_locate_Identifier_constructor_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
''');
    var node = result.findNode.simple('A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_Identifier_fieldName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var x;
}
''');
    var node = result.findNode.variableDeclaration('x;');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@field::x
''');
  }

  test_locate_Identifier_functionCallMethod_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  f.call(a);
}
''');
    var node = result.findNode.methodInvocation('call');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_Identifier_functionCallMethod_tearOff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  f.call;
}
''');
    var node = result.findNode.prefixed('f.call').identifier;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_Identifier_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
 int x = 'foo'.length;
//   ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
    var node = result.findNode.simple('length');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::String::@getter::length
''');
  }

  test_locate_ImportDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';
''');
    var node = result.findNode.import('import');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core
''');
  }

  test_locate_IndexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
  var x = [1, 2];
  var y = x[0];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
    var node = result.findNode.index('[0]');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
SubstitutedMethodElementImpl
  baseElement: dart:core::@class::List::@method::[]
  substitution: {E: int}
''');
  }

  test_locate_InstanceCreationExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void main() {
 new A();
}
''');
    var node = result.findNode.instanceCreation('new A()');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_InstanceCreationExpression_type_prefixedIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as pref;

void main() {
 new pref.A();
}
''');
    var node = result.findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/a.dart::@class::A::@constructor::new
''');
  }

  test_locate_InstanceCreationExpression_type_simpleIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void main() {
 new A();
}
''');
    var node = result.findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_LibraryDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library foo;
''');
    var node = result.findNode.library('library');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_LibraryElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// only comment
''');

    var element = ElementLocator.locate(result.unit);
    _assertElement(element, r'''
<testLibrary>
''');
  }

  test_locate_MethodDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
''');
    var node = result.findNode.methodDeclaration('foo');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_MethodInvocation_class_callMethod_argument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int i) {}
}
void f(A a) {
  a.call(1);
}
''');
    var node = result.findNode.methodInvocation('call(1)').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::call
''');
  }

  test_locate_MethodInvocation_class_callMethod_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call(int i) {}
}
void f() {
  A().call(1);
}
''');
    var node = result.findNode.methodInvocation('call(1)').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::call
''');
  }

  test_locate_MethodInvocation_function_callMethod_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int i) {
  f.call(1);
}
''');
    var node = result.findNode.methodInvocation('call').methodName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_MethodInvocation_function_callMethod_tearOff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int i) {
  f.call;
}
''');
    var node = result.findNode.prefixed('call').identifier;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_MethodInvocation_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

void main() {
 new A().foo();
}
''');
    var node = result.findNode.methodInvocation('foo();');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@method::foo
''');
  }

  test_locate_MethodInvocation_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
foo(x) {}

void main() {
 foo(0);
}
''');
    var node = result.findNode.methodInvocation('foo(0)');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::foo
''');
  }

  test_locate_MixinDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {}
''');
    var node = result.findNode.singleMixinDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@mixin::A
''');
  }

  test_locate_PatternField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int(isEven: true)) {}
}
''');
    var node = result.findNode.patternField('isEven:');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::int::@getter::isEven
''');
  }

  test_locate_PostfixExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int addOne(int x) => x++;
''');
    var node = result.findNode.postfix('x++');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_Prefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

math.Random? r;
''');
    var node = result.findNode.importPrefixReference('math.Random');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibraryFragment>::@prefix::math
''');
  }

  test_locate_PrefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a.isEven;
}
''');
    var node = result.findNode.prefixed('a.isEven');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::int::@getter::isEven
''');
  }

  test_locate_PrefixedIdentifier_functionCallMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  f.call;
}
''');
    var node = result.findNode.prefixed('f.call');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@function::f
''');
  }

  test_locate_PrefixExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int addOne(int x) => ++x;
''');
    var node = result.findNode.prefix('++x');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
dart:core::@class::num::@method::+
''');
  }

  test_locate_PrimaryConstructorBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A() { this { } }
''');
    var node = result.findNode.singlePrimaryConstructorBody;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::new
''');
  }

  test_locate_PrimaryConstructorDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
''');
    var node = result.findNode.singlePrimaryConstructorDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A
''');
  }

  test_locate_PrimaryConstructorDeclaration_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {}
''');
    var node = result.findNode.singlePrimaryConstructorDeclaration;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A
''');
  }

  test_locate_PrimaryConstructorDeclaration_named_atConstructorName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {}
''');
    var node =
        result.findNode.singlePrimaryConstructorDeclaration.constructorName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@extensionType::A::@constructor::named
''');
  }

  test_locate_PrimaryConstructorDeclaration_namedConstructor_constructorName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A.named() {}
''');
    var node =
        result.findNode.singlePrimaryConstructorDeclaration.constructorName;
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<testLibrary>::@class::A::@constructor::named
''');
  }

  test_locate_StringLiteral_exportUri() async {
    newFile("$testPackageLibPath/foo.dart", '');
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'foo.dart';
''');
    var node = result.findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/foo.dart
''');
  }

  test_locate_StringLiteral_expression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 'abc';
''');
    var node = result.findNode.stringLiteral('abc');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
<null>
''');
  }

  test_locate_StringLiteral_importUri() async {
    newFile("$testPackageLibPath/foo.dart", '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
//     ^^^^^^^^^^
// [diag.unusedImport] Unused import: 'foo.dart'.
''');
    var node = result.findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
package:test/foo.dart
''');
  }

  test_locate_VariableDeclaration_Local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f() {
  var x = 42;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
    var node = result.findNode.variableDeclaration('x =');
    var element = ElementLocator.locate(node);
    _assertElement(element, r'''
x@12
''');
  }

  test_locate_VariableDeclaration_TopLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 42;
''');
    var node = result.findNode.variableDeclaration('x =');
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
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }
}
