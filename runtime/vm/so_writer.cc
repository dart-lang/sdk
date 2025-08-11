// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/so_writer.h"

#if defined(DART_PRECOMPILER)

#include "vm/image_snapshot.h"

namespace dart {

void SharedObjectWriter::WriteStream::WriteBytesWithRelocations(
    const uint8_t* bytes,
    intptr_t size,
    intptr_t start_address,
    const RelocationArray& relocations) {
  // Resolve relocations as we write.
  intptr_t current_pos = 0;
  for (const auto& reloc : relocations) {
    // We assume here that the relocations are sorted in increasing order,
    // with unique section offsets.
    const intptr_t preceding = reloc.section_offset - current_pos;
    if (preceding > 0) {
      WriteBytes(bytes + current_pos, preceding);
      current_pos += preceding;
    }
    ASSERT_EQUAL(current_pos, reloc.section_offset);
    intptr_t source_address = reloc.source_offset;
    switch (reloc.source_label) {
      case Relocation::kSelfRelative:
        source_address += start_address + current_pos;
        break;
      case Relocation::kSnapshotRelative:
        // No change to source_address.
        break;
      default:
        ASSERT(reloc.source_label > 0);
        source_address += FindValueForLabel(reloc.source_label);
    }
    ASSERT(reloc.size_in_bytes <= kWordSize);
    word to_write = reloc.target_offset - source_address;
    switch (reloc.target_label) {
      case Relocation::kSelfRelative:
        to_write += start_address + current_pos;
        break;
      case Relocation::kSnapshotRelative:
        // No change to to_write.
        break;
      default: {
        ASSERT(reloc.target_label > 0);
        intptr_t value;
        if (HasValueForLabel(reloc.target_label, &value)) {
          to_write += value;
        } else {
          ASSERT_EQUAL(reloc.target_label, kBuildIdLabel);
          ASSERT_EQUAL(reloc.target_offset, 0);
          ASSERT_EQUAL(reloc.source_offset, 0);
          ASSERT_EQUAL(reloc.size_in_bytes, compiler::target::kWordSize);
          // TODO(dartbug.com/43516): Special case for snapshots with deferred
          // sections that handles the build ID relocation in an
          // InstructionsSection when there is no build ID.
          to_write = Image::kNoRelocatedAddress;
        }
      }
    }
    ASSERT(Utils::IsInt(reloc.size_in_bytes * kBitsPerByte, to_write));
    WriteBytes(reinterpret_cast<const uint8_t*>(&to_write),
               reloc.size_in_bytes);
    current_pos += reloc.size_in_bytes;
  }
  WriteBytes(bytes + current_pos, size - current_pos);
}

}  // namespace dart

#endif  // DART_PRECOMPILER
