// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/tls_socket.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_api.h"

bool TlsFilter::library_initialized_ = false;

static TlsFilter* NativePeer(Dart_NativeArguments args) {
  TlsFilter* native_peer;

  Dart_Handle dart_this = HandleError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  HandleError(Dart_GetNativeInstanceField(dart_this, 0,
      reinterpret_cast<intptr_t*>(&native_peer)));
  return native_peer;
}


static void SetNativePeer(Dart_NativeArguments args, TlsFilter* native_peer) {
  Dart_Handle dart_this = HandleError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  HandleError(Dart_SetNativeInstanceField(dart_this, 0,
      reinterpret_cast<intptr_t>(native_peer)));
}


void FUNCTION_NAME(TlsSocket_Init)(Dart_NativeArguments args) {
  Dart_EnterScope();
  TlsFilter* native_peer = new TlsFilter;
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  if (Dart_IsError(dart_this)) {
    delete native_peer;
    Dart_PropagateError(dart_this);
  }
  SetNativePeer(args, native_peer);
  native_peer->Init(dart_this);


  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_Connect)(Dart_NativeArguments args) {
  Dart_EnterScope();
  NativePeer(args)->Connect();
  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_Destroy)(Dart_NativeArguments args) {
  Dart_EnterScope();
  TlsFilter* native_peer = NativePeer(args);
  SetNativePeer(args, NULL);
  native_peer->Destroy();
  delete native_peer;
  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_RegisterHandshakeCallbacks)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handshake_start = HandleError(Dart_GetNativeArgument(args, 1));
  Dart_Handle handshake_finish = HandleError(Dart_GetNativeArgument(args, 2));
  if (!Dart_IsClosure(handshake_start) ||
      !Dart_IsClosure(handshake_finish)) {
    Dart_ThrowException(DartUtils::NewDartIllegalArgumentException(
        "Illegal argument to RegisterHandshakeCallbacks"));
  }
  NativePeer(args)->RegisterHandshakeCallbacks(handshake_start,
                                               handshake_finish);
  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_ProcessBuffer)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle buffer_id_object = HandleError(Dart_GetNativeArgument(args, 1));
  int64_t buffer_id = DartUtils::GetIntegerValue(buffer_id_object);
  if (buffer_id < 0 || buffer_id >= TlsFilter::kNumBuffers) {
    Dart_ThrowException(DartUtils::NewDartIllegalArgumentException(
        "Illegal argument to ProcessBuffer"));
  }

  intptr_t bytes_read =
      NativePeer(args)->ProcessBuffer(static_cast<int>(buffer_id));
  Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  Dart_ExitScope();
}


void TlsFilter::Init(Dart_Handle dart_this) {
  stringStart_ = HandleError(
      Dart_NewPersistentHandle(Dart_NewString("start")));
  stringLength_ = HandleError(
      Dart_NewPersistentHandle(Dart_NewString("length")));

  InitializeBuffers(dart_this);
  InitializePlatformData();
}


void TlsFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create TlsFilter buffers as ExternalUint8Array objects.
  Dart_Handle dart_buffers_object = HandleError(
      Dart_GetField(dart_this, Dart_NewString("buffers")));
  Dart_Handle dart_buffer_object = HandleError(
      Dart_ListGetAt(dart_buffers_object, kReadPlaintext));
  Dart_Handle tlsExternalBuffer_class = HandleError(
      Dart_InstanceGetClass(dart_buffer_object));
  Dart_Handle dart_buffer_size = HandleError(
      Dart_GetField(tlsExternalBuffer_class, Dart_NewString("kSize")));
  buffer_size_ = DartUtils::GetIntegerValue(dart_buffer_size);
  if (buffer_size_ <= 0 || buffer_size_ > 1024 * 1024) {
    Dart_ThrowException(
        Dart_NewString("Invalid buffer size in _TlsExternalBuffer"));
  }

  for (int i = 0; i < kNumBuffers; ++i) {
    dart_buffer_objects_[i] = HandleError(
        Dart_NewPersistentHandle(Dart_ListGetAt(dart_buffers_object, i)));
    buffers_[i] = new uint8_t[buffer_size_];
    Dart_Handle data = HandleError(
      Dart_NewExternalByteArray(buffers_[i],
                                buffer_size_, NULL, NULL));
    HandleError(
        Dart_SetField(dart_buffer_objects_[i], Dart_NewString("data"), data));
  }
}


void TlsFilter::RegisterHandshakeCallbacks(Dart_Handle start,
                                           Dart_Handle finish) {
  handshake_start_ = HandleError(Dart_NewPersistentHandle(start));
  handshake_finish_ = HandleError(Dart_NewPersistentHandle(finish));
}


void TlsFilter::DestroyPlatformIndependent() {
  for (int i = 0; i < kNumBuffers; ++i) {
    Dart_DeletePersistentHandle(dart_buffer_objects_[i]);
  }
  Dart_DeletePersistentHandle(stringStart_);
  Dart_DeletePersistentHandle(stringLength_);
}
