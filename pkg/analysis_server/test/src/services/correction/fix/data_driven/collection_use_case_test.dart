// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';
import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionUseCaseTest);
  });
}

@reflectiveTest
class CollectionUseCaseTest extends DataDrivenFixProcessorTest {
  Future<void> test_package_collection_whereNotNull_deprecated() async {
    newFile('$workspaceRootPath/p/lib/it.dart', '''
extension IterableNullableExtension<T extends Object> on Iterable<T?> {
  @Deprecated('Use .nonNulls instead.')
  Iterable<T> whereNotNull() sync* {
    for (var element in this) {
      if (element != null) yield element;
    }
  }
}
''');

    writeTestPackageConfig(
        config: PackageConfigFileBuilder()
          ..add(name: 'p', rootPath: '$workspaceRootPath/p'));

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace whereNotNull with nonNulls from dart:core'
    date: 2023-11-09
    element:
      uris: [  'package:p/it.dart' ]
      method: 'whereNotNull'
      inClass: 'List'
    changes:
    - kind: 'replacedBy'
      newElement:
        uris: [  'dart:collection' ]
        getter: 'nonNulls'
''');

    await resolveTestCode('''
import 'package:p/it.dart';

main() {
  var list1 = <String?>['foo', 'bar', null, 'baz'];
  var list2 = list1.whereNotNull();
  print(list2);
}
''');
    await assertHasFix('''
import 'dart:collection';

import 'package:p/it.dart';

main() {
  var list1 = <String?>['foo', 'bar', null, 'baz'];
  var list2 = list1.nonNulls;
  print(list2);
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/56078')
  Future<void> test_package_collection_whereNotNull_removed() async {
    newFile('$workspaceRootPath/p/lib/it.dart', '''
extension IterableNullableExtension<T extends Object> on Iterable<T?> {
}
''');

    writeTestPackageConfig(
        config: PackageConfigFileBuilder()
          ..add(name: 'p', rootPath: '$workspaceRootPath/p'));

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace whereNotNull with nonNulls from dart:core'
    date: 2023-11-09
    element:
      uris: [  'package:p/it.dart' ]
      method: 'whereNotNull'
      inClass: 'List'
    changes:
    - kind: 'replacedBy'
      newElement:
        uris: [  'dart:collection' ]
        getter: 'nonNulls'
''');

    await resolveTestCode('''
// ignore: unused_import
import 'package:p/it.dart';

main() {
  var list1 = <String?>['foo', 'bar', null, 'baz'];
  var list2 = list1.whereNotNull();
  print(list2);
}
''');
    await assertHasFix('''
// ignore: unused_import
import 'dart:collection';

import 'package:p/it.dart';

main() {
  var list1 = <String?>['foo', 'bar', null, 'baz'];
  var list2 = list1.nonNulls;
  print(list2);
}
''');
  }
}
