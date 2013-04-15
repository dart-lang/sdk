// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_api.h"

static const int kMSPerSecond = 1000;


// Forward declaration.
static void FileService(Dart_Port, Dart_Port, Dart_CObject*);

NativeService File::file_service_("FileService", FileService, 16);


// The file pointer has been passed into Dart as an intptr_t and it is safe
// to pull it out of Dart as a 64-bit integer, cast it to an intptr_t and
// from there to a File pointer.
static File* GetFilePointer(Dart_Handle handle) {
  intptr_t value = DartUtils::GetIntptrValue(handle);
  return reinterpret_cast<File*>(value);
}


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


File::FileOpenMode File::DartModeToFileMode(DartFileOpenMode mode) {
  ASSERT(mode == File::kDartRead ||
         mode == File::kDartWrite ||
         mode == File::kDartAppend);
  if (mode == File::kDartWrite) {
    return File::kWriteTruncate;
  }
  if (mode == File::kDartAppend) {
    return File::kWrite;
  }
  return File::kRead;
}


void FUNCTION_NAME(File_Open)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* filename =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  int64_t mode = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  File::DartFileOpenMode dart_file_mode =
      static_cast<File::DartFileOpenMode>(mode);
  File::FileOpenMode file_mode = File::DartModeToFileMode(dart_file_mode);
  // Check that the file exists before opening it only for
  // reading. This is to prevent the opening of directories as
  // files. Directories can be opened for reading using the posix
  // 'open' call.
  File* file = NULL;
  file = File::Open(filename, file_mode);
  if (file != NULL) {
    Dart_SetReturnValue(args,
                        Dart_NewInteger(reinterpret_cast<intptr_t>(file)));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
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
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  delete file;
  Dart_SetReturnValue(args, Dart_NewInteger(0));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  uint8_t buffer;
  int64_t bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
  if (bytes_read == 1) {
    Dart_SetReturnValue(args, Dart_NewInteger(buffer));
  } else if (bytes_read == 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(-1));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  int64_t byte = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &byte)) {
    uint8_t buffer = static_cast<uint8_t>(byte & 0xff);
    int64_t bytes_written = file->Write(reinterpret_cast<void*>(&buffer), 1);
    if (bytes_written >= 0) {
      Dart_SetReturnValue(args, Dart_NewInteger(bytes_written));
    } else {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Read)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  Dart_Handle length_object = Dart_GetNativeArgument(args, 1);
  int64_t length = 0;
  if (DartUtils::GetInt64Value(length_object, &length)) {
    uint8_t* buffer = NULL;
    Dart_Handle external_array = IOBuffer::Allocate(length, &buffer);
    int64_t bytes_read = file->Read(reinterpret_cast<void*>(buffer), length);
    if (bytes_read < 0) {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
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
        if (Dart_IsError(io_lib)) Dart_PropagateError(io_lib);
        Dart_Handle array_view =
            Dart_Invoke(io_lib,
                        DartUtils::NewString("_makeUint8ListView"),
                        kNumArgs,
                        dart_args);
        if (Dart_IsError(array_view)) Dart_PropagateError(array_view);
        Dart_SetReturnValue(args, array_view);
      } else {
        Dart_SetReturnValue(args, external_array);
      }
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadInto)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  // start and end arguments are checked in Dart code to be
  // integers and have the property that end <=
  // list.length. Therefore, it is safe to extract their value as
  // intptr_t.
  intptr_t start =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t end =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  intptr_t length = end - start;
  intptr_t array_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &array_len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  ASSERT(end <= array_len);
  uint8_t* buffer = new uint8_t[length];
  int64_t bytes_read = file->Read(reinterpret_cast<void*>(buffer), length);
  if (bytes_read >= 0) {
    result = Dart_ListSetAsBytes(buffer_obj, start, buffer, bytes_read);
    if (Dart_IsError(result)) {
      delete[] buffer;
      Dart_PropagateError(result);
    }
    Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  delete[] buffer;
  Dart_ExitScope();
}


void FUNCTION_NAME(File_WriteFrom)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  // Offset and length arguments are checked in Dart code to be
  // integers and have the property that (offset + length) <=
  // list.length. Therefore, it is safe to extract their value as
  // intptr_t.
  intptr_t start =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t end =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  intptr_t length = end - start;
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  ASSERT(end <= buffer_len);
  uint8_t* buffer = new uint8_t[length];
  result = Dart_ListGetAsBytes(buffer_obj, start, buffer, length);
  if (Dart_IsError(result)) {
    delete[] buffer;
    Dart_PropagateError(result);
  }
  int64_t bytes_written = file->Write(reinterpret_cast<void*>(buffer), length);
  if (bytes_written != length) {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  delete[] buffer;
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Position)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  intptr_t return_value = file->Position();
  if (return_value >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_SetPosition)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  int64_t position = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &position)) {
    if (file->SetPosition(position)) {
      Dart_SetReturnValue(args, Dart_True());
    } else {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Truncate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  int64_t length = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &length)) {
    if (file->Truncate(length)) {
      Dart_SetReturnValue(args, Dart_True());
    } else {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  intptr_t return_value = file->Length();
  if (return_value >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_LengthFromPath)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* path =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  intptr_t return_value = File::LengthFromPath(path);
  if (return_value >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_LastModified)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* name =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  int64_t return_value = File::LastModified(name);
  if (return_value >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(return_value * kMSPerSecond));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  Dart_EnterScope();
  File* file = GetFilePointer(Dart_GetNativeArgument(args, 0));
  ASSERT(file != NULL);
  if (file->Flush()) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Create)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool result = File::Create(str);
  if (result) {
    Dart_SetReturnValue(args, Dart_NewBoolean(result));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_CreateLink)(Dart_NativeArguments args) {
  Dart_EnterScope();
  if (Dart_IsString(Dart_GetNativeArgument(args, 0)) &&
      Dart_IsString(Dart_GetNativeArgument(args, 1))) {
    const char* name =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
    const char* target =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    if (!File::CreateLink(name, target)) {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    }
  } else  {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to Link.create");
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_LinkTarget)(Dart_NativeArguments args) {
  Dart_EnterScope();
  if (Dart_IsString(Dart_GetNativeArgument(args, 0))) {
    const char* name =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
    char* target = File::LinkTarget(name);
    if (target == NULL) {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    } else {
      Dart_SetReturnValue(args, DartUtils::NewString(target));
      free(target);
    }
  } else {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to Link.target");
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Delete)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool result = File::Delete(str);
  if (result) {
    Dart_SetReturnValue(args, Dart_NewBoolean(result));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_DeleteLink)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  bool result = File::DeleteLink(str);
  if (result) {
    Dart_SetReturnValue(args, Dart_NewBoolean(result));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Directory)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  char* str_copy = strdup(str);
  char* path = File::GetContainingDirectory(str_copy);
  free(str_copy);
  if (path != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(path));
    free(path);
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_FullPath)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  char* path = File::GetCanonicalPath(str);
  if (path != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(path));
    free(path);
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_OpenStdio)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int64_t fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  ASSERT(fd == 0 || fd == 1 || fd == 2);
  File* file = File::OpenStdio(static_cast<int>(fd));
  Dart_SetReturnValue(args, Dart_NewInteger(reinterpret_cast<intptr_t>(file)));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_GetStdioHandleType)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int64_t fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  ASSERT(fd == 0 || fd == 1 || fd == 2);
  File::StdioHandleType type = File::GetStdioHandleType(static_cast<int>(fd));
  Dart_SetReturnValue(args, Dart_NewInteger(type));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_GetType)(Dart_NativeArguments args) {
  Dart_EnterScope();
  if (Dart_IsString(Dart_GetNativeArgument(args, 0)) &&
      Dart_IsBoolean(Dart_GetNativeArgument(args, 1))) {
    const char* str =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
    bool follow_links =
        DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
    File::Type type = File::GetType(str, follow_links);
    Dart_SetReturnValue(args, Dart_NewInteger(static_cast<int>(type)));
  } else  {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to FileSystemEntity.type");
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_AreIdentical)(Dart_NativeArguments args) {
  Dart_EnterScope();
  if (Dart_IsString(Dart_GetNativeArgument(args, 0)) &&
      Dart_IsString(Dart_GetNativeArgument(args, 1))) {
    const char* path_1 =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
    const char* path_2 =
        DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
    File::Identical result = File::AreIdentical(path_1, path_2);
    if (result == File::kError) {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    } else {
      Dart_SetReturnValue(args, Dart_NewBoolean(result == File::kIdentical));
    }
  } else  {
    Dart_Handle err = DartUtils::NewDartArgumentError(
        "Non-string argument to FileSystemEntity.identical");
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
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


File* CObjectToFilePointer(CObject* cobject) {
  CObjectIntptr value(cobject);
  return reinterpret_cast<File*>(value.Value());
}


static CObject* FileExistsRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    bool result = File::Exists(filename.CString());
    return CObject::Bool(result);
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileCreateRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    bool result = File::Create(filename.CString());
    if (result) {
      return CObject::True();
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}

static CObject* FileOpenRequest(const CObjectArray& request) {
  File* file = NULL;
  if (request.Length() == 3 &&
      request[1]->IsString() &&
      request[2]->IsInt32()) {
    CObjectString filename(request[1]);
    CObjectInt32 mode(request[2]);
    File::DartFileOpenMode dart_file_mode =
        static_cast<File::DartFileOpenMode>(mode.Value());
    File::FileOpenMode file_mode = File::DartModeToFileMode(dart_file_mode);
    file = File::Open(filename.CString(), file_mode);
    if (file != NULL) {
      return new CObjectIntptr(
          CObject::NewIntptr(reinterpret_cast<intptr_t>(file)));
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileDeleteRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    bool result = File::Delete(filename.CString());
    if (result) {
      return CObject::True();
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::False();
}


static CObject* FileFullPathRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    char* result = File::GetCanonicalPath(filename.CString());
    if (result != NULL) {
      CObject* path = new CObjectString(CObject::NewString(result));
      free(result);
      return path;
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileDirectoryRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    char* str_copy = strdup(filename.CString());
    char* path = File::GetContainingDirectory(str_copy);
    free(str_copy);
    if (path != NULL) {
      CObject* result = new CObjectString(CObject::NewString(path));
      free(path);
      return result;
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::Null();
}


static CObject* FileCloseRequest(const CObjectArray& request) {
  intptr_t return_value = -1;
  if (request.Length() == 2 && request[1]->IsIntptr()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    delete file;
    return_value = 0;
  }
  return new CObjectIntptr(CObject::NewIntptr(return_value));
}


static CObject* FilePositionRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsIntptr()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      intptr_t return_value = file->Position();
      if (return_value >= 0) {
        return new CObjectIntptr(CObject::NewIntptr(return_value));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileSetPositionRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t position = CObjectInt32OrInt64ToInt64(request[2]);
      if (file->SetPosition(position)) {
        return CObject::True();
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileTruncateRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t length = CObjectInt32OrInt64ToInt64(request[2]);
      if (file->Truncate(length)) {
        return CObject::True();
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileLengthRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsIntptr()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      intptr_t return_value = file->Length();
      if (return_value >= 0) {
        return new CObjectIntptr(CObject::NewIntptr(return_value));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileLengthFromPathRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filepath(request[1]);
    intptr_t return_value = File::LengthFromPath(filepath.CString());
    if (return_value >= 0) {
      return new CObjectIntptr(CObject::NewIntptr(return_value));
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileLastModifiedRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filepath(request[1]);
    int64_t return_value = File::LastModified(filepath.CString());
    if (return_value >= 0) {
      return new CObjectIntptr(CObject::NewInt64(return_value * kMSPerSecond));
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileFlushRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsIntptr()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      if (file->Flush()) {
        return CObject::True();
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileReadByteRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsIntptr()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      uint8_t buffer;
      int64_t bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
      if (bytes_read > 0) {
        return new CObjectIntptr(CObject::NewIntptr(buffer));
      } else if (bytes_read == 0) {
        return new CObjectIntptr(CObject::NewIntptr(-1));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileWriteByteRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t byte = CObjectInt32OrInt64ToInt64(request[2]);
      uint8_t buffer = static_cast<uint8_t>(byte & 0xff);
      int64_t bytes_written = file->Write(reinterpret_cast<void*>(&buffer), 1);
      if (bytes_written > 0) {
        return new CObjectInt64(CObject::NewInt64(bytes_written));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileReadRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t length = CObjectInt32OrInt64ToInt64(request[2]);
      Dart_CObject* io_buffer = CObject::NewIOBuffer(length);
      uint8_t* data = io_buffer->value.as_external_typed_data.data;
      int64_t bytes_read = file->Read(data, length);
      if (bytes_read >= 0) {
        CObjectExternalUint8Array* external_array =
            new CObjectExternalUint8Array(io_buffer);
        external_array->SetLength(bytes_read);
        CObjectArray* result = new CObjectArray(CObject::NewArray(2));
        result->SetAt(0, new CObjectIntptr(CObject::NewInt32(0)));
        result->SetAt(1, external_array);
        return result;
      } else {
        CObject::FreeIOBufferData(io_buffer);
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileReadIntoRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t length = CObjectInt32OrInt64ToInt64(request[2]);
      Dart_CObject* io_buffer = CObject::NewIOBuffer(length);
      uint8_t* data = io_buffer->value.as_external_typed_data.data;
      int64_t bytes_read = file->Read(data, length);
      if (bytes_read >= 0) {
        CObjectExternalUint8Array* external_array =
            new CObjectExternalUint8Array(io_buffer);
        external_array->SetLength(bytes_read);
        CObjectArray* result = new CObjectArray(CObject::NewArray(3));
        result->SetAt(0, new CObjectIntptr(CObject::NewInt32(0)));
        result->SetAt(1, new CObjectInt64(CObject::NewInt64(bytes_read)));
        result->SetAt(2, external_array);
        return result;
      } else {
        CObject::FreeIOBufferData(io_buffer);
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static int SizeInBytes(Dart_CObject::TypedDataType type) {
  switch (type) {
    case Dart_CObject::kInt8Array:
    case Dart_CObject::kUint8Array:
    case Dart_CObject::kUint8ClampedArray:
      return 1;
    case Dart_CObject::kInt16Array:
    case Dart_CObject::kUint16Array:
      return 2;
    case Dart_CObject::kInt32Array:
    case Dart_CObject::kUint32Array:
    case Dart_CObject::kFloat32Array:
      return 4;
    case Dart_CObject::kInt64Array:
    case Dart_CObject::kUint64Array:
    case Dart_CObject::kFloat64Array:
      return 8;
    default:
      break;
  }
  UNREACHABLE();
  return -1;
}


static CObject* FileWriteFromRequest(const CObjectArray& request) {
  if (request.Length() == 5 &&
      request[1]->IsIntptr() &&
      (request[2]->IsTypedData() || request[2]->IsArray()) &&
      request[3]->IsInt32OrInt64() &&
      request[4]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t start = CObjectInt32OrInt64ToInt64(request[3]);
      int64_t end = CObjectInt32OrInt64ToInt64(request[4]);
      int64_t length = end - start;
      uint8_t* buffer_start;
      if (request[2]->IsTypedData()) {
        CObjectTypedData typed_data(request[2]);
        start = start * SizeInBytes(typed_data.Type());
        length = length * SizeInBytes(typed_data.Type());
        buffer_start = typed_data.Buffer() + start;
      } else {
        CObjectArray array(request[2]);
        buffer_start = new uint8_t[length];
        for (int i = 0; i < length; i++) {
          if (array[i + start]->IsInt32OrInt64()) {
            int64_t value = CObjectInt32OrInt64ToInt64(array[i + start]);
            buffer_start[i] = static_cast<uint8_t>(value & 0xFF);
          } else {
            // Unsupported type.
            delete[] buffer_start;
            return CObject::IllegalArgumentError();
          }
        }
        start = 0;
      }
      int64_t bytes_written =
          file->Write(reinterpret_cast<void*>(buffer_start), length);
      if (!request[2]->IsTypedData()) {
        delete[] buffer_start;
      }
      if (bytes_written >= 0) {
        return new CObjectInt64(CObject::NewInt64(bytes_written));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileCreateLinkRequest(const CObjectArray& request) {
  if (request.Length() != 3 ||
      !request[1]->IsString() ||
      !request[2]->IsString()) {
    return CObject::IllegalArgumentError();
  }
  CObjectString link_name(request[1]);
  CObjectString target_name(request[2]);
  if (File::CreateLink(link_name.CString(), target_name.CString())) {
    return CObject::True();
  } else {
    return CObject::NewOSError();
  }
}


static CObject* FileDeleteLinkRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    bool result = File::DeleteLink(filename.CString());
    if (result) {
      return CObject::True();
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}


static void FileService(Dart_Port dest_port_id,
                 Dart_Port reply_port_id,
                 Dart_CObject* message) {
  CObject* response = CObject::IllegalArgumentError();
  CObjectArray request(message);
  if (message->type == Dart_CObject::kArray) {
    if (request.Length() > 1 && request[0]->IsInt32()) {
      CObjectInt32 requestType(request[0]);
      switch (requestType.Value()) {
        case File::kExistsRequest:
          response = FileExistsRequest(request);
          break;
        case File::kCreateRequest:
          response = FileCreateRequest(request);
          break;
        case File::kOpenRequest:
          response = FileOpenRequest(request);
          break;
        case File::kDeleteRequest:
          response = FileDeleteRequest(request);
          break;
        case File::kFullPathRequest:
          response = FileFullPathRequest(request);
          break;
        case File::kDirectoryRequest:
          response = FileDirectoryRequest(request);
          break;
        case File::kCloseRequest:
          response = FileCloseRequest(request);
          break;
        case File::kPositionRequest:
          response = FilePositionRequest(request);
          break;
        case File::kSetPositionRequest:
          response = FileSetPositionRequest(request);
          break;
        case File::kTruncateRequest:
          response = FileTruncateRequest(request);
          break;
        case File::kLengthRequest:
          response = FileLengthRequest(request);
          break;
        case File::kLengthFromPathRequest:
          response = FileLengthFromPathRequest(request);
          break;
        case File::kLastModifiedRequest:
          response = FileLastModifiedRequest(request);
          break;
        case File::kFlushRequest:
          response = FileFlushRequest(request);
          break;
        case File::kReadByteRequest:
          response = FileReadByteRequest(request);
          break;
        case File::kWriteByteRequest:
          response = FileWriteByteRequest(request);
          break;
        case File::kReadRequest:
          response = FileReadRequest(request);
          break;
        case File::kReadIntoRequest:
          response = FileReadIntoRequest(request);
          break;
        case File::kWriteFromRequest:
          response = FileWriteFromRequest(request);
          break;
        case File::kDeleteLinkRequest:
          response = FileDeleteLinkRequest(request);
          break;
        case File::kCreateLinkRequest:
          response = FileCreateLinkRequest(request);
          break;
        default:
          UNREACHABLE();
      }
    }
  }

  Dart_PostCObject(reply_port_id, response->AsApiCObject());
}


Dart_Port File::GetServicePort() {
  return file_service_.GetServicePort();
}


void FUNCTION_NAME(File_NewServicePort)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_Null());
  Dart_Port service_port = File::GetServicePort();
  if (service_port != ILLEGAL_PORT) {
    // Return a send port for the service port.
    Dart_Handle send_port = Dart_NewSendPort(service_port);
    Dart_SetReturnValue(args, send_port);
  }
  Dart_ExitScope();
}
