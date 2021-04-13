// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddConstToConstructorTest);
    defineReflectiveTests(AddConstToImmutableConstructorTest);
  });
}

@reflectiveTest
class AddConstToConstructorTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors;

  /// Disabled in BulkFixProcessor.
  @failingTest
  Future<void> test_singleFile() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode(r'''
class C {
  const C([C c]);
}
var c = C(C());
''');
    // TODO (pq): results are incompatible w/ `unnecessary_const`
    await assertHasFix(r'''
class C {
  const C([C c]);
}
var c = const C(const C());
''');
  }
}

@reflectiveTest
class AddConstToImmutableConstructorTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors_in_immutables;

  Future<void> test_singleFile() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  A();
  /// Comment.
  A.a();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  const A();
  /// Comment.
  const A.a();
}
''');
  }
}
