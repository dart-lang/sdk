// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(CompilationUnitMemberTest);
    defineReflectiveTests(ImportDirectiveTest);
    defineReflectiveTests(TryStatementTest);
  });
}

/**
 * Test how well the parser recovers when the clauses in a class declaration are
 * out of order.
 */
@reflectiveTest
class ClassDeclarationTest extends AbstractRecoveryTest {
  void test_implementsBeforeExtends() {
    testRecovery('''
class A implements B extends C {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS], '''
class A extends C implements B {}
''');
  }

  void test_implementsBeforeWith() {
    testRecovery('''
class A extends B implements C with D {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_WITH], '''
class A extends B with D implements C {}
''');
  }

  void test_implementsBeforeWithBeforeExtends() {
    testRecovery('''
class A implements B with C extends D {}
''', [
      ParserErrorCode.IMPLEMENTS_BEFORE_WITH,
      ParserErrorCode.WITH_BEFORE_EXTENDS
    ], '''
class A extends D with C implements B {}
''');
  }

  void test_multipleExtends() {
    testRecovery('''
class A extends B extends C {}
''', [ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES], '''
class A extends B {}
''');
  }

  void test_multipleImplements() {
    testRecovery('''
class A implements B implements C, D {}
''', [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES], '''
class A implements B, C, D {}
''');
  }

  void test_multipleWith() {
    testRecovery('''
class A extends B with C, D with E {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class A extends B with C, D, E {}
''');
  }

  @failingTest
  void test_typing_extends() {
    testRecovery('''
class Foo exte
class UnrelatedClass extends Bar {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class Foo {}
class UnrelatedClass extends Bar {}
''');
  }

  @failingTest
  void test_typing_extends_identifier() {
    testRecovery('''
class Foo extends CurrentlyTypingHere
class UnrelatedClass extends Bar {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class Foo extends CurrentlyTypingHere {}
class UnrelatedClass extends Bar {}
''');
  }

  void test_withBeforeExtends() {
    testRecovery('''
class A with B extends C {}
''', [ParserErrorCode.WITH_BEFORE_EXTENDS], '''
class A extends C with B {}
''');
  }

  void test_withWithoutExtends() {
    testRecovery('''
class A with B, C {}
''', [ParserErrorCode.WITH_WITHOUT_EXTENDS], '''
class A with B, C {}
''', [ParserErrorCode.WITH_WITHOUT_EXTENDS]);
  }
}

/**
 * Test how well the parser recovers when the members of a compilation unit are
 * out of order.
 */
@reflectiveTest
class CompilationUnitMemberTest extends AbstractRecoveryTest {
  @failingTest
  void test_declarationBeforeDirective_export() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
class C { }
export 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
export 'bar.dart';
class C { }
''');
  }

  @failingTest
  void test_declarationBeforeDirective_import() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
class C { }
import 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
import 'bar.dart';
class C { }
''');
  }

  @failingTest
  void test_declarationBeforeDirective_part() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
class C { }
part 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part 'bar.dart';
class C { }
''');
  }

  @failingTest
  void test_declarationBeforeDirective_part_of() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
class C { }
part of foo;
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part of foo;
class C { }
''');
  }

  @failingTest
  void test_exportBeforeLibrary() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
export 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
export 'bar.dart';
''');
  }

  @failingTest
  void test_importBeforeLibrary() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
import 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
import 'bar.dart';
''');
  }

  @failingTest
  void test_partBeforeExport() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
part 'foo.dart';
export 'bar.dart';
''', [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
export 'bar.dart';
part 'foo.dart';
''');
  }

  @failingTest
  void test_partBeforeImport() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
part 'foo.dart';
import 'bar.dart';
''', [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
import 'bar.dart';
part 'foo.dart';
''');
  }

  @failingTest
  void test_partBeforeLibrary() {
    // TODO(danrubel): members are not reordered
    testRecovery('''
part 'foo.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
part 'foo.dart';
''');
  }
}

/**
 * Test how well the parser recovers when the members of an import directive are
 * out of order.
 */
@reflectiveTest
class ImportDirectiveTest extends AbstractRecoveryTest {
  void test_combinatorsBeforeAndAfterPrefix() {
    testRecovery('''
import 'bar.dart' show A as p show B;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' as p show A show B;
''');
  }

  void test_combinatorsBeforePrefix() {
    testRecovery('''
import 'bar.dart' show A as p;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' as p show A;
''');
  }

  void test_combinatorsBeforePrefixAfterDeferred() {
    testRecovery('''
import 'bar.dart' deferred show A as p;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' deferred as p show A;
''');
  }

  void test_deferredAfterPrefix() {
    testRecovery('''
import 'bar.dart' as p deferred;
''', [ParserErrorCode.DEFERRED_AFTER_PREFIX], '''
import 'bar.dart' deferred as p;
''');
  }

  void test_duplicatePrefix() {
    testRecovery('''
import 'bar.dart' as p as q;
''', [ParserErrorCode.DUPLICATE_PREFIX], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenAtEnd() {
    testRecovery('''
import 'bar.dart' as p sh;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenBeforePrefix() {
    testRecovery('''
import 'bar.dart' d as p;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenBeforePrefixAfterCombinatorMissingSemicolon() {
    testRecovery('''
import 'bar.dart' d show A as p
import 'b.dart';
''', [
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.PREFIX_AFTER_COMBINATOR,
      ParserErrorCode.EXPECTED_TOKEN
    ], '''
import 'bar.dart' as p show A;
import 'b.dart';
''');
  }

  void test_unknownTokenBeforePrefixAfterDeferred() {
    testRecovery('''
import 'bar.dart' deferred s as p;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' deferred as p;
''');
  }
}

/**
 * Test how well the parser recovers when the clauses in a try statement are
 * out of order.
 */
@reflectiveTest
class TryStatementTest extends AbstractRecoveryTest {
  @failingTest
  void test_finallyBeforeCatch() {
    testRecovery('''
f() {
  try {
  } finally {
  } catch (e) {
  }
}
''', [/*ParserErrorCode.CATCH_AFTER_FINALLY*/], '''
f() {
  try {
  } catch (e) {
  } finally {
  }
}
''');
  }

  @failingTest
  void test_finallyBeforeOn() {
    testRecovery('''
f() {
  try {
  } finally {
  } on String {
  }
}
''', [/*ParserErrorCode.CATCH_AFTER_FINALLY*/], '''
f() {
  try {
  } on String {
  } finally {
  }
}
''');
  }
}
