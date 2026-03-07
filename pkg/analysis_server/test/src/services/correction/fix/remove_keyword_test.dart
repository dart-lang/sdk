// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCovariantModifierInPrimaryConstructorTest);
    defineReflectiveTests(RemoveKeywordBulkTest);
  });
}

@reflectiveTest
class InvalidCovariantModifierInPrimaryConstructorTest
    extends RemoveKeywordTest {
  Future<void> test_requiredNamed_withComment() async {
    await resolveTestCode('''
class C({covariant /* ? */ final int v = 0});
''');
    await assertHasFix('''
class C({/* ? */ final int v = 0});
''');
  }

  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
class C<T>(covariant final T v);
''');
    await assertHasFix('''
class C<T>(final T v);
''');
  }
}

@reflectiveTest
class RemoveKeywordBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A(covariant final int v);
class B(covariant final int v);
class C<T>(covariant final T v);
''');
    await assertHasFix('''
class A(final int v);
class B(final int v);
class C<T>(final T v);
''');
  }
}

class RemoveKeywordTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeKeyword;
}
