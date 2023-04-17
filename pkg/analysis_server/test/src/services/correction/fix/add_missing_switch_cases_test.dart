// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingSwitchCasesTest);
  });
}

@reflectiveTest
class AddMissingSwitchCasesTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_SWITCH_CASES;

  Future<void> test_switchExpression_enum_hasFirst() async {
    await resolveTestCode('''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFix('''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => null,
  };
}
''');
  }

  Future<void> test_switchExpression_num_anyDouble_intProperty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
    // TODO: Handle this case.
    int() => null,
  };
}
''');
  }

  Future<void> test_switchExpression_num_doubleAny() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    // TODO: Handle this case.
    int() => null,
  };
}
''');
  }

  Future<void> test_switchExpression_num_doubleAny_intWhen() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
    // TODO: Handle this case.
    int() => null,
  };
}
''');
  }

  Future<void> test_switchExpression_num_empty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {};
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    // TODO: Handle this case.
    double() => null,
  };
}
''');
  }

  Future<void> test_switchStatement_num_doubleAny() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
      break;
  }
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
      break;
    case int():
      // TODO: Handle this case.
  }
}
''');
  }

  Future<void> test_switchStatement_num_doubleAny_intProperty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
      break;
    case int(hashCode: 5):
      break;
  }
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
      break;
    case int(hashCode: 5):
      break;
    case int():
      // TODO: Handle this case.
  }
}
''');
  }

  Future<void> test_switchStatement_num_empty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {}
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
      // TODO: Handle this case.
  }
}
''');
  }
}
