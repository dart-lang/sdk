// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_TLS_SOCKET_H_
#define BIN_TLS_SOCKET_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "platform/globals.h"
#include "platform/thread.h"

static Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) Dart_PropagateError(handle);
  return handle;
}


class TlsFilterPlatformData;

class TlsFilter {
 public:
  enum BufferIndex { kReadPlaintext,
                     kWritePlaintext,
                     kReadEncrypted,
                     kWriteEncrypted,
                     kNumBuffers};

  TlsFilter();
  void Init(Dart_Handle dart_this);
  void Connect();
  void Destroy();
  void DestroyPlatformIndependent();
  void RegisterHandshakeCallbacks(Dart_Handle start, Dart_Handle finish);

  intptr_t ProcessBuffer(int bufferIndex);

 private:
  //  static const char* bufferNames_[kNumBuffers];
  static bool library_initialized_;  // Should be mutex protected.

  uint8_t* buffers_[kNumBuffers];
  int64_t buffer_size_;
  Dart_Handle stringStart_;
  Dart_Handle stringLength_;
  Dart_Handle dart_buffer_objects_[kNumBuffers];
  Dart_Handle handshake_start_;
  Dart_Handle handshake_finish_;
  bool in_handshake_;
  TlsFilterPlatformData* data_;

  void InitializeBuffers(Dart_Handle dart_this);
  void InitializePlatformData();
  void InitializeLibrary();
  void LockInitMutex() {}
  void UnlockInitMutex() {}

  DISALLOW_COPY_AND_ASSIGN(TlsFilter);
};

#endif  // BIN_TLS_SOCKET_H_
