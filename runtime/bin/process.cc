// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/process.h"

#include "include/dart_api.h"

void FUNCTION_NAME(Process_Start)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle process =  Dart_GetNativeArgument(args, 0);
  intptr_t in;
  intptr_t out;
  intptr_t err;
  intptr_t exit_event;
  Dart_Handle status_handle = Dart_GetNativeArgument(args, 7);
  Dart_Handle path_handle = Dart_GetNativeArgument(args, 1);
  // The Dart code verifies that the path implements the String
  // interface. However, only builtin Strings are handled by
  // GetStringValue.
  if (!Dart_IsString(path_handle)) {
    DartUtils::SetIntegerInstanceField(status_handle, "_errorCode", 0);
    DartUtils::SetStringInstanceField(
        status_handle, "_errorMessage", "Path must be a builtin string");
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    Dart_ExitScope();
    return;
  }
  const char* path = DartUtils::GetStringValue(path_handle);
  Dart_Handle arguments = Dart_GetNativeArgument(args, 2);
  // The arguments are copied into a non-extensible array in the
  // dart code so this should not fail.
  ASSERT(Dart_IsList(arguments));
  intptr_t length = 0;
  Dart_Handle result = Dart_ListLength(arguments, &length);
  ASSERT(!Dart_IsError(result));
  char** string_args = new char*[length];
  for (int i = 0; i < length; i++) {
    Dart_Handle arg = Dart_ListGetAt(arguments, i);
    ASSERT(!Dart_IsError(arg));
    // The Dart code verifies that the arguments implement the String
    // interface. However, only builtin Strings are handled by
    // GetStringValue.
    if (!Dart_IsString(arg)) {
      DartUtils::SetIntegerInstanceField(status_handle, "_errorCode", 0);
      DartUtils::SetStringInstanceField(
          status_handle, "_errorMessage", "Arguments must be builtin strings");
      delete[] string_args;
      Dart_SetReturnValue(args, Dart_NewBoolean(false));
      Dart_ExitScope();
      return;
    }
    string_args[i] = const_cast<char *>(DartUtils::GetStringValue(arg));
  }
  Dart_Handle in_handle = Dart_GetNativeArgument(args, 3);
  Dart_Handle out_handle = Dart_GetNativeArgument(args, 4);
  Dart_Handle err_handle = Dart_GetNativeArgument(args, 5);
  Dart_Handle exit_handle = Dart_GetNativeArgument(args, 6);
  intptr_t pid = -1;
  static const int kMaxChildOsErrorMessageLength = 256;
  char os_error_message[kMaxChildOsErrorMessageLength];

  int error_code = Process::Start(
      path, string_args, length,
      &in, &out, &err, &pid, &exit_event,
      os_error_message, kMaxChildOsErrorMessageLength);
  if (error_code == 0) {
    DartUtils::SetIntegerInstanceField(in_handle, DartUtils::kIdFieldName, in);
    DartUtils::SetIntegerInstanceField(
        out_handle, DartUtils::kIdFieldName, out);
    DartUtils::SetIntegerInstanceField(
        err_handle, DartUtils::kIdFieldName, err);
    DartUtils::SetIntegerInstanceField(
        exit_handle, DartUtils::kIdFieldName, exit_event);
    DartUtils::SetIntegerInstanceField(process, "_pid", pid);
  } else {
    DartUtils::SetIntegerInstanceField(
        status_handle, "_errorCode", error_code);
    DartUtils::SetStringInstanceField(
        status_handle, "_errorMessage", os_error_message);
  }
  delete[] string_args;
  Dart_SetReturnValue(args, Dart_NewBoolean(error_code == 0));
  Dart_ExitScope();
}


void FUNCTION_NAME(Process_Kill)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t pid = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  bool success = Process::Kill(pid);
  Dart_SetReturnValue(args, Dart_NewBoolean(success));
  Dart_ExitScope();
}


void FUNCTION_NAME(Process_Exit)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t pid = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  Process::Exit(pid);
  Dart_ExitScope();
}
