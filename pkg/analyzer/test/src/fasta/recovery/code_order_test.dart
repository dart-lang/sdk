// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(CompilationUnitMemberTest);
    defineReflectiveTests(ImportDirectiveTest);
    defineReflectiveTests(MisplacedMetadataTest);
    defineReflectiveTests(MixinDeclarationTest);
    defineReflectiveTests(TryStatementTest);
  });
}

/// Test how well the parser recovers when the clauses in a class declaration
/// are out of order.
@reflectiveTest
class ClassDeclarationTest extends AbstractRecoveryTest {
  void test_implementsBeforeExtends() {
    testRecovery(
      '''
class A implements B extends C {}
''',
      [ParserErrorCode.implementsBeforeExtends],
      '''
class A extends C implements B {}
''',
    );
  }

  void test_implementsBeforeWith() {
    testRecovery(
      '''
class A extends B implements C with D {}
''',
      [ParserErrorCode.implementsBeforeWith],
      '''
class A extends B with D implements C {}
''',
    );
  }

  void test_implementsBeforeWithBeforeExtends() {
    testRecovery(
      '''
class A implements B with C extends D {}
''',
      [ParserErrorCode.implementsBeforeWith, ParserErrorCode.withBeforeExtends],
      '''
class A extends D with C implements B {}
''',
    );
  }

  void test_multipleExtends() {
    testRecovery(
      '''
class A extends B extends C {}
''',
      [ParserErrorCode.multipleExtendsClauses],
      '''
class A extends B {}
''',
    );
  }

  void test_multipleImplements() {
    testRecovery(
      '''
class A implements B implements C, D {}
''',
      [ParserErrorCode.multipleImplementsClauses],
      '''
class A implements B, C, D {}
''',
    );
  }

  void test_multipleWith() {
    testRecovery(
      '''
class A extends B with C, D with E {}
''',
      [ParserErrorCode.multipleWithClauses],
      '''
class A extends B with C, D, E {}
''',
    );
  }

  @failingTest
  void test_typing_extends() {
    testRecovery(
      '''
class Foo exte
class UnrelatedClass extends Bar {}
''',
      [ParserErrorCode.multipleWithClauses],
      '''
class Foo {}
class UnrelatedClass extends Bar {}
''',
    );
  }

  void test_typing_extends_identifier() {
    testRecovery(
      '''
class Foo extends CurrentlyTypingHere
class UnrelatedClass extends Bar {}
''',
      [ParserErrorCode.expectedClassBody],
      '''
class Foo extends CurrentlyTypingHere {}
class UnrelatedClass extends Bar {}
''',
    );
  }

  void test_withBeforeExtends() {
    testRecovery(
      '''
class A with B extends C {}
''',
      [ParserErrorCode.withBeforeExtends],
      '''
class A extends C with B {}
''',
    );
  }
}

/// Test how well the parser recovers when the members of a compilation unit are
/// out of order.
@reflectiveTest
class CompilationUnitMemberTest extends AbstractRecoveryTest {
  void test_declarationBeforeDirective_export() {
    testRecovery(
      '''
class C { }
export 'bar.dart';
''',
      [ParserErrorCode.directiveAfterDeclaration],
      '''
export 'bar.dart';
class C { }
''',
    );
  }

  void test_declarationBeforeDirective_import() {
    testRecovery(
      '''
class C { }
import 'bar.dart';
''',
      [ParserErrorCode.directiveAfterDeclaration],
      '''
import 'bar.dart';
class C { }
''',
    );
  }

  void test_declarationBeforeDirective_part() {
    testRecovery(
      '''
class C { }
part 'bar.dart';
''',
      [ParserErrorCode.directiveAfterDeclaration],
      '''
part 'bar.dart';
class C { }
''',
    );
  }

  void test_declarationBeforeDirective_part_of() {
    testRecovery(
      '''
class C { }
part of foo;
''',
      [ParserErrorCode.directiveAfterDeclaration],
      '''
part of foo;
class C { }
''',
    );
  }

  void test_exportBeforeLibrary() {
    testRecovery(
      '''
export 'bar.dart';
library l;
''',
      [ParserErrorCode.libraryDirectiveNotFirst],
      '''
library l;
export 'bar.dart';
''',
      adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd,
    );
  }

  void test_importBeforeLibrary() {
    testRecovery(
      '''
import 'bar.dart';
library l;
''',
      [ParserErrorCode.libraryDirectiveNotFirst],
      '''
library l;
import 'bar.dart';
''',
      adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd,
    );
  }

  void test_partBeforeLibrary() {
    testRecovery(
      '''
part 'foo.dart';
library l;
''',
      [ParserErrorCode.libraryDirectiveNotFirst],
      '''
library l;
part 'foo.dart';
''',
      adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd,
    );
  }

  CompilationUnitImpl _moveFirstDirectiveToEnd(CompilationUnitImpl unit) {
    return CompilationUnitImpl(
      beginToken: unit.directives.skip(1).first.beginToken,
      scriptTag: unit.scriptTag,
      directives: [...unit.directives.skip(1), unit.directives.first],
      declarations: unit.declarations,
      endToken: unit.endToken,
      featureSet: unit.featureSet,
      languageVersion: unit.languageVersion,
      lineInfo: unit.lineInfo,
      invalidNodes: [],
    );
  }
}

/// Test how well the parser recovers when the members of an import directive
/// are out of order.
@reflectiveTest
class ImportDirectiveTest extends AbstractRecoveryTest {
  void test_combinatorsBeforeAndAfterPrefix() {
    testRecovery(
      '''
import 'bar.dart' show A as p show B;
''',
      [ParserErrorCode.prefixAfterCombinator],
      '''
import 'bar.dart' as p show A show B;
''',
    );
  }

  void test_combinatorsBeforePrefix() {
    testRecovery(
      '''
import 'bar.dart' show A as p;
''',
      [ParserErrorCode.prefixAfterCombinator],
      '''
import 'bar.dart' as p show A;
''',
    );
  }

  void test_combinatorsBeforePrefixAfterDeferred() {
    testRecovery(
      '''
import 'bar.dart' deferred show A as p;
''',
      [ParserErrorCode.prefixAfterCombinator],
      '''
import 'bar.dart' deferred as p show A;
''',
    );
  }

  void test_deferredAfterPrefix() {
    testRecovery(
      '''
import 'bar.dart' as p deferred;
''',
      [ParserErrorCode.deferredAfterPrefix],
      '''
import 'bar.dart' deferred as p;
''',
    );
  }

  void test_duplicatePrefix() {
    testRecovery(
      '''
import 'bar.dart' as p as q;
''',
      [ParserErrorCode.duplicatePrefix],
      '''
import 'bar.dart' as p;
''',
    );
  }

  void test_unknownTokenAtEnd() {
    testRecovery(
      '''
import 'bar.dart' as p sh;
''',
      [ParserErrorCode.unexpectedToken],
      '''
import 'bar.dart' as p;
''',
    );
  }

  void test_unknownTokenBeforePrefix() {
    testRecovery(
      '''
import 'bar.dart' d as p;
''',
      [ParserErrorCode.unexpectedToken],
      '''
import 'bar.dart' as p;
''',
    );
  }

  void test_unknownTokenBeforePrefixAfterCombinatorMissingSemicolon() {
    testRecovery(
      '''
import 'bar.dart' d show A as p
import 'b.dart';
''',
      [
        ParserErrorCode.unexpectedToken,
        ParserErrorCode.prefixAfterCombinator,
        ParserErrorCode.expectedToken,
      ],
      '''
import 'bar.dart' as p show A;
import 'b.dart';
''',
    );
  }

  void test_unknownTokenBeforePrefixAfterDeferred() {
    testRecovery(
      '''
import 'bar.dart' deferred s as p;
''',
      [ParserErrorCode.unexpectedToken],
      '''
import 'bar.dart' deferred as p;
''',
    );
  }
}

/// Test how well the parser recovers when metadata appears in invalid places.
@reflectiveTest
class MisplacedMetadataTest extends AbstractRecoveryTest {
  @failingTest
  void test_field_afterType() {
    // This test fails because `findMemberName` doesn't recognize that the `@`
    // isn't a valid token in the stream leading up to a member name. That
    // causes `parseMethod` to attempt to parse from the `x` as a function body.
    testRecovery(
      '''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}
''',
      [ParserErrorCode.unexpectedToken],
      '''
class A {
  const A([x]);
}
class B {
  @A(const A()) dynamic x;
}
''',
    );
  }
}

/// Test how well the parser recovers when the clauses in a mixin declaration
/// are out of order.
@reflectiveTest
class MixinDeclarationTest extends AbstractRecoveryTest {
  void test_implementsBeforeOn() {
    testRecovery(
      '''
mixin A implements B on C {}
''',
      [ParserErrorCode.implementsBeforeOn],
      '''
mixin A on C implements B {}
''',
    );
  }

  void test_multipleImplements() {
    testRecovery(
      '''
mixin A implements B implements C, D {}
''',
      [ParserErrorCode.multipleImplementsClauses],
      '''
mixin A implements B, C, D {}
''',
    );
  }

  void test_multipleOn() {
    testRecovery(
      '''
mixin A on B on C {}
''',
      [ParserErrorCode.multipleOnClauses],
      '''
mixin A on B, C {}
''',
    );
  }

  @failingTest
  void test_typing_implements() {
    testRecovery(
      '''
mixin Foo imple
mixin UnrelatedMixin on Bar {}
''',
      [ParserErrorCode.multipleWithClauses],
      '''
mixin Foo {}
mixin UnrelatedMixin on Bar {}
''',
    );
  }

  void test_typing_implements_identifier() {
    testRecovery(
      '''
mixin Foo implements CurrentlyTypingHere
mixin UnrelatedMixin on Bar {}
''',
      [ParserErrorCode.expectedMixinBody],
      '''
mixin Foo implements CurrentlyTypingHere {}
mixin UnrelatedMixin on Bar {}
''',
    );
  }
}

/// Test how well the parser recovers when the clauses in a try statement are
/// out of order.
@reflectiveTest
class TryStatementTest extends AbstractRecoveryTest {
  @failingTest
  void test_finallyBeforeCatch() {
    testRecovery(
      '''
f() {
  try {
  } finally {
  } catch (e) {
  }
}
''',
      [/*ParserErrorCode.CATCH_AFTER_FINALLY*/],
      '''
f() {
  try {
  } catch (e) {
  } finally {
  }
}
''',
    );
  }

  @failingTest
  void test_finallyBeforeOn() {
    testRecovery(
      '''
f() {
  try {
  } finally {
  } on String {
  }
}
''',
      [/*ParserErrorCode.CATCH_AFTER_FINALLY*/],
      '''
f() {
  try {
  } on String {
  } finally {
  }
}
''',
    );
  }
}
