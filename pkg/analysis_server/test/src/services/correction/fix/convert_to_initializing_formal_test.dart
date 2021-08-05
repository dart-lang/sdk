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
    defineReflectiveTests(ConvertToInitializingFormalTest);
  });
}

@reflectiveTest
class ConvertToInitializingFormalTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_INITIALIZING_FORMAL;

  @override
  String get lintCode => LintNames.prefer_initializing_formals;

  Future<void> test_assignment_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int a) {
    this.a = a;
  }
}
''');
    await assertHasFix('''
class C {
  int a = 0;
  C(this.a);
}
''');
  }

  Future<void> test_assignment_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int a) {
    this.a = a;
    print(a);
  }
}
''');
    await assertHasFix('''
class C {
  int a = 0;
  C(this.a) {
    print(a);
  }
}
''');
  }

  Future<void> test_initializer_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  C(int a) : this.a = a;
}
''');
    await assertHasFix('''
class C {
  int a;
  C(this.a);
}
''');
  }

  Future<void> test_initializer_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  int b;
  C(int a) : this.a = a, this.b = 2;
}
''');
    await assertHasFix('''
class C {
  int a;
  int b;
  C(this.a) : this.b = 2;
}
''');
  }
}
