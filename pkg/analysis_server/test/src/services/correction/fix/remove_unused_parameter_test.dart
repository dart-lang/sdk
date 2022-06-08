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
    defineReflectiveTests(RemoveUnusedParameterTest);
    defineReflectiveTests(RemoveUnusedParameterBulkTest);
    defineReflectiveTests(RemoveUnusedParameterTestHint);
    defineReflectiveTests(RemoveUnusedParameterBulkTestHint);
  });
}

@reflectiveTest
class RemoveUnusedParameterBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_unused_constructor_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  int y;
  C({int x = 0, this.y = 0, int z = 0});
}
''');
    await assertHasFix('''
class C {
  int y;
  C({this.y = 0});
}
''');
  }
}

@reflectiveTest
class RemoveUnusedParameterBulkTestHint extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
class _C {
  int? a;
  int b;
  int? c;
  _C([this.a, this.b = 1, this.c]);
}

class _C2 {
  int? a;
  int b;
  int? c;
  _C2({this.a, this.b = 1, this.c});
}

void main() {
  print(_C());
  print(_C2());
}
''');
    await assertHasFix('''
class _C {
  int? a;
  int b;
  int? c;
  _C([this.b = 1]);
}

class _C2 {
  int? a;
  int b;
  int? c;
  _C2({this.b = 1});
}

void main() {
  print(_C());
  print(_C2());
}
''');
  }
}

@reflectiveTest
class RemoveUnusedParameterTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_PARAMETER;

  @override
  String get lintCode => LintNames.avoid_unused_constructor_parameters;

  Future<void> test_first_optionalNamed_second_optionalNamed() async {
    await resolveTestCode('''
class C {
  int y;
  C({int x = 0, this.y = 0});
}
''');
    await assertHasFix('''
class C {
  int y;
  C({this.y = 0});
}
''');
  }

  Future<void> test_first_optionalPositional_second_optionalPositional() async {
    await resolveTestCode('''
class C {
  int y;
  C([int x = 0, this.y = 0]);
}
''');
    await assertHasFix('''
class C {
  int y;
  C([this.y = 0]);
}
''');
  }

  Future<void> test_first_required_second_optionalInvalid() async {
    await resolveTestCode('''
class C {
  C(int a, int b = 1,);
}
''');
    await assertHasFix('''
class C {
  C(int b = 1,);
}
''',
        errorFilter: (e) => e.offset == testCode.indexOf('int a'),
        allowFixAllFixes: true);
  }

  Future<void> test_first_requiredPositional_second_optionalNamed() async {
    await resolveTestCode('''
class C {
  int y;
  C(int x, {this.y = 0});
}
''');
    await assertHasFix('''
class C {
  int y;
  C({this.y = 0});
}
''');
  }

  Future<void> test_first_requiredPositional_second_optionalPositional() async {
    await resolveTestCode('''
class C {
  int y;
  C(int x, [this.y = 0]);
}
''');
    await assertHasFix('''
class C {
  int y;
  C([this.y = 0]);
}
''');
  }

  Future<void> test_first_requiredPositional_second_requiredPositional() async {
    await resolveTestCode('''
class C {
  int y;
  C(int x, this.y);
}
''');
    await assertHasFix('''
class C {
  int y;
  C(this.y);
}
''');
  }

  Future<void> test_last_optionalNamed_noDefaultValue() async {
    await resolveTestCode('''
class C {
  C({int? x});
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_last_optionalNamed_previous_optionalNamed() async {
    await resolveTestCode('''
class C {
  int x;
  C({this.x = 0, int y = 0});
}
''');
    await assertHasFix('''
class C {
  int x;
  C({this.x = 0});
}
''');
  }

  Future<void> test_last_optionalNamed_previous_requiredPositional() async {
    await resolveTestCode('''
class C {
  int x;
  C(this.x, {int y = 0});
}
''');
    await assertHasFix('''
class C {
  int x;
  C(this.x);
}
''');
  }

  Future<void> test_last_optionalPositional_noDefaultValue() async {
    await resolveTestCode('''
class C {
  C([int? x]);
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void>
      test_last_optionalPositional_previous_optionalPositional() async {
    await resolveTestCode('''
class C {
  int x;
  C([this.x = 0, int y = 0]);
}
''');
    await assertHasFix('''
class C {
  int x;
  C([this.x = 0]);
}
''');
  }

  Future<void>
      test_last_optionalPositional_previous_requiredPositional() async {
    await resolveTestCode('''
class C {
  int x;
  C(this.x, [int y = 0]);
}
''');
    await assertHasFix('''
class C {
  int x;
  C(this.x);
}
''');
  }

  Future<void>
      test_last_requiredPositional_previous_requiredPositional() async {
    await resolveTestCode('''
class C {
  int x;
  C(this.x, int y);
}
''');
    await assertHasFix('''
class C {
  int x;
  C(this.x);
}
''');
  }

  Future<void> test_only_optionalNamed() async {
    await resolveTestCode('''
class C {
  C({int x = 0});
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_only_optionalPositional() async {
    await resolveTestCode('''
class C {
  C([int x = 0]);
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_only_requiredPositional() async {
    await resolveTestCode('''
class C {
  C(int x);
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }
}

/// Situations exist where unused parameters are flagged by hints, rather
/// than lints.   Apply the same algorithm for parameter removal as for
/// lints.
@reflectiveTest
class RemoveUnusedParameterTestHint extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_PARAMETER;

  Future<void> test_optionalNamed() async {
    await resolveTestCode('''
class _C {
  final int variable;
  int? somethingElse;
  _C({required this.variable, this.somethingElse});
}

void main() {
  print(_C(variable: 123));
}
''');
    await assertHasFix('''
class _C {
  final int variable;
  int? somethingElse;
  _C({required this.variable});
}

void main() {
  print(_C(variable: 123));
}
''');
  }

  Future<void> test_optionalPositional() async {
    await resolveTestCode('''
class _C {
  int? somethingElse;
  int? entirely;
  _C([this.somethingElse, this.entirely]);
}

void main() {
  print(_C(123));
}
''');
    await assertHasFix('''
class _C {
  int? somethingElse;
  int? entirely;
  _C([this.somethingElse]);
}

void main() {
  print(_C(123));
}
''');
  }

  Future<void> test_optionalSuperNamed() async {
    await resolveTestCode('''
class B {
  final int? key;
  B({this.key});
}

class _C extends B {
  final int variable;
  _C({super.key, required this.variable});
}

void main() {
  print(_C(variable: 123));
}
''');
    await assertHasFix('''
class B {
  final int? key;
  B({this.key});
}

class _C extends B {
  final int variable;
  _C({required this.variable});
}

void main() {
  print(_C(variable: 123));
}
''');
  }
}
