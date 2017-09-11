// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/sync_socket.h"

#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/isolate_data.h"
#include "bin/lockers.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

#define DART_CHECK_ERROR_AND_CLEANUP(handle, ptr)                              \
  do {                                                                         \
    if (Dart_IsError((handle))) {                                              \
      delete (ptr);                                                            \
      Dart_SetReturnValue(args, (handle));                                     \
      return;                                                                  \
    }                                                                          \
  } while (0)

#define DART_CHECK_ERROR(handle)                                               \
  do {                                                                         \
    if (Dart_IsError((handle))) {                                              \
      Dart_SetReturnValue(args, (handle));                                     \
      return;                                                                  \
    }                                                                          \
  } while (0)

namespace dart {
namespace bin {

static const int kSocketIdNativeField = 0;

void FUNCTION_NAME(SynchronousSocket_LookupRequest)(Dart_NativeArguments args) {
  if (Dart_GetNativeArgumentCount(args) != 2) {
    Dart_SetReturnValue(
        args, DartUtils::NewDartArgumentError("Invalid argument count."));
    return;
  }

  char* peer = NULL;
  Dart_Handle host_arg =
      Dart_GetNativeStringArgument(args, 0, reinterpret_cast<void**>(&peer));
  DART_CHECK_ERROR(host_arg);

  char* host = NULL;
  host_arg = Dart_StringToCString(host_arg, const_cast<const char**>(&host));
  DART_CHECK_ERROR(host_arg);

  int64_t type = 0;
  Dart_Handle port_error = Dart_GetNativeIntegerArgument(args, 1, &type);
  DART_CHECK_ERROR(port_error);

  OSError* os_error = NULL;
  AddressList<SocketAddress>* addresses =
      SocketBase::LookupAddress(host, type, &os_error);
  if (addresses == NULL) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(os_error));
    return;
  }

  Dart_Handle array = Dart_NewList(addresses->count());
  DART_CHECK_ERROR_AND_CLEANUP(array, addresses);

  for (intptr_t i = 0; i < addresses->count(); i++) {
    SocketAddress* addr = addresses->GetAt(i);
    Dart_Handle entry = Dart_NewList(3);
    DART_CHECK_ERROR_AND_CLEANUP(entry, addresses);

    Dart_Handle type = Dart_NewInteger(addr->GetType());
    DART_CHECK_ERROR_AND_CLEANUP(type, addresses);
    Dart_Handle error = Dart_ListSetAt(entry, 0, type);
    DART_CHECK_ERROR_AND_CLEANUP(error, addresses);

    Dart_Handle as_string = Dart_NewStringFromCString(addr->as_string());
    DART_CHECK_ERROR_AND_CLEANUP(as_string, addresses);
    error = Dart_ListSetAt(entry, 1, as_string);
    DART_CHECK_ERROR_AND_CLEANUP(error, addresses);

    RawAddr raw = addr->addr();
    Dart_Handle data = SocketAddress::ToTypedData(raw);
    DART_CHECK_ERROR_AND_CLEANUP(data, addresses);

    error = Dart_ListSetAt(entry, 2, data);
    DART_CHECK_ERROR_AND_CLEANUP(error, addresses);
    error = Dart_ListSetAt(array, i, entry);
    DART_CHECK_ERROR_AND_CLEANUP(error, addresses);
  }
  delete addresses;
  Dart_SetReturnValue(args, array);
  return;
}

void FUNCTION_NAME(SynchronousSocket_CreateConnectSync)(
    Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 2);
  DART_CHECK_ERROR(port_arg);
  int64_t port = DartUtils::GetInt64ValueCheckRange(port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&addr, static_cast<intptr_t>(port));
  intptr_t socket = SynchronousSocket::CreateConnect(addr);
  if (socket >= 0) {
    Dart_Handle error = SynchronousSocket::SetSocketIdNativeField(
        Dart_GetNativeArgument(args, 0), new SynchronousSocket(socket));
    DART_CHECK_ERROR(error);
    Dart_SetBooleanReturnValue(args, true);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(SynchronousSocket_WriteList)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsList(buffer_obj)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(
                                  "First parameter must be a List<int>"));
    return;
  }
  intptr_t offset = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t length = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  Dart_TypedData_Type type;
  uint8_t* buffer = NULL;
  intptr_t len;
  result = Dart_TypedDataAcquireData(buffer_obj, &type,
                                     reinterpret_cast<void**>(&buffer), &len);
  DART_CHECK_ERROR(result);
  ASSERT((offset + length) <= len);
  buffer += offset;
  intptr_t bytes_written =
      SynchronousSocket::Write(socket->fd(), buffer, length);
  if (bytes_written >= 0) {
    Dart_SetIntegerReturnValue(args, bytes_written);
  } else {
    OSError os_error;
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
  Dart_TypedDataReleaseData(buffer_obj);
}

void FUNCTION_NAME(SynchronousSocket_ReadList)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsList(buffer_obj)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(
                                  "First parameter must be a List<int>"));
    return;
  }
  intptr_t offset = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t bytes = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  intptr_t array_len = 0;

  result = Dart_ListLength(buffer_obj, &array_len);
  DART_CHECK_ERROR(result);

  uint8_t* buffer = Dart_ScopeAllocate(bytes);
  intptr_t bytes_read = SynchronousSocket::Read(socket->fd(), buffer, bytes);
  if (bytes_read < 0) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    return;
  }
  if (bytes_read > 0) {
    result = Dart_ListSetAsBytes(buffer_obj, offset, buffer, bytes_read);
    DART_CHECK_ERROR(result);
  }
  Dart_SetIntegerReturnValue(args, bytes_read);
}

void FUNCTION_NAME(SynchronousSocket_Available)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  intptr_t available = SynchronousSocket::Available(socket->fd());
  if (available >= 0) {
    Dart_SetIntegerReturnValue(args, available);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(SynchronousSocket_CloseSync)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  SynchronousSocket::Close(socket->fd());
  socket->SetClosedFd();
}

void FUNCTION_NAME(SynchronousSocket_Read)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  int64_t length = 0;
  if (!DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &length)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(
                                  "First parameter must be an integer."));
    return;
  }
  uint8_t* buffer = NULL;
  result = IOBuffer::Allocate(length, &buffer);
  ASSERT(buffer != NULL);
  intptr_t bytes_read = SynchronousSocket::Read(socket->fd(), buffer, length);
  if (bytes_read == length) {
    Dart_SetReturnValue(args, result);
  } else if (bytes_read > 0) {
    uint8_t* new_buffer = NULL;
    Dart_Handle new_result = IOBuffer::Allocate(bytes_read, &new_buffer);
    ASSERT(new_buffer != NULL);
    memmove(new_buffer, buffer, bytes_read);
    Dart_SetReturnValue(args, new_result);
  } else if (bytes_read == -1) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(SynchronousSocket_ShutdownRead)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  SynchronousSocket::ShutdownRead(socket->fd());
}

void FUNCTION_NAME(SynchronousSocket_ShutdownWrite)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  SynchronousSocket::ShutdownWrite(socket->fd());
}

void FUNCTION_NAME(SynchronousSocket_GetPort)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  intptr_t port = SynchronousSocket::GetPort(socket->fd());
  if (port > 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(port));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(SynchronousSocket_GetRemotePeer)(Dart_NativeArguments args) {
  SynchronousSocket* socket = NULL;
  Dart_Handle result = SynchronousSocket::GetSocketIdNativeField(
      Dart_GetNativeArgument(args, 0), &socket);
  DART_CHECK_ERROR(result);

  intptr_t port = 0;
  SocketAddress* addr = SynchronousSocket::GetRemotePeer(socket->fd(), &port);
  if (addr == NULL) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    return;
  }
  Dart_Handle list = Dart_NewList(2);
  DART_CHECK_ERROR_AND_CLEANUP(list, addr);

  Dart_Handle entry = Dart_NewList(3);
  DART_CHECK_ERROR_AND_CLEANUP(entry, addr);

  Dart_Handle error =
      Dart_ListSetAt(entry, 0, Dart_NewInteger(addr->GetType()));
  DART_CHECK_ERROR_AND_CLEANUP(error, addr);
  error =
      Dart_ListSetAt(entry, 1, Dart_NewStringFromCString(addr->as_string()));
  DART_CHECK_ERROR_AND_CLEANUP(error, addr);

  RawAddr raw = addr->addr();
  error = Dart_ListSetAt(entry, 2, SocketAddress::ToTypedData(raw));
  DART_CHECK_ERROR_AND_CLEANUP(error, addr);

  error = Dart_ListSetAt(list, 0, entry);
  DART_CHECK_ERROR_AND_CLEANUP(error, addr);
  error = Dart_ListSetAt(list, 1, Dart_NewInteger(port));
  DART_CHECK_ERROR_AND_CLEANUP(error, addr);
  Dart_SetReturnValue(args, list);
  delete addr;
}

static void SynchronousSocketFinalizer(void* isolate_data,
                                       Dart_WeakPersistentHandle handle,
                                       void* data) {
  SynchronousSocket* socket = reinterpret_cast<SynchronousSocket*>(data);
  if (socket->fd() >= 0) {
    SynchronousSocket::Close(socket->fd());
    socket->SetClosedFd();
  }
  delete socket;
}

Dart_Handle SynchronousSocket::SetSocketIdNativeField(
    Dart_Handle handle,
    SynchronousSocket* socket) {
  Dart_Handle error = Dart_SetNativeInstanceField(
      handle, kSocketIdNativeField, reinterpret_cast<intptr_t>(socket));
  if (Dart_IsError(error)) {
    delete socket;
    return error;
  }

  Dart_NewWeakPersistentHandle(handle, reinterpret_cast<void*>(socket),
                               sizeof(SynchronousSocket),
                               SynchronousSocketFinalizer);
  return error;
}

Dart_Handle SynchronousSocket::GetSocketIdNativeField(
    Dart_Handle socket_obj,
    SynchronousSocket** socket) {
  ASSERT(socket != NULL);
  intptr_t id;
  Dart_Handle result =
      Dart_GetNativeInstanceField(socket_obj, kSocketIdNativeField, &id);
  if (Dart_IsError(result)) {
    return result;
  }
  *socket = reinterpret_cast<SynchronousSocket*>(id);
  return result;
}

}  // namespace bin
}  // namespace dart
