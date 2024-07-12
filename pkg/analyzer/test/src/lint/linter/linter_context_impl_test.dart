// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CanBeConstConstructorTest);
    defineReflectiveTests(CanBeConstInstanceCreationTest);
    defineReflectiveTests(CanBeConstTypedLiteralTest);
    defineReflectiveTests(EvaluateExpressionTest);
    defineReflectiveTests(PubDependencyTest);
  });
}

@reflectiveTest
abstract class AbstractLinterContextTest extends PubPackageResolutionTest {
  late final LinterContextWithResolvedResults context;

  Future<void> resolve(String content) async {
    await resolveTestCode(content);
    var errorReporter = ErrorReporter(
      RecordingErrorListener(),
      StringSource(result.content, null),
    );
    var contextUnit = LintRuleUnitContext(
      file: result.file,
      content: result.content,
      errorReporter: errorReporter,
      unit: result.unit,
    );

    var libraryElement = result.libraryElement;
    var analysisContext = libraryElement.session.analysisContext;
    var libraryPath = libraryElement.source.fullName;
    var workspace = analysisContext.contextRoot.workspace;
    var workspacePackage = workspace.findPackageFor(libraryPath);

    context = LinterContextWithResolvedResults(
      [contextUnit],
      contextUnit,
      result.typeProvider,
      result.typeSystem as TypeSystemImpl,
      InheritanceManager3(),
      // TODO(pq): Use a test package or consider passing in `null`.
      workspacePackage,
    );
  }
}

@reflectiveTest
class CanBeConstConstructorTest extends AbstractLinterContextTest {
  void assertCanBeConstConstructor(String search, bool expectedResult) {
    var constructor =
        findNode.constructor(search) as ConstructorDeclarationImpl;
    expect(constructor.canBeConst, expectedResult);
  }

  test_assertInitializer_parameter() async {
    await resolve(r'''
class C {
  C(int a) : assert(a >= 0, 'error');
}
''');
    assertCanBeConstConstructor('C(int a)', true);
  }

  test_empty() async {
    await resolve(r'''
class C {
  C();
}
''');
    assertCanBeConstConstructor('C()', true);
  }

  test_field_notConstInitializer() async {
    await resolve(r'''
class C {
  final int f = a;
  C();
}

var a = 0;
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_field_notFinal() async {
    await resolve(r'''
class C {
  int f = 0;
  C();
}
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_field_notFinal_inherited() async {
    await resolve(r'''
class A {
  int f = 0;
}

class B extends A {
  B();
}
''');
    assertCanBeConstConstructor('B()', false);
  }

  test_fieldInitializer_literal() async {
    await resolve(r'''
class C {
  final int f;
  C() : f = 0;
}
''');
    assertCanBeConstConstructor('C()', true);
  }

  test_fieldInitializer_notConst() async {
    await resolve(r'''
class C {
  final int f;
  C() : f = a;
}

var a = 0;
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_fieldInitializer_parameter() async {
    await resolve(r'''
class C {
  final int f;
  C(int a) : f = a;
}
''');
    assertCanBeConstConstructor('C(int a)', true);
  }
}

@reflectiveTest
class CanBeConstInstanceCreationTest extends AbstractLinterContextTest {
  void assertCanBeConst(String snippet, bool expectedResult) {
    var node = findNode.instanceCreation(snippet);
    expect(node.canBeConst, expectedResult);
  }

  void test_deferred_argument() async {
    await resolveFileCode('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}

const aa = A();
''');
    await resolve(r'''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  print(B(a.aa));
}
''');
    assertCanBeConst('B(a.aa)', false);
  }

  void test_false_argument_invocation() async {
    await resolve('''
class A {}
class B {
  const B(A a);
}
A f() => A();
B g() => B(f());
''');
    assertCanBeConst("B(f", false);
  }

  void test_false_argument_invocationInList() async {
    await resolve('''
class A {}
class B {
  const B(a);
}
A f() => A();
B g() => B([f()]);
''');
    assertCanBeConst("B([", false);
  }

  void test_false_argument_nonConstConstructor() async {
    await resolve('''
class A {}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", false);
  }

  void test_false_constructorReference_typeParameter() async {
    await resolve('''
class A<T> {
  const A();
}
class B<T> {
  final A<T> Function() fn;
  const B(this.fn);
}
B<T> fn<T>() => B(A<T>.new);
''');
    assertCanBeConst('B(A<T>.new)', false);
  }

  void test_false_mapKeyType_implementsEqual() async {
    await resolve('''
class A {
  const A();
  bool operator ==(other) => false;
}

class B {
  const B(_);
}

main() {
  B({A(): 0});
}
''');
    assertCanBeConst("B({", false);
  }

  void test_false_nonConstConstructor() async {
    await resolve('''
class A {}
A f() => A();
''');
    assertCanBeConst("A(", false);
  }

  void test_false_setElementType_implementsEqual() async {
    await resolve('''
class A {
  const A();
  bool operator ==(other) => false;
}

class B {
  const B(_);
}

main() {
  B({A()});
}
''');
    assertCanBeConst("B({", false);
  }

  void test_false_typeParameter() async {
    await resolve('''
class A<T> {
  const A();
}
f<U>() => A<U>();
''');
    assertCanBeConst("A<U>", false);
  }

  void test_true_argument_list_nonBool() async {
    await resolve('''
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');
class A {
  const A(List<int> l);
}
A f() => A([if (!kIsWeb) ...[1, 2, 3] else ...[1]]);
''');
    assertCanBeConst("A([", true);
  }

  void test_true_computeDependencies() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await resolve('''
import 'a.dart';

class A {
  const A(int a);
}

A f() => A(a);
''');
    assertCanBeConst('A(a)', true);
  }

  void test_true_constConstructor_instance() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static const A instance = const A();
  const A();
}
''');
    await resolve('''
import 'a.dart';
class B {
  final A v;
  const B(this.v);
}
B f1() => B(A.instance);
''');
    assertCanBeConst('B(A.instance)', true);
  }

  void test_true_constConstructorArg() async {
    await resolve('''
class A {
  const A();
}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", true);
  }

  void test_true_constListArg() async {
    await resolve('''
class A {
  const A(List<int> l);
}
A f() => A([1, 2, 3]);
''');
    assertCanBeConst("A([", true);
  }

  void test_true_importedClass_defaultValue() async {
    var aPath = convertPath('$testPackageLibPath/a.dart');
    newFile(aPath, r'''
class A {
  final int a;
  const A({int b = 1}) : a = b * 2;
}
''');
    await resolve('''
import 'a.dart';

A f() => A();
''');
    assertCanBeConst("A();", true);
  }
}

@reflectiveTest
class CanBeConstTypedLiteralTest extends AbstractLinterContextTest {
  void assertCanBeConst(String snippet, bool expectedResult) {
    var node = findNode.typedLiteral(snippet);
    expect(node.canBeConst, expectedResult);
  }

  void test_listLiteral_false_forElement() async {
    await resolve('''
f() => [for (var i = 0; i < 10; i++) i];
''');
    assertCanBeConst('[for', false);
  }

  void test_listLiteral_false_methodInvocation() async {
    await resolve('''
f() => [g()];
int g() => 0;
''');
    assertCanBeConst('[', false);
  }

  void test_listLiteral_false_typeParameter() async {
    await resolve('''
class A<T> {
  const A();
}

f<U>() => [A<U>()];
''');
    assertCanBeConst('[', false);
  }

  void test_listLiteral_true_computeDependencies() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await resolve('''
import 'a.dart';

f() => [a];
''');
    assertCanBeConst('[', true);
  }

  void test_listLiteral_true_constConstructor() async {
    await resolve('''
class A {
  const A();
}

f() => [A()];
''');
    assertCanBeConst('[', true);
  }

  void test_listLiteral_true_ifElement() async {
    await resolve('''
const a = true;
f() => [if (a) 0 else 1];
''');
    assertCanBeConst('[if', true);
  }

  void test_listLiteral_true_integerLiteral() async {
    await resolve('''
f() => [1, 2, 3];
''');
    assertCanBeConst('[', true);
  }

  void test_mapLiteral_false_forElement() async {
    await resolve('''
f() => {for (var i = 0; i < 10; i++) i: 0};
''');
    assertCanBeConst('{', false);
  }

  void test_mapLiteral_false_methodInvocation_key() async {
    await resolve('''
f() => {g(): 0};
int g() => 0;
''');
    assertCanBeConst('{', false);
  }

  void test_mapLiteral_false_methodInvocation_value() async {
    await resolve('''
f() => {0: g()};
int g() => 0;
''');
    assertCanBeConst('{', false);
  }

  void test_mapLiteral_true_ifElement() async {
    await resolve('''
const a = true;
f() => {if (a) 0: 0 else 1: 1};
''');
    assertCanBeConst('{', true);
  }

  void test_mapLiteral_true_integerLiteral() async {
    await resolve('''
f() => {1: 2, 3: 4};
''');
    assertCanBeConst('{', true);
  }

  void test_setLiteral_false_forElement() async {
    await resolve('''
f() => {for (var i = 0; i < 10; i++) i};
''');
    assertCanBeConst('{for', false);
  }

  void test_setLiteral_false_methodInvocation() async {
    await resolve('''
f() => {g()};
int g() => 0;
''');
    assertCanBeConst('{', false);
  }

  void test_setLiteral_true_ifElement() async {
    await resolve('''
const a = true;
f() => {if (a) 0 else 1};
''');
    assertCanBeConst('{', true);
  }

  void test_setLiteral_true_integerLiteral() async {
    await resolve('''
f() => {1, 2, 3};
''');
    assertCanBeConst('{', true);
  }
}

@reflectiveTest
class EvaluateExpressionTest extends AbstractLinterContextTest {
  test_hasError_listLiteral_forElement() async {
    await resolve('''
var x = const [for (var i = 0; i < 4; i++) i];
''');
    var result = _evaluateX();
    expect(result.errors, isNotEmpty);
    expect(result.value, isNull);
  }

  test_hasError_mapLiteral_forElement() async {
    await resolve('''
var x = const {for (var i = 0; i < 4; i++) i: 0};
''');
    var result = _evaluateX();
    expect(result.errors, isNotEmpty);
    expect(result.value, isNull);
  }

  test_hasError_methodInvocation() async {
    await resolve('''
var x = 42.abs();
''');
    var result = _evaluateX();
    expect(result.errors, isNotEmpty);
    expect(result.value, isNull);
  }

  test_hasError_setLiteral_forElement() async {
    await resolve('''
var x = const {for (var i = 0; i < 4; i++) i};
''');
    var result = _evaluateX();
    expect(result.errors, isNotEmpty);
    expect(result.value, isNull);
  }

  test_hasValue_binaryExpression() async {
    await resolve('''
var x = 1 + 2;
''');
    var result = _evaluateX();
    expect(result.errors, isEmpty);
    expect(result.value!.toIntValue(), 3);
  }

  test_hasValue_constantReference() async {
    await resolve('''
const a = 42;
var x = a;
''');
    var result = _evaluateX();
    expect(result.errors, isEmpty);
    expect(result.value!.toIntValue(), 42);
  }

  test_hasValue_constantReference_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 42;
''');
    await resolve('''
import 'a.dart';
var x = a;
''');
    var result = _evaluateX();
    expect(result.errors, isEmpty);
    expect(result.value!.toIntValue(), 42);
  }

  test_hasValue_intLiteral() async {
    await resolve('''
var x = 42;
''');
    var result = _evaluateX();
    expect(result.errors, isEmpty);
    expect(result.value!.toIntValue(), 42);
  }

  LinterConstantEvaluationResult _evaluateX() {
    var node = findNode.topVariableDeclarationByName('x').initializer!;
    return node.computeConstantValue();
  }
}

@reflectiveTest
class PubDependencyTest extends AbstractLinterContextTest {
  test_dependencies() async {
    newPubspecYamlFile(testPackageRootPath, '''
name: test

dependencies:
  args: '>=0.12.1 <2.0.0'
  charcode: ^1.1.0
''');
    await resolve(r'''
/// Dummy class.
class C { }
''');

    expect(context.package, TypeMatcher<PubPackage>());
    var pubPackage = context.package as PubPackage;
    var pubspec = pubPackage.pubspec!;

    var argsDep = pubspec.dependencies!
        .singleWhere((element) => element.name!.text == 'args');
    expect(argsDep.version!.value.text, '>=0.12.1 <2.0.0');

    var charCodeDep = pubspec.dependencies!
        .singleWhere((element) => element.name!.text == 'charcode');
    expect(charCodeDep.version!.value.text, '^1.1.0');
  }
}
