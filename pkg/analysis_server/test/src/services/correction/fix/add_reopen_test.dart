// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddReopenBulkTest);
    defineReflectiveTests(AddReopenTest);
  });
}

@reflectiveTest
class AddReopenBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.implicit_reopen;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
final class F {}
sealed class S extends F {}
base class C extends S {}
base class D extends S {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

final class F {}
sealed class S extends F {}
@reopen
base class C extends S {}
@reopen
base class D extends S {}
''');
  }
}

@reflectiveTest
class AddReopenTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_REOPEN;

  @override
  String get lintCode => LintNames.implicit_reopen;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_inducedFinal() async {
    await resolveTestCode('''
final class F {}
sealed class S extends F {}
base class C extends S {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

final class F {}
sealed class S extends F {}
@reopen
base class C extends S {}
''');
  }

  Future<void> test_inducedFinal_comment() async {
    await resolveTestCode('''
final class F {}
sealed class S extends F {}
/// Class C.
base class C extends S {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

final class F {}
sealed class S extends F {}
/// Class C.
@reopen
base class C extends S {}
''');
  }

  Future<void> test_inducedFinal_prefixed() async {
    await resolveTestCode('''
import 'package:meta/meta.dart' as meta;

@meta.visibleForTesting
final class F {}
sealed class S extends F {}
base class C extends S {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart' as meta;

@meta.visibleForTesting
final class F {}
sealed class S extends F {}
@meta.reopen
base class C extends S {}
''');
  }
}
