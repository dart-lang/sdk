// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectiveResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExportDirectiveResolutionTest extends PubPackageResolutionTest {
  test_inLibrary_combinators_hide() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'dart:math' hide Random;
''');

    var node = result.findNode.singleExportDirective;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'dart:math' hide Unresolved;
//                      ^^^^^^^^^^
// [diag.undefinedHiddenName] The library 'dart:math' doesn't export a member with the hidden name 'Unresolved'.
''');

    var node = result.findNode.singleExportDirective;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'dart:math' show Random;
''');

    var node = result.findNode.singleExportDirective;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'dart:math' show Unresolved;
//                      ^^^^^^^^^^
// [diag.undefinedShownName] The library 'dart:math' doesn't export a member with the shown name 'Unresolved'.
''');

    var node = result.findNode.singleExportDirective;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = result.findNode.export('a.dart');
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
        tokens
          dart
          .
          library
          .
          html
      rightParenthesis: )
      uri: SimpleStringLiteral
        literal: 'a_html.dart'
      resolvedUri: DirectiveUriWithSource
        source: package:test/a_html.dart
    Configuration
      ifKeyword: if
      leftParenthesis: (
      name: DottedName
        tokens
          dart
          .
          library
          .
          io
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = result.findNode.export('a.dart');
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
        tokens
          dart
          .
          library
          .
          html
      rightParenthesis: )
      uri: SimpleStringLiteral
        literal: 'a_html.dart'
      resolvedUri: DirectiveUriWithSource
        source: package:test/a_html.dart
    Configuration
      ifKeyword: if
      leftParenthesis: (
      name: DottedName
        tokens
          dart
          .
          library
          .
          io
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    var node = result.findNode.export('a.dart');
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
        tokens
          dart
          .
          library
          .
          html
      rightParenthesis: )
      uri: SimpleStringLiteral
        literal: 'a_html.dart'
      resolvedUri: DirectiveUriWithSource
        source: package:test/a_html.dart
    Configuration
      ifKeyword: if
      leftParenthesis: (
      name: DottedName
        tokens
          dart
          .
          library
          .
          io
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
''');

    var node = result.findNode.export('a.dart');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.
''');

    var node = result.findNode.singleExportDirective;
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
    enableIndex = false;
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {'lib/foo.dart': 'class F {}'}),
    ];
    sdkSummaryFile = await writeSdkSummary();

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'package:foo/foo.dart';
''');

    var node = result.findNode.export('package:foo');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
''');
    var exportNamespace = result.libraryElement.exportNamespace;
    expect(exportNamespace.get2('f'), isNotNull);
    expect(exportNamespace.get2('f='), isNotNull);
  }

  test_inLibrary_noRelativeUri() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
export ':net';
//     ^^^^^^
// [diag.invalidUri] Invalid URI syntax: ':net'.
''');

    var node = result.findNode.export('export');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export '${'foo'}.dart';
//     ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''');

    var node = result.findNode.export('export');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'foo:bar';
//     ^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'foo:bar'.
''');

    var node = result.findNode.export('export');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
//     ^^^^^^^^
// [diag.exportOfNonLibrary] The exported library 'a.dart' can't have a part-of directive.
''');

    var node = result.findNode.singleExportDirective;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
//     ^^^^^^^^
// [diag.exportOfNonLibrary] The exported library 'a.dart' can't have a part-of directive.
''');

    var node = result.findNode.singleExportDirective;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'package:foo/foo2.dart';
//     ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.exportOfNonLibrary] The exported library 'package:foo/foo2.dart' can't have a part-of directive.
''');

    var node = result.findNode.singleExportDirective;
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    newFile('$testPackageLibPath/c.dart', '');

    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'c.dart';
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('c.dart');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'c.dart';
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'c.dart'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('c.dart');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export ':net';
//     ^^^^^^
// [diag.invalidUri] Invalid URI syntax: ':net'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('export');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export '${'foo'}.dart';
//     ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('export');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'foo:bar';
//     ^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'foo:bar'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('export');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'c.dart';
//     ^^^^^^^^
// [diag.exportOfNonLibrary] The exported library 'c.dart' can't have a part-of directive.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('c.dart');
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
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'c.dart';
//     ^^^^^^^^
// [diag.exportOfNonLibrary] The exported library 'c.dart' can't have a part-of directive.
''',
    });
    var result = results[b]!;

    var node = result.findNode.export('c.dart');
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
