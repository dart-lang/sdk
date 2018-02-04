// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationTest);
    defineReflectiveTests(MiscellaneousTest);
    defineReflectiveTests(ModifiersTest);
    defineReflectiveTests(MultipleTypeTest);
    defineReflectiveTests(PunctuationTest);
  });
}

/**
 * Test how well the parser recovers when annotations are included in places
 * where they are not allowed.
 */
@reflectiveTest
class AnnotationTest extends AbstractRecoveryTest {
  @failingTest
  void test_typeArgument() {
    // https://github.com/dart-lang/sdk/issues/22314
    // Parser crashes
    // 'package:analyzer/src/fasta/ast_builder.dart': Failed assertion:
    //     line 256 pos 12: 'token.isKeywordOrIdentifier': is not true.
    testRecovery('''
const annotation = null;
class A<E> {}
class C {
  m() => new A<@annotation C>();
}
''', [ParserErrorCode.UNEXPECTED_TOKEN, ParserErrorCode.UNEXPECTED_TOKEN], '''
const annotation = null;
class A<E> {}
class C {
  m() => new A<C>();
}
''');
  }
}

/**
 * Test how well the parser recovers in other cases.
 */
@reflectiveTest
class MiscellaneousTest extends AbstractRecoveryTest {
  @failingTest
  void test_classTypeAlias_withBody() {
    // Parser crashes
    testRecovery('''
class B = Object with A {}
''', [ParserErrorCode.EXPECTED_TOKEN], '''
class B = Object with A;
''');
  }

  @failingTest
  void test_extraParenInMapLiteral() {
    // https://github.com/dart-lang/sdk/issues/12100
    testRecovery('''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C()),
  'c': () => new C(),
};
''', [ParserErrorCode.EXPECTED_TOKEN], '''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C(),
  'c': () => new C(),
};
''');
  }

  void test_getter_parameters() {
    testRecovery('''
int get g() => 0;
''', [ParserErrorCode.GETTER_WITH_PARAMETERS], '''
int get g => 0;
''');
  }

  void test_invalidRangeCheck() {
    parseCompilationUnit('''
f(x) {
  while (1 < x < 3) {}
}
''', codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_multipleRedirectingInitializers() {
    testRecovery('''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''', [], '''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''');
  }
}

/**
 * Test how well the parser recovers when extra modifiers are provided.
 */
@reflectiveTest
class ModifiersTest extends AbstractRecoveryTest {
  @failingTest
  void test_classDeclaration_static() {
    // TODO(danrubel): Fails because compilation unit begin token is `static`
    // even after recovery.
    testRecovery('''
static class A {}
''', [ParserErrorCode.EXTRANEOUS_MODIFIER], '''
class A {}
''');
  }
}

/**
 * Test how well the parser recovers when multiple type annotations are
 * provided.
 */
@reflectiveTest
class MultipleTypeTest extends AbstractRecoveryTest {
  @failingTest
  void test_topLevelVariable() {
    // https://github.com/dart-lang/sdk/issues/25875
    // Recovers with 'void bar() {}', which seems wrong. Seems like we should
    // keep the first type, not the second.
    testRecovery('''
String void bar() { }
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
String bar() { }
''');
  }
}

/**
 * Test how well the parser recovers when there is extra punctuation.
 */
@reflectiveTest
class PunctuationTest extends AbstractRecoveryTest {
  @failingTest
  void test_extraComma_extendsClause() {
    // https://github.com/dart-lang/sdk/issues/22313
    testRecovery('''
class A { }
class B { }
class Foo extends A, B {
  Foo() { }
}
''', [ParserErrorCode.UNEXPECTED_TOKEN, ParserErrorCode.UNEXPECTED_TOKEN], '''
class A { }
class B { }
class Foo extends A {
  Foo() { }
}
''');
  }

  void test_extraSemicolon_afterLastClassMember() {
    testRecovery('''
class C {
  foo() {};
}
''', [ParserErrorCode.EXPECTED_CLASS_MEMBER], '''
class C {
  foo() {}
}
''');
  }

  void test_extraSemicolon_afterLastTopLevelMember() {
    testRecovery('''
foo() {};
''', [ParserErrorCode.EXPECTED_EXECUTABLE], '''
foo() {}
''');
  }

  void test_extraSemicolon_beforeFirstClassMember() {
    testRecovery('''
class C {
  ;foo() {}
}
''', [ParserErrorCode.EXPECTED_CLASS_MEMBER], '''
class C {
  foo() {}
}
''');
  }

  @failingTest
  void test_extraSemicolon_beforeFirstTopLevelMember() {
    // This test fails because the beginning token for the invalid unit is the
    // semicolon, despite the fact that it was skipped.
    testRecovery('''
;foo() {}
''', [ParserErrorCode.EXPECTED_EXECUTABLE], '''
foo() {}
''');
  }

  void test_extraSemicolon_betweenClassMembers() {
    testRecovery('''
class C {
  foo() {};
  bar() {}
}
''', [ParserErrorCode.EXPECTED_CLASS_MEMBER], '''
class C {
  foo() {}
  bar() {}
}
''');
  }

  void test_extraSemicolon_betweenTopLevelMembers() {
    testRecovery('''
foo() {};
bar() {}
''', [ParserErrorCode.EXPECTED_EXECUTABLE], '''
foo() {}
bar() {}
''');
  }
}
