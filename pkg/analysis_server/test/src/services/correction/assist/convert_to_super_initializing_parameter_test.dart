// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSuperInitializingParameterTest);
  });
}

@reflectiveTest
class ConvertToSuperInitializingParameterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SUPER_INITIALIZING_PARAMETER;

  Future<void> test_named_first() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? y}) : super(x: x, y: y);
}
''');
    await assertHasAssistAt('x, int? y}) :', '''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({super.x, int? y}) : super(y: y);
}
''');
  }

  Future<void> test_named_last() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? y}) : super(x: x, y: y);
}
''');
    await assertHasAssistAt('y}) :', '''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, super.y}) : super(x: x);
}
''');
  }

  Future<void> test_named_middle() async {
    await resolveTestCode('''
class A {
  A({int? x, int? y, int? z});
}
class B extends A {
  B({int? x, int? y, int? z}) : super(x: x, y: y, z: z);
}
''');
    await assertHasAssistAt('y, int? z}) :', '''
class A {
  A({int? x, int? y, int? z});
}
class B extends A {
  B({int? x, super.y, int? z}) : super(x: x, z: z);
}
''');
  }

  Future<void> test_named_noSuperInvocation() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 1});
}
''');
    await assertNoAssistAt('x = 1');
  }

  Future<void> test_named_notGenerative() async {
    await resolveTestCode('''
class A {
  A({required int x});
}
class B extends A {
  static List<B> instances = [];
  factory B({required int x}) => instances[x];
}
''');
    await assertNoAssistAt('x}) =>');
  }

  Future<void> test_named_notInConstructor() async {
    await resolveTestCode('''
class A {
  void m({required int x}) {}
}
''');
    await assertNoAssistAt('x})');
  }

  Future<void> test_named_notPassed_unreferenced() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 0}) : super(x: 0);
}
''');
    await assertNoAssistAt('x = 0}) :');
  }

  Future<void> test_named_notPassed_usedInExpression() async {
    await resolveTestCode('''
class A {
  A({String x = ''});
}
class B extends A {
  B({required Object x}) : super(x: x.toString());
}
''');
    await assertNoAssistAt('x}) :');
  }

  Future<void> test_named_notSupported() async {
    await resolveTestCode('''
// @dart=2.16
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x);
}
''');
    await assertNoAssistAt('x}) :');
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
    await assertHasAssistAt('x}) :', '''
class A {
  A({int? x});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_named_withDifferentDefaultValue() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 2}) : super(x: x);
}
''');
    await assertHasAssistAt('x = 2}) :', '''
class A {
  A({int x = 0});
}
class B extends A {
  B({super.x = 2});
}
''');
  }

  Future<void> test_named_withEqualDefaultValue() async {
    await resolveTestCode('''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 0}) : super(x: x);
}
''');
    await assertHasAssistAt('x = 0}) :', '''
class A {
  A({int x = 0});
}
class B extends A {
  B({super.x});
}
''');
  }

  Future<void> test_optionalPositional_singleSuperParameter_only() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B([int x = 0]) : super(x);
}
''');
    await assertHasAssistAt('x = 0]', '''
class A {
  A(int x);
}
class B extends A {
  B([super.x = 0]);
}
''');
  }

  Future<void> test_requiredPositional_mixedSuperParameters_first() async {
    await resolveTestCode('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int x, int y) : super(x, y: y);
}
''');
    await assertHasAssistAt('x, int y)', '''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(super.x, int y) : super(y: y);
}
''');
  }

  Future<void> test_requiredPositional_mixedSuperParameters_last() async {
    await resolveTestCode('''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int y, int x) : super(x, y: y);
}
''');
    await assertHasAssistAt('x) :', '''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int y, super.x) : super(y: y);
}
''');
  }

  Future<void> test_requiredPositional_mixedSuperParameters_middle() async {
    await resolveTestCode('''
class A {
  A(int y, {int? z});
}
class B extends A {
  B(int x, int y, int z) : super(y, z: z);
}
''');
    await assertHasAssistAt('y, int z) :', '''
class A {
  A(int y, {int? z});
}
class B extends A {
  B(int x, super.y, int z) : super(z: z);
}
''');
  }

  Future<void> test_requiredPositional_multipleSuperParameters_first() async {
    await resolveTestCode('''
class A {
  A(int x, int y);
}
class B extends A {
  B(int x, int y) : super(x, y);
}
''');
    await assertNoAssistAt('x, int y) :');
  }

  Future<void> test_requiredPositional_multipleSuperParameters_last() async {
    await resolveTestCode('''
class A {
  A(int x, int y);
}
class B extends A {
  B(int x, int y) : super(x, y);
}
''');
    await assertNoAssistAt('y) :');
  }

  Future<void> test_requiredPositional_multipleSuperParameters_middle() async {
    await resolveTestCode('''
class A {
  A(int x, int y, int z);
}
class B extends A {
  B(int x, int y, int z) : super(x, y, z);
}
''');
    await assertNoAssistAt('y, int z) :');
  }

  Future<void> test_requiredPositional_noSuperInvocation() async {
    await resolveTestCode('''
class A {
  A();
}
class B extends A {
  B(int x);
}
''');
    await assertNoAssistAt('x);');
  }

  Future<void> test_requiredPositional_notGenerative() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  static List<B> instances = [];
  factory B(int x) => instances[x];
}
''');
    await assertNoAssistAt('x) =>');
  }

  Future<void> test_requiredPositional_notInConstructor() async {
    await resolveTestCode('''
class A {
  void m(int x) {}
}
''');
    await assertNoAssistAt('x)');
  }

  Future<void> test_requiredPositional_notPassed_unreferenced() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(0);
}
''');
    await assertNoAssistAt('x) :');
  }

  Future<void> test_requiredPositional_notPassed_usedInExpression() async {
    await resolveTestCode('''
class A {
  A(String x);
}
class B extends A {
  B(Object x) : super(x.toString());
}
''');
    await assertNoAssistAt('x) :');
  }

  Future<void> test_requiredPositional_notSupported() async {
    await resolveTestCode('''
// @dart=2.16
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(x);
}
''');
    await assertNoAssistAt('x) :');
  }

  Future<void> test_requiredPositional_singleSuperParameter_first() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y) : super(x);
}
''');
    await assertHasAssistAt('x, int y)', '''
class A {
  A(int x);
}
class B extends A {
  B(super.x, int y);
}
''');
  }

  Future<void> test_requiredPositional_singleSuperParameter_last() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y) : super(y);
}
''');
    await assertHasAssistAt('y) :', '''
class A {
  A(int x);
}
class B extends A {
  B(int x, super.y);
}
''');
  }

  Future<void> test_requiredPositional_singleSuperParameter_middle() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x, int y, int z) : super(y);
}
''');
    await assertHasAssistAt('y, int z) :', '''
class A {
  A(int x);
}
class B extends A {
  B(int x, super.y, int z);
}
''');
  }

  Future<void> test_requiredPositional_singleSuperParameter_only() async {
    await resolveTestCode('''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(x);
}
''');
    await assertHasAssistAt('x) :', '''
class A {
  A(int x);
}
class B extends A {
  B(super.x);
}
''');
  }

  Future<void> test_requiredPositional_unpassedOptionalPositional() async {
    await resolveTestCode('''
class A {
  A(int x, [int y = 0]);
}
class B extends A {
  B(int x) : super(x);
}
''');
    await assertHasAssistAt('x) :', '''
class A {
  A(int x, [int y = 0]);
}
class B extends A {
  B(super.x);
}
''');
  }
}
