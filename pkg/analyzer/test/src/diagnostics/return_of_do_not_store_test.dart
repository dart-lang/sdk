// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfDoNotStoreTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnOfDoNotStoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor() async {
    // TODO(srawlins): We should report `returnOfDoNotStore`.
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  A();

  String getA() {
    return A();
//         ^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'A' can't be returned from the method 'getA' because it has a return type of 'String'.
  }
}
''');
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    var file = getFile('$testPackageRootPath/test/test.dart');

    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

String f() {
  var v = () => _v;
  return v();
}

String g() {
  return _v;
}
''');
  }

  test_returnFromClosureInFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

String f() {
  var v = () => _v;
//              ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'f' is also annotated.
  return v();
}
''');
  }

  test_returnFromFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

String getV() {
  return v;
//       ^
// [diag.returnOfDoNotStore] 'v' is annotated with 'doNotStore' and shouldn't be returned unless 'getV' is also annotated.
}

String getV2() => v;
//                ^
// [diag.returnOfDoNotStore] 'v' is annotated with 'doNotStore' and shouldn't be returned unless 'getV2' is also annotated.

@doNotStore
String getV3() => v;
''');
  }

  test_returnFromGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

String get v {
  return _v;
//       ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'v' is also annotated.
}

String get v2 => _v;
//               ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'v2' is also annotated.

@doNotStore
String get v3 => _v;
''');
  }

  test_returnFromGetter_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String? get _v => '';

@doNotStore
String? get _v2 => '';

String? get v => _v ?? _v2;
//               ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'v' is also annotated.
//                     ^^^
// [diag.returnOfDoNotStore] '_v2' is annotated with 'doNotStore' and shouldn't be returned unless 'v' is also annotated.
''');
  }

  test_returnFromGetter_library() async {
    await resolveTestCodeWithDiagnostics(r'''
@doNotStore
import 'package:meta/meta.dart';
int get foo => 0;
int get bar => foo;
''');
  }

  test_returnFromGetter_ternary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

@doNotStore
String get _v2 => '';

var b = true;

String get v => b ? _v : _v2;
//                  ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'v' is also annotated.
//                       ^^^
// [diag.returnOfDoNotStore] '_v2' is annotated with 'doNotStore' and shouldn't be returned unless 'v' is also annotated.
''');
  }

  test_returnFromMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get _v => '';

  String getV() {
    return _v;
//         ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'getV' is also annotated.
  }

  String getV2() => _v;
//                  ^^
// [diag.returnOfDoNotStore] '_v' is annotated with 'doNotStore' and shouldn't be returned unless 'getV2' is also annotated.

  @doNotStore
  String getV3() => _v;
}
''');
  }

  test_topLevelVariable_awaitExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

void get f async => await v;

@doNotStore
Future<String> get v async => '';
''');
  }
}
