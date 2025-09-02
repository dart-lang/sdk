// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibrarySdkPrefixedTest);
    defineReflectiveTests(ImportLibrarySdkPrefixedWithShowTest);
    defineReflectiveTests(ImportLibrarySdkPriorityTest);
    defineReflectiveTests(ImportLibrarySdkTest);
    defineReflectiveTests(ImportLibrarySdkWithShowTest);
  });
}

@reflectiveTest
class ImportLibrarySdkPrefixedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED;

  Future<void> test_prefixed_class_async() async {
    await resolveTestCode('''
void f() {
  prefix.Completer? c;
  print('\$c');
}
''');
    await assertHasFix('''
import 'dart:async' as prefix;

void f() {
  prefix.Completer? c;
  print('\$c');
}
''');
  }
}

@reflectiveTest
class ImportLibrarySdkPrefixedWithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED_SHOW;

  Future<void> test_prefixed_class_async() async {
    await resolveTestCode('''
void f() {
  prefix.Completer? c;
  print('\$c');
}
''');
    await assertHasFix('''
import 'dart:async' as prefix show Completer;

void f() {
  prefix.Completer? c;
  print('\$c');
}
''');
  }
}

@reflectiveTest
class ImportLibrarySdkPriorityTest extends FixPriorityTest {
  Future<void> test_sdksFirst_prefixed() async {
    newFile('$testPackageLibPath/lib.dart', '''
int max(int a) => a;
''');
    await resolveTestCode('''
import 'lib.dart' as lib;

void f() {
  math.max();
}
''');
    await assertFixPriorityOrder([
      DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED,
      DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED_SHOW,
      DartFixKind.IMPORT_LIBRARY_PREFIX,
    ]);
  }

  Future<void> test_sdksFirst_project1() async {
    newFile('$testPackageLibPath/lib.dart', '''
int max(int a) => a;
''');
    await resolveTestCode('''
void f() {
  max();
}
''');
    await assertFixPriorityOrder([
      DartFixKind.IMPORT_LIBRARY_SDK,
      DartFixKind.IMPORT_LIBRARY_SDK_SHOW,
      DartFixKind.IMPORT_LIBRARY_PROJECT1,
    ]);
  }
}

@reflectiveTest
class ImportLibrarySdkTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK;

  Future<void> test_alreadyImported_sdk() async {
    await resolveTestCode('''
import 'dart:collection' show HashMap;
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('\$s \$f');
}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_asExpression() async {
    await resolveTestCode('''
void f(p) {
  p as HashMap;
}
''');
    await assertHasFix('''
import 'dart:collection';

void f(p) {
  p as HashMap;
}
''');
  }

  Future<void> test_withClass_dartHtml() async {
    await resolveTestCode('''
void f(KeyEvent e) {}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_extends() async {
    await resolveTestCode('''
class MyCompleter extends Completer<String> {}
''');
    await assertHasFix('''
import 'dart:async';

class MyCompleter extends Completer<String> {}
''');
  }

  Future<void> test_withClass_implements() async {
    await resolveTestCode('''
class MyCompleter implements Completer<String> {}
''');
    await assertHasFix('''
import 'dart:async';

class MyCompleter implements Completer<String> {}
''');
  }

  Future<void> test_withClass_instanceCreation_explicitNew() async {
    await resolveTestCode('''
class C {
  foo() {
    new HashMap();
  }
}
''');
    await assertHasFix('''
import 'dart:collection';

class C {
  foo() {
    new HashMap();
  }
}
''');
  }

  Future<void>
  test_withClass_instanceCreation_explicitNew_namedConstructor() async {
    await resolveTestCode('''
class C {
  foo() {
    new Completer.sync(0);
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    new Completer.sync(0);
  }
}
''');
  }

  Future<void> test_withClass_instanceCreation_implicitNew() async {
    await resolveTestCode('''
class C {
  foo() {
    HashMap();
  }
}
''');
    await assertHasFix('''
import 'dart:collection';

class C {
  foo() {
    HashMap();
  }
}
''');
  }

  Future<void>
  test_withClass_instanceCreation_implicitNew_namedConstructor() async {
    await resolveTestCode('''
class C {
  foo() {
    Completer.sync(0);
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    Completer.sync(0);
  }
}
''');
  }

  Future<void> test_withClass_invocationTarget() async {
    await resolveTestCode('''
void f() {
  Timer.run(null);
}
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  Timer.run(null);
}
''');
  }

  Future<void> test_withClass_IsExpression() async {
    await resolveTestCode('''
void f(p) {
  p is Completer;
}
''');
    await assertHasFix('''
import 'dart:async';

void f(p) {
  p is Completer;
}
''');
  }

  Future<void> test_withClass_itemOfList() async {
    await resolveTestCode('''
void f() {
  var a = [Completer];
  print(a);
}
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  var a = [Completer];
  print(a);
}
''');
  }

  Future<void> test_withClass_itemOfList_inAnnotation() async {
    await resolveTestCode('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Completer])
void f() {}
''');
    await assertHasFix(
      '''
import 'dart:async';

class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Completer])
void f() {}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedIdentifier;
      },
    );
  }

  Future<void> test_withClass_typeAnnotation() async {
    await resolveTestCode('''
void f() {
  Completer f = null;
  print(f);
}
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  Completer f = null;
  print(f);
}
''');
  }

  Future<void> test_withClass_typeAnnotation_PrefixedIdentifier() async {
    await resolveTestCode('''
void f() {
  Timer.run;
}
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  Timer.run;
}
''');
  }

  Future<void> test_withClass_typeArgument() async {
    await resolveTestCode('''
void f() {
  List<Completer> completers = [];
  print(completers);
}
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  List<Completer> completers = [];
  print(completers);
}
''');
  }

  Future<void> test_withClass_with() async {
    await resolveTestCode('''
class MyCompleter with Completer<String> {}
''');
    await assertHasFix('''
import 'dart:async';

class MyCompleter with Completer<String> {}
''');
  }

  Future<void> test_withTopLevelVariable() async {
    await resolveTestCode('''
void f() {
  print(pi);
}
''');
    await assertHasFix('''
import 'dart:math';

void f() {
  print(pi);
}
''');
  }

  Future<void> test_withTopLevelVariable_annotation() async {
    await resolveTestCode('''
@pi
void f() {
}
''');
    await assertHasFix('''
import 'dart:math';

@pi
void f() {
}
''');
  }
}

@reflectiveTest
class ImportLibrarySdkWithShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK_SHOW;

  Future<void> test_prefixed_class_async() async {
    await resolveTestCode('''
void f() {
  Completer? c;
  print('\$c');
}
''');
    await assertHasFix('''
import 'dart:async' show Completer;

void f() {
  Completer? c;
  print('\$c');
}
''');
  }
}
