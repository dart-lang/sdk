// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
library my.lib;
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
part of my.lib;
''');

    await resolveFile2(b);
    assertNoErrorsInResult();

    var result = await resolveFile2(a);
    assertNoErrorsInResult();

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
library my.lib;
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
part of my.lib;
''');

    await resolveFile2(b);
    assertNoErrorsInResult();

    var result = await resolveFile2(a);
    assertNoErrorsInResult();

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
library foo;
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
part of bar;
''');

    await resolveFile2(b);
    assertNoErrorsInResult();

    var result = await resolveFile2(a);
    assertErrorsInResult([error(diag.partOfDifferentLibrary, 33, 8)]);

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

    var foo = newFile('$testPackageRootPath/lib/foo.dart', '''
part 'foo.g.dart';
''');

    var result = await resolveFile2(foo);
    assertErrorsInResolvedUnit(result.analysisResult, const []);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.uriDoesNotExist, 23, 8)]);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part ':net';
''');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.invalidUri, 23, 6)]);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part '${'foo'}.dart';
''');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.uriWithInterpolation, 23, 15)]);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'foo:bar';
''');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.uriDoesNotExist, 23, 9)]);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    await resolveFile2(c);
    assertErrorsInResult([error(diag.partOfName, 8, 6)]);

    // We already reported an error above.
    var result = await resolveFile2(b);
    assertNoErrorsInResult();

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    var result = await resolveFile2(b);
    assertNoErrorsInResult();

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
''');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.partOfDifferentLibrary, 23, 8)]);

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    var result = await resolveFile2(b);
    assertErrorsInResult([error(diag.partOfNonPart, 23, 8)]);

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
