// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiNativeTest);
  });
}

@reflectiveTest
class FfiNativeTest extends PubPackageResolutionTest {
  test_FfiNativeAnnotationOnInstanceMethod() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @FfiNative<Void Function()>('DoesntMatter')
  external void doesntMatter();
}
''', [
      error(FfiCode.FFI_NATIVE_ONLY_STATIC, 31, 75),
    ]);
  }

  test_FfiNativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function(Handle)>('DoesntMatter')
external Object doesntMatter(Object);
''', []);
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function()>('DoesntMatter', isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 19, 90),
    ]);
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Handle)>('DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 19, 100),
    ]);
  }
}
