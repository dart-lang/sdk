// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(MixinOfNonClassTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertHasFix('''
import '$importUri';
class A extends New {}
class B extends New {}
''');
  }
}

@reflectiveTest
class ImplementsNonClassTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A implements Old {}
class B implements Old {}
''');
    await assertHasFix('''
import '$importUri';
class A implements New {}
class B implements New {}
''');
  }
}

@reflectiveTest
class MixinOfNonClassTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A with Old {}
class B with Old {}
''');
    await assertHasFix('''
import '$importUri';
class A with New {}
class B with New {}
''');
  }
}

class _DataDrivenTest extends BulkFixProcessorTest {
  /// Return the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  /// Add the file containing the data used by the data-driven fix with the
  /// given [content].
  void addPackageDataFile(String content) {
    addPackageFile('p', TransformSetManager.dataFileName, content);
  }

  /// Set the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    addPackageFile('p', 'lib.dart', content);
  }
}
