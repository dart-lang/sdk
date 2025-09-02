// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDirectiveResolutionTest);
  });
}

@reflectiveTest
class ImportDirectiveResolutionTest extends PubPackageResolutionTest {
  test_inLibrary_combinators_hide() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' hide Random;
''',
      [error(WarningCode.unusedImport, 7, 11)],
    );

    var node = findNode.singleImportDirective;
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'dart:math'
  combinators
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: Random
          element: dart:math::@class::Random
          staticType: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_hide_unresolved() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' hide Unresolved;
''',
      [
        error(WarningCode.unusedImport, 7, 11),
        error(WarningCode.undefinedHiddenName, 24, 10),
      ],
    );

    var node = findNode.singleImportDirective;
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'dart:math'
  combinators
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: Unresolved
          element: <null>
          staticType: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_show() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' show Random;
''',
      [error(WarningCode.unusedImport, 7, 11)],
    );

    var node = findNode.singleImportDirective;
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'dart:math'
  combinators
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: Random
          element: dart:math::@class::Random
          staticType: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_show_unresolved() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' show Unresolved;
''',
      [
        error(WarningCode.unusedImport, 7, 11),
        error(WarningCode.undefinedShownName, 24, 10),
      ],
    );

    var node = findNode.singleImportDirective;
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'dart:math'
  combinators
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: Unresolved
          element: <null>
          staticType: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_configurations_default() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/a_html.dart', 'class A {}');
    newFile('$testPackageLibPath/a_io.dart', 'class A {}');

    declaredVariables = {
      'dart.library.html': 'false',
      'dart.library.io': 'false',
    };

    await assertNoErrorsInCode(r'''
import 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';

var a = A();
''');

    var node = findNode.unit;
    assertResolvedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: html
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_html.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_html.dart
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: io
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_io.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_io.dart
      semicolon: ;
      libraryImport: LibraryImport
        uri: DirectiveUriWithLibrary
          uri: package:test/a.dart
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A
                  element2: package:test/a.dart::@class::A
                  type: A
                element: package:test/a.dart::@class::A::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              staticType: A
            declaredElement: <testLibraryFragment> a@96
      semicolon: ;
      declaredElement: <null>
''');
  }

  test_inLibrary_configurations_first() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/a_html.dart', 'class A {}');
    newFile('$testPackageLibPath/a_io.dart', 'class A {}');

    declaredVariables = {
      'dart.library.html': 'true',
      'dart.library.io': 'false',
    };

    await assertNoErrorsInCode(r'''
import 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';

var a = A();
''');

    var node = findNode.unit;
    assertResolvedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: html
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_html.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_html.dart
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: io
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_io.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_io.dart
      semicolon: ;
      libraryImport: LibraryImport
        uri: DirectiveUriWithLibrary
          uri: package:test/a_html.dart
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A
                  element2: package:test/a_html.dart::@class::A
                  type: A
                element: package:test/a_html.dart::@class::A::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              staticType: A
            declaredElement: <testLibraryFragment> a@96
      semicolon: ;
      declaredElement: <null>
''');
  }

  test_inLibrary_configurations_noRelativeUri() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart'
  if (x) ':net';
''');

    var node = findNode.configuration('if (');
    assertResolvedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    components
      SimpleIdentifier
        token: x
        element: <null>
        staticType: null
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: ':net'
  resolvedUri: DirectiveUriWithRelativeUriString
    relativeUriString: :net
''');
  }

  test_inLibrary_configurations_noRelativeUriStr() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart'
  if (x) '${'foo'}.dart';
''');

    var node = findNode.configuration('if (');
    assertResolvedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    components
      SimpleIdentifier
        token: x
        element: <null>
        staticType: null
  rightParenthesis: )
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: null
    stringValue: null
  resolvedUri: DirectiveUri
''');
  }

  test_inLibrary_configurations_noSource() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart'
  if (x) 'foo:bar';
''');

    var node = findNode.configuration('if (');
    assertResolvedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    components
      SimpleIdentifier
        token: x
        element: <null>
        staticType: null
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  resolvedUri: DirectiveUriWithRelativeUri
    relativeUri: foo:bar
''');
  }

  test_inLibrary_configurations_onlySource_notLibrary() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart'
  if (x) 'a.dart';
''');

    var node = findNode.configuration('if (');
    assertResolvedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    components
      SimpleIdentifier
        token: x
        element: <null>
        staticType: null
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'a.dart'
  resolvedUri: DirectiveUriWithSource
    source: package:test/a.dart
''');
  }

  test_inLibrary_configurations_second() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/a_html.dart', 'class A {}');
    newFile('$testPackageLibPath/a_io.dart', 'class A {}');

    declaredVariables = {
      'dart.library.html': 'false',
      'dart.library.io': 'true',
    };

    await assertNoErrorsInCode(r'''
import 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';

var a = A();
''');

    var node = findNode.unit;
    assertResolvedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: html
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_html.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_html.dart
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            components
              SimpleIdentifier
                token: dart
                element: <null>
                staticType: null
              SimpleIdentifier
                token: library
                element: <null>
                staticType: null
              SimpleIdentifier
                token: io
                element: <null>
                staticType: null
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: 'a_io.dart'
          resolvedUri: DirectiveUriWithSource
            source: package:test/a_io.dart
      semicolon: ;
      libraryImport: LibraryImport
        uri: DirectiveUriWithLibrary
          uri: package:test/a_io.dart
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A
                  element2: package:test/a_io.dart::@class::A
                  type: A
                element: package:test/a_io.dart::@class::A::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              staticType: A
            declaredElement: <testLibraryFragment> a@96
      semicolon: ;
      declaredElement: <null>
''');
  }

  test_inLibrary_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
// ignore: unused_import
import 'a.dart';
''');

    var node = findNode.import('a.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: package:test/a.dart
''');
  }

  test_inLibrary_library_fileDoesNotExist() async {
    await assertErrorsInCode(
      r'''
import 'a.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 8)],
    );

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: package:test/a.dart
''');
  }

  test_inLibrary_library_inSummary() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {'lib/foo.dart': 'class F {}'}),
    ];
    sdkSummaryFile = await writeSdkSummary();

    await assertNoErrorsInCode(r'''
// ignore: unused_import
import 'package:foo/foo.dart';
''');

    var node = findNode.import('package:foo');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'package:foo/foo.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: package:foo/foo.dart
''');
  }

  test_inLibrary_noRelativeUri() async {
    await assertErrorsInCode(
      r'''
import ':net';
''',
      [error(CompileTimeErrorCode.invalidUri, 7, 6)],
    );

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inLibrary_noRelativeUriStr() async {
    await assertErrorsInCode(
      r'''
import '${'foo'}.dart';
''',
      [error(CompileTimeErrorCode.uriWithInterpolation, 7, 15)],
    );

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: String
    stringValue: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUri
''');
  }

  test_inLibrary_noSource() async {
    await assertErrorsInCode(
      r'''
import 'foo:bar';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 9)],
    );

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inLibrary_notLibrary_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
''',
      [error(CompileTimeErrorCode.importOfNonLibrary, 7, 8)],
    );

    var node = findNode.import('a.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_notLibrary_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
''',
      [error(CompileTimeErrorCode.importOfNonLibrary, 7, 8)],
    );

    var node = findNode.import('a.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_notLibrary_partOfUri_inSummary() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(
        files: {
          'lib/foo.dart': "part 'foo2.dart';",
          'lib/foo2.dart': "part of 'foo.dart';",
        },
      ),
    ];
    sdkSummaryFile = await writeSdkSummary();

    await assertErrorsInCode(
      r'''
import 'package:foo/foo2.dart';
''',
      [error(CompileTimeErrorCode.importOfNonLibrary, 7, 23)],
    );

    var node = findNode.import('package:foo');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'package:foo/foo2.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithSource
      source: package:foo/foo2.dart
''');
  }

  test_inPart_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b);
    // TODO(scheglov): update the hint.
    // assertErrorsInResult([
    //   error(WarningCode.UNUSED_IMPORT, 33, 8),
    // ]);

    var node = findNode.import('c.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: package:test/c.dart
''');
  }

  test_inPart_library_fileDoesNotExist() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'c.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 25, 8)]);

    var node = findNode.import('c.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithLibrary
      uri: package:test/c.dart
''');
  }

  test_inPart_noRelativeUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import ':net';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.invalidUri, 25, 6)]);

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inPart_noRelativeUriStr() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import '${'foo'}.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.uriWithInterpolation, 25, 15),
    ]);

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: String
    stringValue: null
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUri
''');
  }

  test_inPart_noSource() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'foo:bar';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 25, 9)]);

    var node = findNode.import('import');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inPart_notLibrary_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.importOfNonLibrary, 25, 8),
    ]);

    var node = findNode.import('c.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }

  test_inPart_notLibrary_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.importOfNonLibrary, 25, 8),
    ]);

    var node = findNode.import('c.dart');
    assertResolvedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryImport: LibraryImport
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }
}
