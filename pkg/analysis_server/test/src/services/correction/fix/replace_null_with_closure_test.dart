// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNullWithClosureTest);
  });
}

@reflectiveTest
class ReplaceNullWithClosureTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_NULL_WITH_CLOSURE;

  @override
  String get lintCode => LintNames.null_closures;

  /// Currently failing since the LINT annotation is tagging the ArgumentList
  /// where the fix (and lint) expect a NullLiteral.
  /// todo (pq): re-write FixProcessorLintTest to run the actual lints.
  @failingTest
  Future<void> test_null_closure_literal() async {
    await resolveTestUnit('''
void f(dynamic x) { }
main() {
  f(null/*LINT*/);
}
''');
    await assertHasFix('''
void f(dynamic x) { }
main() {
  f(() => null);
}
''');
  }

  Future<void> test_null_closure_named_expression() async {
    await resolveTestUnit('''
main() {
  [1, 3, 5].firstWhere((e) => e.isOdd, orElse: /*LINT*/null);
}
''');
    await assertHasFix('''
main() {
  [1, 3, 5].firstWhere((e) => e.isOdd, orElse: () => null);
}
''');
  }

  Future<void> test_null_closure_named_expression_with_args() async {
    await resolveTestUnit('''
void f({int closure(x, y)}) { }
main() {
  f(closure: /*LINT*/null);
}
''');
    await assertHasFix('''
void f({int closure(x, y)}) { }
main() {
  f(closure: (x, y) => null);
}
''');
  }

  Future<void> test_null_closure_named_expression_with_args_2() async {
    await resolveTestUnit('''
void f({int closure(x, y, {z})}) { }
main() {
  f(closure: /*LINT*/null);
}
''');
    await assertHasFix('''
void f({int closure(x, y, {z})}) { }
main() {
  f(closure: (x, y, {z}) => null);
}
''');
  }
}
