// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// NOTE: There is no `test/ffi_2/...` version of this test since annotations
// with type arguments isn't supported in that version of Dart.

import 'dart:ffi';
import 'dart:nativewrappers';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final nativeLib = dlopenPlatformSpecific('ffi_test_functions');

final getRootLibraryUrl = nativeLib
    .lookupFunction<Handle Function(), Object Function()>('GetRootLibraryUrl');

final setFfiNativeResolverForTest =
    nativeLib.lookupFunction<Void Function(Handle), void Function(Object)>(
        'SetFfiNativeResolverForTest');

final triggerGC = nativeLib
    .lookupFunction<Void Function(IntPtr), void Function(int)>('TriggerGC');

@FfiNative<Handle Function(Handle, IntPtr, IntPtr)>(
    'Dart_SetNativeInstanceField')
external Object setNativeInstanceField(Object obj, int index, int ptr);

// Basic FfiNative test functions.

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
external int returnIntPtr(int x);

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

@FfiNative<IntPtr Function()>('IsThreadInGenerated')
external int isThreadInGenerated();

@FfiNative<IntPtr Function()>('IsThreadInGenerated', isLeaf: true)
external int isThreadInGeneratedLeaf();

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);
}

// For automatic transform of NativeFieldWrapperClass1 to Pointer.

class ClassWithNativeField extends NativeFieldWrapperClass1 {
  ClassWithNativeField(int value) {
    setNativeInstanceField(this, 0, value);
  }
}

// Native function takes a Handle, so a Handle is passed as-is.
@FfiNative<IntPtr Function(Handle)>('PassAsHandle')
external int passAsHandle(NativeFieldWrapperClass1 obj);
// FFI signature takes Pointer, Dart signature takes NativeFieldWrapperClass1.
// This implies automatic conversion.
@FfiNative<IntPtr Function(Pointer<Void>)>('PassAsPointer')
external int passAsPointer(NativeFieldWrapperClass1 obj);
// Pass Pointer automatically, and return value.
@FfiNative<IntPtr Function(Pointer<Void>, IntPtr)>('PassAsPointerAndValue')
external int passAsPointerAndValue(NativeFieldWrapperClass1 obj, int value);
// Pass Pointer automatically, and return value.
@FfiNative<IntPtr Function(IntPtr, Pointer<Void>)>('PassAsValueAndPointer')
external int passAsValueAndPointer(int value, NativeFieldWrapperClass1 obj);

// Allocate new native resource we can use to keep track of whether the
// finalizer has run.
@FfiNative<Pointer<Void> Function(IntPtr)>('AllocateResource')
external Pointer<Void> allocateResource(int value);

@FfiNative<Void Function(Pointer<Void>)>('DeleteResource')
external void deleteResource(Pointer<Void> resource);

// Set up the object's finalizer to reset the resource.
@FfiNative<Void Function(Handle, Pointer<Void>)>('SetResourceFinalizer')
external void setResourceFinalizer(
    NativeFieldWrapperClass1 obj, Pointer<Void> resource);

// Return the native resource's value.
@FfiNative<IntPtr Function(Pointer<Void>)>('GetResourceValue')
external int getResourceValue(Pointer<Void> resource);

// Class which ties itself to a resource, resetting the value of the resource
// when the instance gets collected.
class ResourceResetter extends NativeFieldWrapperClass1 {
  ResourceResetter(Pointer<Void> resource) {
    setNativeInstanceField(this, 0, 0);
    setResourceFinalizer(this, resource);
  }
}

// Helper to embed triggerGC(..) as an expression.
int triggerGCWrap() {
  triggerGC(0);
  return 0;
}

// Helpers for testing argumnent evaluation order is preserved.
int state = 0;
int setState(int value) {
  state = value;
  return 0;
}

class StateSetter extends NativeFieldWrapperClass1 {
  StateSetter(int value) {
    setNativeInstanceField(this, 0, 0);
    state = value;
  }
}

void main() {
  // Register test resolver for top-level functions above.
  setFfiNativeResolverForTest(getRootLibraryUrl());

  // Test we can call FfiNative functions.
  Expect.equals(123, returnIntPtr(123));
  Expect.equals(123, returnIntPtrLeaf(123));
  Expect.equals(123, Classy.returnIntPtrStatic(123));

  // Test FfiNative leaf calls remain in generated code.
  // Regular calls should transition generated -> native.
  Expect.equals(0, isThreadInGenerated());
  // Leaf calls should remain in generated state.
  Expect.equals(1, isThreadInGeneratedLeaf());

  // Test that objects extending NativeFieldWrapperClass1 can be passed to
  // FfiNative functions that take Pointer.
  // Such objects should automatically be converted and pass as Pointer.
  {
    final cwnf = ClassWithNativeField(123456);
    Expect.equals(123456, passAsHandle(cwnf));
    Expect.equals(123456, passAsPointer(cwnf));
  }

  // Test that the transform to wrap NativeFieldWrapperClass1 objects in
  // _getNativeField(..) doesn't violate the original argument's liveness.
  final resource = allocateResource(314159);
  Expect.equals(
      314159,
      passAsPointerAndValue(
          // 1: Locally alloc. instance.
          // If this gets wrapped in another call the instance does not live
          // past the return of the wrapper call.
          ResourceResetter(resource),
          // 2: Force GC, to collect the above if it isn't being kept alive.
          // 3: Check that the underlying (dummy) resource hasn't been
          // "collected" (i.e. reset to 0).
          triggerGCWrap() + getResourceValue(resource)));
  deleteResource(resource);

  // Test that the order of argument evaluation is being preserved through the
  // transform wrapping NativeFieldWrapperClass1 objects.
  state = 0;
  passAsValueAndPointer(setState(7), StateSetter(3));
  Expect.equals(3, state);
}
