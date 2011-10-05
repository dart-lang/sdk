// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEBUGINFO_H_
#define VM_DEBUGINFO_H_

#include "vm/assert.h"
#include "vm/globals.h"
#include "vm/utils.h"

namespace dart {

// A basic ByteArray which is growable and uses malloc/free.
class ByteArray {
 public:
  ByteArray() : size_(0), capacity_(0), data_(NULL) { }
  ~ByteArray() {
    free(data_);
    size_ = 0;
    capacity_ = 0;
    data_ = NULL;
  }

  uint8_t at(int index) const {
    ASSERT(0 <= index);
    ASSERT(index < size_);
    ASSERT(size_ <= capacity_);
    return data_[index];
  }

  uint8_t* data() const { return data_; }
  void set_data(uint8_t* value) { data_ = value; }
  int size() const { return size_; }

  // Append an element.
  void Add(const uint8_t value) {
    Resize(size() + 1);
    data_[size() - 1] = value;
  }

 private:
  void Resize(int new_size) {
    if (new_size > capacity_) {
      int new_capacity = Utils::RoundUpToPowerOfTwo(new_size);
      uint8_t* new_data =
          reinterpret_cast<uint8_t*>(realloc(data_, new_capacity));
      ASSERT(new_data != NULL);
      data_ = new_data;
      capacity_ = new_capacity;
    }
    size_ = new_size;
  }

  int size_;
  int capacity_;
  uint8_t* data_;

  // Disallow assignment
  DISALLOW_COPY_AND_ASSIGN(ByteArray);
};


// DebugInfo is used to generate minimal debug information containing code,
// symbols, and line numbers for generated code in the dart VM. This information
// can be used in two ways:
// - for debugging using a debugger
// - for generating information to be read by pprof to analyze Dart programs.
class DebugInfo {
 public:
  ~DebugInfo();

  // Add the code starting at pc.
  void AddCode(uword pc, intptr_t size);

  // Add symbol information for a region (includes the start and end symbol),
  // does not add the actual code.
  void AddCodeRegion(const char* name, uword pc, intptr_t size);

  // Write out all the debug information info the memory region.
  bool WriteToMemory(ByteArray* region);

  // Create a new debug information generator.
  static DebugInfo* NewGenerator();

  // Register this generated section with debuggger using the JIT interface.
  static void RegisterSection(const char* name,
                              uword entry_point,
                              intptr_t size);

  // Unregister all generated section from debuggger.
  static void UnregisterAllSections();

 private:
  void* handle_;
  DebugInfo();

  DISALLOW_COPY_AND_ASSIGN(DebugInfo);
};

}  // namespace dart

#endif  // VM_DEBUGINFO_H_
