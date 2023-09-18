// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddRedeclareBulkTest);
    defineReflectiveTests(AddRedeclareTest);
  });
}

@reflectiveTest
class AddRedeclareBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.annotate_redeclares;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  void f() {}
  void g() {}
}

extension type E(C c) implements C {
  /// Comment.
  void f() {}
  void g() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {
  void f() {}
  void g() {}
}

extension type E(C c) implements C {
  /// Comment.
  @redeclare
  void f() {}
  @redeclare
  void g() {}
}
''');
  }
}

@reflectiveTest
class AddRedeclareTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_REDECLARE;

  @override
  String get lintCode => LintNames.annotate_redeclares;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  void f() {}
}

extension type E(C c) implements C {
  void f() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {
  void f() {}
}

extension type E(C c) implements C {
  @redeclare
  void f() {}
}
''');
  }

  Future<void> test_method_withComment() async {
    await resolveTestCode('''
class C {
  void f() {}
}

extension type E(C c) implements C {
  /// Comment.
  void f() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {
  void f() {}
}

extension type E(C c) implements C {
  /// Comment.
  @redeclare
  void f() {}
}
''');
  }
}
