// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/process.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

int Process::global_exit_code_ = 0;
Mutex* Process::global_exit_code_mutex_ = new Mutex();
Process::ExitHook Process::exit_hook_ = NULL;

void Process::TerminateExitCodeHandler() {}

void Process::ClearAllSignalHandlers() {}

void FUNCTION_NAME(Process_Start)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_Wait)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_KillPid)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_Exit)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_SetExitCode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_GetExitCode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_Sleep)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_Pid)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_SetSignalHandler)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(Process_ClearSignalHandler)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(SystemEncodingToString)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(StringToSystemEncoding)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(ProcessInfo_CurrentRSS)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}


void FUNCTION_NAME(ProcessInfo_MaxRSS)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("Process is not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
