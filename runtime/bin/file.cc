// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_api.h"

dart::Mutex File::mutex_;
int File::service_ports_size_ = 0;
Dart_Port* File::service_ports_ = NULL;
int File::service_ports_index_ = 0;

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
  int mode = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  delete file;
  Dart_SetReturnValue(args, Dart_NewInteger(0));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  uint8_t buffer;
  int bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
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
  intptr_t file_ptr =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(file_ptr);
  ASSERT(file != NULL);
  int64_t value = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &value)) {
    uint8_t buffer = static_cast<uint8_t>(value & 0xff);
    int bytes_written = file->Write(reinterpret_cast<void*>(&buffer), 1);
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


void FUNCTION_NAME(File_WriteString)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int bytes_written = file->Write(reinterpret_cast<const void*>(str),
                                  strlen(str));
  if (bytes_written >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(bytes_written));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_ReadList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  int64_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  int64_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t array_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &array_len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  ASSERT((offset + length) <= array_len);
  uint8_t* buffer = new uint8_t[length];
  int bytes_read = file->Read(reinterpret_cast<void*>(buffer), length);
  if (bytes_read >= 0) {
    result = Dart_ListSetAsBytes(buffer_obj, offset, buffer, bytes_read);
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


void FUNCTION_NAME(File_WriteList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  int64_t offset =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  int64_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  intptr_t buffer_len = 0;
  Dart_Handle result = Dart_ListLength(buffer_obj, &buffer_len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  ASSERT((offset + length) <= buffer_len);
  uint8_t* buffer = new uint8_t[length];
  result = Dart_ListGetAsBytes(buffer_obj, offset, buffer, length);
  if (Dart_IsError(result)) {
    delete[] buffer;
    Dart_PropagateError(result);
  }
  int bytes_written = file->Write(reinterpret_cast<void*>(buffer), length);
  if (bytes_written >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(bytes_written));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  delete[] buffer;
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Position)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
  ASSERT(file != NULL);
  int64_t length =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  if (file->Truncate(length)) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Length)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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


void FUNCTION_NAME(File_LengthFromName)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* name =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  intptr_t return_value = File::LengthFromName(name);
  if (return_value >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(File_Flush)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t value =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = reinterpret_cast<File*>(value);
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


void FUNCTION_NAME(File_Directory)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* str =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  char* str_copy = strdup(str);
  char* path = File::GetContainingDirectory(str_copy);
  free(str_copy);
  if (path != NULL) {
    Dart_SetReturnValue(args, Dart_NewString(path));
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
    Dart_SetReturnValue(args, Dart_NewString(path));
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
  int fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File* file = File::OpenStdio(fd);
  Dart_SetReturnValue(args, Dart_NewInteger(reinterpret_cast<intptr_t>(file)));
  Dart_ExitScope();
}


void FUNCTION_NAME(File_GetStdioHandleType)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int fd = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0));
  File::StdioHandleType type = File::GetStdioHandleType(fd);
  Dart_SetReturnValue(args, Dart_NewInteger(type));
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


static CObject* FileLengthFromNameRequest(const CObjectArray& request) {
  if (request.Length() == 2 && request[1]->IsString()) {
    CObjectString filename(request[1]);
    intptr_t return_value = File::LengthFromName(filename.CString());
    if (return_value >= 0) {
      return new CObjectIntptr(CObject::NewIntptr(return_value));
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
      int bytes_read = file->Read(reinterpret_cast<void*>(&buffer), 1);
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
      int bytes_written = file->Write(reinterpret_cast<void*>(&buffer), 1);
      if (bytes_written > 0) {
        return new CObjectIntptr(CObject::NewIntptr(bytes_written));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileReadListRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t length = CObjectInt32OrInt64ToInt64(request[2]);
      CObjectUint8Array* byte_array =
          new CObjectUint8Array(CObject::NewUint8Array(length));
      void* buffer = reinterpret_cast<void*>(byte_array->Buffer());
      int bytes_read = file->Read(buffer, byte_array->Length());
      if (bytes_read >= 0) {
        CObjectArray* result = new CObjectArray(CObject::NewArray(3));
        result->SetAt(0, new CObjectIntptr(CObject::NewInt32(0)));
        result->SetAt(1, new CObjectIntptr(CObject::NewIntptr(bytes_read)));
        result->SetAt(2, byte_array);
        return result;
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileWriteListRequest(const CObjectArray& request) {
  if (request.Length() == 5 &&
      request[1]->IsIntptr() &&
      (request[2]->IsUint8Array() || request[2]->IsArray()) &&
      request[3]->IsInt32OrInt64() &&
      request[4]->IsInt32OrInt64()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      int64_t offset = CObjectInt32OrInt64ToInt64(request[3]);
      int64_t length = CObjectInt32OrInt64ToInt64(request[4]);
      uint8_t* buffer_start;
      if (request[2]->IsUint8Array()) {
        CObjectUint8Array byte_array(request[2]);
        buffer_start = byte_array.Buffer() + offset;
      } else {
        CObjectArray array(request[2]);
        buffer_start = new uint8_t[length];
        for (int i = 0; i < length; i++) {
          if (array[i + offset]->IsInt32OrInt64()) {
            int64_t value = CObjectInt32OrInt64ToInt64(array[i + offset]);
            buffer_start[i] = value & 0xFF;
          } else {
            // Unsupported type.
            delete[] buffer_start;
            return CObject::IllegalArgumentError();
          }
        }
        offset = 0;
      }
      int64_t bytes_written =
          file->Write(reinterpret_cast<void*>(buffer_start), length);
      if (!request[2]->IsUint8Array()) {
        delete[] buffer_start;
      }
      if (bytes_written >= 0) {
        return new CObjectIntptr(CObject::NewIntptr(bytes_written));
      } else {
        return CObject::NewOSError();
      }
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


static CObject* FileWriteStringRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsIntptr() &&
      request[2]->IsString()) {
    File* file = CObjectToFilePointer(request[1]);
    ASSERT(file != NULL);
    if (!file->IsClosed()) {
      CObjectString str(request[2]);
      const void* buffer = reinterpret_cast<const void*>(str.CString());
      int64_t bytes_written = file->Write(buffer, str.Length());
      return new CObjectInt64(CObject::NewInt64(bytes_written));
    } else {
      return CObject::FileClosedError();
    }
  }
  return CObject::IllegalArgumentError();
}


void FileService(Dart_Port dest_port_id,
                 Dart_Port reply_port_id,
                 Dart_CObject* message) {
  CObject* response = CObject::False();
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
        case File::kLengthFromNameRequest:
          response = FileLengthFromNameRequest(request);
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
        case File::kReadListRequest:
          response = FileReadListRequest(request);
          break;
        case File::kWriteListRequest:
          response = FileWriteListRequest(request);
          break;
        case File::kWriteStringRequest:
          response = FileWriteStringRequest(request);
          break;
        default:
          UNREACHABLE();
      }
    }
  }

  Dart_PostCObject(reply_port_id, response->AsApiCObject());
}


Dart_Port File::GetServicePort() {
  MutexLocker lock(&mutex_);
  if (service_ports_size_ == 0) {
    ASSERT(service_ports_ == NULL);
    service_ports_size_ = 16;
    service_ports_ = new Dart_Port[service_ports_size_];
    service_ports_index_ = 0;
    for (int i = 0; i < service_ports_size_; i++) {
      service_ports_[i] = kIllegalPort;
    }
  }

  Dart_Port result = service_ports_[service_ports_index_];
  if (result == kIllegalPort) {
    result = Dart_NewNativePort("FileService",
                                FileService,
                                true);
    ASSERT(result != kIllegalPort);
    service_ports_[service_ports_index_] = result;
  }
  service_ports_index_ = (service_ports_index_ + 1) % service_ports_size_;
  return result;
}


void FUNCTION_NAME(File_NewServicePort)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_Null());
  Dart_Port service_port = File::GetServicePort();
  if (service_port != kIllegalPort) {
    // Return a send port for the service port.
    Dart_Handle send_port = Dart_NewSendPort(service_port);
    Dart_SetReturnValue(args, send_port);
  }
  Dart_ExitScope();
}
