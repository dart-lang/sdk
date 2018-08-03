// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_IO_BUFFER_H_
#define RUNTIME_BIN_IO_BUFFER_H_

#include "include/dart_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class IOBuffer {
 public:
  // Allocate an IO buffer dart object (of type Uint8List) backed by
  // an external byte array.
  static Dart_Handle Allocate(intptr_t size, uint8_t** buffer);

  // Allocate IO buffer storage.
  static uint8_t* Allocate(intptr_t size);

  // Function for disposing of IO buffer storage. All backing storage
  // for IO buffers must be freed using this function.
  static void Free(void* buffer) { free(buffer); }

  // Function for finalizing external byte arrays used as IO buffers.
  static void Finalizer(void* isolate_callback_data,
                        Dart_WeakPersistentHandle handle,
                        void* buffer) {
    Free(buffer);
  }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(IOBuffer);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_IO_BUFFER_H_
