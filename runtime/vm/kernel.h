// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_H_
#define RUNTIME_VM_KERNEL_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/token_position.h"

namespace dart {

class Field;
class ParsedFunction;
class Zone;

namespace kernel {

class Reader;

class StringIndex {
 public:
  StringIndex() : value_(-1) {}
  explicit StringIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};

class NameIndex {
 public:
  NameIndex() : value_(-1) {}
  explicit NameIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};

const uint8_t kNativeYieldFlags = 0x2;

enum LogicalOperator { kAnd, kOr };

class Program {
 public:
  ~Program() {
    if (buffer_ownership_ && kernel_data_ != NULL) {
      ASSERT(release_callback != NULL);
      release_callback(const_cast<uint8_t*>(kernel_data_));
    }
    kernel_data_ = NULL;
  }

  /**
   * Read a kernel Program from the given Reader. Note the returned Program
   * can potentially contain several "sub programs", though the library count
   * etc will reference the last "sub program" only.
   * @param reader
   * @param take_buffer_ownership if set to true, the release callback will be
   * called upon Program destruction, i.e. the data from reader will likely be
   * released. If set to false the data will not be released. This is for
   * instance useful for creating Programs out of "sub programs" where each
   * "sub program" should not try to release the buffer.
   * @return
   */
  static Program* ReadFrom(Reader* reader, bool take_buffer_ownership = true);

  bool is_single_program() { return single_program_; }
  NameIndex main_method() { return main_method_reference_; }
  intptr_t source_table_offset() const { return source_table_offset_; }
  intptr_t string_table_offset() const { return string_table_offset_; }
  intptr_t name_table_offset() const { return name_table_offset_; }
  intptr_t constant_table_offset() { return constant_table_offset_; }
  const uint8_t* kernel_data() { return kernel_data_; }
  intptr_t kernel_data_size() { return kernel_data_size_; }
  intptr_t library_count() { return library_count_; }
  void set_release_buffer_callback(Dart_ReleaseBufferCallback callback) {
    release_callback = callback;
  }

 private:
  Program()
      : kernel_data_(NULL), kernel_data_size_(-1), release_callback(NULL) {}

  bool single_program_;
  bool buffer_ownership_;
  NameIndex main_method_reference_;  // Procedure.
  intptr_t library_count_;

  // The offset from the start of the binary to the start of the source table.
  intptr_t source_table_offset_;

  // The offset from the start of the binary to the start of the constant table.
  intptr_t constant_table_offset_;

  // The offset from the start of the binary to the canonical name table.
  intptr_t name_table_offset_;

  // The offset from the start of the binary to the start of the string table.
  intptr_t string_table_offset_;

  const uint8_t* kernel_data_;
  intptr_t kernel_data_size_;
  Dart_ReleaseBufferCallback release_callback;

  DISALLOW_COPY_AND_ASSIGN(Program);
};

ParsedFunction* ParseStaticFieldInitializer(Zone* zone, const Field& field);

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end);

}  // namespace kernel

kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length);

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
