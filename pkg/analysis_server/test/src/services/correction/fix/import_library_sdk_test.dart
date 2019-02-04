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
import 'dart:collection' show HashMap;
main() {
  HashMap s = null;
  LinkedHashMap f = null;
  print('\$s \$f');
}
''');
    await assertNoFix();
  }

  test_withClass_asExpression() async {
    await resolveTestUnit('''
main(p) {
  p as HashMap;
}
''');
    await assertHasFix('''
import 'dart:collection';

main(p) {
  p as HashMap;
}
''');
  }

  test_withClass_instanceCreation_explicitNew() async {
    await resolveTestUnit('''
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

  test_withClass_instanceCreation_explicitNew_namedConstructor() async {
    await resolveTestUnit('''
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

  test_withClass_instanceCreation_implicitNew() async {
    await resolveTestUnit('''
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

  test_withClass_instanceCreation_implicitNew_namedConstructor() async {
    await resolveTestUnit('''
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

  test_withClass_invocationTarget() async {
    await resolveTestUnit('''
main() {
  Timer.run(null);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Timer.run(null);
}
''');
  }

  test_withClass_IsExpression() async {
    await resolveTestUnit('''
main(p) {
  p is Completer;
}
''');
    await assertHasFix('''
import 'dart:async';

main(p) {
  p is Completer;
}
''');
  }

  test_withClass_itemOfList() async {
    await resolveTestUnit('''
main() {
  var a = [Completer];
  print(a);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  var a = [Completer];
  print(a);
}
''');
  }

  test_withClass_itemOfList_inAnnotation() async {
    await resolveTestUnit('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Completer])
main() {}
''');
    await assertHasFix('''
import 'dart:async';

class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Completer])
main() {}
''', errorFilter: (error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    });
  }

  test_withClass_typeAnnotation() async {
    await resolveTestUnit('''
main() {
  Completer f = null;
  print(f);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Completer f = null;
  print(f);
}
''');
  }

  test_withClass_typeAnnotation_PrefixedIdentifier() async {
    await resolveTestUnit('''
main() {
  Timer.run;
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  Timer.run;
}
''');
  }

  test_withClass_typeArgument() async {
    await resolveTestUnit('''
main() {
  List<Completer> completers = [];
  print(completers);
}
''');
    await assertHasFix('''
import 'dart:async';

main() {
  List<Completer> completers = [];
  print(completers);
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
