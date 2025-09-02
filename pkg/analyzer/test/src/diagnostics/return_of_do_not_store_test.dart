// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfDoNotStoreInTestsTest);
    defineReflectiveTests(ReturnOfDoNotStoreTest);
  });
}

@reflectiveTest
class ReturnOfDoNotStoreInTestsTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir (the default for PubPackageResolutionTests)
    // should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    await assertNoErrorsInCode('''
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
}

@reflectiveTest
class ReturnOfDoNotStoreTest extends PubPackageResolutionTest {
  /// Override the default which is in .../test and should not trigger hints.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test_project';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  A();

  String getA() {
    return A();
  }
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 95, 3)],
    );
  }

  test_returnFromClosureInFunction() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

String f() {
  var v = () => _v;
  return v();
}
''',
      [error(WarningCode.returnOfDoNotStore, 97, 2)],
    );
  }

  test_returnFromFunction() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

String getV() {
  return v;
}

String getV2() => v;

@doNotStore
String getV3() => v;
''',
      [
        error(WarningCode.returnOfDoNotStore, 92, 1, messageContains: ['getV']),
        error(
          WarningCode.returnOfDoNotStore,
          116,
          1,
          messageContains: ['getV2'],
        ),
      ],
    );
  }

  test_returnFromGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

String get v {
  return _v;
}

String get v2 => _v;

@doNotStore
String get v3 => _v;
''',
      [
        error(WarningCode.returnOfDoNotStore, 92, 2, messageContains: ['v']),
        error(WarningCode.returnOfDoNotStore, 116, 2, messageContains: ['v2']),
      ],
    );
  }

  test_returnFromGetter_binaryExpression() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String? get _v => '';

@doNotStore
String? get _v2 => '';

String? get v => _v ?? _v2;
''',
      [
        error(WarningCode.returnOfDoNotStore, 122, 2, messageContains: ['_v']),
        error(WarningCode.returnOfDoNotStore, 128, 3, messageContains: ['_v2']),
      ],
    );
  }

  test_returnFromGetter_library() async {
    await assertNoErrorsInCode('''
@doNotStore
import 'package:meta/meta.dart';
int get foo => 0;
int get bar => foo;
''');
  }

  test_returnFromGetter_ternary() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

@doNotStore
String get _v2 => '';

var b = true;

String get v => b ? _v : _v2;
''',
      [
        error(WarningCode.returnOfDoNotStore, 138, 2),
        error(WarningCode.returnOfDoNotStore, 143, 3),
      ],
    );
  }

  test_returnFromMethod() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get _v => '';

  String getV() {
    return _v;
  }

  String getV2() => _v;

  @doNotStore
  String getV3() => _v;
}
''',
      [
        error(
          WarningCode.returnOfDoNotStore,
          111,
          2,
          messageContains: ['getV'],
        ),
        error(
          WarningCode.returnOfDoNotStore,
          140,
          2,
          messageContains: ['getV2'],
        ),
      ],
    );
  }
}
