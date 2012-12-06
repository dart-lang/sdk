// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef IO_BUFFER_H_
#define IO_BUFFER_H_

#include "platform/globals.h"

#include "include/dart_api.h"

class IOBuffer {
 public:
  // Allocate an IO buffer dart object (of type Uint8List) backed by
  // an external byte array.
  static Dart_Handle Allocate(intptr_t size, uint8_t **buffer);

  // Allocate IO buffer storage.
  static uint8_t* Allocate(intptr_t size);

  // Function for disposing of IO buffer storage. All backing storage
  // for IO buffers must be freed using this function.
  static void Free(void* buffer) {
    delete[] reinterpret_cast<uint8_t*>(buffer);
  }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(IOBuffer);
};

#endif  // IO_BUFFER_H_
