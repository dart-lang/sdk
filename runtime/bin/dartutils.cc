// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

#include "bin/extensions.h"
#include "bin/directory.h"
#include "bin/file.h"
#include "bin/io_buffer.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

const char* DartUtils::original_working_directory = NULL;
const char* DartUtils::kDartScheme = "dart:";
const char* DartUtils::kDartExtensionScheme = "dart-ext:";
const char* DartUtils::kAsyncLibURL = "dart:async";
const char* DartUtils::kBuiltinLibURL = "dart:builtin";
const char* DartUtils::kCoreLibURL = "dart:core";
const char* DartUtils::kIOLibURL = "dart:io";
const char* DartUtils::kIOLibPatchURL = "dart:io-patch";
const char* DartUtils::kUriLibURL = "dart:uri";
const char* DartUtils::kUtfLibURL = "dart:utf";

const char* DartUtils::kIdFieldName = "_id";

uint8_t DartUtils::magic_number[] = { 0xf5, 0xf5, 0xdc, 0xdc };

static bool IsWindowsHost() {
#if defined(TARGET_OS_WINDOWS)
  return true;
#else  // defined(TARGET_OS_WINDOWS)
  return false;
#endif  // defined(TARGET_OS_WINDOWS)
}


const char* DartUtils::MapLibraryUrl(CommandLineOptions* url_mapping,
                                     const char* url_string) {
  ASSERT(url_mapping != NULL);
  // We need to check if the passed in url is found in the url_mapping array,
  // in that case use the mapped entry.
  int len = strlen(url_string);
  for (int idx = 0; idx < url_mapping->count(); idx++) {
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
  ASSERT(Dart_IsInteger(value_obj));
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, &value);
  ASSERT(!Dart_IsError(result));
  return value;
}


intptr_t DartUtils::GetIntptrValue(Dart_Handle value_obj) {
  ASSERT(Dart_IsInteger(value_obj));
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, &value);
  ASSERT(!Dart_IsError(result));
  return static_cast<intptr_t>(value);
}


bool DartUtils::GetInt64Value(Dart_Handle value_obj, int64_t* value) {
  bool valid = Dart_IsInteger(value_obj);
  if (valid) {
    Dart_Handle result = Dart_IntegerFitsIntoInt64(value_obj, &valid);
    ASSERT(!Dart_IsError(result));
  }
  if (!valid) return false;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, value);
  ASSERT(!Dart_IsError(result));
  return true;
}


const char* DartUtils::GetStringValue(Dart_Handle str_obj) {
  const char* cstring = NULL;
  Dart_Handle result = Dart_StringToCString(str_obj, &cstring);
  ASSERT(!Dart_IsError(result));
  return cstring;
}


bool DartUtils::GetBooleanValue(Dart_Handle bool_obj) {
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(bool_obj, &value);
  ASSERT(!Dart_IsError(result));
  return value;
}


void DartUtils::SetIntegerField(Dart_Handle handle,
                                const char* name,
                                intptr_t val) {
  Dart_Handle result = Dart_SetField(handle,
                                     NewString(name),
                                     Dart_NewInteger(val));
  ASSERT(!Dart_IsError(result));
}


intptr_t DartUtils::GetIntegerField(Dart_Handle handle,
                                    const char* name) {
  Dart_Handle result = Dart_GetField(handle, NewString(name));
  ASSERT(!Dart_IsError(result));
  intptr_t value = DartUtils::GetIntegerValue(result);
  return value;
}


void DartUtils::SetStringField(Dart_Handle handle,
                               const char* name,
                               const char* val) {
  Dart_Handle result = Dart_SetField(handle, NewString(name), NewString(val));
  ASSERT(!Dart_IsError(result));
}


bool DartUtils::IsDartSchemeURL(const char* url_name) {
  static const intptr_t kDartSchemeLen = strlen(kDartScheme);
  // If the URL starts with "dart:" then it is considered as a special
  // library URL which is handled differently from other URLs.
  return (strncmp(url_name, kDartScheme, kDartSchemeLen) == 0);
}


bool DartUtils::IsDartExtensionSchemeURL(const char* url_name) {
  static const intptr_t kDartExtensionSchemeLen = strlen(kDartExtensionScheme);
  // If the URL starts with "dartext:" then it is considered as a special
  // extension library URL which is handled differently from other URLs.
  return
      (strncmp(url_name, kDartExtensionScheme, kDartExtensionSchemeLen) == 0);
}


bool DartUtils::IsDartIOLibURL(const char* url_name) {
  return (strcmp(url_name, kIOLibURL) == 0);
}


bool DartUtils::IsDartBuiltinLibURL(const char* url_name) {
  return (strcmp(url_name, kBuiltinLibURL) == 0);
}


Dart_Handle DartUtils::CanonicalizeURL(CommandLineOptions* url_mapping,
                                       Dart_Handle library,
                                       const char* url_str) {
  // Get the url of the including library.
  Dart_Handle library_url = Dart_LibraryUrl(library);
  if (Dart_IsError(library_url)) {
    return Dart_Error("accessing library url failed");
  }
  if (!Dart_IsString(library_url)) {
    return Dart_Error("library url is not a string");
  }
  const char* library_url_str = NULL;
  Dart_Handle result = Dart_StringToCString(library_url, &library_url_str);
  if (Dart_IsError(result)) {
    return Dart_Error("accessing library url characters failed");
  }
  if (url_mapping != NULL) {
    const char* mapped_library_url_str = MapLibraryUrl(url_mapping,
                                                       library_url_str);
    if (mapped_library_url_str != NULL) {
      library_url_str = mapped_library_url_str;
    }
  }
  // Calculate the canonical path.
  const char* canon_url_str = GetCanonicalPath(library_url_str, url_str);
  Dart_Handle canon_url = NewString(canon_url_str);
  free(const_cast<char*>(canon_url_str));

  return canon_url;
}


static const uint8_t* ReadFile(const char* filename,
                               intptr_t* file_len,
                               const char** error_msg) {
  File* file = File::Open(filename, File::kRead);
  if (file == NULL) {
    const char* format = "Unable to open file: %s";
    intptr_t len = snprintf(NULL, 0, format, filename);
    // TODO(iposva): Allocate from the zone instead of leaking error string
    // here. On the other hand the binary is about the exit anyway.
    char* msg = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(msg, len + 1, format, filename);
    *error_msg = msg;
    return NULL;
  }
  *file_len = file->Length();
  uint8_t* text_buffer = reinterpret_cast<uint8_t*>(malloc(*file_len));
  if (text_buffer == NULL) {
    delete file;
    *error_msg = "Unable to allocate buffer";
    return NULL;
  }
  if (!file->ReadFully(text_buffer, *file_len)) {
    delete file;
    free(text_buffer);
    *error_msg = "Unable to fully read contents";
    return NULL;
  }
  delete file;
  return text_buffer;
}


Dart_Handle DartUtils::ReadStringFromFile(const char* filename) {
  const char* error_msg = NULL;
  intptr_t len;
  const uint8_t* text_buffer = ReadFile(filename, &len, &error_msg);
  if (text_buffer == NULL) {
    return Dart_Error(error_msg);
  }
  Dart_Handle str = Dart_NewStringFromUTF8(text_buffer, len);
  return str;
}


Dart_Handle DartUtils::ResolveScriptUri(Dart_Handle script_uri,
                                        Dart_Handle builtin_lib) {
  const int kNumArgs = 3;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = NewString(original_working_directory);
  dart_args[1] = script_uri;
  dart_args[2] = (IsWindowsHost() ? Dart_True() : Dart_False());
  return Dart_Invoke(builtin_lib,
                     NewString("_resolveScriptUri"),
                     kNumArgs,
                     dart_args);
}


Dart_Handle DartUtils::FilePathFromUri(Dart_Handle script_uri,
                                       Dart_Handle builtin_lib) {
  const int kNumArgs = 2;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = script_uri;
  dart_args[1] = (IsWindowsHost() ? Dart_True() : Dart_False());
  return Dart_Invoke(builtin_lib,
                     NewString("_filePathFromUri"),
                     kNumArgs,
                     dart_args);
}


Dart_Handle DartUtils::ResolveUri(Dart_Handle library_url,
                                  Dart_Handle url,
                                  Dart_Handle builtin_lib) {
  const int kNumArgs = 2;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = library_url;
  dart_args[1] = url;
  return Dart_Invoke(
      builtin_lib, NewString("_resolveUri"), kNumArgs, dart_args);
}


Dart_Handle DartUtils::LibraryTagHandler(Dart_LibraryTag tag,
                                         Dart_Handle library,
                                         Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
  bool is_dart_extension_url = DartUtils::IsDartExtensionSchemeURL(url_string);
  if (tag == kCanonicalizeUrl) {
    // If this is a Dart Scheme URL then it is not modified as it will be
    // handled by the VM internally.
    if (is_dart_scheme_url) {
      return url;
    }
    // Resolve the url within the context of the library's URL.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    return ResolveUri(library_url, url, builtin_lib);
  }
  if (is_dart_scheme_url) {
    if (tag == kImportTag) {
      // Handle imports of other built-in libraries present in the SDK.
      Builtin::BuiltinLibraryId id;
      if (DartUtils::IsDartIOLibURL(url_string)) {
        id = Builtin::kIOLibrary;
      } else {
        return Dart_Error("Do not know how to load '%s'", url_string);
      }
      return Builtin::LoadAndCheckLibrary(id);
    } else {
      ASSERT(tag == kSourceTag);
      return Dart_Error("Unable to load source '%s' ", url_string);
    }
  } else {
    // Get the file path out of the url.
    Dart_Handle builtin_lib =
        Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
    Dart_Handle file_path = FilePathFromUri(url, builtin_lib);
    if (Dart_IsError(file_path)) {
      return file_path;
    }
    Dart_StringToCString(file_path, &url_string);
  }
  if (is_dart_extension_url) {
    if (tag != kImportTag) {
      return Dart_Error("Dart extensions must use import: '%s'", url_string);
    }
    return Extensions::LoadExtension(url_string, library);
  }
  result = DartUtils::LoadSource(NULL,
                                 library,
                                 url,
                                 tag,
                                 url_string);
  return result;
}


const uint8_t* DartUtils::SniffForMagicNumber(const uint8_t* text_buffer,
                                              intptr_t* buffer_len,
                                              bool* is_snapshot) {
  intptr_t len = sizeof(magic_number);
  for (intptr_t i = 0; i < len; i++) {
    if (text_buffer[i] != magic_number[i]) {
      *is_snapshot = false;
      return text_buffer;
    }
  }
  *is_snapshot = true;
  ASSERT(*buffer_len > len);
  *buffer_len -= len;
  return text_buffer + len;
}


void DartUtils::WriteMagicNumber(File* file) {
  // Write a magic number and version information into the snapshot file.
  bool bytes_written = file->WriteFully(magic_number, sizeof(magic_number));
  ASSERT(bytes_written);
}


Dart_Handle DartUtils::LoadScript(const char* script_uri,
                                  Dart_Handle builtin_lib) {
  Dart_Handle resolved_script_uri;
  resolved_script_uri = ResolveScriptUri(NewString(script_uri), builtin_lib);
  if (Dart_IsError(resolved_script_uri)) {
    return resolved_script_uri;
  }
  Dart_Handle script_path = DartUtils::FilePathFromUri(resolved_script_uri,
                                                       builtin_lib);
  if (Dart_IsError(script_path)) {
    return script_path;
  }
  const char* script_path_cstr;
  Dart_StringToCString(script_path, &script_path_cstr);
  const char* error_msg = NULL;
  intptr_t len;
  const uint8_t* text_buffer = ReadFile(script_path_cstr, &len, &error_msg);
  if (text_buffer == NULL) {
    return Dart_Error(error_msg);
  }
  bool is_snapshot = false;
  text_buffer = SniffForMagicNumber(text_buffer, &len, &is_snapshot);
  if (is_snapshot) {
    return Dart_LoadScriptFromSnapshot(text_buffer, len);
  } else {
    Dart_Handle source = Dart_NewStringFromUTF8(text_buffer, len);
    return Dart_LoadScript(resolved_script_uri, source, 0, 0);
  }
}


Dart_Handle DartUtils::LoadSource(CommandLineOptions* url_mapping,
                                  Dart_Handle library,
                                  Dart_Handle url,
                                  Dart_LibraryTag tag,
                                  const char* url_string) {
  if (url_mapping != NULL && IsDartSchemeURL(url_string)) {
    const char* mapped_url_string = MapLibraryUrl(url_mapping, url_string);
    if (mapped_url_string == NULL) {
      return Dart_Error("Do not know how to load %s", url_string);
    }
    // We have a URL mapping specified, just read the file that the
    // URL mapping specifies and load it.
    url_string = mapped_url_string;
  }
  // The tag is either an import or a source tag.
  // Read the file and load it according to the specified tag.
  Dart_Handle source = DartUtils::ReadStringFromFile(url_string);
  if (Dart_IsError(source)) {
    return source;  // source contains the error string.
  }
  if (tag == kImportTag) {
    // Return library object or an error string.
    return Dart_LoadLibrary(url, source);
  } else if (tag == kSourceTag) {
    return Dart_LoadSource(library, url, source);
  }
  return Dart_Error("wrong tag");
}


Dart_Handle DartUtils::PrepareForScriptLoading(const char* package_root,
                                               Dart_Handle builtin_lib) {
  // Setup the corelib 'print' function.
  Dart_Handle print = Dart_Invoke(
      builtin_lib, NewString("_getPrintClosure"), 0, 0);
  Dart_Handle corelib = Dart_LookupLibrary(NewString("dart:core"));
  Dart_Handle result = Dart_SetField(corelib,
                                     NewString("_printClosure"),
                                     print);

  // Setup the 'timer' factory.
  Dart_Handle url = NewString(kAsyncLibURL);
  DART_CHECK_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(async_lib);
  Dart_Handle io_lib = Builtin::LoadAndCheckLibrary(Builtin::kIOLibrary);
  Dart_Handle timer_closure =
      Dart_Invoke(io_lib, NewString("_getTimerFactoryClosure"), 0, NULL);
  Dart_Handle args[1];
  args[0] = timer_closure;
  DART_CHECK_VALID(Dart_Invoke(
      async_lib, NewString("_setTimerFactoryClosure"), 1, args));

  // Set up package root if specified.
  if (package_root != NULL) {
    result = NewString(package_root);
    if (!Dart_IsError(result)) {
      const int kNumArgs = 1;
      Dart_Handle dart_args[kNumArgs];
      dart_args[0] = result;
      return Dart_Invoke(builtin_lib,
                         NewString("_setPackageRoot"),
                         kNumArgs,
                         dart_args);
    }
  }
  return result;
}


const char* DartUtils::GetCanonicalPath(const char* reference_dir,
                                        const char* filename) {
  if (File::IsAbsolutePath(filename)) {
    return strdup(filename);
  }

  char* canonical_path = File::GetCanonicalPath(reference_dir);
  if  (canonical_path == NULL) {
    canonical_path = strdup(reference_dir);
    ASSERT(canonical_path != NULL);
  }
  ASSERT(File::PathSeparator() != NULL && strlen(File::PathSeparator()) == 1);
  char* path_sep = strrchr(canonical_path, File::PathSeparator()[0]);
  if (path_sep == NULL) {
    // No separator found: Reference is a file in local directory.
    free(canonical_path);
    return strdup(filename);
  }
  *path_sep = '\0';
  intptr_t len = snprintf(NULL, 0, "%s%s%s",
                          canonical_path, File::PathSeparator(), filename);
  char* absolute_filename = reinterpret_cast<char*>(malloc(len + 1));
  ASSERT(absolute_filename != NULL);

  snprintf(absolute_filename, len + 1, "%s%s%s",
           canonical_path, File::PathSeparator(), filename);
  free(canonical_path);
  canonical_path = File::GetCanonicalPath(absolute_filename);
  if (canonical_path == NULL) {
    return absolute_filename;
  }
  free(absolute_filename);
  return canonical_path;
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
  object.type = Dart_CObject::kInt32;
  object.value.as_int32 = value;
  return Dart_PostCObject(port_id, &object);
}


Dart_Handle DartUtils::GetDartClass(const char* library_url,
                                    const char* class_name) {
  return Dart_GetClass(Dart_LookupLibrary(NewString(library_url)),
                       NewString(class_name));
}


Dart_Handle DartUtils::NewDartOSError() {
  // Extract the current OS error.
  OSError os_error;
  return NewDartOSError(&os_error);
}


Dart_Handle DartUtils::NewDartOSError(OSError* os_error) {
  // Create a dart:io OSError object with the information retrieved from the OS.
  Dart_Handle clazz = GetDartClass(kIOLibURL, "OSError");
  Dart_Handle args[2];
  args[0] = NewString(os_error->message());
  args[1] = Dart_NewInteger(os_error->code());
  return Dart_New(clazz, Dart_Null(), 2, args);
}


Dart_Handle DartUtils::NewDartSocketIOException(const char* message,
                                                Dart_Handle os_error) {
  // Create a dart:io SocketIOException object.
  Dart_Handle clazz = GetDartClass(kIOLibURL, "SocketIOException");
  Dart_Handle args[2];
  args[0] = NewString(message);
  args[1] = os_error;
  return Dart_New(clazz, Dart_Null(), 2, args);
}


Dart_Handle DartUtils::NewDartExceptionWithMessage(const char* library_url,
                                                   const char* exception_name,
                                                   const char* message) {
  // Create a Dart Exception object with a message.
  Dart_Handle clazz = GetDartClass(library_url, exception_name);
  Dart_Handle args[1];
  args[0] = NewString(message);
  return Dart_New(clazz, Dart_Null(), 1, args);
}


Dart_Handle DartUtils::NewDartArgumentError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL,
                                     "ArgumentError",
                                     message);
}


Dart_Handle DartUtils::NewInternalError(const char* message) {
  return NewDartExceptionWithMessage(kCoreLibURL, "InternalError", message);
}


void DartUtils::SetOriginalWorkingDirectory() {
  original_working_directory = Directory::Current();
}


// Statically allocated Dart_CObject instances for immutable
// objects. As these will be used by different threads the use of
// these depends on the fact that the marking internally in the
// Dart_CObject structure is not marking simple value objects.
Dart_CObject CObject::api_null_ = { Dart_CObject::kNull , { 0 } };
Dart_CObject CObject::api_true_ = { Dart_CObject::kBool , { true } };
Dart_CObject CObject::api_false_ = { Dart_CObject::kBool, { false } };
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


Dart_CObject* CObject::New(Dart_CObject::Type type, int additional_bytes) {
  Dart_CObject* cobject = reinterpret_cast<Dart_CObject*>(
      Dart_ScopeAllocate(sizeof(Dart_CObject) + additional_bytes));
  cobject->type = type;
  return cobject;
}


Dart_CObject* CObject::NewInt32(int32_t value) {
  Dart_CObject* cobject = New(Dart_CObject::kInt32);
  cobject->value.as_int32 = value;
  return cobject;
}


Dart_CObject* CObject::NewInt64(int64_t value) {
  Dart_CObject* cobject = New(Dart_CObject::kInt64);
  cobject->value.as_int64 = value;
  return cobject;
}


Dart_CObject* CObject::NewIntptr(intptr_t value) {
  // Pointer values passed as intptr_t are always send as int64_t.
  Dart_CObject* cobject = New(Dart_CObject::kInt64);
  cobject->value.as_int64 = value;
  return cobject;
}


Dart_CObject* CObject::NewDouble(double value) {
  Dart_CObject* cobject = New(Dart_CObject::kDouble);
  cobject->value.as_double = value;
  return cobject;
}


Dart_CObject* CObject::NewString(int length) {
  Dart_CObject* cobject = New(Dart_CObject::kString, length + 1);
  cobject->value.as_string = reinterpret_cast<char*>(cobject + 1);
  return cobject;
}


Dart_CObject* CObject::NewString(const char* str) {
  int length = strlen(str);
  Dart_CObject* cobject = NewString(length);
  memmove(cobject->value.as_string, str, length + 1);
  return cobject;
}


Dart_CObject* CObject::NewArray(int length) {
  Dart_CObject* cobject =
      New(Dart_CObject::kArray, length * sizeof(Dart_CObject*));  // NOLINT
  cobject->value.as_array.length = length;
  cobject->value.as_array.values =
      reinterpret_cast<Dart_CObject**>(cobject + 1);
  return cobject;
}


Dart_CObject* CObject::NewUint8Array(int length) {
  Dart_CObject* cobject = New(Dart_CObject::kTypedData, length);
  cobject->value.as_typed_data.type = Dart_CObject::kUint8Array;
  cobject->value.as_typed_data.length = length;
  cobject->value.as_typed_data.values = reinterpret_cast<uint8_t*>(cobject + 1);
  return cobject;
}


Dart_CObject* CObject::NewExternalUint8Array(
    int64_t length, uint8_t* data, void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  Dart_CObject* cobject = New(Dart_CObject::kExternalTypedData);
  cobject->value.as_external_typed_data.type = Dart_CObject::kUint8Array;
  cobject->value.as_external_typed_data.length = length;
  cobject->value.as_external_typed_data.data = data;
  cobject->value.as_external_typed_data.peer = peer;
  cobject->value.as_external_typed_data.callback = callback;
  return cobject;
}


Dart_CObject* CObject::NewIOBuffer(int64_t length) {
  uint8_t* data = IOBuffer::Allocate(length);
  return NewExternalUint8Array(length, data, data, IOBuffer::Finalizer);
}


void CObject::FreeIOBufferData(Dart_CObject* cobject) {
  ASSERT(cobject->type == Dart_CObject::kExternalTypedData);
  cobject->value.as_external_typed_data.callback(
      NULL, cobject->value.as_external_typed_data.peer);
  cobject->value.as_external_typed_data.data = NULL;
}


static int kArgumentError = 1;
static int kOSError = 2;
static int kFileClosedError = 3;


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
