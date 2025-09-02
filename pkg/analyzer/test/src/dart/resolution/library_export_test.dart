// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectiveResolutionTest);
  });
}

@reflectiveTest
class ExportDirectiveResolutionTest extends PubPackageResolutionTest {
  test_inLibrary_combinators_hide() async {
    await assertNoErrorsInCode(r'''
export 'dart:math' hide Random;
''');

    var node = findNode.singleExportDirective;
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_hide_unresolved() async {
    await assertErrorsInCode(
      r'''
export 'dart:math' hide Unresolved;
''',
      [error(WarningCode.undefinedHiddenName, 24, 10)],
    );

    var node = findNode.singleExportDirective;
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_show() async {
    await assertNoErrorsInCode(r'''
export 'dart:math' show Random;
''');

    var node = findNode.singleExportDirective;
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: dart:math
''');
  }

  test_inLibrary_combinators_show_unresolved() async {
    await assertErrorsInCode(
      r'''
export 'dart:math' show Unresolved;
''',
      [error(WarningCode.undefinedShownName, 24, 10)],
    );

    var node = findNode.singleExportDirective;
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
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
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: package:test/a.dart
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
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: package:test/a_html.dart
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
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: package:test/a_io.dart
''');
  }

  test_inLibrary_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
export 'a.dart';
''');

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: package:test/a.dart
''');
  }

  test_inLibrary_library_fileDoesNotExist() async {
    await assertErrorsInCode(
      r'''
export 'a.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 8)],
    );

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'package:foo/foo.dart';
''');

    var node = findNode.export('package:foo');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'package:foo/foo.dart'
  semicolon: ;
  libraryExport: LibraryExport
    uri: DirectiveUriWithLibrary
      uri: package:foo/foo.dart
''');
  }

  /// Test that both getter and setter are in the export namespace.
  test_inLibrary_namespace_getter_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
get f => null;
set f(_) {}
''');
    await resolveTestCode(r'''
export 'a.dart';
''');
    var exportNamespace = result.libraryElement.exportNamespace;
    expect(exportNamespace.get2('f'), isNotNull);
    expect(exportNamespace.get2('f='), isNotNull);
  }

  test_inLibrary_noRelativeUri() async {
    await assertErrorsInCode(
      r'''
export ':net';
''',
      [error(CompileTimeErrorCode.invalidUri, 7, 6)],
    );

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  libraryExport: LibraryExport
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inLibrary_noRelativeUriStr() async {
    await assertErrorsInCode(
      r'''
export '${'foo'}.dart';
''',
      [error(CompileTimeErrorCode.uriWithInterpolation, 7, 15)],
    );

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUri
''');
  }

  test_inLibrary_noSource() async {
    await assertErrorsInCode(
      r'''
export 'foo:bar';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 9)],
    );

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'a.dart';
''',
      [error(CompileTimeErrorCode.exportOfNonLibrary, 7, 8)],
    );

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'a.dart';
''',
      [error(CompileTimeErrorCode.exportOfNonLibrary, 7, 8)],
    );

    var node = findNode.export('a.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'package:foo/foo2.dart';
''',
      [error(CompileTimeErrorCode.exportOfNonLibrary, 7, 23)],
    );

    var node = findNode.export('package:foo');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'package:foo/foo2.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b);
    assertNoErrorsInResult();

    var node = findNode.export('c.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'c.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 25, 8)]);

    var node = findNode.export('c.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export ':net';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.invalidUri, 25, 6)]);

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  libraryExport: LibraryExport
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
export '${'foo'}.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.uriWithInterpolation, 25, 15),
    ]);

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
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
  libraryExport: LibraryExport
    uri: DirectiveUri
''');
  }

  test_inPart_noSource() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
export 'foo:bar';
''');

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 25, 9)]);

    var node = findNode.export('export');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.exportOfNonLibrary, 25, 8),
    ]);

    var node = findNode.export('c.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryExport: LibraryExport
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
export 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.exportOfNonLibrary, 25, 8),
    ]);

    var node = findNode.export('c.dart');
    assertResolvedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  libraryExport: LibraryExport
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }
}
