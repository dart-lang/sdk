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
  });
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
''', errorFilter: (e) => e.offset == testCode.indexOf('int a'));
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
  C({int x});
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
  C([int x]);
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
