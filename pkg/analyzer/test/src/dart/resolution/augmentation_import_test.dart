// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await resolveTestCode(r'''
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

  test_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await resolveTestCode(r'''
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
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }

  test_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await resolveTestCode(r'''
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
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }

  test_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await resolveTestCode(r'''
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
    uri: DirectiveUriWithSource
      source: package:test/a.dart
  uriContent: a.dart
  uriElement: <null>
  uriSource: package:test/a.dart
''');
  }
}
