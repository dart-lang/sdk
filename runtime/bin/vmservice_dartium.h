// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_VMSERVICE_DARTIUM_H_
#define BIN_VMSERVICE_DARTIUM_H_

/* In order to avoid conflicts / issues with blink, no headers are included */

#include <dart_api.h>
#include <cstddef>

namespace dart {
namespace bin {

class VmServiceServer {
 public:
  static void Bootstrap();
  static Dart_Isolate CreateIsolate(const uint8_t* snapshot_buffer);

  static const char* GetServerIP();
  static intptr_t GetServerPort();

/* DISALLOW_ALLOCATION */
  void operator delete(void* pointer);
 private:
  void* operator new(size_t size);

/* DISALLOW_IMPLICIT_CONSTRUCTORS */
  VmServiceServer();
  VmServiceServer(const VmServiceServer&);
  void operator=(const VmServiceServer&);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_VMSERVICE_DARTIUM_H_
