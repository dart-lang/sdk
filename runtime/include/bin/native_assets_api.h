// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_INCLUDE_BIN_NATIVE_ASSETS_API_H_
#define RUNTIME_INCLUDE_BIN_NATIVE_ASSETS_API_H_

namespace dart {
namespace bin {

class NativeAssets {
 public:
  static void* DlopenAbsolute(const char* path, char** error);
  static void* DlopenRelative(const char* path,
                              const char* script_uri,
                              char** error);
  static void* DlopenSystem(const char* path, char** error);
  static void* DlopenProcess(char** error);
  static void* DlopenExecutable(char** error);
  static void* Dlsym(void* handle, const char* symbol, char** error);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_INCLUDE_BIN_NATIVE_ASSETS_API_H_
