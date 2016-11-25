// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_VMSERVICE_DARTIUM_H_
#define RUNTIME_BIN_VMSERVICE_DARTIUM_H_

/* In order to avoid conflicts / issues with blink, no headers are included */

#include <dart_api.h>
#include <cstddef>

namespace dart {
namespace bin {

class VmServiceServer {
 public:
  static void Bootstrap();
  static Dart_Isolate CreateIsolate(const uint8_t* snapshot_buffer);

  static const char* GetServerAddress();

  static void DecompressAssets(const uint8_t* input,
                               unsigned int input_len,
                               uint8_t** output,
                               unsigned int* output_length);

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

#endif  // RUNTIME_BIN_VMSERVICE_DARTIUM_H_
