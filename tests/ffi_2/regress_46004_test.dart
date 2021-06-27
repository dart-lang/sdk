// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

class COMObject extends Struct {
  Pointer<IntPtr> lpVtbl;

  // This should not be interpreted as a native field.
  Pointer<IntPtr> get vtable => Pointer.fromAddress(lpVtbl.value);
}

void main() {
  Expect.equals(sizeOf<Pointer>(), sizeOf<COMObject>());

  final comObjectPointer = calloc<COMObject>();
  final vTablePointer = calloc<IntPtr>();
  vTablePointer.value = 1234;
  final comObject = comObjectPointer.ref;
  comObject.lpVtbl = vTablePointer;
  Expect.equals(1234, comObject.vtable.address);
  calloc.free(comObjectPointer);
  calloc.free(vTablePointer);
}
