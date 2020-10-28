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
    defineReflectiveTests(ImportLibrarySdkTest);
  });
}

@reflectiveTest
class ImportLibrarySdkTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SDK;

  Future<void> test_alreadyImported_sdk() async {
    await resolveTestCode('''
import 'dart:collection' show HashMap;
main() {
  HashMap s = null;
  LinkedHashMap f = null;
  print('\$s \$f');
}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_asExpression() async {
    await resolveTestCode('''
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

  Future<void> test_withClass_IsExpression() async {
    await resolveTestCode('''
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

  Future<void> test_withClass_itemOfList() async {
    await resolveTestCode('''
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

  Future<void> test_withClass_itemOfList_inAnnotation() async {
    await resolveTestCode('''
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
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER;
    });
  }

  Future<void> test_withClass_typeAnnotation() async {
    await resolveTestCode('''
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

  Future<void> test_withClass_typeAnnotation_PrefixedIdentifier() async {
    await resolveTestCode('''
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

  Future<void> test_withClass_typeArgument() async {
    await resolveTestCode('''
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
main() {
  print(pi);
}
''');
    await assertHasFix('''
import 'dart:math';

main() {
  print(pi);
}
''');
  }

  Future<void> test_withTopLevelVariable_annotation() async {
    await resolveTestCode('''
@pi
main() {
}
''');
    await assertHasFix('''
import 'dart:math';

@pi
main() {
}
''');
  }
}
