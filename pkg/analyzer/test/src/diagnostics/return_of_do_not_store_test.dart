// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfDoNotStoreTest);
  });
}

@reflectiveTest
class ReturnOfDoNotStoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_returnFromFunction() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String v = '';

String getV() {
  return v;
}

String getV2() => v;

@doNotStore
String getV3() => v;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 87, 1, messageContains: 'getV'),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 111, 1, messageContains: 'getV2'),
    ]);
  }

  test_returnFromGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

String get v {
  return _v;
}

String get v2 => _v;

@doNotStore
String get v3 => _v;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 87, 2, messageContains: 'v'),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 111, 2, messageContains: 'v2'),
    ]);
  }

  test_returnFromMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String _v = '';

  String getV() {
    return _v;
  }

  String getV2() => _v;
  
  @doNotStore
  String getV3() => _v;
}
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 106, 2, messageContains: 'getV'),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 135, 2, messageContains: 'getV2'),
    ]);
  }
}
