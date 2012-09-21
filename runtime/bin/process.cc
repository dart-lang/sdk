// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/process.h"
#include "bin/socket.h"

#include "include/dart_api.h"


// Extract an array of C strings from a list of Dart strings.
static char** ExtractCStringList(Dart_Handle strings,
                                 Dart_Handle status_handle,
                                 const char* error_msg,
                                 intptr_t* length) {
  static const intptr_t kMaxArgumentListLength = 1024 * 1024;
  ASSERT(Dart_IsList(strings));
  intptr_t len = 0;
  Dart_Handle result = Dart_ListLength(strings, &len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  // Protect against user-defined list implementations that can have
  // arbitrary length.
  if (len < 0 || len > kMaxArgumentListLength) {
    DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    DartUtils::SetStringField(
        status_handle, "_errorMessage", "Max argument list length exceeded");
    return NULL;
  }
  *length = len;
  char** string_args = new char*[len];
  for (int i = 0; i < len; i++) {
    Dart_Handle arg = Dart_ListGetAt(strings, i);
    if (Dart_IsError(arg)) {
      delete[] string_args;
      Dart_PropagateError(arg);
    }
    if (!Dart_IsString(arg)) {
      DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
      DartUtils::SetStringField(
          status_handle, "_errorMessage", error_msg);
      delete[] string_args;
      return NULL;
    }
    string_args[i] = const_cast<char *>(DartUtils::GetStringValue(arg));
  }
  return string_args;
}

void FUNCTION_NAME(Process_Start)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle process =  Dart_GetNativeArgument(args, 0);
  intptr_t in;
  intptr_t out;
  intptr_t err;
  intptr_t exit_event;
  Dart_Handle status_handle = Dart_GetNativeArgument(args, 9);
  Dart_Handle path_handle = Dart_GetNativeArgument(args, 1);
  // The Dart code verifies that the path implements the String
  // interface. However, only builtin Strings are handled by
  // GetStringValue.
  if (!Dart_IsString(path_handle)) {
    DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    DartUtils::SetStringField(
        status_handle, "_errorMessage", "Path must be a builtin string");
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    Dart_ExitScope();
    return;
  }
  const char* path = DartUtils::GetStringValue(path_handle);
  Dart_Handle arguments = Dart_GetNativeArgument(args, 2);
  intptr_t args_length = 0;
  char** string_args =
      ExtractCStringList(arguments,
                         status_handle,
                         "Arguments must be builtin strings",
                         &args_length);
  if (string_args == NULL) {
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    Dart_ExitScope();
    return;
  }
  Dart_Handle working_directory_handle = Dart_GetNativeArgument(args, 3);
  // Defaults to the current working directoy.
  const char* working_directory = NULL;
  if (Dart_IsString(working_directory_handle)) {
    working_directory = DartUtils::GetStringValue(working_directory_handle);
  } else if (!Dart_IsNull(working_directory_handle)) {
    delete[] string_args;
    DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    DartUtils::SetStringField(
        status_handle, "_errorMessage",
        "WorkingDirectory must be a builtin string");
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    Dart_ExitScope();
    return;
  }
  Dart_Handle environment = Dart_GetNativeArgument(args, 4);
  intptr_t environment_length = 0;
  char** string_environment = NULL;
  if (!Dart_IsNull(environment)) {
    string_environment =
        ExtractCStringList(environment,
                           status_handle,
                           "Environment values must be builtin strings",
                           &environment_length);
    if (string_environment == NULL) {
      delete[] string_args;
      Dart_SetReturnValue(args, Dart_NewBoolean(false));
      Dart_ExitScope();
      return;
    }
  }
  Dart_Handle in_handle = Dart_GetNativeArgument(args, 5);
  Dart_Handle out_handle = Dart_GetNativeArgument(args, 6);
  Dart_Handle err_handle = Dart_GetNativeArgument(args, 7);
  Dart_Handle exit_handle = Dart_GetNativeArgument(args, 8);
  intptr_t pid = -1;
  static const int kMaxChildOsErrorMessageLength = 256;
  char os_error_message[kMaxChildOsErrorMessageLength];

  int error_code = Process::Start(path,
                                  string_args,
                                  args_length,
                                  working_directory,
                                  string_environment,
                                  environment_length,
                                  &in,
                                  &out,
                                  &err,
                                  &pid,
                                  &exit_event,
      os_error_message, kMaxChildOsErrorMessageLength);
  if (error_code == 0) {
    Socket::SetSocketIdNativeField(in_handle, in);
    Socket::SetSocketIdNativeField(out_handle, out);
    Socket::SetSocketIdNativeField(err_handle, err);
    Socket::SetSocketIdNativeField(exit_handle, exit_event);
    DartUtils::SetIntegerField(process, "_pid", pid);
  } else {
    DartUtils::SetIntegerField(
        status_handle, "_errorCode", error_code);
    DartUtils::SetStringField(
        status_handle, "_errorMessage", os_error_message);
  }
  delete[] string_args;
  delete[] string_environment;
  Dart_SetReturnValue(args, Dart_NewBoolean(error_code == 0));
  Dart_ExitScope();
}


void FUNCTION_NAME(Process_Kill)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t pid = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  int signal = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  bool success = Process::Kill(pid, signal);
  Dart_SetReturnValue(args, Dart_NewBoolean(success));
  Dart_ExitScope();
}
