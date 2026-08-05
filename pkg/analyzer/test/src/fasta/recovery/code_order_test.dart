// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(CompilationUnitMemberTest);
    defineReflectiveTests(ImportDirectiveTest);
    defineReflectiveTests(MisplacedMetadataTest);
    defineReflectiveTests(MixinDeclarationTest);
    defineReflectiveTests(TryStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test how well the parser recovers when the clauses in a class declaration
/// are out of order.
@reflectiveTest
class ClassDeclarationTest extends ParserDiagnosticsTest {
  void test_implementsBeforeExtends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B extends C {}
//                   ^^^^^^^
// [diag.implementsBeforeExtends] The extends clause must be before the implements clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: C
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_implementsBeforeWith() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements C with D {}
//                             ^^^^
// [diag.implementsBeforeWith] The with clause must be before the implements clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: D
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_implementsBeforeWithBeforeExtends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B with C extends D {}
//                   ^^^^
// [diag.implementsBeforeWith] The with clause must be before the implements clause.
//                          ^^^^^^^
// [diag.withBeforeExtends] The extends clause must be before the with clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: D
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleExtends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B extends C {}
//                ^^^^^^^
// [diag.multipleExtendsClauses] Each class definition can have at most one extends clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B implements C, D {}
//                   ^^^^^^^^^^
// [diag.multipleImplementsClauses] Each class or mixin definition can have at most one implements clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: C
          NamedType
            name: D
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleWith() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C, D with E {}
//                          ^^^^
// [diag.multipleWithClauses] Each class definition can have at most one with clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
          NamedType
            name: D
          NamedType
            name: E
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typing_extends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Foo exte
//    ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
//        ^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
class UnrelatedClass extends Bar {}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: exte
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: UnrelatedClass
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: Bar
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typing_extends_identifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Foo extends CurrentlyTypingHere
//                ^^^^^^^^^^^^^^^^^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
class UnrelatedClass extends Bar {}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: CurrentlyTypingHere
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: UnrelatedClass
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: Bar
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_withBeforeExtends() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A with B extends C {}
//             ^^^^^^^
// [diag.withBeforeExtends] The extends clause must be before the with clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: C
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }
}

/// Test how well the parser recovers when the members of a compilation unit are
/// out of order.
@reflectiveTest
class CompilationUnitMemberTest extends ParserDiagnosticsTest {
  void test_declarationBeforeDirective_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { }
export 'bar.dart';
// [diag.directiveAfterDeclaration][column 1][length 6] Directives must appear before any declarations.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_declarationBeforeDirective_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { }
import 'bar.dart';
// [diag.directiveAfterDeclaration][column 1][length 6] Directives must appear before any declarations.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_declarationBeforeDirective_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { }
part 'bar.dart';
// [diag.directiveAfterDeclaration][column 1][length 4] Directives must appear before any declarations.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_declarationBeforeDirective_part_of() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { }
part of foo;
// [diag.directiveAfterDeclaration][column 1][length 4] Directives must appear before any declarations.
//      ^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          foo
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_exportBeforeLibrary() {
    var parseResult = parseTestCodeWithDiagnostics('''
export 'bar.dart';
library l;
// [diag.libraryDirectiveNotFirst][column 1][length 7] The library directive must appear before all other directives.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, '''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_importBeforeLibrary() {
    var parseResult = parseTestCodeWithDiagnostics('''
import 'bar.dart';
library l;
// [diag.libraryDirectiveNotFirst][column 1][length 7] The library directive must appear before all other directives.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, '''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }

  void test_partBeforeLibrary() {
    var parseResult = parseTestCodeWithDiagnostics('''
part 'foo.dart';
library l;
// [diag.libraryDirectiveNotFirst][column 1][length 7] The library directive must appear before all other directives.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, '''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'foo.dart'
      semicolon: ;
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          l
      semicolon: ;
''');
  }
}

/// Test how well the parser recovers when the members of an import directive
/// are out of order.
@reflectiveTest
class ImportDirectiveTest extends ParserDiagnosticsTest {
  void test_combinatorsBeforeAndAfterPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' show A as p show B;
//                       ^^
// [diag.prefixAfterCombinator] The prefix ('as' clause) should come before any show/hide combinators.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: B
      semicolon: ;
''');
  }

  void test_combinatorsBeforePrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' show A as p;
//                       ^^
// [diag.prefixAfterCombinator] The prefix ('as' clause) should come before any show/hide combinators.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ;
''');
  }

  void test_combinatorsBeforePrefixAfterDeferred() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' deferred show A as p;
//                                ^^
// [diag.prefixAfterCombinator] The prefix ('as' clause) should come before any show/hide combinators.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      deferredKeyword: deferred
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ;
''');
  }

  void test_deferredAfterPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' as p deferred;
//                     ^^^^^^^^
// [diag.deferredAfterPrefix] The deferred keyword should come immediately before the prefix ('as' clause).

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      deferredKeyword: deferred
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      semicolon: ;
''');
  }

  void test_duplicatePrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' as p as q;
//                     ^^
// [diag.duplicatePrefix] An import directive can only have one prefix ('as' clause).

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      semicolon: ;
''');
  }

  void test_unknownTokenAtEnd() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' as p sh;
//                     ^^
// [diag.unexpectedToken] Unexpected text 'sh'.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      semicolon: ;
''');
  }

  void test_unknownTokenBeforePrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' d as p;
//                ^
// [diag.unexpectedToken] Unexpected text 'd'.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      semicolon: ;
''');
  }

  void test_unknownTokenBeforePrefixAfterCombinatorMissingSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' d show A as p
//                ^
// [diag.unexpectedToken] Unexpected text 'd'.
//                         ^^
// [diag.prefixAfterCombinator] The prefix ('as' clause) should come before any show/hide combinators.
//                            ^
// [diag.expectedToken] Expected to find ';'.
import 'b.dart';

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'b.dart'
      semicolon: ;
''');
  }

  void test_unknownTokenBeforePrefixAfterDeferred() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'bar.dart' deferred s as p;
//                         ^
// [diag.unexpectedToken] Unexpected text 's'.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      deferredKeyword: deferred
      asKeyword: as
      prefix: SimpleIdentifier
        token: p
      semicolon: ;
''');
  }
}

/// Test how well the parser recovers when metadata appears in invalid places.
@reflectiveTest
class MisplacedMetadataTest extends ParserDiagnosticsTest {
  void test_field_afterType() {
    // This test fails because `findMemberName` doesn't recognize that the `@`
    // isn't a valid token in the stream leading up to a member name. That
    // causes `parseMethod` to attempt to parse from the `x` as a function body.
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
//^^^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            constKeyword: const
            typeName: SimpleIdentifier
              token: A
            parameters: FormalParameterList
              leftParenthesis: (
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: x
              rightDelimiter: ]
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: B
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: dynamic
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: A
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: A
                      argumentList: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: )
                  rightParenthesis: )
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: x
            semicolon: ;
        rightBracket: }
''');
  }
}

/// Test how well the parser recovers when the clauses in a mixin declaration
/// are out of order.
@reflectiveTest
class MixinDeclarationTest extends ParserDiagnosticsTest {
  void test_implementsBeforeOn() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B on C {}
//                   ^^
// [diag.implementsBeforeOn] The on clause must be before the implements clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: C
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleImplements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B implements C, D {}
//                   ^^^^^^^^^^
// [diag.multipleImplementsClauses] Each class or mixin definition can have at most one implements clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: C
          NamedType
            name: D
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleOn() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B on C {}
//           ^^
// [diag.multipleOnClauses] Each mixin definition can have at most one on clause.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typing_implements() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin Foo imple
//    ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
mixin UnrelatedMixin on Bar {}
// [diag.missingIdentifier][column 1][length 5] Expected an identifier.

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: Foo
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: imple
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: UnrelatedMixin
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: Bar
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typing_implements_identifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin Foo implements CurrentlyTypingHere
//                   ^^^^^^^^^^^^^^^^^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
mixin UnrelatedMixin on Bar {}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: Foo
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: CurrentlyTypingHere
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: UnrelatedMixin
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: Bar
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }
}

/// Test how well the parser recovers when the clauses in a try statement are
/// out of order.
@reflectiveTest
class TryStatementTest extends ParserDiagnosticsTest {
  void test_finallyBeforeCatch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  try {
  } finally {
  } catch (e) {
//  ^^^^^
// [diag.expectedIdentifierButGotKeyword] 'catch' can't be used as an identifier because it's a keyword.
//          ^
// [diag.expectedToken] Expected to find ';'.
  }
}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
              ExpressionStatement
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: catch
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      SimpleIdentifier
                        token: e
                    rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_finallyBeforeOn() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  try {
  } finally {
  } on String {
//     ^^^^^^
// [diag.expectedToken] Expected to find ';'.
  }
}

''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: on
                  variables
                    VariableDeclaration
                      name: String
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }
}
