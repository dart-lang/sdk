// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationTest);
    defineReflectiveTests(MiscellaneousTest);
    defineReflectiveTests(ModifiersTest);
    defineReflectiveTests(MultipleTypeTest);
    defineReflectiveTests(PunctuationTest);
    defineReflectiveTests(VarianceModifierTest);
  });
}

/// Test how well the parser recovers when annotations are included in places
/// where they are not allowed.
@reflectiveTest
class AnnotationTest extends AbstractRecoveryTest {
  void test_typeArgument() {
    testRecovery(
      '''
const annotation = null;
class A<E> {}
class C {
  m() => new A<@annotation C>();
}
''',
      [ParserErrorCode.annotationOnTypeArgument],
      '''
const annotation = null;
class A<E> {}
class C {
  m() => new A<C>();
}
''',
    );
  }
}

/// Test how well the parser recovers in other cases.
@reflectiveTest
class MiscellaneousTest extends AbstractRecoveryTest {
  void test_classTypeAlias_withBody() {
    testRecovery(
      '''
class B = Object with A {}
''',
      // TODO(danrubel): Consolidate and improve error message.
      [ParserErrorCode.expectedExecutable, ParserErrorCode.expectedToken],
      '''
class B = Object with A;
''',
    );
  }

  void test_getter_parameters() {
    var content = '''
int get g(x) => 0;
''';
    var unit = parseCompilationUnit(
      content,
      codes: [ParserErrorCode.getterWithParameters],
    );
    validateTokenStream(unit.beginToken);

    var g = unit.declarations.first as FunctionDeclaration;
    var parameters = g.functionExpression.parameters!;
    expect(parameters.parameters, hasLength(1));
  }

  @failingTest
  void test_identifier_afterNamedArgument() {
    // https://github.com/dart-lang/sdk/issues/30370
    testRecovery(
      '''
a() {
  b(c: c(d: d(e: null f,),),);
}
''',
      [],
      '''
a() {
  b(c: c(d: d(e: null,),),);
}
''',
    );
  }

  void test_invalidRangeCheck() {
    parseCompilationUnit(
      '''
f(x) {
  while (1 < x < 3) {}
}
''',
      codes: [ParserErrorCode.equalityCannotBeEqualityOperand],
    );
  }

  @failingTest
  void test_listLiteralType() {
    // https://github.com/dart-lang/sdk/issues/4348
    testRecovery(
      '''
List<int> ints = List<int>[];
''',
      [],
      '''
List<int> ints = <int>[];
''',
    );
  }

  @failingTest
  void test_mapLiteralType() {
    // https://github.com/dart-lang/sdk/issues/4348
    testRecovery(
      '''
Map<int, int> map = Map<int, int>{};
''',
      [],
      '''
Map<int, int> map = <int, int>{};
''',
    );
  }

  void test_mixin_using_with_clause() {
    testRecovery(
      '''
mixin M {}
mixin N with M {}
''',
      [ParserErrorCode.mixinWithClause],
      '''
mixin M {}
mixin N {}
''',
    );
  }

  void test_multipleRedirectingInitializers() {
    testRecovery(
      '''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''',
      [],
      '''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''',
    );
  }

  @failingTest
  void test_parenInMapLiteral() {
    // https://github.com/dart-lang/sdk/issues/12100
    testRecovery(
      '''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C()),
  'c': () => new C(),
};
''',
      [ParserErrorCode.unexpectedToken],
      '''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C(),
  'c': () => new C(),
};
''',
    );
  }
}

/// Test how well the parser recovers when extra modifiers are provided.
@reflectiveTest
class ModifiersTest extends AbstractRecoveryTest {
  void test_classDeclaration_static() {
    testRecovery(
      '''
static class A {}
''',
      [ParserErrorCode.extraneousModifier],
      '''
class A {}
''',
    );
  }

  void test_methodDeclaration_const_getter() {
    testRecovery(
      '''
main() {}
const int get foo => 499;
''',
      [ParserErrorCode.extraneousModifier],
      '''
main() {}
int get foo => 499;
''',
    );
  }

  void test_methodDeclaration_const_method() {
    testRecovery(
      '''
main() {}
const int foo() => 499;
''',
      [ParserErrorCode.extraneousModifier],
      '''
main() {}
int foo() => 499;
''',
    );
  }

  void test_methodDeclaration_const_setter() {
    testRecovery(
      '''
main() {}
const set foo(v) => 499;
''',
      [ParserErrorCode.extraneousModifier],
      '''
main() {}
set foo(v) => 499;
''',
    );
  }
}

/// Test how well the parser recovers when multiple type annotations are
/// provided.
@reflectiveTest
class MultipleTypeTest extends AbstractRecoveryTest {
  @failingTest
  void test_topLevelVariable() {
    // https://github.com/dart-lang/sdk/issues/25875
    // Recovers with 'void bar() {}', which seems wrong. Seems like we should
    // keep the first type, not the second.
    testRecovery(
      '''
String void bar() { }
''',
      [ParserErrorCode.unexpectedToken],
      '''
String bar() { }
''',
    );
  }
}

/// Test how well the parser recovers when there is extra punctuation.
@reflectiveTest
class PunctuationTest extends AbstractRecoveryTest {
  @failingTest
  void test_extraComma_extendsClause() {
    // https://github.com/dart-lang/sdk/issues/22313
    testRecovery(
      '''
class A { }
class B { }
class Foo extends A, B {
  Foo() { }
}
''',
      [ParserErrorCode.unexpectedToken, ParserErrorCode.unexpectedToken],
      '''
class A { }
class B { }
class Foo extends A {
  Foo() { }
}
''',
    );
  }

  void test_extraSemicolon_afterLastClassMember() {
    testRecovery(
      '''
class C {
  foo() {};
}
''',
      [ParserErrorCode.expectedClassMember],
      '''
class C {
  foo() {}
}
''',
    );
  }

  void test_extraSemicolon_afterLastTopLevelMember() {
    testRecovery(
      '''
foo() {};
''',
      [ParserErrorCode.unexpectedToken],
      '''
foo() {}
''',
    );
  }

  void test_extraSemicolon_beforeFirstClassMember() {
    testRecovery(
      '''
class C {
  ;foo() {}
}
''',
      [ParserErrorCode.expectedClassMember],
      '''
class C {
  foo() {}
}
''',
    );
  }

  @failingTest
  void test_extraSemicolon_beforeFirstTopLevelMember() {
    // This test fails because the beginning token for the invalid unit is the
    // semicolon, despite the fact that it was skipped.
    testRecovery(
      '''
;foo() {}
''',
      [ParserErrorCode.expectedExecutable],
      '''
foo() {}
''',
    );
  }

  void test_extraSemicolon_betweenClassMembers() {
    testRecovery(
      '''
class C {
  foo() {};
  bar() {}
}
''',
      [ParserErrorCode.expectedClassMember],
      '''
class C {
  foo() {}
  bar() {}
}
''',
    );
  }

  void test_extraSemicolon_betweenTopLevelMembers() {
    testRecovery(
      '''
foo() {};
bar() {}
''',
      [ParserErrorCode.unexpectedToken],
      '''
foo() {}
bar() {}
''',
    );
  }
}

/// Test how well the parser recovers when there is extra variance modifiers.
@reflectiveTest
class VarianceModifierTest extends AbstractRecoveryTest {
  void test_extraModifier_inClass() {
    testRecovery(
      '''
class A<in out X> {}
''',
      [ParserErrorCode.multipleVarianceModifiers],
      '''
class A<in X> {}
''',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: [Feature.variance.enableString],
      ),
    );
  }
}
