// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationImportDirectiveResolutionTest);
  });
}

@reflectiveTest
class AugmentationImportDirectiveResolutionTest
    extends PubPackageResolutionTest {
  test_inAugmentation_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    await resolveFile2(b.path);
    assertNoErrorsInResult();

    final node = findNode.augmentationImportDirective('c.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/c.dart
  uriContent: c.dart
  uriElement: package:test/a.dart::@augmentation::package:test/c.dart
  uriSource: package:test/c.dart
''');
  }

  test_inAugmentation_augmentation_duplicate() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
import augment 'c.dart' /*2*/;
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT, 66, 8),
    ]);

    final node = findNode.augmentationImportDirective('/*2*/');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/c.dart
  uriContent: c.dart
  uriElement: package:test/a.dart::@augmentation::package:test/c.dart
  uriSource: package:test/c.dart
''');
  }

  test_inAugmentation_notAugmentation_invalidUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'da:';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.INVALID_URI, 41, 5),
    ]);

    final node = findNode.augmentationImportDirective('da:');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'da:'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithRelativeUri
      relativeUri: da:
  uriContent: da:
  uriElement: <null>
  uriSource: <null>
''');
  }

  test_inAugmentation_notAugmentation_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 41, 8),
    ]);

    final node = findNode.augmentationImportDirective('c.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/c.dart
  uriContent: c.dart
  uriElement: <null>
  uriSource: package:test/c.dart
''');
  }

  test_inAugmentation_notAugmentation_uriDoesNotExist() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 41, 8),
    ]);

    final node = findNode.augmentationImportDirective('c.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/c.dart
  uriContent: c.dart
  uriElement: <null>
  uriSource: package:test/c.dart
''');
  }

  test_inLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertNoErrorsInCode(r'''
import augment 'a.dart';
''');

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/a.dart
  uriContent: a.dart
  uriElement: self::@augmentation::package:test/a.dart
  uriSource: package:test/a.dart
''');
  }

  test_inLibrary_augmentation_duplicate() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
import augment /*2*/ 'a.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT, 46, 8),
    ]);

    final node = findNode.augmentationImportDirective('/*2*/');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/a.dart
  uriContent: a.dart
  uriElement: self::@augmentation::package:test/a.dart
  uriSource: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }
}
