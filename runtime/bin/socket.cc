// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/socket.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"

dart::Mutex Socket::mutex_;
int Socket::service_ports_size_ = 0;
Dart_Port* Socket::service_ports_ = NULL;
int Socket::service_ports_index_ = 0;

void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 0);
  const char* host = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t port = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t socket = Socket::CreateConnect(host, port);
  if (socket >= 0) {
    DartUtils::SetIntegerField(socketobj, DartUtils::kIdFieldName, socket);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_Available)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int64_t socket = DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                              DartUtils::kIdFieldName);
  intptr_t available = Socket::Available(socket);
  Dart_SetReturnValue(args, Dart_NewInteger(available));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_ReadList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT((offset + length) <= buffer_len);

  if (Dart_IsVMFlagSet("short_socket_read")) {
    length = (length + 1) / 2;
  }

  uint8_t* buffer = new uint8_t[length];
  intptr_t bytes_read = Socket::Read(socket, buffer, length);
  if (bytes_read > 0) {
    Dart_Handle result =
        Dart_ListSetAsBytes(buffer_obj, offset, buffer, bytes_read);
    if (Dart_IsError(result)) {
      delete[] buffer;
      Dart_PropagateError(result);
    }
  }
  delete[] buffer;
  if (bytes_read >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_WriteList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT((offset + length) <= buffer_len);

  if (Dart_IsVMFlagSet("short_socket_write")) {
    length = (length + 1) / 2;
  }

  // Send data in chunks of maximum 16KB.
  const intptr_t max_chunk_length =
      dart::Utils::Minimum(length, static_cast<intptr_t>(16 * KB));
  uint8_t* buffer = new uint8_t[max_chunk_length];
  intptr_t total_bytes_written = 0;
  intptr_t bytes_written = 0;
  do {
    intptr_t chunk_length =
        dart::Utils::Minimum(max_chunk_length, length - total_bytes_written);
    result = Dart_ListGetAsBytes(buffer_obj,
                                 offset + total_bytes_written,
                                 buffer,
                                 chunk_length);
    if (Dart_IsError(result)) {
      delete[] buffer;
      Dart_PropagateError(result);
    }
    bytes_written =
        Socket::Write(socket, reinterpret_cast<void*>(buffer), chunk_length);
    total_bytes_written += bytes_written;
  } while (bytes_written > 0 && total_bytes_written < length);
  delete[] buffer;
  if (bytes_written >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(total_bytes_written));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetPort)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  OSError os_error;
  intptr_t port = Socket::GetPort(socket);
  if (port > 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(port));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetRemotePeer)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  OSError os_error;
  intptr_t port = 0;
  char host[INET_ADDRSTRLEN];
  if (Socket::GetRemotePeer(socket, host, &port)) {
    Dart_Handle list = Dart_NewList(2);
    Dart_ListSetAt(list, 0, Dart_NewString(host));
    Dart_ListSetAt(list, 1, Dart_NewInteger(port));
    Dart_SetReturnValue(args, list);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetError)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  OSError os_error;
  Socket::GetError(socket, &os_error);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 0);
  intptr_t num =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  ASSERT(num == 0 || num == 1 || num == 2);
  intptr_t socket = Socket::GetStdioHandle(num);
  DartUtils::SetIntegerField(
      socketobj, DartUtils::kIdFieldName, socket);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
  Dart_ExitScope();
}


void FUNCTION_NAME(ServerSocket_CreateBindListen)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 0);
  const char* bindAddress =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  intptr_t port = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t backlog =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t socket =
      ServerSocket::CreateBindListen(bindAddress, port, backlog);
  if (socket >= 0) {
    DartUtils::SetIntegerField(
        socketobj, DartUtils::kIdFieldName, socket);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(ServerSocket_Accept)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerField(Dart_GetNativeArgument(args, 0),
                                 DartUtils::kIdFieldName);
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 1);
  intptr_t newSocket = ServerSocket::Accept(socket);
  if (newSocket >= 0) {
    DartUtils::SetIntegerField(
        socketobj, DartUtils::kIdFieldName, newSocket);
    Dart_SetReturnValue(args, Dart_True());
  } else if (newSocket == ServerSocket::kTemporaryFailure) {
    Dart_SetReturnValue(args, Dart_False());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


static CObject* LookupRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString host(request[1]);
    CObject* result = NULL;
    OSError* os_error = NULL;
    const char* ip_address =
        Socket::LookupIPv4Address(host.CString(), &os_error);
    if (ip_address != NULL) {
      result = new CObjectString(CObject::NewString(ip_address));
      free(const_cast<char*>(ip_address));
    } else {
      result = CObject::NewOSError(os_error);
      delete os_error;
    }
    return result;
  }
  return CObject::IllegalArgumentError();
}


void SocketService(Dart_Port dest_port_id,
                   Dart_Port reply_port_id,
                   Dart_CObject* message) {
  CObject* response = CObject::False();
  CObjectArray request(message);
  if (message->type == Dart_CObject::kArray) {
    if (request.Length() > 1 && request[0]->IsInt32()) {
      CObjectInt32 requestType(request[0]);
      switch (requestType.Value()) {
        case Socket::kLookupRequest:
          response = LookupRequest(request);
          break;
        default:
          UNREACHABLE();
      }
    }
  }

  Dart_PostCObject(reply_port_id, response->AsApiCObject());
}


Dart_Port Socket::GetServicePort() {
  MutexLocker lock(&mutex_);
  if (service_ports_size_ == 0) {
    ASSERT(service_ports_ == NULL);
    service_ports_size_ = 16;
    service_ports_ = new Dart_Port[service_ports_size_];
    service_ports_index_ = 0;
    for (int i = 0; i < service_ports_size_; i++) {
      service_ports_[i] = kIllegalPort;
    }
  }

  Dart_Port result = service_ports_[service_ports_index_];
  if (result == kIllegalPort) {
    result = Dart_NewNativePort("SocketService",
                                SocketService,
                                true);
    ASSERT(result != kIllegalPort);
    service_ports_[service_ports_index_] = result;
  }
  service_ports_index_ = (service_ports_index_ + 1) % service_ports_size_;
  return result;
}


void FUNCTION_NAME(Socket_NewServicePort)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_Null());
  Dart_Port service_port = Socket::GetServicePort();
  if (service_port != kIllegalPort) {
    // Return a send port for the service port.
    Dart_Handle send_port = Dart_NewSendPort(service_port);
    Dart_SetReturnValue(args, send_port);
  }
  Dart_ExitScope();
}
