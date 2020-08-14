// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ZONE_TEXT_BUFFER_H_
#define RUNTIME_VM_ZONE_TEXT_BUFFER_H_

#include "platform/text_buffer.h"
#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class String;
class Zone;

// ZoneTextBuffer allocates the character buffer in the given zone. Thus,
// pointers returned by buffer() have the same lifetime as the zone.
class ZoneTextBuffer : public BaseTextBuffer {
 public:
  explicit ZoneTextBuffer(Zone* zone, intptr_t initial_capacity = 64);
  ~ZoneTextBuffer() {}

  // Allocates a new internal buffer. Thus, the contents of buffers returned by
  // previous calls to buffer() are no longer affected by this object.
  void Clear();

 private:
  bool EnsureCapacity(intptr_t len);
  Zone* zone_;

  DISALLOW_COPY_AND_ASSIGN(ZoneTextBuffer);
};

}  // namespace dart

#endif  // RUNTIME_VM_ZONE_TEXT_BUFFER_H_
