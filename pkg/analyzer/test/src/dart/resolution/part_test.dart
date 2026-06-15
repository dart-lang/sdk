// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartDirectiveResolutionTest extends PubPackageResolutionTest {
  test_enclosingUnit() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
''');
    expect(
      (result.findNode.part('part').partInclude! as PartIncludeImpl)
          .libraryFragment,
      same(result.findNode.unit.declaredFragment),
    );
  }

  test_inLibrary_fileDoesNotExist() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_fileDoesNotExist_generated() async {
    await resolveTestCodeWithDiagnostics('''
part 'part.g.dart';
//   ^^^^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/part.g.dart'.
''');
  }

  test_inLibrary_noRelativeUri() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
part ':net';
//   ^^^^^^
// [diag.invalidUri] Invalid URI syntax: ':net'.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inLibrary_noRelativeUriStr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
part '${'foo'}.dart';
//   ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
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
  partInclude: PartInclude
    uri: DirectiveUri
''');
  }

  test_inLibrary_noSource() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
part 'foo:bar';
//   ^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'foo:bar'.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inLibrary_withPart_partOfName() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.4
library my.lib;
part 'b.dart';
''',
      b: r'''
// @dart = 3.4
part of my.lib;
''',
    });
    var result = results[a]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithUnit
      uri: package:test/b.dart
''');
  }

  test_inLibrary_withPart_partOfName_preEnhancedParts() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.4
library my.lib;
part 'b.dart';
''',
      b: r'''
// @dart = 3.4
part of my.lib;
''',
    });
    var result = results[a]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithUnit
      uri: package:test/b.dart
''');
  }

  test_inLibrary_withPart_partOfName_preEnhancedParts_different() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.4
library foo;
part 'b.dart';
//   ^^^^^^^^
// [diag.partOfDifferentLibrary] Expected this library to be part of 'foo', not 'bar'.
''',
      b: r'''
// @dart = 3.4
part of bar;
''',
    });
    var result = results[a]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/b.dart
''');
  }

  test_inLibrary_withPart_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithUnit
      uri: package:test/a.dart
''');
  }

  test_inLibrary_withPart_partOfUri_different() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'x.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.partOfDifferentLibrary] Expected this library to be part of 'package:test/test.dart', not 'package:test/a.dart'.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_withPart_partOfUri_packageBuild_generated() async {
    var packageName = 'test';
    newPubspecYamlFile(testPackageRootPath, 'name: $packageName');

    var testPackageGeneratedPath =
        '$testPackageRootPath/.dart_tool/build/generated';
    newFile('$testPackageGeneratedPath/$packageName/lib/foo.g.dart', '''
part of 'foo.dart';
''');

    var foo = getFile('$testPackageRootPath/lib/foo.dart');
    var result = await resolveFileWithDiagnostics(foo, '''
part 'foo.g.dart';
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'foo.g.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithUnit
      uri: package:test/foo.g.dart
''');
  }

  test_inLibrary_withSource_notPart_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    var result = await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.partOfNonPart] The included part 'package:test/a.dart' must have a part-of directive.
''');

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inPart_fileDoesNotExist() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/c.dart'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/c.dart
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
part ':net';
//   ^^^^^^
// [diag.invalidUri] Invalid URI syntax: ':net'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  partInclude: PartInclude
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
part '${'foo'}.dart';
//   ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
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
  partInclude: PartInclude
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
part 'foo:bar';
//   ^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'foo:bar'.
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inPart_withPart_partOfName() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of my.lib;
//      ^^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''',
    });

    // We already reported an error above.
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }

  test_inPart_withPart_partOfUri() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithUnit
      uri: package:test/c.dart
''');
  }

  test_inPart_withPart_partOfUri_different() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.partOfDifferentLibrary] Expected this library to be part of 'package:test/b.dart', not 'package:test/c.dart'.
''',
      c: r'''
part of 'a.dart';
''',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }

  test_inPart_withSource_notPart_library() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.partOfNonPart] The included part 'package:test/c.dart' must have a part-of directive.
''',
      c: '',
    });
    var result = results[b]!;

    var node = result.findNode.singlePartDirective;
    assertResolvedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  partInclude: PartInclude
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }
}
