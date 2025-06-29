// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddLateTest);
  });
}

@reflectiveTest
class AddLateTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.addLate;

  Future<void> test_field_const() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class C {
  const ^s = '';
}
''');
    await assertNoAssist();
  }

  Future<void> test_field_final() async {
    await resolveTestCode('''
class C {
  final s^ = '';
}
''');
    await assertHasAssist('''
class C {
  late final s = '';
}
''');
  }

  Future<void> test_field_finalType() async {
    await resolveTestCode('''
class C {
  final String s^ = '';
}
''');
    await assertHasAssist('''
class C {
  late final String s = '';
}
''');
  }

  Future<void> test_field_finalType_in_other_file() async {
    late var test2FilePath = '$testPackageLibPath/test2.dart';
    var test2File = getFile(test2FilePath);
    newFile(test2File.path, '''
class C {
  final String s;
  C(this.s);
}
''');
    await resolveTestCode('''
import 'test2.dart';

void foo() {
  C c = C('42');
  c.s^;
}
''');

    // Don't give assists for another file.
    await assertNoAssist();
  }

  Future<void> test_field_finalType_when_in_constructor() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class C {
  final String s;
  C() {
    s^ = '';
  }
}
''');
    await assertHasAssist('''
class C {
  late final String s;
  C() {
    s = '';
  }
}
''');
  }

  Future<void> test_field_type() async {
    await resolveTestCode('''
class C {
  String s^ = '';
}
''');
    await assertHasAssist('''
class C {
  late String s = '';
}
''');
  }

  Future<void> test_field_var() async {
    await resolveTestCode('''
class C {
  var s^;
}
''');
    await assertHasAssist('''
class C {
  late var s;
}
''');
  }

  Future<void> test_local() async {
    await resolveTestCode('''
void foo() {
  String ^s;
}
''');
    await assertHasAssist('''
void foo() {
  late String s;
}
''');
  }
}
