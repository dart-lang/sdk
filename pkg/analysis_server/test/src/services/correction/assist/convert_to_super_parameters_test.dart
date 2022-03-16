// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSuperParametersTest);
  });
}

@reflectiveTest
class ConvertToSuperParametersTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SUPER_PARAMETERS;

  Future<void> test_cursorLocation_named_onClassName() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B.name({int? x}) : super(x: x);
}
''');
    await assertHasAssistAt('B.name', '''
class A {
  A({int? x});
}
class B extends A {
  B.name({super.x});
}
''');
  }

  Future<void> test_cursorLocation_named_onConstructorName() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B.name({int? x}) : super(x: x);
}
''');
    await assertHasAssistAt('ame(', '''
class A {
  A({int? x});
}
class B extends A {
  B.name({super.x});
}
''');
  }

  Future<void> test_cursorLocation_unnamed_notOnClassName() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x);
}
''');
    await assertNoAssistAt('super');
  }

  Future<void> test_cursorLocation_unnamed_onClassName() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x);
}
''');
    await assertHasAssistAt('B(', '''
class A {
  A({int? x});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_defaultValue_different_named() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 2}) : super(x: x);
}
''');
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
class A {
  A([int x = 0]);
}
class B extends A {
  B([super.x]);
}
''');
  }

  Future<void> test_invalid_namedToPositional() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B({int x = 0}) : super(x);
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_noSuperInvocation_factory() async {
    await resolveTestCode('''
class A {
  A({required int x});
}
class B extends A {
  static List<B> instances = [];
  factory B({required int x}) => instances[x];
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_noSuperInvocation_generative() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 1});
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_notAConstructor() async {
    await resolveTestCode('''
class A {
  void m({required int x}) {}
}
''');
    await assertNoAssistAt('m(');
  }

  Future<void> test_invalid_notPassed_unreferenced_named() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 0}) : super(x: 0);
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_notPassed_unreferenced_positional() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(0);
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_notPassed_usedInExpression_named() async {
    await resolveTestCode('''
class A {
  A({String x = ''});
}
class B extends A {
  B({required Object x}) : super(x: x.toString());
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_notPassed_usedInExpression_positional() async {
    await resolveTestCode('''
class A {
  A(String x);
}
class B extends A {
  B(Object x) : super(x.toString());
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_optedOut() async {
    await resolveTestCode('''
// @dart=2.16
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x);
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_positionalToNamed() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B(int x) : super(x: x);
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_referencedInBody_named() async {
    await resolveTestCode('''
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x) {
    print(x);
  }
}
''');
    await assertNoAssistAt('B(');
  }

  Future<void> test_invalid_referencedInBody_positional() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(x) {
    print(x);
  }
}
''');
    await assertNoAssistAt('B(');
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
class A {
  A({int? x});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_namedConstructor() async {
    await resolveTestCode('''
class A {
  A.m({int? x});
}
class B extends A {
  B.m({int? x}) : super.m(x: x);
}
''');
    await assertHasAssistAt('B.m', '''
class A {
  A.m({int? x});
}
class B extends A {
  B.m({super.x}) : super.m();
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
class A {
  A(int x);
}
class B extends A {
  B(int x, super.y, int z);
}
''');
  }

  Future<void> test_positional_multiple_notInOrder() async {
    await resolveTestCode('''
class A {
  A(int x, int y);
}
class B extends A {
  B(int x, int y) : super(y, x);
}
''');
    await assertNoAssistAt('B(');
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
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
    await assertHasAssistAt('B(', '''
class A {
  A(int x, [int y = 0]);
}
class B extends A {
  B(super.x);
}
''');
  }
}
