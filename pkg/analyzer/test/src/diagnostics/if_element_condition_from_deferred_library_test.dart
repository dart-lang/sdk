// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElementConditionFromDeferredLibraryTest);
  });
}

@reflectiveTest
class IfElementConditionFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_inList_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return const [if(a.c) 0];
//                   ^
// [diag.ifElementConditionFromDeferredLibrary] Constant values from a deferred library can't be used as values in an if condition inside a const collection literal.
}
''');
  }

  test_inList_nonConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return [if(a.c) 0];
}
''');
  }

  test_inList_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as a;
f() {
  return const [if(a.c) 0];
}
''');
  }

  test_inMap_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return const {if(a.c) 0 : 0};
//                   ^
// [diag.ifElementConditionFromDeferredLibrary] Constant values from a deferred library can't be used as values in an if condition inside a const collection literal.
}
''');
  }

  test_inMap_notConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return {if(a.c) 0 : 0};
}
''');
  }

  test_inMap_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as a;
f() {
  return const {if(a.c) 0 : 0};
}
''');
  }

  test_inSet_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return const {if(a.c) 0};
//                   ^
// [diag.ifElementConditionFromDeferredLibrary] Constant values from a deferred library can't be used as values in an if condition inside a const collection literal.
}
''');
  }

  test_inSet_notConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
f() {
  return {if(a.c) 0};
}
''');
  }

  test_inSet_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const bool c = true;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as a;
f() {
  return const {if(a.c) 0};
}
''');
  }
}
