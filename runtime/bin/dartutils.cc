// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

#include "bin/file.h"
#include "bin/globals.h"

const char* DartUtils::kDartScheme = "dart:";
const char* DartUtils::kBuiltinLibURL = "dart:builtin";
const char* DartUtils::kCoreLibURL = "dart:core";
const char* DartUtils::kCoreImplLibURL = "dart:coreimpl";
const char* DartUtils::kCoreNativeWrappersLibURL = "dart:nativewrappers";
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
  Dart_Handle result = Dart_IntegerValue(value_obj, &value);
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


void DartUtils::SetIntegerInstanceField(Dart_Handle handle,
                                        const char* name,
                                        intptr_t val) {
  Dart_Handle result = Dart_SetInstanceField(handle,
                                             Dart_NewString(name),
                                             Dart_NewInteger(val));
  ASSERT(!Dart_IsError(result));
}


intptr_t DartUtils::GetIntegerInstanceField(Dart_Handle handle,
                                            const char* name) {
  Dart_Handle result =
      Dart_GetInstanceField(handle, Dart_NewString(name));
  ASSERT(!Dart_IsError(result));
  intptr_t value = DartUtils::GetIntegerValue(result);
  return value;
}


void DartUtils::SetStringInstanceField(Dart_Handle handle,
                                       const char* name,
                                       const char* val) {
  Dart_Handle result = Dart_SetInstanceField(handle,
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
  File* file = File::Open(filename, false);
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


const char* DartUtils::GetCanonicalPath(const char* reference_dir,
                                        const char* filename) {
  if (File::IsAbsolutePath(filename)) {
    return strdup(filename);
  }

  char* path = strdup(reference_dir);
  if  (path == NULL) {
    return NULL;
  }
  char* path_sep = strrchr(path, File::PathSeparator()[0]);
  if (path_sep == NULL) {
    // No separator found: Reference is a file in local directory.
    return strdup(filename);
  }
  *path_sep = '\0';
  intptr_t len = snprintf(NULL, 0, "%s%s%s",
                          path, File::PathSeparator(), filename);
  char* absolute_filename = reinterpret_cast<char*>(malloc(len + 1));
  ASSERT(absolute_filename != NULL);

  snprintf(absolute_filename, len + 1, "%s%s%s",
           path, File::PathSeparator(), filename);

  free(path);
  char* canonical_filename = File::GetCanonicalPath(absolute_filename);
  if (canonical_filename == NULL) {
    return absolute_filename;
  }
  free(absolute_filename);
  return canonical_filename;
}
