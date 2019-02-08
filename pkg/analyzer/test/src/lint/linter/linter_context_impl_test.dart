// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinterContextImplTest);
  });
}

@reflectiveTest
class LinterContextImplTest extends ResolverTestCase {
  String testSource;
  CompilationUnitImpl testUnit;
  LinterContextImpl context;

  bool get enableNewAnalysisDriver => true;

  void assertCanBeConst(String snippet, bool expectedResult) {
    int index = testSource.indexOf(snippet);
    expect(index >= 0, isTrue);
    NodeLocator visitor = new NodeLocator(index);
    AstNodeImpl node = visitor.searchWithin(testUnit);
    node = node.thisOrAncestorOfType<InstanceCreationExpressionImpl>();
    expect(node, isNotNull);
    expect(context.canBeConst(node as InstanceCreationExpressionImpl),
        expectedResult ? isTrue : isFalse);
  }

  Future<void> resolve(String sourceText) async {
    testSource = sourceText;
    Source source = addNamedSource('/test.dart', sourceText);
    ResolvedUnitResult analysisResult = await driver.getResult(source.fullName);
    testUnit = analysisResult.unit;
    LinterContextUnit contextUnit = new LinterContextUnit(sourceText, testUnit);
    context = new LinterContextImpl(
        [contextUnit],
        contextUnit,
        analysisResult.session.declaredVariables,
        analysisResult.typeProvider,
        analysisResult.typeSystem,
        analysisOptions);
  }

  void test_canBeConst_false_argument_invocation() async {
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

  void test_canBeConst_false_argument_invocationInList() async {
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

  void test_canBeConst_false_argument_nonConstConstructor() async {
    await resolve('''
class A {}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", false);
  }

  void test_canBeConst_false_nonConstConstructor() async {
    await resolve('''
class A {}
A f() => A();
''');
    assertCanBeConst("A(", false);
  }

  void test_canBeConst_true_constConstructorArg() async {
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

  void test_canBeConst_true_constListArg() async {
    await resolve('''
class A {
  const A(List<int> l);
}
A f() => A([1, 2, 3]);
''');
    assertCanBeConst("A([", true);
  }
}
