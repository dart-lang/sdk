// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/socket.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 0);
  const char* host =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  intptr_t port = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t socket = Socket::CreateConnect(host, port);
  DartUtils::SetIntegerInstanceField(
      socketobj, DartUtils::kIdFieldName, socket);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_Available)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerInstanceField(Dart_GetNativeArgument(args, 0),
                                         DartUtils::kIdFieldName);
  intptr_t available = Socket::Available(socket);
  Dart_SetReturnValue(args, Dart_NewInteger(available));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_ReadList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerInstanceField(Dart_GetNativeArgument(args, 0),
                                         DartUtils::kIdFieldName);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  ASSERT(!Dart_IsError(result));
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
      bytes_read = -1;
    }
  } else if (bytes_read < 0) {
    bytes_read = 0;
  }
  delete[] buffer;
  Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_WriteList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerInstanceField(Dart_GetNativeArgument(args, 0),
                                         DartUtils::kIdFieldName);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  intptr_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  ASSERT(!Dart_IsError(result));
  ASSERT((offset + length) <= buffer_len);

  if (Dart_IsVMFlagSet("short_socket_write")) {
    length = (length + 1) / 2;
  }

  uint8_t* buffer = new uint8_t[length];
  result = Dart_ListGetAsBytes(buffer_obj, offset, buffer, length);
  ASSERT(!Dart_IsError(result));
  intptr_t total_bytes_written =
      Socket::Write(socket, reinterpret_cast<void*>(buffer), length);
  delete[] buffer;
  if (total_bytes_written < 0) {
    total_bytes_written = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(total_bytes_written));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetPort)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerInstanceField(Dart_GetNativeArgument(args, 0),
                                         DartUtils::kIdFieldName);
  intptr_t port = Socket::GetPort(socket);
  Dart_SetReturnValue(args, Dart_NewInteger(port));
  Dart_ExitScope();
}


void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 0);
  intptr_t num =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  ASSERT(num == 0 || num == 1 || num == 2);
  intptr_t socket = Socket::GetStdioHandle(num);
  DartUtils::SetIntegerInstanceField(
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
  DartUtils::SetIntegerInstanceField(
      socketobj, DartUtils::kIdFieldName, socket);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
  Dart_ExitScope();
}


void FUNCTION_NAME(ServerSocket_Accept)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t socket =
      DartUtils::GetIntegerInstanceField(Dart_GetNativeArgument(args, 0),
                                         DartUtils::kIdFieldName);
  Dart_Handle socketobj = Dart_GetNativeArgument(args, 1);
  intptr_t newSocket = ServerSocket::Accept(socket);
  if (newSocket >= 0) {
    DartUtils::SetIntegerInstanceField(
        socketobj, DartUtils::kIdFieldName, newSocket);
  }
  Dart_SetReturnValue(args, Dart_NewBoolean(newSocket >= 0));
  Dart_ExitScope();
}
