// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DISPATCH_TABLE_H_
#define RUNTIME_VM_DISPATCH_TABLE_H_

#include <memory>

#include "vm/globals.h"
#include "vm/growable_array.h"

namespace dart {

class Array;
class Code;
class Deserializer;
class RawCode;
class Serializer;

namespace compiler {
class DispatchTableGenerator;
}

class DispatchTable {
 public:
  explicit DispatchTable(intptr_t length)
      : length_(length), array_(new uword[length]()) {}

  intptr_t length() const { return length_; }
  uword* array() const { return array_.get(); }

  // The element of the dispatch table array to which the dispatch table
  // register points.
  static intptr_t OriginElement() {
#if defined(TARGET_ARCH_X64)
    // Max negative byte offset / 8
    return 16;
#elif defined(TARGET_ARCH_ARM)
    // Max negative load offset / 4
    return 1023;
#elif defined(TARGET_ARCH_ARM64)
    // Max consecutive sub immediate value
    return 4096;
#else
    // No AOT on IA32
    UNREACHABLE();
    return 0;
#endif
  }

  // The largest offset that can use a more compact instruction sequence.
  static intptr_t LargestSmallOffset() {
#if defined(TARGET_ARCH_X64)
    // Origin + Max positive byte offset / 8
    return 31;
#elif defined(TARGET_ARCH_ARM)
    // Origin + Max positive load offset / 4
    return 2046;
#elif defined(TARGET_ARCH_ARM64)
    // Origin + Max consecutive add immediate value
    return 8192;
#else
    // No AOT on IA32
    UNREACHABLE();
    return 0;
#endif
  }

  // Dispatch table array pointer to put into the dispatch table register.
  uword* ArrayOrigin() const { return &array()[OriginElement()]; }

  void SetCodeAt(intptr_t index, const Code& code);

  static intptr_t Serialize(Serializer* serializer,
                            const DispatchTable* table,
                            const GrowableArray<RawCode*>& code_objects);
  static DispatchTable* Deserialize(Deserializer* deserializer,
                                    const Array& code_array);

 private:
  friend class compiler::DispatchTableGenerator;

  void Serialize(Serializer* serializer,
                 const GrowableArray<RawCode*>& code_objects) const;

  static uword EntryPointFor(const Code& code);

  intptr_t length_;
  std::unique_ptr<uword[]> array_;

  DISALLOW_COPY_AND_ASSIGN(DispatchTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_DISPATCH_TABLE_H_
