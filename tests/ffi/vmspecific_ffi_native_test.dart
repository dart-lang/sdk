// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:nativewrappers';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final nativeLib = dlopenPlatformSpecific('ffi_test_functions');

final getRootLibraryUrl = nativeLib
    .lookupFunction<Handle Function(), Object Function()>('GetRootLibraryUrl');

final setFfiNativeResolverForTest = nativeLib
    .lookupFunction<Void Function(Handle), void Function(Object)>(
      'SetFfiNativeResolverForTest',
    );

@Native<Handle Function(Handle, IntPtr, IntPtr)>(
  symbol: 'Dart_SetNativeInstanceField',
)
external Object setNativeInstanceField(Object obj, int index, int ptr);

// Basic Native test functions.

@Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
external int returnIntPtr(int x);

@Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

@Native<IntPtr Function()>(symbol: 'IsThreadInGenerated')
external int isThreadInGenerated();

@Native<IntPtr Function()>(symbol: 'IsThreadInGenerated', isLeaf: true)
external int isThreadInGeneratedLeaf();

class Classy {
  @Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
  external static int returnIntPtrStatic(int x);
}

// For automatic transform of NativeFieldWrapperClass1 to Pointer.

base class ClassWithNativeField extends NativeFieldWrapperClass1 {
  ClassWithNativeField(int value) {
    setNativeInstanceField(this, 0, value);
  }

  // Instance methods implicitly pass a 'self' reference as the first argument.
  // Passed as Pointer if the native function takes that (and the class can be
  // converted).
  @Native<IntPtr Function(Pointer<Void>, IntPtr)>(symbol: 'AddPtrAndInt')
  external int addSelfPtrAndIntMethod(int x);

  // Instance methods implicitly pass a 'self' reference as the first argument.
  // Passed as Handle if the native function takes that.
  @Native<IntPtr Function(Handle, IntPtr)>(symbol: 'AddHandleFieldAndInt')
  external int addSelfHandleFieldAndIntMethod(int x);

  @Native<IntPtr Function(Pointer<Void>, Pointer<Void>)>(symbol: 'AddPtrAndPtr')
  external int addSelfPtrAndPtrMethod(ClassWithNativeField other);

  @Native<IntPtr Function(Handle, Pointer<Void>)>(
    symbol: 'AddHandleFieldAndPtr',
  )
  external int addSelfHandleFieldAndPtrMethod(ClassWithNativeField other);

  @Native<IntPtr Function(Handle, Handle)>(
    symbol: 'AddHandleFieldAndHandleField',
  )
  external int addSelfHandleFieldAndHandleFieldMethod(
    ClassWithNativeField other,
  );

  @Native<IntPtr Function(Pointer<Void>, Handle)>(
    symbol: 'AddPtrAndHandleField',
  )
  external int addselfPtrAndHandleFieldMethod(ClassWithNativeField other);
}

class ClassWithoutNativeField {
  // Instance methods implicitly pass their handle as the first arg.
  @Native<IntPtr Function(Handle, IntPtr)>(symbol: 'ReturnIntPtrMethod')
  external int returnIntPtrMethod(int x);
}

// Native function takes a Handle, so a Handle is passed as-is.
@Native<IntPtr Function(Handle)>(symbol: 'PassAsHandle')
external int passAsHandle(NativeFieldWrapperClass1 obj);
// FFI signature takes Pointer, Dart signature takes NativeFieldWrapperClass1.
// This implies automatic conversion.
@Native<IntPtr Function(Pointer<Void>)>(symbol: 'PassAsPointer')
external int passAsPointer(NativeFieldWrapperClass1 obj);
// Pass Pointer automatically, and return value.
@Native<IntPtr Function(Pointer<Void>, IntPtr)>(symbol: 'PassAsPointerAndValue')
external int passAsPointerAndValue(NativeFieldWrapperClass1 obj, int value);
// Pass Pointer automatically, and return value.
@Native<IntPtr Function(IntPtr, Pointer<Void>)>(symbol: 'PassAsValueAndPointer')
external int passAsValueAndPointer(int value, NativeFieldWrapperClass1 obj);

// Helpers for testing argument evaluation order is preserved.
int state = 0;
int setState(int value) {
  state = value;
  return 0;
}

base class StateSetter extends NativeFieldWrapperClass1 {
  StateSetter(int value) {
    setNativeInstanceField(this, 0, 0);
    state = value;
  }
}

void main() {
  // Register test resolver for top-level functions above.
  setFfiNativeResolverForTest(getRootLibraryUrl());

  // Test we can call Native functions.
  Expect.equals(123, returnIntPtr(123));
  Expect.equals(123, returnIntPtrLeaf(123));
  Expect.equals(123, Classy.returnIntPtrStatic(123));

  // Test Native leaf calls remain in generated code.
  // Regular calls should transition generated -> native.
  Expect.equals(0, isThreadInGenerated());
  // Leaf calls should remain in generated state.
  Expect.equals(1, isThreadInGeneratedLeaf());

  // Test that objects extending NativeFieldWrapperClass1 can be passed to
  // Native functions that take Pointer.
  // Such objects should automatically be converted and pass as Pointer.
  {
    final cwnf = ClassWithNativeField(123456);
    Expect.equals(123456, passAsHandle(cwnf));
    Expect.equals(123456, passAsPointer(cwnf));
  }

  // Test that the order of argument evaluation is being preserved through the
  // transform wrapping NativeFieldWrapperClass1 objects.
  state = 0;
  passAsValueAndPointer(setState(7), StateSetter(3));
  Expect.equals(3, state);

  // Test transforms of instance methods.
  Expect.equals(234, ClassWithoutNativeField().returnIntPtrMethod(234));
  Expect.equals(1012, ClassWithNativeField(12).addSelfPtrAndIntMethod(1000));
  Expect.equals(
    2021,
    ClassWithNativeField(21).addSelfHandleFieldAndIntMethod(2000),
  );
  Expect.equals(
    3031,
    ClassWithNativeField(31).addSelfPtrAndPtrMethod(ClassWithNativeField(3000)),
  );
  Expect.equals(
    4041,
    ClassWithNativeField(
      41,
    ).addSelfHandleFieldAndPtrMethod(ClassWithNativeField(4000)),
  );
  Expect.equals(
    5051,
    ClassWithNativeField(
      51,
    ).addSelfHandleFieldAndHandleFieldMethod(ClassWithNativeField(5000)),
  );
  Expect.equals(
    6061,
    ClassWithNativeField(
      61,
    ).addselfPtrAndHandleFieldMethod(ClassWithNativeField(6000)),
  );
  Expect.throws(() {
    ClassWithNativeField(
      nullptr.address,
    ).addSelfPtrAndPtrMethod(ClassWithNativeField(7000));
  });
  // Does not throw.
  ClassWithNativeField(
    8000,
  ).addSelfPtrAndPtrMethod(ClassWithNativeField(nullptr.address));
}
