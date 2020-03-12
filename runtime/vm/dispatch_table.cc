// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dispatch_table.h"

#include "vm/clustered_snapshot.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

// The serialized format of the dispatch table is a sequence of variable-length
// integers (using the built-in variable-length integer encoding/decoding of
// the stream). Each encoded integer e is interpreted thus:
// -kRecentCount .. -1   Pick value from the recent values buffer at index -1-e.
// 0                     Empty (unused) entry.
// 1 .. kMaxRepeat       Repeat previous entry e times.
// kIndexBase or higher  Pick entry point from the code object at index
//                       e-kIndexBase in the code array and also put it into
//                       the recent values buffer at the next index round-robin.

// Constants for serialization format. Chosen such that repeats and recent
// values are encoded as single bytes.
static const intptr_t kMaxRepeat = 63;
static const intptr_t kRecentCount = 64;  // Must be a power of two.
static const intptr_t kRecentMask = kRecentCount - 1;
static const intptr_t kIndexBase = kMaxRepeat + 1;

uword DispatchTable::EntryPointFor(const Code& code) {
  return code.EntryPoint();
}

void DispatchTable::SetCodeAt(intptr_t index, const Code& code) {
  ASSERT(index >= 0 && index < length());
  // The table is built with the same representation as it has at runtime, that
  // is, table entries are function entry points. This representation assumes
  // that the code will not move between table building and serialization.
  // This property is upheld by the fact that the GC does not move code around.
  array_[index] = EntryPointFor(code);
}

intptr_t DispatchTable::Serialize(Serializer* serializer,
                                  const DispatchTable* table,
                                  const GrowableArray<RawCode*>& code_objects) {
  const intptr_t bytes_before = serializer->bytes_written();
  if (table != nullptr) {
    table->Serialize(serializer, code_objects);
  } else {
    serializer->Write<uint32_t>(0);
  }
  return serializer->bytes_written() - bytes_before;
}

void DispatchTable::Serialize(
    Serializer* serializer,
    const GrowableArray<RawCode*>& code_objects) const {
  Code& code = Code::Handle();
  IntMap<intptr_t> entry_to_index;
  for (intptr_t i = 0; i < code_objects.length(); i++) {
    code = code_objects[i];
    const uword entry = EntryPointFor(code);
    if (!entry_to_index.HasKey(entry)) {
      entry_to_index.Insert(entry, i + 1);
    }
  }

  uword prev_entry = 0;
  uword recent[kRecentCount] = {0};
  intptr_t recent_index = 0;
  intptr_t repeat_count = 0;

  serializer->Write<uint32_t>(length());
  for (intptr_t i = 0; i < length(); i++) {
    const uword entry = array_[i];
    if (entry == prev_entry) {
      if (++repeat_count == kMaxRepeat) {
        serializer->Write<uint32_t>(kMaxRepeat);
        repeat_count = 0;
      }
    } else {
      if (repeat_count > 0) {
        serializer->Write<uint32_t>(repeat_count);
        repeat_count = 0;
      }
      if (entry == 0) {
        serializer->Write<uint32_t>(0);
      } else {
        bool found_recent = false;
        for (intptr_t r = 0; r < kRecentCount; r++) {
          if (recent[r] == entry) {
            serializer->Write<uint32_t>(~r);
            found_recent = true;
            break;
          }
        }
        if (!found_recent) {
          intptr_t index = entry_to_index.Lookup(entry) - 1;
          ASSERT(index != -1);
          ASSERT(EntryPointFor(Code::Handle(code_objects[index])) == entry);
          serializer->Write<uint32_t>(kIndexBase + index);
          recent[recent_index] = entry;
          recent_index = (recent_index + 1) & kRecentMask;
        }
      }
    }
    prev_entry = entry;
  }
  if (repeat_count > 0) {
    serializer->Write<uint32_t>(repeat_count);
  }
}

DispatchTable* DispatchTable::Deserialize(Deserializer* deserializer,
                                          const Array& code_array) {
  const intptr_t length = deserializer->Read<uint32_t>();
  if (length == 0) {
    return nullptr;
  }

  DispatchTable* table = new DispatchTable(length);

  Code& code = Code::Handle();

  code =
      deserializer->isolate()->object_store()->dispatch_table_null_error_stub();
  uword null_entry = code.EntryPoint();

  uword value = 0;
  uword recent[kRecentCount] = {0};
  intptr_t recent_index = 0;
  intptr_t repeat_count = 0;
  for (intptr_t i = 0; i < length; i++) {
    if (repeat_count > 0) {
      repeat_count--;
    } else {
      int32_t encoded = deserializer->Read<uint32_t>();
      if (encoded == 0) {
        value = null_entry;
      } else if (encoded < 0) {
        intptr_t r = ~encoded;
        ASSERT(r < kRecentCount);
        value = recent[r];
      } else if (encoded <= kMaxRepeat) {
        repeat_count = encoded - 1;
      } else {
        intptr_t index = encoded - kIndexBase;
        code ^= code_array.At(index);
        value = EntryPointFor(code);
        recent[recent_index] = value;
        recent_index = (recent_index + 1) & kRecentMask;
      }
    }
    table->array_[i] = value;
  }
  ASSERT(repeat_count == 0);

  return table;
}

}  // namespace dart
