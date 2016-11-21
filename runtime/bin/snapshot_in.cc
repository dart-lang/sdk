// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// clang-format off

// This file is linked into the dart executable when it has a snapshot
// linked into it.

#if defined(_WIN32)
typedef unsigned __int8 uint8_t;
#else
#include <inttypes.h>
#include <stdint.h>
#endif
#include <stddef.h>

namespace dart {
namespace bin {

// The string on the next line will be filled in with the contents of the
// generated snapshot binary file for the vm isolate.
// This string forms the content of a vm isolate snapshot which is loaded
// into the vm isolate.
static const uint8_t vm_isolate_snapshot_buffer_[] = {
  %s
};
const uint8_t* vm_isolate_snapshot_buffer = vm_isolate_snapshot_buffer_;


// The string on the next line will be filled in with the contents of the
// generated snapshot binary file for a regular dart isolate.
// This string forms the content of a regular dart isolate snapshot which is
// loaded into an isolate when it is created.
static const uint8_t isolate_snapshot_buffer_[] = {
  %s
};
const uint8_t* isolate_snapshot_buffer = isolate_snapshot_buffer_;

}  // namespace bin
}  // namespace dart
