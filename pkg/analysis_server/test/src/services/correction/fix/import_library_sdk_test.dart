// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibrarySdkTest);
  });
}

@reflectiveTest
class ImportLibrarySdkTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK;

  test_alreadyImported_sdk() async {
    await resolveTestUnit('''
import 'dart:async' show Stream;
main() {
  Stream s = null;
  Future f = null;
  print('\$s \$f');
}
''');
    await assertNoFix();
  }

  test_withClass_asExpression() async {
    await resolveTestUnit('''
main(p) {
  p as Future;
}
''');
    await assertHasFix('''
import 'dart:async';

main(p) {
  p as Future;
}
''');
  }

  test_withClass_instanceCreation_explicitNew() async {
    await resolveTestUnit('''
class C {
  foo() {
    new Future();
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    new Future();
  }
}
''');
  }

  test_withClass_instanceCreation_explicitNew_namedConstructor() async {
    await resolveTestUnit('''
class C {
  foo() {
    new Future.value(0);
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    new Future.value(0);
  }
}
''');
  }

  test_withClass_instanceCreation_implicitNew() async {
    await resolveTestUnit('''
class C {
  foo() {
    Future();
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    Future();
  }
}
''');
  }

  test_withClass_instanceCreation_implicitNew_namedConstructor() async {
    await resolveTestUnit('''
class C {
  foo() {
    Future.value(0);
  }
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  foo() {
    Future.value(0);
  }
}
''');
  }

  test_withClass_invocationTarget() async {
    await resolveTestUnit('''
main() {
  Future.wait(null);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Future.wait(null);
}
''');
  }

  test_withClass_IsExpression() async {
    await resolveTestUnit('''
main(p) {
  p is Future;
}
''');
    await assertHasFix('''
import 'dart:async';

main(p) {
  p is Future;
}
''');
  }

  test_withClass_itemOfList() async {
    await resolveTestUnit('''
main() {
  var a = [Future];
  print(a);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  var a = [Future];
  print(a);
}
''');
  }

  test_withClass_itemOfList_inAnnotation() async {
    await resolveTestUnit('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Future])
main() {}
''');
    await assertHasFix('''
import 'dart:async';

class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Future])
main() {}
''', errorFilter: (error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    });
  }

  test_withClass_typeAnnotation() async {
    await resolveTestUnit('''
main() {
  Future f = null;
  print(f);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Future f = null;
  print(f);
}
''');
  }

  test_withClass_typeAnnotation_PrefixedIdentifier() async {
    await resolveTestUnit('''
main() {
  Future.wait;
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Future.wait;
}
''');
  }

  test_withClass_typeArgument() async {
    await resolveTestUnit('''
main() {
  List<Future> futures = [];
  print(futures);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  List<Future> futures = [];
  print(futures);
}
''');
  }

  test_withTopLevelVariable() async {
    await resolveTestUnit('''
main() {
  print(PI);
}
''');
    await assertHasFix('''
import 'dart:math';

main() {
  print(PI);
}
''');
  }

  test_withTopLevelVariable_annotation() async {
    await resolveTestUnit('''
@PI
main() {
}
''');
    await assertHasFix('''
import 'dart:math';

@PI
main() {
}
''');
  }
}
