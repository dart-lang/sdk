// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingNameTest);
  });
}

@reflectiveTest
class MissingNameTest extends PubspecFixTest {
  @override
  FixKind get kind => PubspecFixKind.addName;

  @failingTest
  Future<void> test_empty_withComment() async {
    /// The test fails because the comment is included in the span of the
    /// `YamlScalar` that is produced as the contents of the document.
    validatePubspec('''
# comment
''');
    await assertHasFix('''
# comment
name: test
''');
  }

  Future<void> test_empty_withoutComment() async {
    validatePubspec('''
''');
    await assertHasFix('''
name: test
''');
  }

  Future<void> test_nonEmpty_withComment() async {
    validatePubspec('''
# comment
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
    await assertHasFix('''
# comment
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
  }

  Future<void> test_nonEmpty_withoutComment() async {
    validatePubspec('''
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
  }
}
