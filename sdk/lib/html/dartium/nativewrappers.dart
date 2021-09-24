// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nativewrappers;

class NativeFieldWrapperClass1 {}

class NativeFieldWrapperClass2 extends NativeFieldWrapperClass1 {}

class NativeFieldWrapperClass3 extends NativeFieldWrapperClass2 {}

class NativeFieldWrapperClass4 extends NativeFieldWrapperClass3 {}

/// Gets the value of the native field of [object].
///
/// Throws an exception if [object] is null or if the native field was not set.
///
/// NOTE: This is function is temporary and will be deprecated in the near
/// future.
@pragma("vm:recognized", "other")
@pragma("vm:external-name", "FullyRecognizedMethod_NoNative")
external int _getNativeField(NativeFieldWrapperClass1 object);
