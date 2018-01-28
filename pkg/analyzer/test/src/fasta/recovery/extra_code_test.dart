// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MiscellaneousTest);
    defineReflectiveTests(ModifiersTest);
    defineReflectiveTests(MultipleTypeTest);
    defineReflectiveTests(PunctuationTest);
  });
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

  void test_getter_parameters() {
    testRecovery('''
int get g() => 0;
''', [ParserErrorCode.GETTER_WITH_PARAMETERS], '''
int get g => 0;
''');
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
