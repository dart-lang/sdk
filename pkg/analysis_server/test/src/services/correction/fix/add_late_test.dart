// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddLatePreNnbdTest);
    defineReflectiveTests(AddLateTest);
  });
}

@reflectiveTest
class AddLatePreNnbdTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_LATE;

  @override
  String? get testPackageLanguageVersion => '2.9';

  Future<void> test_withFinal() async {
    await resolveTestCode('''
class C {
  final String s;
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class AddLateTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_LATE;

  Future<void> test_changeInImportedLib() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final String s;
}
''');
    await resolveTestCode('''
import 'a.dart';

void f(C c) {
  c.s = '';
}
''');
    await assertHasFix('''
class C {
  late final String s;
}
''', target: '$testPackageLibPath/a.dart');
  }

  Future<void> test_changeInPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

class C {
  final String s;
}
''');
    await resolveTestCode('''
part of 'a.dart';

void f(C c) {
  c.s = '';
}
''');
    await assertHasFix('''
part 'test.dart';

class C {
  late final String s;
}
''', target: '$testPackageLibPath/a.dart');
  }

  Future<void> test_withFinal() async {
    await resolveTestCode('''
class C {
  final String s;
}
''');
    await assertHasFix('''
class C {
  late final String s;
}
''');
  }

  Future<void> test_withFinalAssignedInConstructor() async {
    await resolveTestCode('''
class C {
  final String s;
  C() {
    s = '';
  }
}
''');
    await assertHasFix('''
class C {
  late final String s;
  C() {
    s = '';
  }
}
''',
        errorFilter: (error) =>
            error.errorCode == CompileTimeErrorCode.ASSIGNMENT_TO_FINAL);
  }

  Future<void> test_withFinalAssignedInLibrary() async {
    await resolveTestCode('''
class C {
  final String s;
}

void f(C c) {
  c.s = '';
}
''');
    await assertHasFix('''
class C {
  late final String s;
}

void f(C c) {
  c.s = '';
}
''',
        errorFilter: (error) =>
            error.errorCode == CompileTimeErrorCode.ASSIGNMENT_TO_FINAL);
  }

  Future<void> test_withFinalStaticAssignedInConstructor() async {
    await resolveTestCode('''
class C {
  static final String s;
  C() {
    s = '';
  }
}
''');
    await assertHasFix('''
class C {
  static late final String s;
  C() {
    s = '';
  }
}
''',
        errorFilter: (error) =>
            error.errorCode == CompileTimeErrorCode.ASSIGNMENT_TO_FINAL);
  }

  Future<void> test_withLate() async {
    await resolveTestCode('''
class C {
  late s;
}
''');
    await assertNoFix();
  }

  Future<void> test_withType() async {
    await resolveTestCode('''
class C {
  String s;
}
''');
    await assertHasFix('''
class C {
  late String s;
}
''');
  }
}
