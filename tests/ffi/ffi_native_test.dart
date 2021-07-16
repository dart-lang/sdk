// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final nativeLib = dlopenPlatformSpecific('ffi_test_functions');
final getRootLibraryUrl = nativeLib
    .lookupFunction<Handle Function(), Object Function()>('GetRootLibraryUrl');
final setFfiNativeResolverForTest = nativeLib
    .lookupFunction<Void Function(Handle), void Function(Object)>('SetFfiNativeResolverForTest');

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
external int returnIntPtr(int x);

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

@FfiNative<IntPtr Function()>('IsThreadInGenerated')
external int isThreadInGenerated();

@FfiNative<IntPtr Function()>('IsThreadInGenerated', isLeaf: true)
external int isThreadInGeneratedLeaf();

// Error: FFI leaf call must not have Handle return type.
@FfiNative<Handle Function()>("foo", isLeaf: true)  //# 01: compile-time error
external Object foo();  //# 01: compile-time error

// Error: FFI leaf call must not have Handle argument types.
@FfiNative<Void Function(Handle)>("bar", isLeaf: true)  //# 02: compile-time error
external void bar(Object);  //# 02: compile-time error

void main() {
  // Register test resolver for top-level functions above.
  final root_lib_url = getRootLibraryUrl();
  setFfiNativeResolverForTest(root_lib_url);

  // Test we can call FfiNative functions.
  Expect.equals(123, returnIntPtr(123));
  Expect.equals(123, returnIntPtrLeaf(123));

  // Test FfiNative leaf calls remain in generated code.
  // Regular calls should transition generated -> native.
  Expect.equals(0, isThreadInGenerated());
  // Leaf calls should remain in generated state.
  Expect.equals(1, isThreadInGeneratedLeaf());
}
