// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddOverrideTest);
  });
}

@reflectiveTest
class AddOverrideTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_OVERRIDE;

  @override
  String get lintCode => LintNames.annotate_overrides;

  Future<void> test_field() async {
    await resolveTestUnit('''
class abstract Test {
  int get t;
}
class Sub extends Test {
  int /*LINT*/t = 42;
}
''');
    await assertHasFix('''
class abstract Test {
  int get t;
}
class Sub extends Test {
  @override
  int t = 42;
}
''');
  }

  Future<void> test_getter() async {
    await resolveTestUnit('''
class Test {
  int get t => null;
}
class Sub extends Test {
  int get /*LINT*/t => null;
}
''');
    await assertHasFix('''
class Test {
  int get t => null;
}
class Sub extends Test {
  @override
  int get t => null;
}
''');
  }

  Future<void> test_method() async {
    await resolveTestUnit('''
class Test {
  void t() { }
}
class Sub extends Test {
  void /*LINT*/t() { }
}
''');
    await assertHasFix('''
class Test {
  void t() { }
}
class Sub extends Test {
  @override
  void t() { }
}
''');
  }

  Future<void> test_method_with_doc_comment() async {
    await resolveTestUnit('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  void /*LINT*/t() { }
}
''');
    await assertHasFix('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @override
  void t() { }
}
''');
  }

  Future<void> test_method_with_doc_comment_2() async {
    await resolveTestUnit('''
class Test {
  void t() { }
}
class Sub extends Test {
  /**
   * Doc comment.
   */
  void /*LINT*/t() { }
}
''');
    await assertHasFix('''
class Test {
  void t() { }
}
class Sub extends Test {
  /**
   * Doc comment.
   */
  @override
  void t() { }
}
''');
  }

  Future<void> test_method_with_doc_comment_and_metadata() async {
    await resolveTestUnit('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @foo
  void /*LINT*/t() { }
}
''');
    await assertHasFix('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @override
  @foo
  void t() { }
}
''');
  }

  Future<void> test_method_with_non_doc_comment() async {
    await resolveTestUnit('''
class Test {
  void t() { }
}
class Sub extends Test {
  // Non-doc comment.
  void /*LINT*/t() { }
}
''');
    await assertHasFix('''
class Test {
  void t() { }
}
class Sub extends Test {
  // Non-doc comment.
  @override
  void t() { }
}
''');
  }
}
