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
  });
}

/**
 * Test how well the parser recovers when the clauses in a class declaration are
 * out of order.
 */
@reflectiveTest
class ClassDeclarationTest extends AbstractRecoveryTest {
  @failingTest
  void test_implementsBeforeExtends() {
    // Parser crashes
    testRecovery('''
class A implements B extends C {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS], '''
class A extends C implements B {}
''');
  }

  @failingTest
  void test_implementsBeforeWith() {
    // Parser crashes
    testRecovery('''
class A extends B implements C with D {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_WITH], '''
class A extends B with D implements C {}
''');
  }

  @failingTest
  void test_implementsBeforeWithBeforeExtends() {
    // Parser crashes
    testRecovery('''
class A implements B with C extends D {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_WITH], '''
class A extends D with C implements B {}
''');
  }

  @failingTest
  void test_multipleExtends() {
    // Parser crashes
    testRecovery('''
class A extends B extends C {}
''', [ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES], '''
class A extends B {}
''');
  }

  @failingTest
  void test_multipleImplements() {
    // Parser crashes
    testRecovery('''
class A implements B implements C, D {}
''', [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES], '''
class A implements B, C, D {}
''');
  }

  @failingTest
  void test_multipleWith() {
    // Parser crashes
    testRecovery('''
class A extends B with C, D with E {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class A extends B with C, D, E {}
''');
  }

  @failingTest
  void test_withBeforeExtends() {
    // Parser crashes
    testRecovery('''
class A with B extends C {}
''', [ParserErrorCode.WITH_BEFORE_EXTENDS], '''
class A extends C with B {}
''');
  }
}

/**
 * Test how well the parser recovers when the members of a compilation unit are
 * out of order.
 */
@reflectiveTest
class CompilationUnitMemberTest extends AbstractRecoveryTest {
  void test_declarationBeforeDirective_export() {
    testRecovery('''
class C { }
export 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
export 'bar.dart';
class C { }
''');
  }

  void test_declarationBeforeDirective_import() {
    testRecovery('''
class C { }
import 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
import 'bar.dart';
class C { }
''');
  }

  void test_declarationBeforeDirective_part() {
    testRecovery('''
class C { }
part 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part 'bar.dart';
class C { }
''');
  }

  void test_declarationBeforeDirective_part_of() {
    testRecovery('''
class C { }
part of foo;
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part of foo;
class C { }
''');
  }

  void test_exportBeforeLibrary() {
    testRecovery('''
export 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
export 'bar.dart';
''');
  }

  void test_importBeforeLibrary() {
    testRecovery('''
import 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
import 'bar.dart';
''');
  }

  void test_partBeforeExport() {
    testRecovery('''
part 'foo.dart';
export 'bar.dart';
''', [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
export 'bar.dart';
part 'foo.dart';
''');
  }

  void test_partBeforeImport() {
    testRecovery('''
part 'foo.dart';
import 'bar.dart';
''', [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
import 'bar.dart';
part 'foo.dart';
''');
  }

  void test_partBeforeLibrary() {
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
  @failingTest
  void test_combinatorsBeforeAndAfterPrefix() {
    // Parser crashes
    testRecovery('''
import 'bar.dart' show A as p show B;
''', [/*ParserErrorCode.PREFIX_AFTER_COMBINATOR*/], '''
import 'bar.dart' as p show A show B;
''');
  }

  @failingTest
  void test_combinatorsBeforePrefix() {
    // Parser crashes
    testRecovery('''
import 'bar.dart' show A as p;
''', [/*ParserErrorCode.PREFIX_AFTER_COMBINATOR*/], '''
import 'bar.dart' as p show A;
''');
  }
}
