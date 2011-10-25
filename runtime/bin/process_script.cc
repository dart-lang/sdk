// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Handle dart scripts.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/file.h"
#include "bin/globals.h"
#include "bin/process_script.h"

static const char* CanonicalizeUrl(const char* reference_dir,
                                   const char* filename) {
  static const char* kDartScheme = "dart:";
  static const intptr_t kDartSchemeLen = strlen(kDartScheme);
  // If the URL starts with "dart:" then it is not modified as it will be
  // handled by the VM internally.
  if (strncmp(filename, kDartScheme, kDartSchemeLen) == 0) {
    return strdup(filename);
  }

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


static Dart_Result ReadStringFromFile(const char* filename) {
  File* file = File::OpenFile(filename, false);
  if (file == NULL) {
    const char* format = "Unable to open file: %s";
    intptr_t len = snprintf(NULL, 0, format, filename);
    // TODO(iposva): Allocate from the zone instead of leaking error string
    // here. On the other hand the binary is about the exit anyway.
    char* error_msg = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(error_msg, len + 1, format, filename);
    return Dart_ErrorResult(error_msg);
  }
  intptr_t len = file->Length();
  char* text_buffer = reinterpret_cast<char*>(malloc(len + 1));
  if (text_buffer == NULL) {
    delete file;
    return Dart_ErrorResult("Unable to allocate buffer");
  }
  if (!file->ReadFully(text_buffer, len)) {
    delete file;
    return Dart_ErrorResult("Unable to fully read contents");
  }
  text_buffer[len] = '\0';
  delete file;
  Dart_Handle str = Dart_NewString(text_buffer);
  free(text_buffer);
  return Dart_ResultAsObject(str);
}


static Dart_Result LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_ErrorResult("not a library");
  }
  if (!Dart_IsString8(url)) {
    return Dart_ErrorResult("url is not a string");
  }
  Dart_Result result = Dart_StringToCString(url);
  if (!Dart_IsValidResult(result)) {
    return Dart_ErrorResult("accessing url characters failed");
  }
  const char* url_chars = Dart_GetResultAsCString(result);

  if (tag == kCanonicalizeUrl) {
    // Create the full path based on the including library and the current url.

    // Get the url of the calling library.
    result = Dart_LibraryUrl(library);
    if (!Dart_IsValidResult(result)) {
      return Dart_ErrorResult("accessing library url failed");
    }
    Dart_Handle library_url = Dart_GetResult(result);
    if (!Dart_IsString8(library_url)) {
      return Dart_ErrorResult("library url is not a string");
    }
    result = Dart_StringToCString(library_url);
    if (!Dart_IsValidResult(result)) {
      return Dart_ErrorResult("accessing library url characters failed");
    }
    const char* library_url_chars = Dart_GetResultAsCString(result);

    // Calculate the path.
    const char* canon_url_chars = CanonicalizeUrl(library_url_chars, url_chars);
    Dart_Handle canon_url = Dart_NewString(canon_url_chars);
    free(const_cast<char*>(canon_url_chars));

    return Dart_ResultAsObject(canon_url);
  }

  // The tag is either an import or a source tag. Read the file based on the
  // url chars.
  result = ReadStringFromFile(url_chars);
  if (!Dart_IsValidResult(result)) {
    return result;
  }
  Dart_Handle source = Dart_GetResult(result);

  if (tag == kImportTag) {
    result = Dart_LoadLibrary(url, source);
    if (Dart_IsValidResult(result)) {
      // TODO(iposva): Should the builtin library be added to all libraries?
      Dart_Handle new_lib = Dart_GetResult(result);
      Builtin_ImportLibrary(new_lib);
    }
    return result;
  } else if (tag == kSourceTag) {
    return Dart_LoadSource(library, url, source);
  }
  return Dart_ErrorResult("wrong tag");
}


Dart_Result LoadScript(const char* script_name) {
  Dart_Result result = ReadStringFromFile(script_name);
  if (!Dart_IsValidResult(result)) {
    return result;
  }
  Dart_Handle source = Dart_GetResult(result);
  Dart_Handle url = Dart_NewString(script_name);

  return Dart_LoadScript(url, source, LibraryTagHandler);
}
