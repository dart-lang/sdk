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

const char* GetCanonicalPath(const char* reference_dir,
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


static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_Error("not a library");
  }
  if (!Dart_IsString8(url)) {
    return Dart_Error("url is not a string");
  }
  const char* url_chars = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_chars);
  if (Dart_IsError(result)) {
    return Dart_Error("accessing url characters failed");
  }

  static const char* kDartScheme = "dart:";
  static const intptr_t kDartSchemeLen = strlen(kDartScheme);
  // If the URL starts with "dart:" then it is not modified as it will be
  // handled by the VM internally.
  if (strncmp(url_chars, kDartScheme, kDartSchemeLen) == 0) {
    if (tag == kCanonicalizeUrl) {
      return url;
    }
    return Dart_Error("Do not know how to load '%s'", url_chars);
  }
  if (tag == kCanonicalizeUrl) {
    // Create a canonical path based on the including library and current url.

    // Get the url of the including library.
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return Dart_Error("accessing library url failed");
    }
    if (!Dart_IsString8(library_url)) {
      return Dart_Error("library url is not a string");
    }
    const char* library_url_chars = NULL;
    result = Dart_StringToCString(library_url, &library_url_chars);
    if (Dart_IsError(result)) {
      return Dart_Error("accessing library url characters failed");
    }

    // Calculate the canonical path.
    const char* canon_url_chars = GetCanonicalPath(library_url_chars,
                                                   url_chars);
    Dart_Handle canon_url = Dart_NewString(canon_url_chars);
    free(const_cast<char*>(canon_url_chars));

    return canon_url;
  }

  // The tag is either an import or a source tag. Read the file based on the
  // url chars.
  Dart_Handle source = ReadStringFromFile(url_chars);
  if (Dart_IsError(source)) {
    return source;  // source contains the error string.
  }
  if (tag == kImportTag) {
    Dart_Handle new_lib = Dart_LoadLibrary(url, source);
    if (!Dart_IsError(new_lib)) {
      Builtin_ImportLibrary(new_lib);
    }
    return new_lib;  // Return library object or an error string.
  } else if (tag == kSourceTag) {
    return Dart_LoadSource(library, url, source);
  }
  return Dart_Error("wrong tag");
}


Dart_Handle ReadStringFromFile(const char* filename) {
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


Dart_Handle LoadScript(const char* script_name) {
  Dart_Handle source = ReadStringFromFile(script_name);
  if (Dart_IsError(source)) {
    return source;
  }
  Dart_Handle url = Dart_NewString(script_name);

  return Dart_LoadScript(url, source, LibraryTagHandler);
}
