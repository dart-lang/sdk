// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "bin/process.h"

#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/log.h"
#include "bin/platform.h"
#include "bin/socket.h"
#include "bin/utils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

static const int kProcessIdNativeField = 0;

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
  if ((len < 0) || (len > kMaxArgumentListLength)) {
    result = DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    result = DartUtils::SetStringField(status_handle, "_errorMessage",
                                       "Max argument list length exceeded");
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    return NULL;
  }
  *length = len;
  char** string_args;
  string_args =
      reinterpret_cast<char**>(Dart_ScopeAllocate(len * sizeof(*string_args)));
  for (int i = 0; i < len; i++) {
    Dart_Handle arg = Dart_ListGetAt(strings, i);
    if (Dart_IsError(arg)) {
      Dart_PropagateError(arg);
    }
    if (!Dart_IsString(arg)) {
      result = DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
      if (Dart_IsError(result)) {
        Dart_PropagateError(result);
      }
      result =
          DartUtils::SetStringField(status_handle, "_errorMessage", error_msg);
      if (Dart_IsError(result)) {
        Dart_PropagateError(result);
      }
      return NULL;
    }
    string_args[i] = const_cast<char*>(DartUtils::GetStringValue(arg));
  }
  return string_args;
}


void Process::ClearAllSignalHandlers() {
  for (intptr_t i = 1; i <= kLastSignal; i++) {
    ClearSignalHandler(i);
  }
}


void FUNCTION_NAME(Process_Start)(Dart_NativeArguments args) {
  Dart_Handle process = Dart_GetNativeArgument(args, 0);
  intptr_t process_stdin;
  intptr_t process_stdout;
  intptr_t process_stderr;
  intptr_t exit_event;
  Dart_Handle result;
  Dart_Handle status_handle = Dart_GetNativeArgument(args, 10);
  Dart_Handle path_handle = Dart_GetNativeArgument(args, 1);
  // The Dart code verifies that the path implements the String
  // interface. However, only builtin Strings are handled by
  // GetStringValue.
  if (!Dart_IsString(path_handle)) {
    result = DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    result = DartUtils::SetStringField(status_handle, "_errorMessage",
                                       "Path must be a builtin string");
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    return;
  }
  const char* path = DartUtils::GetStringValue(path_handle);
  Dart_Handle arguments = Dart_GetNativeArgument(args, 2);
  intptr_t args_length = 0;
  char** string_args =
      ExtractCStringList(arguments, status_handle,
                         "Arguments must be builtin strings", &args_length);
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
    result = DartUtils::SetIntegerField(status_handle, "_errorCode", 0);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    result =
        DartUtils::SetStringField(status_handle, "_errorMessage",
                                  "WorkingDirectory must be a builtin string");
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
    return;
  }
  Dart_Handle environment = Dart_GetNativeArgument(args, 4);
  intptr_t environment_length = 0;
  char** string_environment = NULL;
  if (!Dart_IsNull(environment)) {
    string_environment = ExtractCStringList(
        environment, status_handle,
        "Environment values must be builtin strings", &environment_length);
    if (string_environment == NULL) {
      Dart_SetReturnValue(args, Dart_NewBoolean(false));
      return;
    }
  }
  int64_t mode =
      DartUtils::GetInt64ValueCheckRange(Dart_GetNativeArgument(args, 5), 0, 2);
  Dart_Handle stdin_handle = Dart_GetNativeArgument(args, 6);
  Dart_Handle stdout_handle = Dart_GetNativeArgument(args, 7);
  Dart_Handle stderr_handle = Dart_GetNativeArgument(args, 8);
  Dart_Handle exit_handle = Dart_GetNativeArgument(args, 9);
  intptr_t pid = -1;
  char* os_error_message = NULL;  // Scope allocated by Process::Start.

  int error_code = Process::Start(
      path, string_args, args_length, working_directory, string_environment,
      environment_length, static_cast<ProcessStartMode>(mode), &process_stdout,
      &process_stdin, &process_stderr, &pid, &exit_event, &os_error_message);
  if (error_code == 0) {
    if (mode != kDetached) {
      Socket::SetSocketIdNativeField(stdin_handle, process_stdin,
                                     Socket::kFinalizerNormal);
      Socket::SetSocketIdNativeField(stdout_handle, process_stdout,
                                     Socket::kFinalizerNormal);
      Socket::SetSocketIdNativeField(stderr_handle, process_stderr,
                                     Socket::kFinalizerNormal);
    }
    if (mode == kNormal) {
      Socket::SetSocketIdNativeField(exit_handle, exit_event,
                                     Socket::kFinalizerNormal);
    }
    Process::SetProcessIdNativeField(process, pid);
  } else {
    result =
        DartUtils::SetIntegerField(status_handle, "_errorCode", error_code);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    result = DartUtils::SetStringField(status_handle, "_errorMessage",
                                       os_error_message != NULL
                                           ? os_error_message
                                           : "Cannot get error message");
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
  }
  Dart_SetReturnValue(args, Dart_NewBoolean(error_code == 0));
}


void FUNCTION_NAME(Process_Wait)(Dart_NativeArguments args) {
  Dart_Handle process = Dart_GetNativeArgument(args, 0);
  Socket* process_stdin =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 1));
  Socket* process_stdout =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 2));
  Socket* process_stderr =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 3));
  Socket* exit_event =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 4));
  ProcessResult result;
  intptr_t pid;
  Process::GetProcessIdNativeField(process, &pid);
  bool success = Process::Wait(pid, process_stdin->fd(), process_stdout->fd(),
                               process_stderr->fd(), exit_event->fd(), &result);
  // Process::Wait() closes the file handles, so blow away the fds in the
  // Sockets so that they don't get picked up by the finalizer on _NativeSocket.
  process_stdin->SetClosedFd();
  process_stdout->SetClosedFd();
  process_stderr->SetClosedFd();
  exit_event->SetClosedFd();
  if (success) {
    Dart_Handle out = result.stdout_data();
    if (Dart_IsError(out)) {
      Dart_PropagateError(out);
    }
    Dart_Handle err = result.stderr_data();
    if (Dart_IsError(err)) {
      Dart_PropagateError(err);
    }
    Dart_Handle list = Dart_NewList(4);
    Dart_ListSetAt(list, 0, Dart_NewInteger(pid));
    Dart_ListSetAt(list, 1, Dart_NewInteger(result.exit_code()));
    Dart_ListSetAt(list, 2, out);
    Dart_ListSetAt(list, 3, err);
    Dart_SetReturnValue(args, list);
  } else {
    Dart_Handle error = DartUtils::NewDartOSError();
    Process::Kill(pid, 9);
    Dart_ThrowException(error);
  }
}


void FUNCTION_NAME(Process_KillPid)(Dart_NativeArguments args) {
  intptr_t pid = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  intptr_t signal = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  bool success = Process::Kill(pid, signal);
  Dart_SetReturnValue(args, Dart_NewBoolean(success));
}


void FUNCTION_NAME(Process_Exit)(Dart_NativeArguments args) {
  int64_t status = 0;
  // Ignore result if passing invalid argument and just exit 0.
  DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &status);
  Process::RunExitHook(status);
  Dart_ExitIsolate();
  Platform::Exit(static_cast<int>(status));
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
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  uint8_t* buffer = Dart_ScopeAllocate(bytes_length + 1);
  result = Dart_ListGetAsBytes(bytes, 0, buffer, bytes_length);
  buffer[bytes_length] = '\0';
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  intptr_t len;
  char* str = StringUtils::ConsoleStringToUtf8(reinterpret_cast<char*>(buffer),
                                               bytes_length, &len);
  if (str == NULL) {
    Dart_ThrowException(
        DartUtils::NewInternalError("SystemEncodingToString failed"));
  }
  result = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(str), len);
  Dart_SetReturnValue(args, result);
}


void FUNCTION_NAME(StringToSystemEncoding)(Dart_NativeArguments args) {
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  char* utf8;
  intptr_t utf8_len;
  Dart_Handle result =
      Dart_StringToUTF8(str, reinterpret_cast<uint8_t**>(&utf8), &utf8_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  intptr_t system_len;
  const char* system_string =
      StringUtils::Utf8ToConsoleString(utf8, utf8_len, &system_len);
  if (system_string == NULL) {
    Dart_ThrowException(
        DartUtils::NewInternalError("StringToSystemEncoding failed"));
  }
  uint8_t* buffer = NULL;
  Dart_Handle external_array = IOBuffer::Allocate(system_len, &buffer);
  if (!Dart_IsError(external_array)) {
    memmove(buffer, system_string, system_len);
  }
  Dart_SetReturnValue(args, external_array);
}


void FUNCTION_NAME(ProcessInfo_CurrentRSS)(Dart_NativeArguments args) {
  int64_t current_rss = Process::CurrentRSS();
  if (current_rss < 0) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    return;
  }
  Dart_SetIntegerReturnValue(args, current_rss);
}


void FUNCTION_NAME(ProcessInfo_MaxRSS)(Dart_NativeArguments args) {
  int64_t max_rss = Process::MaxRSS();
  if (max_rss < 0) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    return;
  }
  Dart_SetIntegerReturnValue(args, max_rss);
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
