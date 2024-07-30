// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"

#include "platform/assert.h"
#include "vm/image_snapshot.h"
#include "vm/native_symbol.h"

namespace dart {

const uint8_t* OS::GetAppDSOBase(const uint8_t* snapshot_instructions) {
  // Use the relocated address in the Image if the snapshot was compiled
  // directly to ELF.
  const Image instructions_image(snapshot_instructions);
  if (instructions_image.compiled_to_elf()) {
    return snapshot_instructions -
           instructions_image.instructions_relocated_address();
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
