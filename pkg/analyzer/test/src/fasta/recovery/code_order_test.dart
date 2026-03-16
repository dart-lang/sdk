// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
class A implements B extends C {}

''');
    parseResult.assertErrors([error(diag.implementsBeforeExtends, 21, 7)]);
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
    var parseResult = parseStringWithErrors(r'''
class A extends B implements C with D {}

''');
    parseResult.assertErrors([error(diag.implementsBeforeWith, 31, 4)]);
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
    var parseResult = parseStringWithErrors(r'''
class A implements B with C extends D {}

''');
    parseResult.assertErrors([
      error(diag.implementsBeforeWith, 21, 4),
      error(diag.withBeforeExtends, 28, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
class A extends B extends C {}

''');
    parseResult.assertErrors([error(diag.multipleExtendsClauses, 18, 7)]);
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
    var parseResult = parseStringWithErrors(r'''
class A implements B implements C, D {}

''');
    parseResult.assertErrors([error(diag.multipleImplementsClauses, 21, 10)]);
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
    var parseResult = parseStringWithErrors(r'''
class A extends B with C, D with E {}

''');
    parseResult.assertErrors([error(diag.multipleWithClauses, 28, 4)]);
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
    var parseResult = parseStringWithErrors(r'''
class Foo exte
class UnrelatedClass extends Bar {}

''');
    parseResult.assertErrors([
      error(diag.expectedClassBody, 6, 3),
      error(diag.missingConstFinalVarOrType, 10, 4),
      error(diag.expectedToken, 10, 4),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
class Foo extends CurrentlyTypingHere
class UnrelatedClass extends Bar {}

''');
    parseResult.assertErrors([error(diag.expectedClassBody, 18, 19)]);
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
    var parseResult = parseStringWithErrors(r'''
class A with B extends C {}

''');
    parseResult.assertErrors([error(diag.withBeforeExtends, 15, 7)]);
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
    var parseResult = parseStringWithErrors(r'''
class C { }
export 'bar.dart';

''');
    parseResult.assertErrors([error(diag.directiveAfterDeclaration, 12, 6)]);
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
    var parseResult = parseStringWithErrors(r'''
class C { }
import 'bar.dart';

''');
    parseResult.assertErrors([error(diag.directiveAfterDeclaration, 12, 6)]);
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
    var parseResult = parseStringWithErrors(r'''
class C { }
part 'bar.dart';

''');
    parseResult.assertErrors([error(diag.directiveAfterDeclaration, 12, 4)]);
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
    var parseResult = parseStringWithErrors(r'''
class C { }
part of foo;

''');
    parseResult.assertErrors([
      error(diag.directiveAfterDeclaration, 12, 4),
      error(diag.partOfName, 20, 3),
    ]);
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
    var parseResult = parseStringWithErrors('''
export 'bar.dart';
library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 19, 7)]);
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
    var parseResult = parseStringWithErrors('''
import 'bar.dart';
library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 19, 7)]);
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
    var parseResult = parseStringWithErrors('''
part 'foo.dart';
library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 17, 7)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' show A as p show B;

''');
    parseResult.assertErrors([error(diag.prefixAfterCombinator, 25, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' show A as p;

''');
    parseResult.assertErrors([error(diag.prefixAfterCombinator, 25, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' deferred show A as p;

''');
    parseResult.assertErrors([error(diag.prefixAfterCombinator, 34, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' as p deferred;

''');
    parseResult.assertErrors([error(diag.deferredAfterPrefix, 23, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' as p as q;

''');
    parseResult.assertErrors([error(diag.duplicatePrefix, 23, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' as p sh;

''');
    parseResult.assertErrors([error(diag.unexpectedToken, 23, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' d as p;

''');
    parseResult.assertErrors([error(diag.unexpectedToken, 18, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' d show A as p
import 'b.dart';

''');
    parseResult.assertErrors([
      error(diag.unexpectedToken, 18, 1),
      error(diag.prefixAfterCombinator, 27, 2),
      error(diag.expectedToken, 30, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' deferred s as p;

''');
    parseResult.assertErrors([error(diag.unexpectedToken, 27, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}

''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 40, 7),
      error(diag.expectedToken, 40, 7),
      error(diag.missingConstFinalVarOrType, 62, 1),
    ]);
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
              parameter: DefaultFormalParameter
                parameter: SimpleFormalParameter
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
    var parseResult = parseStringWithErrors(r'''
mixin A implements B on C {}

''');
    parseResult.assertErrors([error(diag.implementsBeforeOn, 21, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
mixin A implements B implements C, D {}

''');
    parseResult.assertErrors([error(diag.multipleImplementsClauses, 21, 10)]);
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
    var parseResult = parseStringWithErrors(r'''
mixin A on B on C {}

''');
    parseResult.assertErrors([error(diag.multipleOnClauses, 13, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
mixin Foo imple
mixin UnrelatedMixin on Bar {}

''');
    parseResult.assertErrors([
      error(diag.expectedMixinBody, 6, 3),
      error(diag.missingIdentifier, 16, 5),
      error(diag.expectedToken, 10, 5),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
mixin Foo implements CurrentlyTypingHere
mixin UnrelatedMixin on Bar {}

''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 21, 19)]);
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
    var parseResult = parseStringWithErrors(r'''
f() {
  try {
  } finally {
  } catch (e) {
  }
}

''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 32, 5),
      error(diag.expectedToken, 40, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
f() {
  try {
  } finally {
  } on String {
  }
}

''');
    parseResult.assertErrors([error(diag.expectedToken, 35, 6)]);
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
