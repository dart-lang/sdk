// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "bin/socket.h"
#include "bin/utils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

static const int kProcessIdNativeField = 0;

int Process::global_exit_code_ = 0;
Mutex* Process::global_exit_code_mutex_ = new Mutex();

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
  Dart_Handle process =  Dart_GetNativeArgument(args, 0);
  intptr_t process_stdin;
  intptr_t process_stdout;
  intptr_t process_stderr;
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
      return;
    }
  }
  Dart_Handle stdin_handle = Dart_GetNativeArgument(args, 5);
  Dart_Handle stdout_handle = Dart_GetNativeArgument(args, 6);
  Dart_Handle stderr_handle = Dart_GetNativeArgument(args, 7);
  Dart_Handle exit_handle = Dart_GetNativeArgument(args, 8);
  intptr_t pid = -1;
  char* os_error_message = NULL;

  int error_code = Process::Start(path,
                                  string_args,
                                  args_length,
                                  working_directory,
                                  string_environment,
                                  environment_length,
                                  &process_stdout,
                                  &process_stdin,
                                  &process_stderr,
                                  &pid,
                                  &exit_event,
                                  &os_error_message);
  if (error_code == 0) {
    Socket::SetSocketIdNativeField(stdin_handle, process_stdin);
    Socket::SetSocketIdNativeField(stdout_handle, process_stdout);
    Socket::SetSocketIdNativeField(stderr_handle, process_stderr);
    Socket::SetSocketIdNativeField(exit_handle, exit_event);
    Process::SetProcessIdNativeField(process, pid);
  } else {
    DartUtils::SetIntegerField(
        status_handle, "_errorCode", error_code);
    DartUtils::SetStringField(
        status_handle, "_errorMessage", os_error_message);
  }
  delete[] string_args;
  delete[] string_environment;
  free(os_error_message);
  Dart_SetReturnValue(args, Dart_NewBoolean(error_code == 0));
}


void FUNCTION_NAME(Process_Wait)(Dart_NativeArguments args) {
  Dart_Handle process =  Dart_GetNativeArgument(args, 0);
  intptr_t process_stdin =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 1));
  intptr_t process_stdout =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 2));
  intptr_t process_stderr =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 3));
  intptr_t exit_event =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 4));
  ProcessResult result;
  intptr_t pid;
  Process::GetProcessIdNativeField(process, &pid);
  if (Process::Wait(pid,
                    process_stdin,
                    process_stdout,
                    process_stderr,
                    exit_event,
                    &result)) {
    Dart_Handle out = result.stdout_data();
    if (Dart_IsError(out)) Dart_PropagateError(out);
    Dart_Handle err = result.stderr_data();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_Handle list = Dart_NewList(4);
    Dart_ListSetAt(list, 0, Dart_NewInteger(pid));
    Dart_ListSetAt(list, 1, Dart_NewInteger(result.exit_code()));
    Dart_ListSetAt(list, 2, out);
    Dart_ListSetAt(list, 3, err);
    Dart_SetReturnValue(args, list);
  } else {
    Dart_Handle error = DartUtils::NewDartOSError();
    Process::Kill(pid, 9);
    if (Dart_IsError(error)) Dart_PropagateError(error);
    Dart_ThrowException(error);
  }
}


void FUNCTION_NAME(Process_Kill)(Dart_NativeArguments args) {
  Dart_Handle process = Dart_GetNativeArgument(args, 1);
  intptr_t pid = -1;
  Process::GetProcessIdNativeField(process, &pid);
  intptr_t signal = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  bool success = Process::Kill(pid, signal);
  Dart_SetReturnValue(args, Dart_NewBoolean(success));
}


void FUNCTION_NAME(Process_Exit)(Dart_NativeArguments args) {
  int64_t status = 0;
  // Ignore result if passing invalid argument and just exit 0.
  DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &status);
  Dart_ExitIsolate();
  Dart_Cleanup();
  exit(static_cast<int>(status));
}


void FUNCTION_NAME(Process_SetExitCode)(Dart_NativeArguments args) {
  int64_t status = 0;
  // Ignore result if passing invalid argument and just set exit code to 0.
  DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &status);
  Process::SetGlobalExitCode(status);
}


void FUNCTION_NAME(Process_GetExitCode)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewInteger(Process::GlobalExitCode()));
}


void FUNCTION_NAME(Process_Sleep)(Dart_NativeArguments args) {
  ScopedBlockingCall blocker;
  int64_t milliseconds = 0;
  // Ignore result if passing invalid argument and just set exit code to 0.
  DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &milliseconds);
  TimerUtils::Sleep(milliseconds);
}


void FUNCTION_NAME(Process_Pid)(Dart_NativeArguments args) {
  // Ignore result if passing invalid argument and just set exit code to 0.
  intptr_t pid = -1;
  Dart_Handle process = Dart_GetNativeArgument(args, 0);
  if (Dart_IsNull(process)) {
    pid = Process::CurrentProcessId();
  } else {
    Process::GetProcessIdNativeField(process, &pid);
  }
  Dart_SetReturnValue(args, Dart_NewInteger(pid));
}


void FUNCTION_NAME(Process_SetSignalHandler)(Dart_NativeArguments args) {
  intptr_t signal = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  intptr_t id = Process::SetSignalHandler(signal);
  if (id == -1) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  } else {
    Dart_SetReturnValue(args, Dart_NewInteger(id));
  }
}


void FUNCTION_NAME(Process_ClearSignalHandler)(Dart_NativeArguments args) {
  intptr_t signal = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  Process::ClearSignalHandler(signal);
}


Dart_Handle Process::GetProcessIdNativeField(Dart_Handle process,
                                             intptr_t* pid) {
  return Dart_GetNativeInstanceField(process, kProcessIdNativeField, pid);
}


Dart_Handle Process::SetProcessIdNativeField(Dart_Handle process,
                                             intptr_t pid) {
  return Dart_SetNativeInstanceField(process, kProcessIdNativeField, pid);
}


void FUNCTION_NAME(SystemEncodingToString)(Dart_NativeArguments args) {
  Dart_Handle bytes = Dart_GetNativeArgument(args, 0);
  intptr_t bytes_length = 0;
  Dart_Handle result = Dart_ListLength(bytes, &bytes_length);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  uint8_t* buffer = new uint8_t[bytes_length + 1];
  result = Dart_ListGetAsBytes(bytes, 0, buffer, bytes_length);
  buffer[bytes_length] = '\0';
  if (Dart_IsError(result)) {
    delete[] buffer;
    Dart_PropagateError(result);
  }
  char* str =
      StringUtils::ConsoleStringToUtf8(reinterpret_cast<char*>(buffer));
  Dart_SetReturnValue(args, DartUtils::NewString(str));
  if (str != reinterpret_cast<char*>(buffer)) free(str);
}


void FUNCTION_NAME(StringToSystemEncoding)(Dart_NativeArguments args) {
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  const char* utf8 = DartUtils::GetStringValue(str);
  const char* system_string = StringUtils::Utf8ToConsoleString(utf8);
  int external_length = strlen(system_string);
  uint8_t* buffer = NULL;
  Dart_Handle external_array = IOBuffer::Allocate(external_length, &buffer);
  memmove(buffer, system_string, external_length);
  if (utf8 != system_string) free(const_cast<char*>(system_string));
  Dart_SetReturnValue(args, external_array);
}

}  // namespace bin
}  // namespace dart
