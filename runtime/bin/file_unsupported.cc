// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(File_GetPointer)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_SetPointer)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Open)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Exists)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Close)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_WriteByte)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Read)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_ReadInto)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_WriteFrom)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Position)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_SetPosition)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Truncate)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_LengthFromPath)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_LastModified)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_LastAccessed)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_SetLastModified)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_SetLastAccessed)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Lock)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Create)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_CreateLink)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_LinkTarget)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Delete)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_DeleteLink)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Rename)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_RenameLink)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Copy)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_ResolveSymbolicLinks)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_OpenStdio)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_GetStdioHandleType)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_GetType)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_Stat)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

void FUNCTION_NAME(File_AreIdentical)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewInternalError("File is not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
