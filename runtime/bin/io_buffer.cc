// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_buffer.h"

static void BufferFree(void* buffer) {
  delete[] reinterpret_cast<uint8_t*>(buffer);
}


Dart_Handle IOBuffer::Allocate(intptr_t size, uint8_t **buffer) {
  uint8_t* data = new uint8_t[size];
  Dart_Handle result = Dart_NewExternalByteArray(data,
                                                 size,
                                                 data,
                                                 BufferFree);
  if (Dart_IsError(result)) {
    BufferFree(data);
    Dart_PropagateError(result);
  }
  if (buffer != NULL) {
    *buffer = data;
  }
  return result;
}
