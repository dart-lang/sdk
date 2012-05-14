// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

#include "bin/file.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

const char* DartUtils::kDartScheme = "dart:";
const char* DartUtils::kDartExtensionScheme = "dart-ext:";
const char* DartUtils::kBuiltinLibURL = "dart:builtin";
const char* DartUtils::kCoreLibURL = "dart:core";
const char* DartUtils::kCoreImplLibURL = "dart:coreimpl";
const char* DartUtils::kCryptoLibURL = "dart:crypto";
const char* DartUtils::kIOLibURL = "dart:io";
const char* DartUtils::kJsonLibURL = "dart:json";
const char* DartUtils::kUriLibURL = "dart:uri";
const char* DartUtils::kUtfLibURL = "dart:utf";
const char* DartUtils::kIsolateLibURL = "dart:isolate";


const char* DartUtils::kIdFieldName = "_id";


static const char* MapLibraryUrl(CommandLineOptions* url_mapping,
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
                                     Dart_NewString(name),
                                     Dart_NewInteger(val));
  ASSERT(!Dart_IsError(result));
}


intptr_t DartUtils::GetIntegerField(Dart_Handle handle,
                                            const char* name) {
  Dart_Handle result = Dart_GetField(handle, Dart_NewString(name));
  ASSERT(!Dart_IsError(result));
  intptr_t value = DartUtils::GetIntegerValue(result);
  return value;
}


void DartUtils::SetStringField(Dart_Handle handle,
                               const char* name,
                               const char* val) {
  Dart_Handle result = Dart_SetField(handle,
                                     Dart_NewString(name),
                                     Dart_NewString(val));
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


bool DartUtils::IsDartCryptoLibURL(const char* url_name) {
  return (strcmp(url_name, kCryptoLibURL) == 0);
}


bool DartUtils::IsDartIOLibURL(const char* url_name) {
  return (strcmp(url_name, kIOLibURL) == 0);
}


bool DartUtils::IsDartJsonLibURL(const char* url_name) {
  return (strcmp(url_name, kJsonLibURL) == 0);
}


bool DartUtils::IsDartUriLibURL(const char* url_name) {
  return (strcmp(url_name, kUriLibURL) == 0);
}


bool DartUtils::IsDartUtfLibURL(const char* url_name) {
  return (strcmp(url_name, kUtfLibURL) == 0);
}


Dart_Handle DartUtils::CanonicalizeURL(CommandLineOptions* url_mapping,
                                       Dart_Handle library,
                                       const char* url_str) {
  // Get the url of the including library.
  Dart_Handle library_url = Dart_LibraryUrl(library);
  if (Dart_IsError(library_url)) {
    return Dart_Error("accessing library url failed");
  }
  if (!Dart_IsString8(library_url)) {
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
  Dart_Handle canon_url = Dart_NewString(canon_url_str);
  free(const_cast<char*>(canon_url_str));

  return canon_url;
}


Dart_Handle DartUtils::ReadStringFromFile(const char* filename) {
  File* file = File::Open(filename, File::kRead);
  if (file == NULL) {
    const char* format = "Unable to open file: %s";
    intptr_t len = snprintf(NULL, 0, format, filename);
    // TODO(iposva): Allocate from the zone instead of leaking error string
    // here. On the other hand the binary is about the exit anyway.
    char* error_msg = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(error_msg, len + 1, format, filename);
    return Dart_Error(error_msg);
  }
  intptr_t len = file->Length();
  char* text_buffer = reinterpret_cast<char*>(malloc(len + 1));
  if (text_buffer == NULL) {
    delete file;
    return Dart_Error("Unable to allocate buffer");
  }
  if (!file->ReadFully(text_buffer, len)) {
    delete file;
    return Dart_Error("Unable to fully read contents");
  }
  text_buffer[len] = '\0';
  delete file;
  Dart_Handle str = Dart_NewString(text_buffer);
  free(text_buffer);
  return str;
}


Dart_Handle DartUtils::LoadSource(CommandLineOptions* url_mapping,
                                  Dart_Handle library,
                                  Dart_Handle url,
                                  Dart_LibraryTag tag,
                                  const char* url_string,
                                  Dart_Handle import_map) {
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
    return Dart_LoadLibrary(url, source, import_map);
  } else if (tag == kSourceTag) {
    return Dart_LoadSource(library, url, source);
  }
  return Dart_Error("wrong tag");
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


Dart_Handle DartUtils::NewDartOSError() {
  // Extract the current OS error.
  OSError os_error;
  return NewDartOSError(&os_error);
}


Dart_Handle DartUtils::NewDartOSError(OSError* os_error) {
  // Create a Dart OSError object with the information retrieved from the OS.
  Dart_Handle url = Dart_NewString("dart:io");
  if (Dart_IsError(url)) return url;
  Dart_Handle lib = Dart_LookupLibrary(url);
  if (Dart_IsError(lib)) return lib;
  Dart_Handle function_name = Dart_NewString("_makeOSError");
  if (Dart_IsError(function_name)) return function_name;
  Dart_Handle args[2];
  args[0] = Dart_NewString(os_error->message());
  if (Dart_IsError(args[0])) return args[0];
  args[1] = Dart_NewInteger(os_error->code());
  if (Dart_IsError(args[1])) return args[1];
  Dart_Handle err = Dart_Invoke(lib, function_name, 2, args);
  return err;
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
  Dart_CObject* cobject = New(Dart_CObject::kUint8Array, length);
  cobject->value.as_byte_array.length = length;
  cobject->value.as_byte_array.values = reinterpret_cast<uint8_t*>(cobject + 1);
  return cobject;
}


static int kIllegalArgumentError = 1;
static int kOSError = 2;
static int kFileClosedError = 3;


CObject* CObject::IllegalArgumentError() {
  CObjectArray* result = new CObjectArray(CObject::NewArray(1));
  result->SetAt(0, new CObjectInt32(CObject::NewInt32(kIllegalArgumentError)));
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
