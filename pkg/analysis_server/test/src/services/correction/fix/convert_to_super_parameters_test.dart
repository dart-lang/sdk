// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSuperParametersBulkTest);
    defineReflectiveTests(ConvertToSuperParametersTest);
  });
}

@reflectiveTest
class ConvertToSuperParametersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_super_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  A.m({int? x});
  A.n(int x);
}
class B extends A {
  B.m({int? x}) : super.m(x: x);
  B.n(int x) : super.n(x);
}
''');
    await assertHasFix('''
class A {
  A.m({int? x});
  A.n(int x);
}
class B extends A {
  B.m({super.x}) : super.m();
  B.n(super.x) : super.n();
}
''');
  }
}

@reflectiveTest
class ConvertToSuperParametersTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_SUPER_PARAMETERS;

  @override
  String get lintCode => LintNames.use_super_parameters;

  Future<void> test_defaultValue_different_named() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 2}) : super(x: x);
}
''');
    await assertHasFix('''
class A {
  A({int x = 0});
}
class B extends A {
  B({super.x = 2});
}
''');
  }

  Future<void> test_defaultValue_different_positional() async {
    await resolveTestCode('''
class A {
  A([int x = 0]);
}
class B extends A {
  B([int x = 2]) : super(x);
}
''');
    await assertHasFix('''
class A {
  A([int x = 0]);
}
class B extends A {
  B([super.x = 2]);
}
''');
  }

  Future<void> test_defaultValue_equal_named() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 0}) : super(x: x);
}
''');
    await assertHasFix('''
class A {
  A({int x = 0});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_defaultValue_equal_positional() async {
    await resolveTestCode('''
class A {
  A([int x = 0]);
}
class B extends A {
  B([int x = 0]) : super(x);
}
''');
    await assertHasFix('''
class A {
  A([int x = 0]);
}
class B extends A {
  B([super.x]);
}
''');
  }

  Future<void> test_mixed_first() async {
    await resolveTestCode('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int x, int y) : super(x, y: y);
}
''');
    await assertHasFix('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(super.x, int y) : super(y: y);
}
''');
  }

  Future<void> test_mixed_last() async {
    await resolveTestCode('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int y, int x) : super(x, y: y);
}
''');
    await assertHasFix('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int y, super.x) : super(y: y);
}
''');
  }

  Future<void> test_mixed_middle() async {
    await resolveTestCode('''
class A {
  A(int y, {int? z});
}
class B extends A {
  B(int x, int y, int z) : super(y, z: z);
}
''');
    await assertHasFix('''
class A {
  A(int y, {int? z});
}
class B extends A {
  B(int x, super.y, int z) : super(z: z);
}
''');
  }

  Future<void> test_named_all_reversedOrder() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? y, int? x}) : super(x: x, y: y);
}
''');
    await assertHasFix('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({super.y, super.x});
}
''');
  }

  Future<void> test_named_all_sameOrder() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? y}) : super(x: x, y: y);
}
''');
    await assertHasFix('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({super.x, super.y});
}
''');
  }

  Future<void> test_named_first() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, required int y}) : super(x: x, y: y + 1);
}
''');
    await assertHasFix('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({super.x, required int y}) : super(y: y + 1);
}
''');
  }

  Future<void> test_named_last() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({required int x, int? y}) : super(x: x + 1, y: y);
}
''');
    await assertHasFix('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({required int x, super.y}) : super(x: x + 1);
}
''');
  }

  Future<void> test_named_middle() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y, int? z});
}
class B extends A {
  B({required int x, int? y, required int z}) : super(x: x + 1, y: y, z: z + 1);
}
''');
    await assertHasFix('''
class A {
  A({int? x, int? y, int? z});
}
class B extends A {
  B({required int x, super.y, required int z}) : super(x: x + 1, z: z + 1);
}
''');
  }

  Future<void> test_named_only() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x);
}
''');
    await assertHasFix('''
class A {
  A({int? x});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_positional_first() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y) : super(x);
}
''');
    await assertHasFix('''
class A {
  A(int x);
}
class B extends A {
  B(super.x, int y);
}
''');
  }

  Future<void> test_positional_functionTypedFormalParameter() async {
    await resolveTestCode('''
class A {
  A(int x(int));
}
class B extends A {
  B(int x(int)) : super(x);
}
''');
    await assertHasFix('''
class A {
  A(int x(int));
}
class B extends A {
  B(super.x);
}
''');
  }

  Future<void> test_positional_last() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y) : super(y);
}
''');
    await assertHasFix('''
class A {
  A(int x);
}
class B extends A {
  B(int x, super.y);
}
''');
  }

  Future<void> test_positional_middle() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y, int z) : super(y);
}
''');
    await assertHasFix('''
class A {
  A(int x);
}
class B extends A {
  B(int x, super.y, int z);
}
''');
  }

  Future<void> test_positional_multiple_optional() async {
    await resolveTestCode('''
class A {
  A([int? x, int? y]);
}
class B extends A {
  B([int? x, int? y]) : super(x, y);
}
''');
    await assertHasFix('''
class A {
  A([int? x, int? y]);
}
class B extends A {
  B([super.x, super.y]);
}
''');
  }

  Future<void> test_positional_multiple_required() async {
    await resolveTestCode('''
class A {
  A(int x, int y);
}
class B extends A {
  B(int x, int y) : super(x, y);
}
''');
    await assertHasFix('''
class A {
  A(int x, int y);
}
class B extends A {
  B(super.x, super.y);
}
''');
  }

  Future<void> test_positional_multiple_requiredAndOptional() async {
    await resolveTestCode('''
class A {
  A(int x, [int? y]);
}
class B extends A {
  B(int x, [int? y]) : super(x, y);
}
''');
    await assertHasFix('''
class A {
  A(int x, [int? y]);
}
class B extends A {
  B(super.x, [super.y]);
}
''');
  }

  Future<void> test_positional_only() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(x);
}
''');
    await assertHasFix('''
class A {
  A(int x);
}
class B extends A {
  B(super.x);
}
''');
  }

  Future<void> test_positional_only_optional() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B([int x = 0]) : super(x);
}
''');
    await assertHasFix('''
class A {
  A(int x);
}
class B extends A {
  B([super.x = 0]);
}
''');
  }

  Future<void> test_positional_unpassedOptionalPositional() async {
    await resolveTestCode('''
class A {
  A(int x, [int y = 0]);
}
class B extends A {
  B(int x) : super(x);
}
''');
    await assertHasFix('''
class A {
  A(int x, [int y = 0]);
}
class B extends A {
  B(super.x);
}
''');
  }
}
