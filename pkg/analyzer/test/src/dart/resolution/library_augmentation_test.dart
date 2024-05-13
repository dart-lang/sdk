// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAugmentationDirectiveResolutionTest);
    defineReflectiveTests(LibraryAugmentationResolutionTest);
  });
}

@reflectiveTest
class LibraryAugmentationDirectiveResolutionTest
    extends PubPackageResolutionTest {
  test_directive() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b);
    assertNoErrorsInResult();

    var node = findNode.libraryAugmentation('a.dart');
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self::@augmentation::package:test/b.dart
''');
  }

  test_hasFile_doesNotExist() async {
    await assertErrorsInCode(r'''
augment library 'a.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 16, 8),
    ]);

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self
''');
  }

  test_hasFile_library_hasImportAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';
''');

    await assertNoErrorsInCode(r'''
augment library 'a.dart';
''');

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self::@augmentation::package:test/test.dart
''');
  }

  test_hasFile_library_noImport() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode(r'''
augment library 'a.dart';
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_IMPORT, 16, 8),
    ]);

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self
''');
  }

  test_hasFile_notLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'b.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_LIBRARY, 16, 8),
    ]);

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self
''');
  }

  test_hasFile_notLibrary_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    await assertErrorsInCode(r'''
augment library 'a.dart';
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_LIBRARY, 16, 8),
    ]);

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self
''');
  }

  test_noRelativeUriStr() async {
    await assertErrorsInCode(r'''
augment library '${'foo.dart'}';
''', [
      error(CompileTimeErrorCode.AUGMENTATION_WITHOUT_LIBRARY, 16, 15),
    ]);

    var node = findNode.singleLibraryAugmentationDirective;
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo.dart'
        rightBracket: }
      InterpolationString
        contents: '
    staticType: String
    stringValue: null
  semicolon: ;
  element: self
''');
  }
}

@reflectiveTest
class LibraryAugmentationResolutionTest extends PubPackageResolutionTest {
  test_namespace_import_augmentationImports() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
math.Random get foo => throw 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
import 'dart:math' as math;
math.Random get bar => throw 0;
''');

    // In the library.
    {
      await resolveFile2(a);
      assertErrorsInResult([
        error(CompileTimeErrorCode.UNDEFINED_CLASS, 25, 11),
      ]);

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: <null>
  name: Random
  element: <null>
  type: InvalidType
''');
    }

    // In the augmentation.
    {
      await resolveFile2(b);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: self::@augmentation::package:test/b.dart::@prefix::math
  name: Random
  element: dart:math::@class::Random
  type: Random
''');
    }
  }

  test_namespace_import_libraryImports() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
import 'dart:math' as math;
math.Random get foo => throw 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
math.Random get bar => throw 0;
''');

    // In the library.
    {
      await resolveFile2(a);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: self::@prefix::math
  name: Random
  element: dart:math::@class::Random
  type: Random
''');
    }

    // In the augmentation.
    {
      await resolveFile2(b);
      assertErrorsInResult([
        error(CompileTimeErrorCode.UNDEFINED_CLASS, 26, 11),
      ]);

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: <null>
  name: Random
  element: <null>
  type: InvalidType
''');
    }
  }

  test_namespace_top_class_augmentationDeclares() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
A foo() => throw 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
class A {}
A bar() => throw 0;
''');

    // In the library.
    {
      await resolveFile2(a);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@augmentation::package:test/b.dart::@class::A
  type: A
''');
    }

    // In the augmentation.
    {
      await resolveFile2(b);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@augmentation::package:test/b.dart::@class::A
  type: A
''');
    }
  }

  test_namespace_top_class_libraryDeclares() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
class A {}
A foo() => throw 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
A bar() => throw 0;
''');

    // In the library.
    {
      await resolveFile2(a);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A
''');
    }

    // In the augmentation.
    {
      await resolveFile2(b);
      assertNoErrorsInResult();

      var node = findNode.singleNamedType;
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A
''');
    }
  }
}
