// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/embedded_dart_io.h"
#include "bin/io_buffer.h"
#include "bin/namespace.h"
#include "bin/utils.h"
#include "include/dart_api.h"
#include "include/dart_tools_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

static const int kFileNativeFieldIndex = 0;

#if !defined(PRODUCT)
static bool IsFile(Dart_Handle file_obj) {
  Dart_Handle file_type = ThrowIfError(
      DartUtils::GetDartType("dart:io", "_RandomAccessFileOpsImpl"));
  bool isinstance = false;
  ThrowIfError(Dart_ObjectIsType(file_obj, file_type, &isinstance));
  return isinstance;
}
#endif

// The file pointer has been passed into Dart as an intptr_t and it is safe
// to pull it out of Dart as a 64-bit integer, cast it to an intptr_t and
// from there to a File pointer.
static File* GetFile(Dart_NativeArguments args) {
  File* file;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  DEBUG_ASSERT(IsFile(dart_this));
  Dart_Handle result = Dart_GetNativeInstanceField(
      dart_this, kFileNativeFieldIndex, reinterpret_cast<intptr_t*>(&file));
  ASSERT(!Dart_IsError(result));
  return file;
}

static void SetFile(Dart_Handle dart_this, intptr_t file_pointer) {
  DEBUG_ASSERT(IsFile(dart_this));
  Dart_Handle result = Dart_SetNativeInstanceField(
      dart_this, kFileNativeFieldIndex, file_pointer);
  if (Dart_IsError(result)) {
    Log::PrintErr("SetNativeInstanceField in SetFile() failed\n");
    Dart_PropagateError(result);
  }
}

void FUNCTION_NAME(File_GetPointer)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  // If the file is already closed, GetFile() will return NULL.
  if (file != NULL) {
    // Increment file's reference count. File_GetPointer() should only be called
    // when we are about to send the File* to the IO Service.
    file->Retain();
  }
  intptr_t file_pointer = reinterpret_cast<intptr_t>(file);
  Dart_SetIntegerReturnValue(args, file_pointer);
}

static void ReleaseFile(void* isolate_callback_data,
                        Dart_WeakPersistentHandle handle,
                        void* peer) {
  File* file = reinterpret_cast<File*>(peer);
  file->Release();
}

void FUNCTION_NAME(File_SetPointer)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  intptr_t file_pointer =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  File* file = reinterpret_cast<File*>(file_pointer);
  Dart_WeakPersistentHandle handle = Dart_NewWeakPersistentHandle(
      dart_this, reinterpret_cast<void*>(file), sizeof(*file), ReleaseFile);
  file->SetWeakHandle(handle);
  SetFile(dart_this, file_pointer);
}

void FUNCTION_NAME(File_Open)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t mode = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  File::DartFileOpenMode dart_file_mode =
      static_cast<File::DartFileOpenMode>(mode);
  File::FileOpenMode file_mode = File::DartModeToFileMode(dart_file_mode);
  // Check that the file exists before opening it only for
  // reading. This is to prevent the opening of directories as
  // files. Directories can be opened for reading using the posix
  // 'open' call.
  File* file = File::Open(namespc, filename, file_mode);
  if (file != NULL) {
    Dart_SetIntegerReturnValue(args, reinterpret_cast<intptr_t>(file));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_Exists)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  bool exists = File::Exists(namespc, filename);
  Dart_SetBooleanReturnValue(args, exists);
}

void FUNCTION_NAME(File_Close)(Dart_NativeArguments args) {
  // TODO(zra): The bots are hitting a crash in this function, so we include
  // some checks here that are normally only in a Debug build. When the crash
  // is gone, this can go back to using GetFile and SetFile.
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
#if !defined(PRODUCT)
  if (!IsFile(dart_this)) {
    Dart_PropagateError(DartUtils::NewInternalError(
        "File_Close expects the reciever to be a _RandomAccessFileOpsImpl."));
  }
#endif
  File* file;
  ThrowIfError(Dart_GetNativeInstanceField(dart_this, kFileNativeFieldIndex,
                                           reinterpret_cast<intptr_t*>(&file)));
  if (file == NULL) {
    Dart_SetIntegerReturnValue(args, -1);
    return;
  }
  file->Close();
  file->DeleteWeakHandle(Dart_CurrentIsolate());
  file->Release();

  ThrowIfError(
      Dart_SetNativeInstanceField(dart_this, kFileNativeFieldIndex, 0));
  Dart_SetIntegerReturnValue(args, 0);
}

void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  uint8_t buffer;
  int64_t bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
  if (bytes_read == 1) {
    Dart_SetIntegerReturnValue(args, buffer);
  } else if (bytes_read == 0) {
    Dart_SetIntegerReturnValue(args, -1);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_WriteByte)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  int64_t byte = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &byte)) {
    uint8_t buffer = static_cast<uint8_t>(byte & 0xff);
    bool success = file->WriteFully(reinterpret_cast<void*>(&buffer), 1);
    if (success) {
      Dart_SetIntegerReturnValue(args, 1);
    } else {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
}

void FUNCTION_NAME(File_Read)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  Dart_Handle length_object = Dart_GetNativeArgument(args, 1);
  int64_t length = 0;
  if (DartUtils::GetInt64Value(length_object, &length)) {
    uint8_t* buffer = NULL;
    Dart_Handle external_array = IOBuffer::Allocate(length, &buffer);
    int64_t bytes_read = file->Read(reinterpret_cast<void*>(buffer), length);
    if (bytes_read < 0) {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    } else {
      if (bytes_read < length) {
        const int kNumArgs = 3;
        Dart_Handle dart_args[kNumArgs];
        dart_args[0] = external_array;
        dart_args[1] = Dart_NewInteger(0);
        dart_args[2] = Dart_NewInteger(bytes_read);
        // TODO(sgjesse): Cache the _makeUint8ListView function somewhere.
        Dart_Handle io_lib =
            Dart_LookupLibrary(DartUtils::NewString("dart:io"));
        if (Dart_IsError(io_lib)) {
          Dart_PropagateError(io_lib);
        }
        Dart_Handle array_view =
            Dart_Invoke(io_lib, DartUtils::NewString("_makeUint8ListView"),
                        kNumArgs, dart_args);
        Dart_SetReturnValue(args, array_view);
      } else {
        Dart_SetReturnValue(args, external_array);
      }
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
}

void FUNCTION_NAME(File_ReadInto)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  // start and end arguments are checked in Dart code to be
  // integers and have the property that end <=
  // list.length. Therefore, it is safe to extract their value as
  // intptr_t.
  intptr_t start = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t end = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  intptr_t length = end - start;
  intptr_t array_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &array_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT(end <= array_len);
  uint8_t* buffer = Dart_ScopeAllocate(length);
  int64_t bytes_read = file->Read(reinterpret_cast<void*>(buffer), length);
  if (bytes_read >= 0) {
    result = Dart_ListSetAsBytes(buffer_obj, start, buffer, bytes_read);
    if (Dart_IsError(result)) {
      Dart_SetReturnValue(args, result);
    } else {
      Dart_SetIntegerReturnValue(args, bytes_read);
    }
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_WriteFrom)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);

  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);

  // Offset and length arguments are checked in Dart code to be
  // integers and have the property that (offset + length) <=
  // list.length. Therefore, it is safe to extract their value as
  // intptr_t.
  intptr_t start = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t end = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));

  // The buffer object passed in has to be an Int8List or Uint8List object.
  // Acquire a direct pointer to the data area of the buffer object.
  Dart_TypedData_Type type;
  intptr_t length = end - start;
  intptr_t buffer_len = 0;
  void* buffer = NULL;
  Dart_Handle result =
      Dart_TypedDataAcquireData(buffer_obj, &type, &buffer, &buffer_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  ASSERT(type == Dart_TypedData_kUint8 || type == Dart_TypedData_kInt8);
  ASSERT(end <= buffer_len);
  ASSERT(buffer != NULL);

  // Write all the data out into the file.
  char* byte_buffer = reinterpret_cast<char*>(buffer);
  bool success = file->WriteFully(byte_buffer + start, length);

  // Release the direct pointer acquired above.
  result = Dart_TypedDataReleaseData(buffer_obj);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  if (!success) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  } else {
    Dart_SetReturnValue(args, Dart_Null());
  }
}

void FUNCTION_NAME(File_Position)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  intptr_t return_value = file->Position();
  if (return_value >= 0) {
    Dart_SetIntegerReturnValue(args, return_value);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_SetPosition)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  int64_t position = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &position)) {
    if (file->SetPosition(position)) {
      Dart_SetBooleanReturnValue(args, true);
    } else {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
}

void FUNCTION_NAME(File_Truncate)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  int64_t length = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &length)) {
    if (file->Truncate(length)) {
      Dart_SetBooleanReturnValue(args, true);
    } else {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
}

void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  int64_t return_value = file->Length();
  if (return_value >= 0) {
    Dart_SetIntegerReturnValue(args, return_value);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_LengthFromPath)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* path = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t return_value = File::LengthFromPath(namespc, path);
  if (return_value >= 0) {
    Dart_SetIntegerReturnValue(args, return_value);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_LastModified)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* name = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t return_value = File::LastModified(namespc, name);
  if (return_value >= 0) {
    Dart_SetIntegerReturnValue(args, return_value * kMillisecondsPerSecond);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_SetLastModified)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* name = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t millis;
  if (!DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &millis)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "The second argument must be a 64-bit int."));
  }
  if (!File::SetLastModified(namespc, name, millis)) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_LastAccessed)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* name = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t return_value = File::LastAccessed(namespc, name);
  if (return_value >= 0) {
    Dart_SetIntegerReturnValue(args, return_value * kMillisecondsPerSecond);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_SetLastAccessed)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* name = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int64_t millis;
  if (!DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &millis)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "The second argument must be a 64-bit int."));
  }
  if (!File::SetLastAccessed(namespc, name, millis)) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  if (file->Flush()) {
    Dart_SetBooleanReturnValue(args, true);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_Lock)(Dart_NativeArguments args) {
  File* file = GetFile(args);
  ASSERT(file != NULL);
  int64_t lock;
  int64_t start;
  int64_t end;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &lock) &&
      DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &start) &&
      DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 3), &end)) {
    if ((lock >= File::kLockMin) && (lock <= File::kLockMax) && (start >= 0) &&
        (end == -1 || end > start)) {
      if (file->Lock(static_cast<File::LockType>(lock), start, end)) {
        Dart_SetBooleanReturnValue(args, true);
      } else {
        Dart_SetReturnValue(args, DartUtils::NewDartOSError());
      }
      return;
    }
  }
  OSError os_error(-1, "Invalid argument", OSError::kUnknown);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
}

void FUNCTION_NAME(File_Create)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* str = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  bool result = File::Create(namespc, str);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_CreateLink)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  if (Dart_IsString(Dart_GetNativeArgument(args, 1)) &&
      Dart_IsString(Dart_GetNativeArgument(args, 2))) {
    const char* name =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    const char* target =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
    if (!File::CreateLink(namespc, name, target)) {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    }
  } else {
    Dart_Handle err =
        DartUtils::NewDartArgumentError("Non-string argument to Link.create");
    Dart_SetReturnValue(args, err);
  }
}

void FUNCTION_NAME(File_LinkTarget)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  if (Dart_IsString(Dart_GetNativeArgument(args, 1))) {
    const char* name =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    const char* target = File::LinkTarget(namespc, name);
    if (target == NULL) {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    } else {
      Dart_SetReturnValue(args, DartUtils::NewString(target));
    }
  } else {
    Dart_Handle err =
        DartUtils::NewDartArgumentError("Non-string argument to Link.target");
    Dart_SetReturnValue(args, err);
  }
}

void FUNCTION_NAME(File_Delete)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* str = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  bool result = File::Delete(namespc, str);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_DeleteLink)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* str = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  bool result = File::DeleteLink(namespc, str);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_Rename)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* old_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  const char* new_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
  bool result = File::Rename(namespc, old_path, new_path);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_RenameLink)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* old_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  const char* new_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
  bool result = File::RenameLink(namespc, old_path, new_path);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_Copy)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* old_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  const char* new_path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
  bool result = File::Copy(namespc, old_path, new_path);
  if (result) {
    Dart_SetBooleanReturnValue(args, result);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_ResolveSymbolicLinks)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  const char* str = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  const char* path = File::GetCanonicalPath(namespc, str);
  if (path != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(path));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(File_OpenStdio)(Dart_NativeArguments args) {
  int64_t fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  ASSERT((fd == STDIN_FILENO) || (fd == STDOUT_FILENO) ||
         (fd == STDERR_FILENO));
  File* file = File::OpenStdio(static_cast<int>(fd));
  Dart_SetIntegerReturnValue(args, reinterpret_cast<intptr_t>(file));
}

void FUNCTION_NAME(File_GetStdioHandleType)(Dart_NativeArguments args) {
  int64_t fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  ASSERT((fd == STDIN_FILENO) || (fd == STDOUT_FILENO) ||
         (fd == STDERR_FILENO));
  File::StdioHandleType type = File::GetStdioHandleType(static_cast<int>(fd));
  Dart_SetIntegerReturnValue(args, type);
}

void FUNCTION_NAME(File_GetType)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  if (Dart_IsString(Dart_GetNativeArgument(args, 1)) &&
      Dart_IsBoolean(Dart_GetNativeArgument(args, 2))) {
    const char* str =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    bool follow_links =
        DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
    File::Type type = File::GetType(namespc, str, follow_links);
    Dart_SetIntegerReturnValue(args, static_cast<int>(type));
  } else {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to FileSystemEntity.type");
    Dart_SetReturnValue(args, err);
  }
}

void FUNCTION_NAME(File_Stat)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  if (Dart_IsString(Dart_GetNativeArgument(args, 1))) {
    const char* path =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));

    int64_t stat_data[File::kStatSize];
    File::Stat(namespc, path, stat_data);
    if (stat_data[File::kType] == File::kDoesNotExist) {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    } else {
      Dart_Handle returned_data =
          Dart_NewTypedData(Dart_TypedData_kInt64, File::kStatSize);
      if (Dart_IsError(returned_data)) {
        Dart_PropagateError(returned_data);
      }
      Dart_TypedData_Type data_type_unused;
      void* data_location;
      intptr_t data_length_unused;
      Dart_Handle status =
          Dart_TypedDataAcquireData(returned_data, &data_type_unused,
                                    &data_location, &data_length_unused);
      if (Dart_IsError(status)) {
        Dart_PropagateError(status);
      }
      memmove(data_location, stat_data, File::kStatSize * sizeof(int64_t));
      status = Dart_TypedDataReleaseData(returned_data);
      if (Dart_IsError(status)) {
        Dart_PropagateError(status);
      }
      Dart_SetReturnValue(args, returned_data);
    }
  } else {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to FileSystemEntity.stat");
    Dart_SetReturnValue(args, err);
  }
}

void FUNCTION_NAME(File_AreIdentical)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  if (Dart_IsString(Dart_GetNativeArgument(args, 1)) &&
      Dart_IsString(Dart_GetNativeArgument(args, 2))) {
    const char* path_1 =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    const char* path_2 =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
    File::Identical result = File::AreIdentical(namespc, path_1, path_2);
    if (result == File::kError) {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    } else {
      Dart_SetBooleanReturnValue(args, result == File::kIdentical);
    }
  } else {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to FileSystemEntity.identical");
    Dart_SetReturnValue(args, err);
  }
}

#define IS_SEPARATOR(c) ((c) == '/' || (c) == 0)

// Checks that if we increment this index forward, we'll still have enough space
// for a null terminator within PATH_MAX bytes.
#define CHECK_CAN_INCREMENT(i)                                                 \
  if ((i) + 1 >= outlen) {                                                     \
    return -1;                                                                 \
  }

intptr_t File::CleanUnixPath(const char* in, char* out, intptr_t outlen) {
  if (in[0] == 0) {
    snprintf(out, outlen, ".");
    return 1;
  }

  const bool rooted = (in[0] == '/');
  intptr_t in_index = 0;   // Index of the next byte to read.
  intptr_t out_index = 0;  // Index of the next byte to write.

  if (rooted) {
    out[out_index++] = '/';
    in_index++;
  }
  // The output index at which '..' cannot be cleaned further.
  intptr_t dotdot = out_index;

  while (in[in_index] != 0) {
    if (in[in_index] == '/') {
      // 1. Reduce multiple slashes to a single slash.
      CHECK_CAN_INCREMENT(in_index);
      in_index++;
    } else if ((in[in_index] == '.') && IS_SEPARATOR(in[in_index + 1])) {
      // 2. Eliminate . path name elements (the current directory).
      CHECK_CAN_INCREMENT(in_index);
      in_index++;
    } else if ((in[in_index] == '.') && (in[in_index + 1] == '.') &&
               IS_SEPARATOR(in[in_index + 2])) {
      CHECK_CAN_INCREMENT(in_index + 1);
      in_index += 2;
      if (out_index > dotdot) {
        // 3. Eliminate .. path elements (the parent directory) and the element
        // that precedes them.
        out_index--;
        while ((out_index > dotdot) && (out[out_index] != '/')) {
          out_index--;
        }
      } else if (rooted) {
        // 4. Eliminate .. elements that begin a rooted path, that is, replace
        // /.. by / at the beginning of a path.
        continue;
      } else if (!rooted) {
        if (out_index > 0) {
          out[out_index++] = '/';
        }
        // 5. Leave intact .. elements that begin a non-rooted path.
        out[out_index++] = '.';
        out[out_index++] = '.';
        dotdot = out_index;
      }
    } else {
      if ((rooted && out_index != 1) || (!rooted && out_index != 0)) {
        // Add '/' before normal path component, for non-root components.
        out[out_index++] = '/';
      }

      while (!IS_SEPARATOR(in[in_index])) {
        CHECK_CAN_INCREMENT(in_index);
        out[out_index++] = in[in_index++];
      }
    }
  }

  if (out_index == 0) {
    snprintf(out, outlen, ".");
    return 1;
  }

  // Append null character.
  out[out_index] = 0;
  return out_index;
}

static int64_t CObjectInt32OrInt64ToInt64(CObject* cobject) {
  ASSERT(cobject->IsInt32OrInt64());
  int64_t result;
  if (cobject->IsInt32()) {
    CObjectInt32 value(cobject);
    result = value.Value();
  } else {
    CObjectInt64 value(cobject);
    result = value.Value();
  }
  return result;
}

static File* CObjectToFilePointer(CObject* cobject) {
  CObjectIntptr value(cobject);
  return reinterpret_cast<File*>(value.Value());
}

static Namespace* CObjectToNamespacePointer(CObject* cobject) {
  CObjectIntptr value(cobject);
  return reinterpret_cast<Namespace*>(value.Value());
}

CObject* File::ExistsRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filename(request[1]);
  return CObject::Bool(File::Exists(namespc, filename.CString()));
}

CObject* File::CreateRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filename(request[1]);
  return File::Create(namespc, filename.CString()) ? CObject::True()
                                                   : CObject::NewOSError();
}

CObject* File::OpenRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 3) || !request[1]->IsString() ||
      !request[2]->IsInt32()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filename(request[1]);
  CObjectInt32 mode(request[2]);
  File::DartFileOpenMode dart_file_mode =
      static_cast<File::DartFileOpenMode>(mode.Value());
  File::FileOpenMode file_mode = File::DartModeToFileMode(dart_file_mode);
  File* file = File::Open(namespc, filename.CString(), file_mode);
  if (file == NULL) {
    return CObject::NewOSError();
  }
  return new CObjectIntptr(
      CObject::NewIntptr(reinterpret_cast<intptr_t>(file)));
}

CObject* File::DeleteRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::False();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::False();
  }
  CObjectString filename(request[1]);
  return File::Delete(namespc, filename.CString()) ? CObject::True()
                                                   : CObject::NewOSError();
}

CObject* File::RenameRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 3) || !request[1]->IsString() ||
      !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString old_path(request[1]);
  CObjectString new_path(request[2]);
  return File::Rename(namespc, old_path.CString(), new_path.CString())
             ? CObject::True()
             : CObject::NewOSError();
}

CObject* File::CopyRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 3) || !request[1]->IsString() ||
      !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString old_path(request[1]);
  CObjectString new_path(request[2]);
  return File::Copy(namespc, old_path.CString(), new_path.CString())
             ? CObject::True()
             : CObject::NewOSError();
}

CObject* File::ResolveSymbolicLinksRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filename(request[1]);
  const char* result = File::GetCanonicalPath(namespc, filename.CString());
  if (result == NULL) {
    return CObject::NewOSError();
  }
  return new CObjectString(CObject::NewString(result));
}

CObject* File::CloseRequest(const CObjectArray& request) {
  if ((request.Length() != 1) || !request[0]->IsIntptr()) {
    return new CObjectIntptr(CObject::NewIntptr(-1));
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  // We have retained a reference to the file here. Therefore the file's
  // destructor can't be running. Since no further requests are dispatched by
  // the Dart code after an async close call, this Close() can't be racing
  // with any other call on the file. We don't do an extra Release(), and we
  // don't delete the weak persistent handle. The file is closed here, but the
  // memory will be cleaned up when the finalizer runs.
  ASSERT(!file->IsClosed());
  file->Close();
  return new CObjectIntptr(CObject::NewIntptr(0));
}

CObject* File::PositionRequest(const CObjectArray& request) {
  if ((request.Length() != 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const intptr_t return_value = file->Position();
  if (return_value < 0) {
    return CObject::NewOSError();
  }
  return new CObjectIntptr(CObject::NewIntptr(return_value));
}

CObject* File::SetPositionRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 2) || !request[1]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t position = CObjectInt32OrInt64ToInt64(request[1]);
  return file->SetPosition(position) ? CObject::True() : CObject::NewOSError();
}

CObject* File::TruncateRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 2) || !request[1]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t length = CObjectInt32OrInt64ToInt64(request[1]);
  if (file->Truncate(length)) {
    return CObject::True();
  }
  return CObject::NewOSError();
}

CObject* File::LengthRequest(const CObjectArray& request) {
  if ((request.Length() != 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t return_value = file->Length();
  if (return_value < 0) {
    return CObject::NewOSError();
  }
  return new CObjectInt64(CObject::NewInt64(return_value));
}

CObject* File::LengthFromPathRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filepath(request[1]);
  const int64_t return_value =
      File::LengthFromPath(namespc, filepath.CString());
  if (return_value < 0) {
    return CObject::NewOSError();
  }
  return new CObjectInt64(CObject::NewInt64(return_value));
}

CObject* File::LastAccessedRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filepath(request[1]);
  const int64_t return_value = File::LastAccessed(namespc, filepath.CString());
  if (return_value < 0) {
    return CObject::NewOSError();
  }
  return new CObjectIntptr(
      CObject::NewInt64(return_value * kMillisecondsPerSecond));
}

CObject* File::SetLastAccessedRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 3) || !request[1]->IsString() ||
      !request[2]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filepath(request[1]);
  const int64_t millis = CObjectInt32OrInt64ToInt64(request[2]);
  return File::SetLastAccessed(namespc, filepath.CString(), millis)
             ? CObject::Null()
             : CObject::NewOSError();
}

CObject* File::LastModifiedRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filepath(request[1]);
  const int64_t return_value = File::LastModified(namespc, filepath.CString());
  if (return_value < 0) {
    return CObject::NewOSError();
  }
  return new CObjectIntptr(
      CObject::NewInt64(return_value * kMillisecondsPerSecond));
}

CObject* File::SetLastModifiedRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 3) || !request[1]->IsString() ||
      !request[2]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString filepath(request[1]);
  const int64_t millis = CObjectInt32OrInt64ToInt64(request[2]);
  return File::SetLastModified(namespc, filepath.CString(), millis)
             ? CObject::Null()
             : CObject::NewOSError();
}

CObject* File::FlushRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  return file->Flush() ? CObject::True() : CObject::NewOSError();
}

CObject* File::ReadByteRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  uint8_t buffer;
  const int64_t bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
  if (bytes_read < 0) {
    return CObject::NewOSError();
  }
  if (bytes_read == 0) {
    return new CObjectIntptr(CObject::NewIntptr(-1));
  }
  return new CObjectIntptr(CObject::NewIntptr(buffer));
}

CObject* File::WriteByteRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 2) || !request[1]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t byte = CObjectInt32OrInt64ToInt64(request[1]);
  uint8_t buffer = static_cast<uint8_t>(byte & 0xff);
  return file->WriteFully(reinterpret_cast<void*>(&buffer), 1)
             ? new CObjectInt64(CObject::NewInt64(1))
             : CObject::NewOSError();
}

CObject* File::ReadRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 2) || !request[1]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t length = CObjectInt32OrInt64ToInt64(request[1]);
  Dart_CObject* io_buffer = CObject::NewIOBuffer(length);
  ASSERT(io_buffer != NULL);
  uint8_t* data = io_buffer->value.as_external_typed_data.data;
  const int64_t bytes_read = file->Read(data, length);
  if (bytes_read < 0) {
    CObject::FreeIOBufferData(io_buffer);
    return CObject::NewOSError();
  }
  CObjectExternalUint8Array* external_array =
      new CObjectExternalUint8Array(io_buffer);
  external_array->SetLength(bytes_read);
  CObjectArray* result = new CObjectArray(CObject::NewArray(2));
  result->SetAt(0, new CObjectIntptr(CObject::NewInt32(0)));
  result->SetAt(1, external_array);
  return result;
}

CObject* File::ReadIntoRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 2) || !request[1]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t length = CObjectInt32OrInt64ToInt64(request[1]);
  Dart_CObject* io_buffer = CObject::NewIOBuffer(length);
  ASSERT(io_buffer != NULL);
  uint8_t* data = io_buffer->value.as_external_typed_data.data;
  const int64_t bytes_read = file->Read(data, length);
  if (bytes_read < 0) {
    CObject::FreeIOBufferData(io_buffer);
    return CObject::NewOSError();
  }
  CObjectExternalUint8Array* external_array =
      new CObjectExternalUint8Array(io_buffer);
  external_array->SetLength(bytes_read);
  CObjectArray* result = new CObjectArray(CObject::NewArray(3));
  result->SetAt(0, new CObjectIntptr(CObject::NewInt32(0)));
  result->SetAt(1, new CObjectInt64(CObject::NewInt64(bytes_read)));
  result->SetAt(2, external_array);
  return result;
}

static int SizeInBytes(Dart_TypedData_Type type) {
  switch (type) {
    case Dart_TypedData_kInt8:
    case Dart_TypedData_kUint8:
    case Dart_TypedData_kUint8Clamped:
      return 1;
    case Dart_TypedData_kInt16:
    case Dart_TypedData_kUint16:
      return 2;
    case Dart_TypedData_kInt32:
    case Dart_TypedData_kUint32:
    case Dart_TypedData_kFloat32:
      return 4;
    case Dart_TypedData_kInt64:
    case Dart_TypedData_kUint64:
    case Dart_TypedData_kFloat64:
      return 8;
    default:
      break;
  }
  UNREACHABLE();
  return -1;
}

CObject* File::WriteFromRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 4) ||
      (!request[1]->IsTypedData() && !request[1]->IsArray()) ||
      !request[2]->IsInt32OrInt64() || !request[3]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  int64_t start = CObjectInt32OrInt64ToInt64(request[2]);
  int64_t end = CObjectInt32OrInt64ToInt64(request[3]);
  int64_t length = end - start;
  uint8_t* buffer_start;
  if (request[1]->IsTypedData()) {
    CObjectTypedData typed_data(request[1]);
    start = start * SizeInBytes(typed_data.Type());
    length = length * SizeInBytes(typed_data.Type());
    buffer_start = typed_data.Buffer() + start;
  } else {
    CObjectArray array(request[1]);
    buffer_start = Dart_ScopeAllocate(length);
    for (int i = 0; i < length; i++) {
      if (array[i + start]->IsInt32OrInt64()) {
        int64_t value = CObjectInt32OrInt64ToInt64(array[i + start]);
        buffer_start[i] = static_cast<uint8_t>(value & 0xFF);
      } else {
        // Unsupported type.
        return CObject::IllegalArgumentError();
      }
    }
    start = 0;
  }
  return file->WriteFully(reinterpret_cast<void*>(buffer_start), length)
             ? new CObjectInt64(CObject::NewInt64(length))
             : CObject::NewOSError();
}

CObject* File::CreateLinkRequest(const CObjectArray& request) {
  if ((request.Length() != 3) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString() || !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString link_name(request[1]);
  CObjectString target_name(request[2]);
  return File::CreateLink(namespc, link_name.CString(), target_name.CString())
             ? CObject::True()
             : CObject::NewOSError();
}

CObject* File::DeleteLinkRequest(const CObjectArray& request) {
  if ((request.Length() != 2) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString link_path(request[1]);
  return File::DeleteLink(namespc, link_path.CString()) ? CObject::True()
                                                        : CObject::NewOSError();
}

CObject* File::RenameLinkRequest(const CObjectArray& request) {
  if ((request.Length() != 3) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString() || !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString old_path(request[1]);
  CObjectString new_path(request[2]);
  return File::RenameLink(namespc, old_path.CString(), new_path.CString())
             ? CObject::True()
             : CObject::NewOSError();
}

CObject* File::LinkTargetRequest(const CObjectArray& request) {
  if ((request.Length() != 2) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString link_path(request[1]);
  const char* target = File::LinkTarget(namespc, link_path.CString());
  if (target == NULL) {
    return CObject::NewOSError();
  }
  return new CObjectString(CObject::NewString(target));
}

CObject* File::TypeRequest(const CObjectArray& request) {
  if ((request.Length() != 3) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString() || !request[2]->IsBool()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString path(request[1]);
  CObjectBool follow_links(request[2]);
  File::Type type =
      File::GetType(namespc, path.CString(), follow_links.Value());
  return new CObjectInt32(CObject::NewInt32(type));
}

CObject* File::IdenticalRequest(const CObjectArray& request) {
  if ((request.Length() != 3) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if (!request[1]->IsString() || !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString path1(request[1]);
  CObjectString path2(request[2]);
  File::Identical result =
      File::AreIdentical(namespc, path1.CString(), path2.CString());
  if (result == File::kError) {
    return CObject::NewOSError();
  }
  return (result == File::kIdentical) ? CObject::True() : CObject::False();
}

CObject* File::StatRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  Namespace* namespc = CObjectToNamespacePointer(request[0]);
  RefCntReleaseScope<Namespace> rs(namespc);
  if ((request.Length() != 2) || !request[1]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  int64_t data[File::kStatSize];
  CObjectString path(request[1]);
  File::Stat(namespc, path.CString(), data);
  if (data[File::kType] == File::kDoesNotExist) {
    return CObject::NewOSError();
  }
  CObjectArray* result = new CObjectArray(CObject::NewArray(File::kStatSize));
  for (int i = 0; i < File::kStatSize; ++i) {
    result->SetAt(i, new CObjectInt64(CObject::NewInt64(data[i])));
  }
  CObjectArray* wrapper = new CObjectArray(CObject::NewArray(2));
  wrapper->SetAt(0, new CObjectInt32(CObject::NewInt32(CObject::kSuccess)));
  wrapper->SetAt(1, result);
  return wrapper;
}

CObject* File::LockRequest(const CObjectArray& request) {
  if ((request.Length() < 1) || !request[0]->IsIntptr()) {
    return CObject::IllegalArgumentError();
  }
  File* file = CObjectToFilePointer(request[0]);
  RefCntReleaseScope<File> rs(file);
  if ((request.Length() != 4) || !request[1]->IsInt32OrInt64() ||
      !request[2]->IsInt32OrInt64() || !request[3]->IsInt32OrInt64()) {
    return CObject::IllegalArgumentError();
  }
  if (file->IsClosed()) {
    return CObject::FileClosedError();
  }
  const int64_t lock = CObjectInt32OrInt64ToInt64(request[1]);
  const int64_t start = CObjectInt32OrInt64ToInt64(request[2]);
  const int64_t end = CObjectInt32OrInt64ToInt64(request[3]);
  return file->Lock(static_cast<File::LockType>(lock), start, end)
             ? CObject::True()
             : CObject::NewOSError();
}

}  // namespace bin
}  // namespace dart
