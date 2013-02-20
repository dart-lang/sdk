// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/extensions.h"
#include "bin/utils.h"

void* Extensions::LoadExtensionLibrary(const char* library_path,
                                       const char* extension_name) {
  const char* strings[] = { library_path, "/", extension_name, ".dll", NULL };
  char* library_file = Concatenate(strings);
  wchar_t* unicode_library_file = StringUtils::Utf8ToWide(library_file);
  void* lib_handle = LoadLibraryW(unicode_library_file);
  free(unicode_library_file);
  free(library_file);
  return lib_handle;
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  return GetProcAddress(reinterpret_cast<HMODULE>(lib_handle), symbol);
}

#endif  // defined(TARGET_OS_WINDOWS)
