// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we can implement the Allocator interface.

import 'dart:ffi';

class MyAllocator implements Allocator {
  const MyAllocator();

  @override
  Pointer<T> allocate<T extends NativeType>(int numBytes, {int? alignment}) {
    throw "Not implemented";
  }

  void free(Pointer pointer) {}
}

const myAllocator = MyAllocator();

void main() {
  print(myAllocator);
}
