// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

#include "bin/crypto.h"
#include "bin/directory.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/io_buffer.h"
#include "bin/platform.h"
#include "bin/utils.h"

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "include/dart_tools_api.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/memory_sanitizer.h"

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

const char* DartUtils::original_working_directory = NULL;
CommandLineOptions* DartUtils::url_mapping = NULL;
const char* const DartUtils::kDartScheme = "dart:";
const char* const DartUtils::kDartExtensionScheme = "dart-ext:";
const char* const DartUtils::kAsyncLibURL = "dart:async";
const char* const DartUtils::kBuiltinLibURL = "dart:_builtin";
const char* const DartUtils::kCoreLibURL = "dart:core";
const char* const DartUtils::kInternalLibURL = "dart:_internal";
const char* const DartUtils::kIsolateLibURL = "dart:isolate";
const char* const DartUtils::kIOLibURL = "dart:io";
const char* const DartUtils::kIOLibPatchURL = "dart:io-patch";
const char* const DartUtils::kUriLibURL = "dart:uri";
const char* const DartUtils::kHttpScheme = "http:";
const char* const DartUtils::kVMServiceLibURL = "dart:vmservice";

struct MagicNumberData {
  static const intptr_t kLength = 4;

  const uint8_t bytes[kLength];
  bool should_skip;
};

MagicNumberData snapshot_magic_number = {{0xf5, 0xf5, 0xdc, 0xdc}, true};
MagicNumberData kernel_magic_number = {{0x90, 0xab, 0xcd, 0xef}, false};

static bool IsWindowsHost() {
#if defined(HOST_OS_WINDOWS)
  return true;
#else   // defined(HOST_OS_WINDOWS)
  return false;
#endif  // defined(HOST_OS_WINDOWS)
}

const char* DartUtils::MapLibraryUrl(const char* url_string) {
  ASSERT(url_mapping != NULL);
  // We need to check if the passed in url is found in the url_mapping array,
  // in that case use the mapped entry.
  intptr_t len = strlen(url_string);
  for (intptr_t idx = 0; idx < url_mapping->count(); idx++) {
    const char* url_name = url_mapping->GetArgument(idx);
    if (!strncmp(url_string, url_name, len) && (url_name[len] == ',')) {
      const char* url_mapped_name = url_name + len + 1;
      if (strlen(url_mapped_name) != 0) {
        return url_mapped_name;  // Found a mapping for this URL.
      }
    }
  }
  return NULL;  // Did not find a mapping for this URL.
}

int64_t DartUtils::GetIntegerValue(Dart_Handle value_obj) {
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, &value);
  if (Dart_IsError(result)) Dart_PropagateError(result);
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
  if (Dart_IsError(result)) Dart_PropagateError(result);
  if (value < kIntptrMin || kIntptrMax < value) {
    Dart_PropagateError(Dart_NewApiError("Value outside intptr_t range"));
  }
  return static_cast<intptr_t>(value);
}

bool DartUtils::GetInt64Value(Dart_Handle value_obj, int64_t* value) {
  bool valid = Dart_IsInteger(value_obj);
  if (valid) {
    Dart_Handle result = Dart_IntegerFitsIntoInt64(value_obj, &valid);
    if (Dart_IsError(result)) Dart_PropagateError(result);
  }
  if (!valid) return false;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, value);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  return true;
}

const char* DartUtils::GetStringValue(Dart_Handle str_obj) {
  const char* cstring = NULL;
  Dart_Handle result = Dart_StringToCString(str_obj, &cstring);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  return cstring;
}

bool DartUtils::GetBooleanValue(Dart_Handle bool_obj) {
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(bool_obj, &value);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  return value;
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

bool DartUtils::IsDartExtensionSchemeURL(const char* url_name) {
  static const intptr_t kDartExtensionSchemeLen = strlen(kDartExtensionScheme);
  // If the URL starts with "dartext:" then it is considered as a special
  // extension library URL which is handled differently from other URLs.
  return (strncmp(url_name, kDartExtensionScheme, kDartExtensionSchemeLen) ==
          0);
}

bool DartUtils::IsDartIOLibURL(const char* url_name) {
  return (strcmp(url_name, kIOLibURL) == 0);
}

bool DartUtils::IsDartBuiltinLibURL(const char* url_name) {
  return (strcmp(url_name, kBuiltinLibURL) == 0);
}

const char* DartUtils::RemoveScheme(const char* url) {
  const char* colon = strchr(url, ':');
  if (colon == NULL) {
    return url;
  } else {
    return colon + 1;
  }
}

char* DartUtils::DirName(const char* url) {
  const char* slash = strrchr(url, File::PathSeparator()[0]);
  if (slash == NULL) {
    return strdup(url);
  } else {
    return StringUtils::StrNDup(url, slash - url + 1);
  }
}

void* DartUtils::OpenFile(const char* name, bool write) {
  File* file = File::Open(name, write ? File::kWriteTruncate : File::kRead);
  return reinterpret_cast<void*>(file);
}

void DartUtils::ReadFile(const uint8_t** data, intptr_t* len, void* stream) {
  ASSERT(data != NULL);
  ASSERT(len != NULL);
  ASSERT(stream != NULL);
  File* file_stream = reinterpret_cast<File*>(stream);
  int64_t file_len = file_stream->Length();
  if ((file_len < 0) || (file_len > kIntptrMax)) {
    *data = NULL;
    *len = -1;  // Indicates read was not successful.
    return;
  }
  *len = static_cast<intptr_t>(file_len);
  uint8_t* text_buffer = reinterpret_cast<uint8_t*>(malloc(*len));
  ASSERT(text_buffer != NULL);
  if (!file_stream->ReadFully(text_buffer, *len)) {
    *data = NULL;
    *len = -1;  // Indicates read was not successful.
    return;
  }
  *data = text_buffer;
}

void DartUtils::WriteFile(const void* buffer,
                          intptr_t num_bytes,
                          void* stream) {
  ASSERT(stream != NULL);
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
  intptr_t len = snprintf(NULL, 0, format, __VA_ARGS__);                       \
  char* msg = reinterpret_cast<char*>(malloc(len + 1));                        \
  snprintf(msg, len + 1, format, __VA_ARGS__);                                 \
  *error_msg = msg

static const uint8_t* ReadFileFully(const char* filename,
                                    intptr_t* file_len,
                                    const char** error_msg) {
  *file_len = -1;
  void* stream = DartUtils::OpenFile(filename, false);
  if (stream == NULL) {
    SET_ERROR_MSG(error_msg, "Unable to open file: %s", filename);
    return NULL;
  }
  const uint8_t* text_buffer = NULL;
  DartUtils::ReadFile(&text_buffer, file_len, stream);
  if (text_buffer == NULL || *file_len == -1) {
    *error_msg = "Unable to read file contents";
    text_buffer = NULL;
  }
  DartUtils::CloseFile(stream);
  return text_buffer;
}

Dart_Handle DartUtils::ReadStringFromFile(const char* filename) {
  const char* error_msg = NULL;
  intptr_t len;
  const uint8_t* text_buffer = ReadFileFully(filename, &len, &error_msg);
  if (text_buffer == NULL) {
    return Dart_NewApiError(error_msg);
  }
  Dart_Handle str = Dart_NewStringFromUTF8(text_buffer, len);
  free(const_cast<uint8_t*>(text_buffer));
  return str;
}

Dart_Handle DartUtils::MakeUint8Array(const uint8_t* buffer, intptr_t len) {
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
    ASSERT(td_data != NULL);
    memmove(td_data, buffer, td_len);
    result = Dart_TypedDataReleaseData(array);
    RETURN_IF_ERROR(result);
  }
  return array;
}

Dart_Handle DartUtils::SetWorkingDirectory() {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  Dart_Handle builtin_lib = isolate_data->builtin_lib();
  Dart_Handle directory = NewString(original_working_directory);
  return SingleArgDart_Invoke(builtin_lib, "_setWorkingDirectory", directory);
}

Dart_Handle DartUtils::ResolveUriInWorkingDirectory(Dart_Handle script_uri) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = script_uri;
  return Dart_Invoke(DartUtils::BuiltinLib(),
                     NewString("_resolveInWorkingDirectory"), kNumArgs,
                     dart_args);
}

Dart_Handle DartUtils::LibraryFilePath(Dart_Handle library_uri) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = library_uri;
  return Dart_Invoke(DartUtils::BuiltinLib(), NewString("_libraryFilePath"),
                     kNumArgs, dart_args);
}

Dart_Handle DartUtils::ResolveScript(Dart_Handle url) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = url;
  return Dart_Invoke(DartUtils::BuiltinLib(), NewString("_resolveScriptUri"),
                     kNumArgs, dart_args);
}

static Dart_Handle LoadDataAsync_Invoke(Dart_Handle tag,
                                        Dart_Handle url,
                                        Dart_Handle library_url) {
  const int kNumArgs = 3;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = tag;
  dart_args[1] = url;
  dart_args[2] = library_url;
  return Dart_Invoke(DartUtils::BuiltinLib(),
                     DartUtils::NewString("_loadDataAsync"), kNumArgs,
                     dart_args);
}

Dart_Handle DartUtils::LibraryTagHandler(Dart_LibraryTag tag,
                                         Dart_Handle library,
                                         Dart_Handle url) {
  Dart_Handle library_url = Dart_LibraryUrl(library);
  if (Dart_IsError(library_url)) {
    return library_url;
  }
  if (tag == Dart_kCanonicalizeUrl) {
    return Dart_DefaultCanonicalizeUrl(library_url, url);
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  const char* library_url_string = NULL;
  result = Dart_StringToCString(library_url, &library_url_string);
  if (Dart_IsError(result)) {
    return result;
  }

  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
  bool is_dart_library = DartUtils::IsDartSchemeURL(library_url_string);

  // Handle canonicalization, 'import' and 'part' of 'dart:' libraries.
  if (is_dart_scheme_url || is_dart_library) {
    if (tag == Dart_kImportTag) {
      Builtin::BuiltinLibraryId id = Builtin::FindId(url_string);
      if (id == Builtin::kInvalidLibrary) {
        return NewError(
            "The built-in library '%s' is not available"
            " on the stand-alone VM.\n",
            url_string);
      }
      return Builtin::LoadLibrary(url, id);
    } else {
      ASSERT(tag == Dart_kSourceTag);
      Builtin::BuiltinLibraryId id = Builtin::FindId(library_url_string);
      if (id == Builtin::kInvalidLibrary) {
        return NewError(
            "The built-in library '%s' is not available"
            " on the stand-alone VM. Trying to load"
            " '%s'.\n",
            library_url_string, url_string);
      }
      // Prepend the library URI to form a unique script URI for the part.
      intptr_t len = snprintf(NULL, 0, "%s/%s", library_url_string, url_string);
      char* part_uri = reinterpret_cast<char*>(malloc(len + 1));
      snprintf(part_uri, len + 1, "%s/%s", library_url_string, url_string);
      Dart_Handle part_uri_obj = DartUtils::NewString(part_uri);
      free(part_uri);
      return Dart_LoadSource(library, part_uri_obj, Dart_Null(),
                             Builtin::PartSource(id, url_string), 0, 0);
    }
    // All cases should have been handled above.
    UNREACHABLE();
  }

  if (DartUtils::IsDartExtensionSchemeURL(url_string)) {
    // Load a native code shared library to use in a native extension
    if (tag != Dart_kImportTag) {
      return NewError("Dart extensions must use import: '%s'", url_string);
    }
    Dart_Handle library_file_path = DartUtils::LibraryFilePath(library_url);
    const char* lib_path_str = NULL;
    Dart_StringToCString(library_file_path, &lib_path_str);
    const char* extension_path = DartUtils::RemoveScheme(url_string);
    if (strchr(extension_path, '/') != NULL ||
        (IsWindowsHost() && strchr(extension_path, '\\') != NULL)) {
      return NewError(
          "Relative paths for dart extensions are not supported: '%s'",
          extension_path);
    }
    return Extensions::LoadExtension(lib_path_str, extension_path, library);
  }

  // Handle 'import' or 'part' requests for all other URIs. Call dart code to
  // read the source code asynchronously.
  return LoadDataAsync_Invoke(Dart_NewInteger(tag), url, library_url);
}

static bool CheckMagicNumber(const uint8_t** buf,
                             intptr_t* len,
                             const MagicNumberData& magic_number) {
  if ((*len >= MagicNumberData::kLength) &&
      (memcmp(*buf, magic_number.bytes, MagicNumberData::kLength) == 0)) {
    if (magic_number.should_skip) {
      *buf += MagicNumberData::kLength;
      *len -= MagicNumberData::kLength;
    }
    return true;
  }
  return false;
}

DartUtils::MagicNumber DartUtils::SniffForMagicNumber(const uint8_t** buf,
                                                      intptr_t* len) {
  if (CheckMagicNumber(buf, len, snapshot_magic_number)) {
    return kSnapshotMagicNumber;
  }

  if (CheckMagicNumber(buf, len, kernel_magic_number)) {
    return kKernelMagicNumber;
  }

  return kUnknownMagicNumber;
}

void DartUtils::WriteMagicNumber(File* file) {
  // Write a magic number and version information into the snapshot file.
  bool bytes_written =
      file->WriteFully(snapshot_magic_number.bytes, MagicNumberData::kLength);
  ASSERT(bytes_written);
}

Dart_Handle DartUtils::LoadScript(const char* script_uri) {
  Dart_TimelineEvent("LoadScript", Dart_TimelineGetMicros(),
                     Dart_GetMainPortId(), Dart_Timeline_Event_Async_Begin, 0,
                     NULL, NULL);
  Dart_Handle uri = Dart_NewStringFromCString(script_uri);
  return LoadDataAsync_Invoke(Dart_Null(), uri, Dart_Null());
}

void FUNCTION_NAME(Builtin_GetCurrentDirectory)(Dart_NativeArguments args) {
  const char* current = Directory::Current();
  if (current != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(current));
  } else {
    Dart_Handle err = DartUtils::NewError("Failed to get current directory.");
    Dart_PropagateError(err);
  }
}

Dart_Handle DartUtils::PrepareBuiltinLibrary(Dart_Handle builtin_lib,
                                             Dart_Handle internal_lib,
                                             bool is_service_isolate,
                                             bool trace_loading) {
  // Setup the internal library's 'internalPrint' function.
  Dart_Handle print =
      Dart_Invoke(builtin_lib, NewString("_getPrintClosure"), 0, NULL);
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
                                          Dart_Handle builtin_lib,
                                          bool is_service_isolate) {
  if (!is_service_isolate) {
    // Setup the 'Uri.base' getter in dart:core.
    Dart_Handle uri_base =
        Dart_Invoke(builtin_lib, NewString("_getUriBaseClosure"), 0, NULL);
    RETURN_IF_ERROR(uri_base);
    Dart_Handle result =
        Dart_SetField(core_lib, NewString("_uriBaseClosure"), uri_base);
    RETURN_IF_ERROR(result);
  }
  return Dart_True();
}

Dart_Handle DartUtils::PrepareAsyncLibrary(Dart_Handle async_lib,
                                           Dart_Handle isolate_lib) {
  Dart_Handle schedule_immediate_closure = Dart_Invoke(
      isolate_lib, NewString("_getIsolateScheduleImmediateClosure"), 0, NULL);
  RETURN_IF_ERROR(schedule_immediate_closure);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  return Dart_Invoke(async_lib, NewString("_setScheduleImmediateClosure"), 1,
                     args);
}

Dart_Handle DartUtils::PrepareIOLibrary(Dart_Handle io_lib) {
  return Dart_Invoke(io_lib, NewString("_setupHooks"), 0, NULL);
}

Dart_Handle DartUtils::PrepareIsolateLibrary(Dart_Handle isolate_lib) {
  return Dart_Invoke(isolate_lib, NewString("_setupHooks"), 0, NULL);
}

Dart_Handle DartUtils::SetupServiceLoadPort() {
  // Wait for the service isolate to initialize the load port.
  Dart_Port load_port = Dart_ServiceWaitForLoadPort();
  if (load_port == ILLEGAL_PORT) {
    return Dart_NewUnhandledExceptionError(
        NewDartUnsupportedError("Service did not return load port."));
  }
  return Builtin::SetLoadPort(load_port);
}

Dart_Handle DartUtils::SetupPackageRoot(const char* package_root,
                                        const char* packages_config) {
  // Set up package root if specified.
  if (package_root != NULL) {
    ASSERT(packages_config == NULL);
    Dart_Handle result = NewString(package_root);
    RETURN_IF_ERROR(result);
    const int kNumArgs = 1;
    Dart_Handle dart_args[kNumArgs];
    dart_args[0] = result;
    result = Dart_Invoke(DartUtils::BuiltinLib(), NewString("_setPackageRoot"),
                         kNumArgs, dart_args);
    RETURN_IF_ERROR(result);
  } else if (packages_config != NULL) {
    Dart_Handle result = NewString(packages_config);
    RETURN_IF_ERROR(result);
    const int kNumArgs = 1;
    Dart_Handle dart_args[kNumArgs];
    dart_args[0] = result;
    result = Dart_Invoke(DartUtils::BuiltinLib(), NewString("_setPackagesMap"),
                         kNumArgs, dart_args);
    RETURN_IF_ERROR(result);
  }
  return Dart_True();
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

  // Setup the builtin library in a persistent handle attached the isolate
  // specific data as we seem to lookup and use builtin lib a lot.
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  isolate_data->set_builtin_lib(builtin_lib);

  // We need to ensure that all the scripts loaded so far are finalized
  // as we are about to invoke some Dart code below to setup closures.
  Dart_Handle result = Dart_FinalizeLoading(false);
  RETURN_IF_ERROR(result);

  result = PrepareBuiltinLibrary(builtin_lib, internal_lib, is_service_isolate,
                                 trace_loading);
  RETURN_IF_ERROR(result);

  RETURN_IF_ERROR(PrepareAsyncLibrary(async_lib, isolate_lib));
  RETURN_IF_ERROR(
      PrepareCoreLibrary(core_lib, builtin_lib, is_service_isolate));
  RETURN_IF_ERROR(PrepareIsolateLibrary(isolate_lib));
  RETURN_IF_ERROR(PrepareIOLibrary(io_lib));
  return result;
}

Dart_Handle DartUtils::SetupIOLibrary(const char* script_uri) {
  Dart_Handle io_lib_url = NewString(kIOLibURL);
  RETURN_IF_ERROR(io_lib_url);
  Dart_Handle io_lib = Dart_LookupLibrary(io_lib_url);
  RETURN_IF_ERROR(io_lib);
  Dart_Handle platform_type = GetDartType(DartUtils::kIOLibURL, "_Platform");
  RETURN_IF_ERROR(platform_type);
  Dart_Handle script_name = NewString("_nativeScript");
  RETURN_IF_ERROR(script_name);
  Dart_Handle dart_script = NewString(script_uri);
  RETURN_IF_ERROR(dart_script);
  Dart_Handle set_script_name =
      Dart_SetField(platform_type, script_name, dart_script);
  RETURN_IF_ERROR(set_script_name);
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

Dart_Handle DartUtils::GetDartType(const char* library_url,
                                   const char* class_name) {
  return Dart_GetType(Dart_LookupLibrary(NewString(library_url)),
                      NewString(class_name), 0, NULL);
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
  if (message != NULL) {
    Dart_Handle args[1];
    args[0] = NewString(message);
    return Dart_New(type, Dart_Null(), 1, args);
  } else {
    return Dart_New(type, Dart_Null(), 0, NULL);
  }
}

Dart_Handle DartUtils::NewDartArgumentError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "ArgumentError", message);
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
  va_list args;
  va_start(args, format);
  intptr_t len = vsnprintf(NULL, 0, format, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(Dart_ScopeAllocate(len + 1));
  MSAN_UNPOISON(buffer, (len + 1));
  va_list args2;
  va_start(args2, format);
  vsnprintf(buffer, (len + 1), format, args2);
  va_end(args2);

  return Dart_NewApiError(buffer);
}

Dart_Handle DartUtils::NewInternalError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "_InternalError", message);
}

bool DartUtils::SetOriginalWorkingDirectory() {
  original_working_directory = Directory::CurrentNoScope();
  return original_working_directory != NULL;
}

Dart_Handle DartUtils::GetCanonicalizableWorkingDirectory() {
  const char* str = DartUtils::original_working_directory;
  intptr_t len = strlen(str);
  if ((str[len] == '/') || (IsWindowsHost() && str[len] == '\\')) {
    return Dart_NewStringFromCString(str);
  }
  char* new_str = reinterpret_cast<char*>(Dart_ScopeAllocate(len + 2));
  snprintf(new_str, (len + 2), "%s%s", str, File::PathSeparator());
  return Dart_NewStringFromCString(new_str);
}

// Statically allocated Dart_CObject instances for immutable
// objects. As these will be used by different threads the use of
// these depends on the fact that the marking internally in the
// Dart_CObject structure is not marking simple value objects.
Dart_CObject CObject::api_null_ = {Dart_CObject_kNull, {0}};
Dart_CObject CObject::api_true_ = {Dart_CObject_kBool, {true}};
Dart_CObject CObject::api_false_ = {Dart_CObject_kBool, {false}};
CObject CObject::null_ = CObject(&api_null_);
CObject CObject::true_ = CObject(&api_true_);
CObject CObject::false_ = CObject(&api_false_);

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

static bool IsHexDigit(char c) {
  return (('0' <= c) && (c <= '9')) || (('A' <= c) && (c <= 'F')) ||
         (('a' <= c) && (c <= 'f'));
}

static int HexDigitToInt(char c) {
  if (('0' <= c) && (c <= '9')) return c - '0';
  if (('A' <= c) && (c <= 'F')) return 10 + (c - 'A');
  return 10 + (c - 'a');
}

Dart_CObject* CObject::NewBigint(const char* hex_value) {
  if (hex_value == NULL) {
    return NULL;
  }
  bool neg = false;
  if (hex_value[0] == '-') {
    neg = true;
    hex_value++;
  }
  if ((hex_value[0] != '0') ||
      ((hex_value[1] != 'x') && (hex_value[1] != 'X'))) {
    return NULL;
  }
  hex_value += 2;
  intptr_t hex_i = strlen(hex_value);  // Terminating byte excluded.
  if (hex_i == 0) {
    return NULL;
  }
  const int kBitsPerHexDigit = 4;
  const int kHexDigitsPerDigit = 8;
  const int kBitsPerDigit = kBitsPerHexDigit * kHexDigitsPerDigit;
  const intptr_t len = (hex_i + kHexDigitsPerDigit - 1) / kHexDigitsPerDigit;
  Dart_CObject* cobject = New(Dart_CObject_kBigint);
  cobject->value.as_bigint.digits = NewUint32Array(len);
  uint32_t* digits = reinterpret_cast<uint32_t*>(
      cobject->value.as_bigint.digits->value.as_typed_data.values);
  intptr_t used = 0;
  uint32_t digit = 0;
  intptr_t bit_i = 0;
  while (--hex_i >= 0) {
    if (!IsHexDigit(hex_value[hex_i])) {
      return NULL;
    }
    digit += HexDigitToInt(hex_value[hex_i]) << bit_i;
    bit_i += kBitsPerHexDigit;
    if (bit_i == kBitsPerDigit) {
      bit_i = 0;
      digits[used++] = digit;
      digit = 0;
    }
  }
  if (bit_i != 0) {
    digits[used++] = digit;
  }
  while ((used > 0) && (digits[used - 1] == 0)) {
    used--;
  }
  cobject->value.as_bigint.used = used;
  if (used == 0) {
    neg = false;
  }
  cobject->value.as_bigint.neg = neg;
  return cobject;
}

static char IntToHexDigit(int i) {
  ASSERT(0 <= i && i < 16);
  if (i < 10) return static_cast<char>('0' + i);
  return static_cast<char>('A' + (i - 10));
}

char* CObject::BigintToHexValue(Dart_CObject* bigint) {
  ASSERT(bigint->type == Dart_CObject_kBigint);
  const intptr_t used = bigint->value.as_bigint.used;
  if (used == 0) {
    const char* zero = "0x0";
    const size_t len = strlen(zero) + 1;
    char* hex_value = reinterpret_cast<char*>(malloc(len));
    strncpy(hex_value, zero, len);
    return hex_value;
  }
  const int kBitsPerHexDigit = 4;
  const int kHexDigitsPerDigit = 8;
  const intptr_t kMaxUsed = (kIntptrMax - 4) / kHexDigitsPerDigit;
  if (used > kMaxUsed) {
    return NULL;
  }
  intptr_t hex_len = (used - 1) * kHexDigitsPerDigit;
  const uint32_t* digits = reinterpret_cast<uint32_t*>(
      bigint->value.as_bigint.digits->value.as_typed_data.values);
  // The most significant digit may use fewer than kHexDigitsPerDigit digits.
  uint32_t digit = digits[used - 1];
  ASSERT(digit != 0);  // Value must be clamped.
  while (digit != 0) {
    hex_len++;
    digit >>= kBitsPerHexDigit;
  }
  const bool neg = bigint->value.as_bigint.neg;
  // Add bytes for '0x', for the minus sign, and for the trailing \0 character.
  const int32_t len = (neg ? 1 : 0) + 2 + hex_len + 1;
  char* hex_value = reinterpret_cast<char*>(malloc(len));
  intptr_t pos = len;
  hex_value[--pos] = '\0';
  for (intptr_t i = 0; i < (used - 1); i++) {
    digit = digits[i];
    for (intptr_t j = 0; j < kHexDigitsPerDigit; j++) {
      hex_value[--pos] = IntToHexDigit(digit & 0xf);
      digit >>= kBitsPerHexDigit;
    }
  }
  digit = digits[used - 1];
  while (digit != 0) {
    hex_value[--pos] = IntToHexDigit(digit & 0xf);
    digit >>= kBitsPerHexDigit;
  }
  hex_value[--pos] = 'x';
  hex_value[--pos] = '0';
  if (neg) {
    hex_value[--pos] = '-';
  }
  ASSERT(pos == 0);
  return hex_value;
}

Dart_CObject* CObject::NewDouble(double value) {
  Dart_CObject* cobject = New(Dart_CObject_kDouble);
  cobject->value.as_double = value;
  return cobject;
}

Dart_CObject* CObject::NewString(intptr_t length) {
  Dart_CObject* cobject = New(Dart_CObject_kString, length + 1);
  cobject->value.as_string = reinterpret_cast<char*>(cobject + 1);
  return cobject;
}

Dart_CObject* CObject::NewString(const char* str) {
  intptr_t length = strlen(str);
  Dart_CObject* cobject = NewString(length);
  memmove(cobject->value.as_string, str, length + 1);
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

Dart_CObject* CObject::NewUint8Array(intptr_t length) {
  Dart_CObject* cobject = New(Dart_CObject_kTypedData, length);
  cobject->value.as_typed_data.type = Dart_TypedData_kUint8;
  cobject->value.as_typed_data.length = length;
  cobject->value.as_typed_data.values = reinterpret_cast<uint8_t*>(cobject + 1);
  return cobject;
}

Dart_CObject* CObject::NewUint32Array(intptr_t length) {
  Dart_CObject* cobject = New(Dart_CObject_kTypedData, 4 * length);
  cobject->value.as_typed_data.type = Dart_TypedData_kUint32;
  cobject->value.as_typed_data.length = length;
  cobject->value.as_typed_data.values = reinterpret_cast<uint8_t*>(cobject + 1);
  return cobject;
}

Dart_CObject* CObject::NewExternalUint8Array(
    intptr_t length,
    uint8_t* data,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  Dart_CObject* cobject = New(Dart_CObject_kExternalTypedData);
  cobject->value.as_external_typed_data.type = Dart_TypedData_kUint8;
  cobject->value.as_external_typed_data.length = length;
  cobject->value.as_external_typed_data.data = data;
  cobject->value.as_external_typed_data.peer = peer;
  cobject->value.as_external_typed_data.callback = callback;
  return cobject;
}

Dart_CObject* CObject::NewIOBuffer(int64_t length) {
  // Make sure that we do not have an integer overflow here. Actual check
  // against max elements will be done at the time of writing, as the constant
  // is not part of the public API.
  if ((length < 0) || (length > kIntptrMax)) {
    return NULL;
  }
  uint8_t* data = IOBuffer::Allocate(static_cast<intptr_t>(length));
  ASSERT(data != NULL);
  return NewExternalUint8Array(static_cast<intptr_t>(length), data, data,
                               IOBuffer::Finalizer);
}

void CObject::FreeIOBufferData(Dart_CObject* cobject) {
  ASSERT(cobject->type == Dart_CObject_kExternalTypedData);
  cobject->value.as_external_typed_data.callback(
      NULL, NULL, cobject->value.as_external_typed_data.peer);
  cobject->value.as_external_typed_data.data = NULL;
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
