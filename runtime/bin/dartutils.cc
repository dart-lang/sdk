// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

#include "bin/crypto.h"
#include "bin/directory.h"
#include "bin/file.h"
#include "bin/io_buffer.h"
#include "bin/namespace.h"
#include "bin/platform.h"
#include "bin/utils.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/memory_sanitizer.h"
#include "platform/utils.h"

// Return the error from the containing function if handle is in error handle.
#define RETURN_IF_ERROR(handle)                                                \
  {                                                                            \
    Dart_Handle __handle = handle;                                             \
    if (Dart_IsError((__handle))) {                                            \
      return __handle;                                                         \
    }                                                                          \
  }

namespace dart {
namespace bin {

const char* DartUtils::original_working_directory = nullptr;

dart::SimpleHashMap* DartUtils::environment_ = nullptr;

MagicNumberData appjit_magic_number = {8, {0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0}};
MagicNumberData kernel_magic_number = {4, {0x90, 0xab, 0xcd, 0xef}};
MagicNumberData kernel_list_magic_number = {
    7,
    {0x23, 0x40, 0x64, 0x69, 0x6c, 0x6c, 0x0a}};  // #@dill\n
MagicNumberData gzip_magic_number = {2, {0x1f, 0x8b, 0, 0}};

static bool IsWindowsHost() {
#if defined(DART_HOST_OS_WINDOWS)
  return true;
#else   // defined(DART_HOST_OS_WINDOWS)
  return false;
#endif  // defined(DART_HOST_OS_WINDOWS)
}

Dart_Handle CommandLineOptions::CreateRuntimeOptions() {
  Dart_Handle string_type = DartUtils::GetDartType("dart:core", "String");
  if (Dart_IsError(string_type)) {
    return string_type;
  }
  Dart_Handle dart_arguments =
      Dart_NewListOfTypeFilled(string_type, Dart_EmptyString(), count_);
  if (Dart_IsError(dart_arguments)) {
    return dart_arguments;
  }
  for (int i = 0; i < count_; i++) {
    Dart_Handle argument_value = DartUtils::NewString(GetArgument(i));
    if (Dart_IsError(argument_value)) {
      return argument_value;
    }
    Dart_Handle result = Dart_ListSetAt(dart_arguments, i, argument_value);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return dart_arguments;
}

int64_t DartUtils::GetIntegerValue(Dart_Handle value_obj) {
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return value;
}

int64_t DartUtils::GetInt64ValueCheckRange(Dart_Handle value_obj,
                                           int64_t lower,
                                           int64_t upper) {
  int64_t value = DartUtils::GetIntegerValue(value_obj);
  if (value < lower || upper < value) {
    Dart_PropagateError(Dart_NewApiError("Value outside expected range"));
  }
  return value;
}

intptr_t DartUtils::GetIntptrValue(Dart_Handle value_obj) {
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  if (value < kIntptrMin || kIntptrMax < value) {
    Dart_PropagateError(Dart_NewApiError("Value outside intptr_t range"));
  }
  return static_cast<intptr_t>(value);
}

bool DartUtils::GetInt64Value(Dart_Handle value_obj, int64_t* value) {
  bool valid = Dart_IsInteger(value_obj);
  if (valid) {
    Dart_Handle result = Dart_IntegerFitsIntoInt64(value_obj, &valid);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
  }
  if (!valid) return false;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return true;
}

const char* DartUtils::GetStringValue(Dart_Handle str_obj) {
  const char* cstring = nullptr;
  Dart_Handle result = Dart_StringToCString(str_obj, &cstring);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return cstring;
}

bool DartUtils::GetBooleanValue(Dart_Handle bool_obj) {
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(bool_obj, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return value;
}

bool DartUtils::GetNativeBooleanArgument(Dart_NativeArguments args,
                                         intptr_t index) {
  bool value = false;
  Dart_Handle result = Dart_GetNativeBooleanArgument(args, index, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return value;
}

int64_t DartUtils::GetNativeIntegerArgument(Dart_NativeArguments args,
                                            intptr_t index) {
  int64_t value = 0;
  Dart_Handle result = Dart_GetNativeIntegerArgument(args, index, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  return value;
}

intptr_t DartUtils::GetNativeIntptrArgument(Dart_NativeArguments args,
                                            intptr_t index) {
  int64_t value = GetNativeIntegerArgument(args, index);
  if (value < kIntptrMin || kIntptrMax < value) {
    Dart_PropagateError(Dart_NewApiError("Value outside intptr_t range"));
  }
  return static_cast<intptr_t>(value);
}

const char* DartUtils::GetNativeStringArgument(Dart_NativeArguments args,
                                               intptr_t index) {
  char* tmp = nullptr;
  Dart_Handle result =
      Dart_GetNativeStringArgument(args, index, reinterpret_cast<void**>(&tmp));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  if (tmp != nullptr) {
    return tmp;
  }
  const char* cstring = nullptr;
  result = Dart_StringToCString(result, &cstring);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT(cstring != nullptr);
  return cstring;
}

Dart_Handle DartUtils::SetIntegerField(Dart_Handle handle,
                                       const char* name,
                                       int64_t val) {
  return Dart_SetField(handle, NewString(name), Dart_NewInteger(val));
}

Dart_Handle DartUtils::SetStringField(Dart_Handle handle,
                                      const char* name,
                                      const char* val) {
  return Dart_SetField(handle, NewString(name), NewString(val));
}

bool DartUtils::IsDartSchemeURL(const char* url_name) {
  static const intptr_t kDartSchemeLen = strlen(kDartScheme);
  // If the URL starts with "dart:" then it is considered as a special
  // library URL which is handled differently from other URLs.
  return (strncmp(url_name, kDartScheme, kDartSchemeLen) == 0);
}

bool DartUtils::IsHttpSchemeURL(const char* url_name) {
  static const intptr_t kHttpSchemeLen = strlen(kHttpScheme);
  return (strncmp(url_name, kHttpScheme, kHttpSchemeLen) == 0);
}

bool DartUtils::IsDartIOLibURL(const char* url_name) {
  return (strcmp(url_name, kIOLibURL) == 0);
}

bool DartUtils::IsDartCLILibURL(const char* url_name) {
  return (strcmp(url_name, kCLILibURL) == 0);
}

bool DartUtils::IsDartHttpLibURL(const char* url_name) {
  return (strcmp(url_name, kHttpLibURL) == 0);
}

bool DartUtils::IsDartBuiltinLibURL(const char* url_name) {
  return (strcmp(url_name, kBuiltinLibURL) == 0);
}

const char* DartUtils::RemoveScheme(const char* url) {
  const char* colon = strchr(url, ':');
  if (colon == nullptr) {
    return url;
  } else {
    return colon + 1;
  }
}

char* DartUtils::DirName(const char* url) {
  const char* slash = strrchr(url, File::PathSeparator()[0]);
  if (slash == nullptr) {
    return Utils::StrDup(url);
  } else {
    return Utils::StrNDup(url, slash - url + 1);
  }
}

void* DartUtils::OpenFile(const char* name, bool write) {
  File* file =
      File::Open(nullptr, name, write ? File::kWriteTruncate : File::kRead);
  return reinterpret_cast<void*>(file);
}

void* DartUtils::OpenFileUri(const char* uri, bool write) {
  File* file =
      File::OpenUri(nullptr, uri, write ? File::kWriteTruncate : File::kRead);
  return reinterpret_cast<void*>(file);
}

void DartUtils::ReadFile(uint8_t** data, intptr_t* len, void* stream) {
  ASSERT(data != nullptr);
  ASSERT(len != nullptr);
  ASSERT(stream != nullptr);
  File* file_stream = reinterpret_cast<File*>(stream);
  int64_t file_len = file_stream->Length();
  if ((file_len < 0) || (file_len > kIntptrMax)) {
    *data = nullptr;
    *len = -1;  // Indicates read was not successful.
    return;
  }
  *len = static_cast<intptr_t>(file_len);
  *data = reinterpret_cast<uint8_t*>(malloc(*len));
  if (!file_stream->ReadFully(*data, *len)) {
    free(*data);
    *data = nullptr;
    *len = -1;  // Indicates read was not successful.
    return;
  }
}

void DartUtils::WriteFile(const void* buffer,
                          intptr_t num_bytes,
                          void* stream) {
  ASSERT(stream != nullptr);
  File* file_stream = reinterpret_cast<File*>(stream);
  bool bytes_written = file_stream->WriteFully(buffer, num_bytes);
  ASSERT(bytes_written);
}

void DartUtils::CloseFile(void* stream) {
  File* file = reinterpret_cast<File*>(stream);
  file->Release();
}

bool DartUtils::EntropySource(uint8_t* buffer, intptr_t length) {
  return Crypto::GetRandomBytes(length, buffer);
}

static Dart_Handle SingleArgDart_Invoke(Dart_Handle lib,
                                        const char* method,
                                        Dart_Handle arg) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = arg;
  return Dart_Invoke(lib, DartUtils::NewString(method), kNumArgs, dart_args);
}

// TODO(iposva): Allocate from the zone instead of leaking error string
// here. On the other hand the binary is about to exit anyway.
#define SET_ERROR_MSG(error_msg, format, ...)                                  \
  intptr_t len = snprintf(nullptr, 0, format, __VA_ARGS__);                    \
  char* msg = reinterpret_cast<char*>(malloc(len + 1));                        \
  snprintf(msg, len + 1, format, __VA_ARGS__);                                 \
  *error_msg = msg

static uint8_t* ReadFileFully(const char* filename,
                              intptr_t* file_len,
                              const char** error_msg) {
  *file_len = -1;
  void* stream = DartUtils::OpenFile(filename, false);
  if (stream == nullptr) {
    SET_ERROR_MSG(error_msg, "Unable to open file: %s", filename);
    return nullptr;
  }
  uint8_t* text_buffer = nullptr;
  DartUtils::ReadFile(&text_buffer, file_len, stream);
  if (text_buffer == nullptr || *file_len == -1) {
    *error_msg = "Unable to read file contents";
    text_buffer = nullptr;
  }
  DartUtils::CloseFile(stream);
  return text_buffer;
}

Dart_Handle DartUtils::ReadStringFromFile(const char* filename) {
  const char* error_msg = nullptr;
  intptr_t len;
  uint8_t* text_buffer = ReadFileFully(filename, &len, &error_msg);
  if (text_buffer == nullptr) {
    return Dart_NewApiError(error_msg);
  }
  Dart_Handle str = Dart_NewStringFromUTF8(text_buffer, len);
  free(text_buffer);
  return str;
}

Dart_Handle DartUtils::MakeUint8Array(const void* buffer, intptr_t len) {
  Dart_Handle array = Dart_NewTypedData(Dart_TypedData_kUint8, len);
  RETURN_IF_ERROR(array);
  {
    Dart_TypedData_Type td_type;
    void* td_data;
    intptr_t td_len;
    Dart_Handle result =
        Dart_TypedDataAcquireData(array, &td_type, &td_data, &td_len);
    RETURN_IF_ERROR(result);
    ASSERT(td_type == Dart_TypedData_kUint8);
    ASSERT(td_len == len);
    ASSERT(td_data != nullptr);
    memmove(td_data, buffer, td_len);
    result = Dart_TypedDataReleaseData(array);
    RETURN_IF_ERROR(result);
  }
  return array;
}

Dart_Handle DartUtils::SetWorkingDirectory() {
  Dart_Handle directory = NewString(original_working_directory);
  return SingleArgDart_Invoke(LookupBuiltinLib(), "_setWorkingDirectory",
                              directory);
}

Dart_Handle DartUtils::ResolveScript(Dart_Handle url) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = url;
  return Dart_Invoke(DartUtils::LookupBuiltinLib(),
                     NewString("_resolveScriptUri"), kNumArgs, dart_args);
}

static bool CheckMagicNumber(const uint8_t* buffer,
                             intptr_t buffer_length,
                             const MagicNumberData& magic_number) {
  if ((buffer_length >= magic_number.length)) {
    return memcmp(buffer, magic_number.bytes, magic_number.length) == 0;
  }
  return false;
}

DartUtils::MagicNumber DartUtils::SniffForMagicNumber(const char* filename) {
  MagicNumber magic_number = DartUtils::kUnknownMagicNumber;
  if (File::GetType(nullptr, filename, true) == File::kIsFile) {
    File* file = File::Open(nullptr, filename, File::kRead);
    if (file != nullptr) {
      RefCntReleaseScope<File> rs(file);
      intptr_t max_magic_length = 0;
      max_magic_length =
          Utils::Maximum(max_magic_length, appjit_magic_number.length);
      max_magic_length =
          Utils::Maximum(max_magic_length, kernel_magic_number.length);
      max_magic_length =
          Utils::Maximum(max_magic_length, kernel_list_magic_number.length);
      max_magic_length =
          Utils::Maximum(max_magic_length, gzip_magic_number.length);
      ASSERT(max_magic_length <= 8);
      uint8_t header[8];
      if (file->ReadFully(&header, max_magic_length)) {
        magic_number = DartUtils::SniffForMagicNumber(header, sizeof(header));
      }
    }
  }
  return magic_number;
}

DartUtils::MagicNumber DartUtils::SniffForMagicNumber(const uint8_t* buffer,
                                                      intptr_t buffer_length) {
  if (CheckMagicNumber(buffer, buffer_length, appjit_magic_number)) {
    return kAppJITMagicNumber;
  }

  if (CheckMagicNumber(buffer, buffer_length, kernel_magic_number)) {
    return kKernelMagicNumber;
  }

  if (CheckMagicNumber(buffer, buffer_length, kernel_list_magic_number)) {
    return kKernelListMagicNumber;
  }

  if (CheckMagicNumber(buffer, buffer_length, gzip_magic_number)) {
    return kGzipMagicNumber;
  }

  if (CheckMagicNumber(buffer, buffer_length, gzip_magic_number)) {
    return kGzipMagicNumber;
  }

  return kUnknownMagicNumber;
}

Dart_Handle DartUtils::PrepareBuiltinLibrary(Dart_Handle builtin_lib,
                                             Dart_Handle internal_lib,
                                             bool is_service_isolate,
                                             bool trace_loading) {
  // Setup the internal library's 'internalPrint' function.
  Dart_Handle print =
      Dart_Invoke(builtin_lib, NewString("_getPrintClosure"), 0, nullptr);
  RETURN_IF_ERROR(print);
  Dart_Handle result =
      Dart_SetField(internal_lib, NewString("_printClosure"), print);
  RETURN_IF_ERROR(result);

  if (!is_service_isolate) {
    if (IsWindowsHost()) {
      result = Dart_SetField(builtin_lib, NewString("_isWindows"), Dart_True());
      RETURN_IF_ERROR(result);
    }
    if (trace_loading) {
      result =
          Dart_SetField(builtin_lib, NewString("_traceLoading"), Dart_True());
      RETURN_IF_ERROR(result);
    }
    // Set current working directory.
    result = SetWorkingDirectory();
    RETURN_IF_ERROR(result);
  }
  return Dart_True();
}

Dart_Handle DartUtils::PrepareCoreLibrary(Dart_Handle core_lib,
                                          Dart_Handle io_lib,
                                          bool is_service_isolate) {
  if (!is_service_isolate) {
    // Setup the 'Uri.base' getter in dart:core.
    Dart_Handle uri_base =
        Dart_Invoke(io_lib, NewString("_getUriBaseClosure"), 0, nullptr);
    RETURN_IF_ERROR(uri_base);
    Dart_Handle result =
        Dart_SetField(core_lib, NewString("_uriBaseClosure"), uri_base);
    RETURN_IF_ERROR(result);
  }
  return Dart_True();
}

Dart_Handle DartUtils::PrepareAsyncLibrary(Dart_Handle async_lib,
                                           Dart_Handle isolate_lib) {
  Dart_Handle schedule_immediate_closure =
      Dart_Invoke(isolate_lib, NewString("_getIsolateScheduleImmediateClosure"),
                  0, nullptr);
  RETURN_IF_ERROR(schedule_immediate_closure);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  return Dart_Invoke(async_lib, NewString("_setScheduleImmediateClosure"), 1,
                     args);
}

Dart_Handle DartUtils::PrepareIOLibrary(Dart_Handle io_lib) {
  return Dart_Invoke(io_lib, NewString("_setupHooks"), 0, nullptr);
}

Dart_Handle DartUtils::PrepareIsolateLibrary(Dart_Handle isolate_lib) {
  return Dart_Invoke(isolate_lib, NewString("_setupHooks"), 0, nullptr);
}

Dart_Handle DartUtils::PrepareCLILibrary(Dart_Handle cli_lib) {
  Dart_Handle wait_for_event_handle =
      Dart_Invoke(cli_lib, NewString("_getWaitForEvent"), 0, nullptr);
  RETURN_IF_ERROR(wait_for_event_handle);
  return Dart_SetField(cli_lib, NewString("_waitForEventClosure"),
                       wait_for_event_handle);
}

Dart_Handle DartUtils::SetupPackageConfig(const char* packages_config) {
  Dart_Handle result = Dart_Null();

  if (packages_config != nullptr) {
    result = NewString(packages_config);
    RETURN_IF_ERROR(result);
    const int kNumArgs = 1;
    Dart_Handle dart_args[kNumArgs];
    dart_args[0] = result;
    result = Dart_Invoke(DartUtils::LookupBuiltinLib(),
                         NewString("_setPackagesMap"), kNumArgs, dart_args);
  }
  return result;
}

Dart_Handle DartUtils::PrepareForScriptLoading(bool is_service_isolate,
                                               bool trace_loading) {
  // First ensure all required libraries are available.
  Dart_Handle url = NewString(kCoreLibURL);
  RETURN_IF_ERROR(url);
  Dart_Handle core_lib = Dart_LookupLibrary(url);
  RETURN_IF_ERROR(core_lib);
  url = NewString(kAsyncLibURL);
  RETURN_IF_ERROR(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  RETURN_IF_ERROR(async_lib);
  url = NewString(kIsolateLibURL);
  RETURN_IF_ERROR(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  RETURN_IF_ERROR(isolate_lib);
  url = NewString(kInternalLibURL);
  RETURN_IF_ERROR(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  RETURN_IF_ERROR(internal_lib);
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  RETURN_IF_ERROR(builtin_lib);
  Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
  Dart_Handle io_lib = Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
  RETURN_IF_ERROR(io_lib);
  Builtin::SetNativeResolver(Builtin::kIOLibrary);
  Dart_Handle cli_lib = Builtin::LoadAndCheckLibrary(Builtin::kCLILibrary);
  RETURN_IF_ERROR(cli_lib);
  Builtin::SetNativeResolver(Builtin::kCLILibrary);

  // We need to ensure that all the scripts loaded so far are finalized
  // as we are about to invoke some Dart code below to setup closures.
  Dart_Handle result = Dart_FinalizeLoading(false);
  RETURN_IF_ERROR(result);

  result = PrepareBuiltinLibrary(builtin_lib, internal_lib, is_service_isolate,
                                 trace_loading);
  RETURN_IF_ERROR(result);

  RETURN_IF_ERROR(PrepareAsyncLibrary(async_lib, isolate_lib));
  RETURN_IF_ERROR(PrepareCoreLibrary(core_lib, io_lib, is_service_isolate));
  RETURN_IF_ERROR(PrepareIsolateLibrary(isolate_lib));
  RETURN_IF_ERROR(PrepareIOLibrary(io_lib));
  RETURN_IF_ERROR(PrepareCLILibrary(cli_lib));
  return result;
}

Dart_Handle DartUtils::SetupIOLibrary(const char* namespc_path,
                                      const char* script_uri,
                                      bool disable_exit) {
  Dart_Handle io_lib_url = NewString(kIOLibURL);
  RETURN_IF_ERROR(io_lib_url);
  Dart_Handle io_lib = Dart_LookupLibrary(io_lib_url);
  RETURN_IF_ERROR(io_lib);

  if (namespc_path != nullptr) {
    Dart_Handle namespc_type = GetDartType(DartUtils::kIOLibURL, "_Namespace");
    RETURN_IF_ERROR(namespc_type);
    Dart_Handle args[1];
    args[0] = NewString(namespc_path);
    RETURN_IF_ERROR(args[0]);
    Dart_Handle result =
        Dart_Invoke(namespc_type, NewString("_setupNamespace"), 1, args);
    RETURN_IF_ERROR(result);
  }

  if (disable_exit) {
    Dart_Handle embedder_config_type =
        GetDartType(DartUtils::kIOLibURL, "_EmbedderConfig");
    RETURN_IF_ERROR(embedder_config_type);
    Dart_Handle result = Dart_SetField(embedder_config_type,
                                       NewString("_mayExit"), Dart_False());
    RETURN_IF_ERROR(result);
  }

  Dart_Handle platform_type = GetDartType(DartUtils::kIOLibURL, "_Platform");
  RETURN_IF_ERROR(platform_type);
  Dart_Handle script_name = NewString("_nativeScript");
  RETURN_IF_ERROR(script_name);
  Dart_Handle dart_script = NewString(script_uri);
  RETURN_IF_ERROR(dart_script);
  Dart_Handle set_script_name =
      Dart_SetField(platform_type, script_name, dart_script);
  RETURN_IF_ERROR(set_script_name);

#if !defined(PRODUCT)
  Dart_Handle network_profiling_type =
      GetDartType(DartUtils::kIOLibURL, "_NetworkProfiling");
  RETURN_IF_ERROR(network_profiling_type);
  Dart_Handle result =
      Dart_Invoke(network_profiling_type,
                  NewString("_registerServiceExtension"), 0, nullptr);
  RETURN_IF_ERROR(result);
#endif  // !defined(PRODUCT)
  return Dart_Null();
}

bool DartUtils::PostNull(Dart_Port port_id) {
  // Post a message with just the null object.
  return Dart_PostCObject(port_id, CObject::Null()->AsApiCObject());
}

bool DartUtils::PostInt32(Dart_Port port_id, int32_t value) {
  // Post a message with the integer value.
  int32_t min = 0xc0000000;  // -1073741824
  int32_t max = 0x3fffffff;  // 1073741823
  ASSERT(min <= value && value < max);
  Dart_CObject object;
  object.type = Dart_CObject_kInt32;
  object.value.as_int32 = value;
  return Dart_PostCObject(port_id, &object);
}

bool DartUtils::PostInt64(Dart_Port port_id, int64_t value) {
  // Post a message with the integer value.
  Dart_CObject object;
  object.type = Dart_CObject_kInt64;
  object.value.as_int64 = value;
  return Dart_PostCObject(port_id, &object);
}

bool DartUtils::PostString(Dart_Port port_id, const char* value) {
  Dart_CObject* object = CObject::NewString(value);
  return Dart_PostCObject(port_id, object);
}

Dart_Handle DartUtils::GetDartType(const char* library_url,
                                   const char* class_name) {
  return Dart_GetNonNullableType(Dart_LookupLibrary(NewString(library_url)),
                                 NewString(class_name), 0, nullptr);
}

Dart_Handle DartUtils::NewDartOSError() {
  // Extract the current OS error.
  OSError os_error;
  return NewDartOSError(&os_error);
}

Dart_Handle DartUtils::NewDartOSError(OSError* os_error) {
  // Create a dart:io OSError object with the information retrieved from the OS.
  Dart_Handle type = GetDartType(kIOLibURL, "OSError");
  ASSERT(!Dart_IsError(type));
  Dart_Handle args[2];
  args[0] = NewString(os_error->message());
  args[1] = Dart_NewInteger(os_error->code());
  return Dart_New(type, Dart_Null(), 2, args);
}

Dart_Handle DartUtils::NewDartExceptionWithOSError(const char* library_url,
                                                   const char* exception_name,
                                                   const char* message,
                                                   Dart_Handle os_error) {
  // Create a Dart Exception object with a message and an OSError.
  Dart_Handle type = GetDartType(library_url, exception_name);
  ASSERT(!Dart_IsError(type));
  Dart_Handle args[2];
  args[0] = NewString(message);
  args[1] = os_error;
  return Dart_New(type, Dart_Null(), 2, args);
}

Dart_Handle DartUtils::NewDartExceptionWithMessage(const char* library_url,
                                                   const char* exception_name,
                                                   const char* message) {
  // Create a Dart Exception object with a message.
  Dart_Handle type = GetDartType(library_url, exception_name);
  ASSERT(!Dart_IsError(type));
  if (message != nullptr) {
    Dart_Handle args[1];
    args[0] = NewString(message);
    return Dart_New(type, Dart_Null(), 1, args);
  } else {
    return Dart_New(type, Dart_Null(), 0, nullptr);
  }
}

Dart_Handle DartUtils::NewDartArgumentError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "ArgumentError", message);
}

Dart_Handle DartUtils::NewDartFormatException(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "FormatException", message);
}

Dart_Handle DartUtils::NewDartUnsupportedError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "UnsupportedError", message);
}

Dart_Handle DartUtils::NewDartIOException(const char* exception_name,
                                          const char* message,
                                          Dart_Handle os_error) {
  // Create a dart:io exception object of the given type.
  return NewDartExceptionWithOSError(kIOLibURL, exception_name, message,
                                     os_error);
}

Dart_Handle DartUtils::NewError(const char* format, ...) {
  va_list measure_args;
  va_start(measure_args, format);
  intptr_t len = vsnprintf(nullptr, 0, format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(Dart_ScopeAllocate(len + 1));
  MSAN_UNPOISON(buffer, (len + 1));
  va_list print_args;
  va_start(print_args, format);
  vsnprintf(buffer, (len + 1), format, print_args);
  va_end(print_args);

  return Dart_NewApiError(buffer);
}

Dart_Handle DartUtils::NewInternalError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "_InternalError", message);
}

Dart_Handle DartUtils::NewStringFormatted(const char* format, ...) {
  va_list measure_args;
  va_start(measure_args, format);
  intptr_t len = vsnprintf(nullptr, 0, format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(Dart_ScopeAllocate(len + 1));
  MSAN_UNPOISON(buffer, (len + 1));
  va_list print_args;
  va_start(print_args, format);
  vsnprintf(buffer, (len + 1), format, print_args);
  va_end(print_args);

  return NewString(buffer);
}

bool DartUtils::SetOriginalWorkingDirectory() {
  // If we happen to re-initialize the Dart VM multiple times, make sure to free
  // the old string (allocated by getcwd()) before setting a new one.
  if (original_working_directory != nullptr) {
    free(const_cast<char*>(original_working_directory));
  }
  original_working_directory = Directory::CurrentNoScope();
  return original_working_directory != nullptr;
}

void DartUtils::SetEnvironment(dart::SimpleHashMap* environment) {
  environment_ = environment;
}

Dart_Handle DartUtils::EnvironmentCallback(Dart_Handle name) {
  uint8_t* utf8_array;
  intptr_t utf8_len;
  Dart_Handle result = Dart_Null();
  Dart_Handle handle = Dart_StringToUTF8(name, &utf8_array, &utf8_len);
  if (Dart_IsError(handle)) {
    handle = Dart_ThrowException(
        DartUtils::NewDartArgumentError(Dart_GetError(handle)));
  } else {
    char* name_chars = reinterpret_cast<char*>(malloc(utf8_len + 1));
    memmove(name_chars, utf8_array, utf8_len);
    name_chars[utf8_len] = '\0';
    const char* value = nullptr;
    if (environment_ != nullptr) {
      SimpleHashMap::Entry* entry =
          environment_->Lookup(GetHashmapKeyFromString(name_chars),
                               SimpleHashMap::StringHash(name_chars), false);
      if (entry != nullptr) {
        value = reinterpret_cast<char*>(entry->value);
      }
    }
    if (value != nullptr) {
      result = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(value),
                                      strlen(value));
      if (Dart_IsError(result)) {
        result = Dart_Null();
      }
    }
    free(name_chars);
  }
  return result;
}

// Statically allocated Dart_CObject instances for immutable
// objects. As these will be used by different threads the use of
// these depends on the fact that the marking internally in the
// Dart_CObject structure is not marking simple value objects.
Dart_CObject CObject::api_null_ = {Dart_CObject_kNull, {false}};
Dart_CObject CObject::api_true_ = {Dart_CObject_kBool, {true}};
Dart_CObject CObject::api_false_ = {Dart_CObject_kBool, {false}};
CObject CObject::null_(&api_null_);
CObject CObject::true_(&api_true_);
CObject CObject::false_(&api_false_);

CObject* CObject::Null() {
  return &null_;
}

CObject* CObject::True() {
  return &true_;
}

CObject* CObject::False() {
  return &false_;
}

CObject* CObject::Bool(bool value) {
  return value ? &true_ : &false_;
}

Dart_CObject* CObject::New(Dart_CObject_Type type, int additional_bytes) {
  Dart_CObject* cobject = reinterpret_cast<Dart_CObject*>(
      Dart_ScopeAllocate(sizeof(Dart_CObject) + additional_bytes));
  cobject->type = type;
  return cobject;
}

Dart_CObject* CObject::NewInt32(int32_t value) {
  Dart_CObject* cobject = New(Dart_CObject_kInt32);
  cobject->value.as_int32 = value;
  return cobject;
}

Dart_CObject* CObject::NewInt64(int64_t value) {
  Dart_CObject* cobject = New(Dart_CObject_kInt64);
  cobject->value.as_int64 = value;
  return cobject;
}

Dart_CObject* CObject::NewIntptr(intptr_t value) {
  // Pointer values passed as intptr_t are always send as int64_t.
  Dart_CObject* cobject = New(Dart_CObject_kInt64);
  cobject->value.as_int64 = value;
  return cobject;
}

Dart_CObject* CObject::NewDouble(double value) {
  Dart_CObject* cobject = New(Dart_CObject_kDouble);
  cobject->value.as_double = value;
  return cobject;
}

Dart_CObject* CObject::NewString(const char* str) {
  intptr_t length = strlen(str);
  Dart_CObject* cobject = New(Dart_CObject_kString, length + 1);
  char* payload = reinterpret_cast<char*>(cobject + 1);
  memmove(payload, str, length + 1);
  cobject->value.as_string = payload;
  return cobject;
}

Dart_CObject* CObject::NewArray(intptr_t length) {
  Dart_CObject* cobject =
      New(Dart_CObject_kArray, length * sizeof(Dart_CObject*));  // NOLINT
  cobject->value.as_array.length = length;
  cobject->value.as_array.values =
      reinterpret_cast<Dart_CObject**>(cobject + 1);
  return cobject;
}

Dart_CObject* CObject::NewUint8Array(const void* data, intptr_t length) {
  Dart_CObject* cobject = New(Dart_CObject_kTypedData, length);
  memmove(reinterpret_cast<uint8_t*>(cobject + 1), data, length);
  cobject->value.as_typed_data.type = Dart_TypedData_kUint8;
  cobject->value.as_typed_data.length = length;
  cobject->value.as_typed_data.values =
      reinterpret_cast<const uint8_t*>(cobject + 1);
  return cobject;
}

Dart_CObject* CObject::NewExternalUint8Array(intptr_t length,
                                             uint8_t* data,
                                             void* peer,
                                             Dart_HandleFinalizer callback) {
  Dart_CObject* cobject = New(Dart_CObject_kExternalTypedData);
  cobject->value.as_external_typed_data.type = Dart_TypedData_kUint8;
  cobject->value.as_external_typed_data.length = length;
  cobject->value.as_external_typed_data.data = data;
  cobject->value.as_external_typed_data.peer = peer;
  cobject->value.as_external_typed_data.callback = callback;
  return cobject;
}

Dart_CObject* CObject::NewNativePointer(intptr_t ptr,
                                        intptr_t size,
                                        Dart_HandleFinalizer callback) {
  Dart_CObject* cobject = New(Dart_CObject_kNativePointer);
  cobject->value.as_native_pointer.ptr = ptr;
  cobject->value.as_native_pointer.size = size;
  cobject->value.as_native_pointer.callback = callback;
  return cobject;
}

Dart_CObject* CObject::NewIOBuffer(int64_t length) {
  // Make sure that we do not have an integer overflow here. Actual check
  // against max elements will be done at the time of writing, as the constant
  // is not part of the public API.
  if ((length < 0) || (length > kIntptrMax)) {
    return nullptr;
  }
  uint8_t* data = IOBuffer::Allocate(static_cast<intptr_t>(length));
  if (data == nullptr) {
    return nullptr;
  }
  return NewExternalUint8Array(static_cast<intptr_t>(length), data, data,
                               IOBuffer::Finalizer);
}

void CObject::ShrinkIOBuffer(Dart_CObject* cobject, int64_t new_length) {
  if (cobject == nullptr) return;
  ASSERT(cobject->type == Dart_CObject_kExternalTypedData);

  const auto old_data = cobject->value.as_external_typed_data.data;
  const auto old_length = cobject->value.as_external_typed_data.length;

  // We only shrink IOBuffers, never grow them.
  ASSERT(0 <= new_length && new_length <= old_length);

  // We only reallocate if we think the freed space is worth reallocating.
  // We consider it worthwhile when freed space is >=25% and we have at
  // least 100 free bytes.
  const auto free_memory = old_length - new_length;
  if ((old_length >> 2) <= free_memory && 100 <= free_memory) {
    const auto new_data = IOBuffer::Reallocate(old_data, new_length);
    if (new_data != nullptr) {
      cobject->value.as_external_typed_data.data = new_data;
      cobject->value.as_external_typed_data.peer = new_data;
    }
  }

  // The typed data object always has to have the shranken length.
  cobject->value.as_external_typed_data.length = new_length;
}

void CObject::FreeIOBufferData(Dart_CObject* cobject) {
  ASSERT(cobject->type == Dart_CObject_kExternalTypedData);
  cobject->value.as_external_typed_data.callback(
      nullptr, cobject->value.as_external_typed_data.peer);
  cobject->value.as_external_typed_data.data = nullptr;
}

CObject* CObject::IllegalArgumentError() {
  CObjectArray* result = new CObjectArray(CObject::NewArray(1));
  result->SetAt(0, new CObjectInt32(CObject::NewInt32(kArgumentError)));
  return result;
}

CObject* CObject::FileClosedError() {
  CObjectArray* result = new CObjectArray(CObject::NewArray(1));
  result->SetAt(0, new CObjectInt32(CObject::NewInt32(kFileClosedError)));
  return result;
}

CObject* CObject::NewOSError() {
  OSError os_error;
  return NewOSError(&os_error);
}

CObject* CObject::NewOSError(OSError* os_error) {
  CObject* error_message =
      new CObjectString(CObject::NewString(os_error->message()));
  CObjectArray* result = new CObjectArray(CObject::NewArray(3));
  result->SetAt(0, new CObjectInt32(CObject::NewInt32(kOSError)));
  result->SetAt(1, new CObjectInt32(CObject::NewInt32(os_error->code())));
  result->SetAt(2, error_message);
  return result;
}

}  // namespace bin
}  // namespace dart
