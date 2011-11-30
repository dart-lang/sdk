// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


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


void FUNCTION_NAME(File_Open)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool writable = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  File* file = File::Open(filename, writable);
  Dart_SetReturnValue(args, Dart_NewInteger(reinterpret_cast<intptr_t>(file)));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Exists)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool exists = File::Exists(filename);
  Dart_SetReturnValue(args, Dart_NewBoolean(exists));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Close)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    delete file;
    return_value = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
    ASSERT(Dart_IsList(buffer_obj));
    int64_t offset =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
    int64_t length =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
    intptr_t array_len = 0;
    Dart_Handle result = Dart_ListLength(buffer_obj, &array_len);
    ASSERT(!Dart_IsError(result));
    ASSERT((offset + length) <= array_len);
    uint8_t* buffer = new uint8_t[length];
    int total_bytes_read =
        file->Read(reinterpret_cast<void*>(buffer), length);
    /*
     * Reading 0 indicates end of file.
     */
    if (total_bytes_read >= 0) {
      result =
          Dart_ListSetAsBytes(buffer_obj, offset, buffer, total_bytes_read);
      if (!Dart_IsError(result)) {
        return_value = total_bytes_read;
      }
    }
    delete[] buffer;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
    ASSERT(Dart_IsList(buffer_obj));
    int64_t offset =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
    int64_t length =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
    intptr_t buffer_len = 0;
    Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
    ASSERT(!Dart_IsError(result));
    ASSERT((offset + length) <= buffer_len);
    uint8_t* buffer = new uint8_t[length];
    result = Dart_ListGetAsBytes(buffer_obj, offset, buffer, length);
    ASSERT(!Dart_IsError(result));
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    return_value = file->Position();
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_SetPosition)(Dart_NativeArguments args) {
  Dart_EnterScope();
  bool return_value = false;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    int64_t position =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
    return_value = file->SetPosition(position);
  }
  Dart_SetReturnValue(args, Dart_NewBoolean(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Truncate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  bool return_value = false;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    int64_t length =
        DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
    return_value = file->Truncate(length);
  }
  Dart_SetReturnValue(args, Dart_NewBoolean(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    return_value = file->Length();
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t return_value = -1;
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  if (file != NULL) {
    file->Flush();
    return_value = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Create)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool result = File::Create(str);
  Dart_SetReturnValue(args, Dart_NewBoolean(result));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Delete)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool result = File::Delete(str);
  Dart_SetReturnValue(args, Dart_NewBoolean(result));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_FullPath)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  char* path = File::GetCanonicalPath(str);
  if (path != NULL) {
    Dart_SetReturnValue(args, Dart_NewString(path));
    free(path);
  }
  Dart_ExitScope();
}
