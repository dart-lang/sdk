// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"

#include "platform/assert.h"
#include "platform/text_buffer.h"
#include "vm/image_snapshot.h"
#include "vm/native_symbol.h"

namespace dart {

void OS::BuildId::PrintTo(BaseTextBuffer* buffer) const {
  ASSERT(data != nullptr);
  if (format == Format::kPEGUID) {
    // The layout of the signature in the CodeView record of the PE image.
    struct GuidAndAge {
      uint32_t data1;
      uint16_t data2;
      uint16_t data3;
      uint8_t data4[8];
      uint32_t age;
    };
    ASSERT_EQUAL(len, static_cast<intptr_t>(sizeof(GuidAndAge)));
    const auto& signature = *reinterpret_cast<const GuidAndAge*>(data);
    buffer->Printf("%08x%04x%04x", signature.data1, signature.data2,
                   signature.data3);
    for (const uint8_t byte : signature.data4) {
      buffer->Printf("%02x", byte);
    }
    buffer->Printf("%x", signature.age);
    return;
  }
  for (intptr_t i = 0; i < len; i++) {
    buffer->Printf("%2.2x", data[i]);
  }
}

const uint8_t* OS::GetAppDSOBase(const uint8_t* snapshot_instructions) {
  // Use the relocated address in the Image if the snapshot was compiled
  // directly to a shared object instead of assembled.
  const TextImage instructions_image(snapshot_instructions);
  if (auto* const so_start = reinterpret_cast<const uint8_t*>(
          instructions_image.shared_object_start())) {
    return so_start;
  }
  uword dso_base;
  if (NativeSymbolResolver::LookupSharedObject(
          reinterpret_cast<uword>(snapshot_instructions), &dso_base)) {
    return reinterpret_cast<const uint8_t*>(dso_base);
  }
  UNIMPLEMENTED();
  return nullptr;
}

}  // namespace dart
