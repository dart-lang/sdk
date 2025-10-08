// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveResolutionTest);
  });
}

@reflectiveTest
class PartDirectiveResolutionTest extends PubPackageResolutionTest {
  test_enclosingUnit() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';
''');
    expect(
      (findNode.part('part').partInclude! as PartIncludeImpl).libraryFragment,
      same(findNode.unit.declaredFragment),
    );
  }

  test_inLibrary_fileDoesNotExist() async {
    await assertErrorsInCode(
      r'''
part 'a.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 5, 8)],
    );

    var node = findNode.singlePartDirective;
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
    await assertErrorsInCode(
      '''
part 'part.g.dart';
''',
      [error(CompileTimeErrorCode.uriHasNotBeenGenerated, 5, 13)],
    );
  }

  test_inLibrary_noRelativeUri() async {
    await assertErrorsInCode(
      r'''
part ':net';
''',
      [error(CompileTimeErrorCode.invalidUri, 5, 6)],
    );

    var node = findNode.singlePartDirective;
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
    await assertErrorsInCode(
      r'''
part '${'foo'}.dart';
''',
      [error(CompileTimeErrorCode.uriWithInterpolation, 5, 15)],
    );

    var node = findNode.singlePartDirective;
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
    await assertErrorsInCode(
      r'''
part 'foo:bar';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 5, 9)],
    );

    var node = findNode.singlePartDirective;
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

    await resolveFile2(a);
    assertNoErrorsInResult();

    var node = findNode.singlePartDirective;
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

    await resolveFile2(a);
    assertNoErrorsInResult();

    var node = findNode.singlePartDirective;
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

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.partOfDifferentLibrary, 33, 8),
    ]);

    var node = findNode.singlePartDirective;
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

    await assertNoErrorsInCode(r'''
part 'a.dart';
''');

    var node = findNode.singlePartDirective;
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

    await assertErrorsInCode(
      r'''
part 'a.dart';
''',
      [error(CompileTimeErrorCode.partOfDifferentLibrary, 5, 8)],
    );

    var node = findNode.singlePartDirective;
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

    await resolveFile2(foo);
    assertErrorsInResolvedUnit(result, const []);

    var node = findNode.singlePartDirective;
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

    await assertErrorsInCode(
      r'''
part 'a.dart';
''',
      [error(CompileTimeErrorCode.partOfNonPart, 5, 8)],
    );

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 23, 8)]);

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.invalidUri, 23, 6)]);

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.uriWithInterpolation, 23, 15),
    ]);

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.uriDoesNotExist, 23, 9)]);

    var node = findNode.singlePartDirective;
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
    assertErrorsInResult([error(ParserErrorCode.partOfName, 8, 6)]);

    // We already reported an error above.
    await resolveFile2(b);
    assertNoErrorsInResult();

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertNoErrorsInResult();

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.partOfDifferentLibrary, 23, 8),
    ]);

    var node = findNode.singlePartDirective;
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

    await resolveFile2(b);
    assertErrorsInResult([error(CompileTimeErrorCode.partOfNonPart, 23, 8)]);

    var node = findNode.singlePartDirective;
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
