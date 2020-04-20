// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file (and "raw_object_fields.cc") provide a kind of reflection that
// allows us to identify the name of fields in hand-written "Raw..." classes
// (from "raw_object.h") given the class and the offset within the object. This
// is used for example by the snapshot profile writer ("v8_snapshot_writer.h")
// to show the property names of these built-in objects in the snapshot profile.

#ifndef RUNTIME_VM_RAW_OBJECT_FIELDS_H_
#define RUNTIME_VM_RAW_OBJECT_FIELDS_H_

#include <utility>

#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

#if defined(DART_PRECOMPILER) || !defined(DART_PRODUCT)

class OffsetsTable : public ZoneAllocated {
 public:
  explicit OffsetsTable(Zone* zone);

  // Returns 'nullptr' if no offset was found.
  // Otherwise, the returned string is allocated in global static memory.
  const char* FieldNameForOffset(intptr_t cid, intptr_t offset);

  struct OffsetsTableEntry {
    const intptr_t class_id;
    const char* field_name;
    intptr_t offset;
  };

  static OffsetsTableEntry offsets_table[];

 private:
  struct IntAndIntToStringMapTraits {
    typedef std::pair<intptr_t, intptr_t> Key;
    typedef const char* Value;

    struct Pair {
      Key key;
      Value value;
      Pair() : key({-1, -1}), value(nullptr) {}
      Pair(Key k, Value v) : key(k), value(v) {}
    };

    static Value ValueOf(Pair pair) { return pair.value; }
    static Key KeyOf(Pair pair) { return pair.key; }
    static size_t Hashcode(Key key) { return key.first ^ key.second; }
    static bool IsKeyEqual(Pair x, Key y) {
      return x.key.first == y.first && x.key.second == y.second;
    }
  };

  DirectChainedHashMap<IntAndIntToStringMapTraits> cached_offsets_;
};

#else

class OffsetsTable : public ZoneAllocated {
 public:
  explicit OffsetsTable(Zone* zone) {}

  const char* FieldNameForOffset(intptr_t cid, intptr_t offset) {
    return nullptr;
  }
};

#endif

}  // namespace dart

#endif  // RUNTIME_VM_RAW_OBJECT_FIELDS_H_
