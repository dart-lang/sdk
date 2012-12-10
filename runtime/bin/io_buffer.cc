// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_buffer.h"

Dart_Handle IOBuffer::Allocate(intptr_t size, uint8_t **buffer) {
  uint8_t* data = Allocate(size);
  Dart_Handle result = Dart_NewExternalByteArray(data, size, data, Free);
  if (Dart_IsError(result)) {
    Free(data);
    Dart_PropagateError(result);
  }
  if (buffer != NULL) {
    *buffer = data;
  }
  return result;
}

uint8_t* IOBuffer::Allocate(intptr_t size) {
  return new uint8_t[size];
}
