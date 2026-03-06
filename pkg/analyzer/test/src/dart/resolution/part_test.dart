// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveResolutionTest_UseDottedName);
    defineReflectiveTests(PartDirectiveResolutionTest_NoUseDottedName);
  });
}

abstract class PartDirectiveResolutionTest extends PubPackageResolutionTest {
  @override
  Future<void> tearDown() async {
    useDottedNameInLibraryDirective = false;
    await super.tearDown();
  }

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
      [error(diag.uriDoesNotExist, 5, 8)],
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
      [error(diag.uriHasNotBeenGenerated, 5, 13)],
    );
  }

  test_inLibrary_noRelativeUri() async {
    await assertErrorsInCode(
      r'''
part ':net';
''',
      [error(diag.invalidUri, 5, 6)],
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
      [error(diag.uriWithInterpolation, 5, 15)],
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
      [error(diag.uriDoesNotExist, 5, 9)],
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

    await resolveFile2(b);
    assertNoErrorsInResult();

    if (useDottedNameInLibraryDirective) {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName2: DottedName
    tokens
      my
      .
      lib
  semicolon: ;
''');
    } else {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: my
        element: <null>
        staticType: null
      SimpleIdentifier
        token: lib
        element: <null>
        staticType: null
    element: <null>
    staticType: null
  semicolon: ;
''');
    }
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

    await resolveFile2(b);
    assertNoErrorsInResult();

    if (useDottedNameInLibraryDirective) {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName2: DottedName
    tokens
      my
      .
      lib
  semicolon: ;
''');
    } else {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: my
        element: <null>
        staticType: null
      SimpleIdentifier
        token: lib
        element: <null>
        staticType: null
    element: <null>
    staticType: null
  semicolon: ;
''');
    }
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

    await resolveFile2(a);
    assertErrorsInResult([error(diag.partOfDifferentLibrary, 33, 8)]);

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

    await resolveFile2(b);
    assertNoErrorsInResult();

    if (useDottedNameInLibraryDirective) {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName2: DottedName
    tokens
      bar
  semicolon: ;
''');
    } else {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: bar
        element: <null>
        staticType: null
    element: <null>
    staticType: null
  semicolon: ;
''');
    }
  }

  test_inLibrary_withPart_partOfUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
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

    await resolveFile2(a);
    assertNoErrorsInResult();
    assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'test.dart'
  semicolon: ;
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
      [error(diag.partOfDifferentLibrary, 5, 8)],
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
      [error(diag.partOfNonPart, 5, 8)],
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
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.uriDoesNotExist, 23, 8)]);

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part ':net';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.invalidUri, 23, 6)]);

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part '${'foo'}.dart';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.uriWithInterpolation, 23, 15)]);

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'foo:bar';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.uriDoesNotExist, 23, 9)]);

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
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

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

    await resolveFile2(c);
    assertErrorsInResult([error(diag.partOfName, 8, 6)]);

    if (useDottedNameInLibraryDirective) {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName2: DottedName
    tokens
      my
      .
      lib
  semicolon: ;
''');
    } else {
      assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: my
        element: <null>
        staticType: null
      SimpleIdentifier
        token: lib
        element: <null>
        staticType: null
    element: <null>
    staticType: null
  semicolon: ;
''');
    }
  }

  test_inPart_withPart_partOfUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

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

    await resolveFile2(c);
    assertNoErrorsInResult();
    assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_inPart_withPart_partOfUri_different() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.partOfDifferentLibrary, 23, 8)]);
    assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');

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

    await resolveFile2(c);
    assertNoErrorsInResult();
    assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }

  test_inPart_withSource_notPart_library() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await resolveFile2(b);
    assertErrorsInResult([error(diag.partOfNonPart, 23, 8)]);
    assertResolvedNodeText(findNode.singlePartOfDirective, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');

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

    await resolveFile2(c);
    assertNoErrorsInResult();
  }
}

@reflectiveTest
class PartDirectiveResolutionTest_NoUseDottedName
    extends PartDirectiveResolutionTest {
  @override
  void setUp() {
    super.setUp();
    useDottedNameInLibraryDirective = false;
  }
}

@reflectiveTest
class PartDirectiveResolutionTest_UseDottedName
    extends PartDirectiveResolutionTest {
  @override
  void setUp() {
    super.setUp();
    useDottedNameInLibraryDirective = true;
  }
}
