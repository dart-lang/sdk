// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FFI_NATIVE_ASSETS_H_
#define RUNTIME_VM_FFI_NATIVE_ASSETS_H_

#include "vm/hash_table.h"
#include "vm/tagged_pointer.h"
#include "vm/thread.h"

namespace dart {

class NativeAssetsMapTraits {
 public:
  static const char* Name() { return "NativeAssetsMapTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const String& a_str = String::Cast(a);
    const String& b_str = String::Cast(b);

    ASSERT(a_str.HasHash() && b_str.HasHash());
    return a_str.Equals(b_str);
  }

  static uword Hash(const Object& key) { return String::Cast(key).Hash(); }

  static ObjectPtr NewKey(const String& str) { return str.ptr(); }
};
typedef UnorderedHashMap<NativeAssetsMapTraits> NativeAssetsMap;

// In JIT: Populates object_store->native_assets_map with the right info from
// object_store->native_assets_library.
//
// In AOT: The object_store->native_assets_library should have been
// pre-populated from the aotsnapshot.
ArrayPtr GetNativeAssetsMap(Thread* thread);

}  // namespace dart

#endif  // RUNTIME_VM_FFI_NATIVE_ASSETS_H_
