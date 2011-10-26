// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


static const int kFileFieldIndex = 0;


bool File::ReadFully(void* buffer, int64_t num_bytes) {
  int64_t remaining = num_bytes;
  char* current_buffer = reinterpret_cast<char*>(buffer);
  while (remaining > 0) {
    int bytes_read = Read(current_buffer, remaining);
    if (bytes_read <= 0) {
      return false;
    }
    remaining -= bytes_read;  // Reduce the number of remaining bytes.
    current_buffer += bytes_read;  // Move the buffer forward.
  }
  return true;
}


bool File::WriteFully(const void* buffer, int64_t num_bytes) {
  int64_t remaining = num_bytes;
  const char* current_buffer = reinterpret_cast<const char*>(buffer);
  while (remaining > 0) {
    int bytes_read = Write(current_buffer, remaining);
    if (bytes_read < 0) {
      return false;
    }
    remaining -= bytes_read;  // Reduce the number of remaining bytes.
    current_buffer += bytes_read;  // Move the buffer forward.
  }
  return true;
}


static File* GetFileHandle(Dart_Handle fileobj) {
  intptr_t value = 0;
  Dart_Handle result = Dart_GetNativeInstanceField(fileobj, kFileFieldIndex,
                                                   &value);
  ASSERT(Dart_IsValid(result));
  File* file = reinterpret_cast<File*>(value);
  return file;
}


void FUNCTION_NAME(File_OpenFile)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle fileobj = Dart_GetNativeArgument(args, 0);
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  bool writable = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  File* file = File::OpenFile(filename, writable);
  Dart_SetNativeInstanceField(fileobj,
                              kFileFieldIndex,
                              reinterpret_cast<intptr_t>(file));
  Dart_SetReturnValue(args, Dart_NewBoolean(file != NULL));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Exists)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool exists = File::FileExists(filename);
  Dart_SetReturnValue(args, Dart_NewBoolean(exists));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Close)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  Dart_Handle fileobj = Dart_GetNativeArgument(args, 0);
  File* file = GetFileHandle(fileobj);
  if (file != NULL) {
    Dart_SetNativeInstanceField(fileobj,
                                kFileFieldIndex,
                                NULL);
    delete file;
    return_value = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    uint8_t buffer;
    int bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
    if (bytes_read >= 0) {
      return_value = static_cast<intptr_t>(buffer);
    }
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    int64_t value = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
    uint8_t buffer = static_cast<uint8_t>(value & 0xff);
    int bytes_written = file->Write(reinterpret_cast<void*>(&buffer), 1);
    if (bytes_written >= 0) {
      return_value = bytes_written;
    }
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteString)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    const char* str =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    int bytes_written = file->Write(reinterpret_cast<const void*>(str),
                                  strlen(str));
    if (bytes_written >= 0) {
      return_value = bytes_written;
    }
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
    ASSERT(Dart_IsArray(buffer_obj));
    int64_t offset =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
    int64_t length =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
    intptr_t array_len = 0;
    Dart_Handle result = Dart_GetLength(buffer_obj, &array_len);
    ASSERT(Dart_IsValid(result));
    ASSERT((offset + length) <= array_len);
    uint8_t* buffer = new uint8_t[length];
    int total_bytes_read =
        file->Read(reinterpret_cast<void*>(buffer), length);
    /*
     * Reading 0 indicates end of file.
     */
    if (total_bytes_read >= 0) {
      result =
          Dart_ArraySet(buffer_obj, offset, buffer, total_bytes_read);
      ASSERT(Dart_IsValid(result));
      return_value = total_bytes_read;
    }
    delete[] buffer;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
    ASSERT(Dart_IsArray(buffer_obj));
    int64_t offset =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
    int64_t length =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
    intptr_t buffer_len = 0;
    Dart_Handle result = Dart_GetLength(buffer_obj, &buffer_len);
    ASSERT(Dart_IsValid(result));
    ASSERT((offset + length) <= buffer_len);
    uint8_t* buffer = new uint8_t[length];
    result = Dart_ArrayGet(buffer_obj, offset, buffer, length);
    ASSERT(Dart_IsValid(result));
    int total_bytes_written =
        file->Write(reinterpret_cast<void*>(buffer), length);
    if (total_bytes_written >= 0) {
      return_value = total_bytes_written;
    }
    delete[] buffer;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Position)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    return_value = file->Position();
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    return_value = file->Length();
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  File* file = GetFileHandle(Dart_GetNativeArgument(args, 0));
  if (file != NULL) {
    file->Flush();
    return_value = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}
