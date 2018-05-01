// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_H_
#define RUNTIME_VM_KERNEL_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/token_position.h"

namespace dart {
namespace kernel {
class NameIndex {
 public:
  static const int kInvalidName = -1;

  NameIndex() : value_(kInvalidName) {}
  explicit NameIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};
}  // namespace kernel
}  // namespace dart

#if !defined(DART_PRECOMPILED_RUNTIME)
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

  static Program* ReadFromFile(const char* script_uri);
  static Program* ReadFromBuffer(const uint8_t* buffer,
                                 intptr_t buffer_length,
                                 bool take_buffer_ownership = true);

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

class KernelSourceFingerprintHelper {
 public:
  static uint32_t CalculateClassFingerprint(const Class& klass);
  static uint32_t CalculateFieldFingerprint(const Field& field);
  static uint32_t CalculateFunctionFingerprint(const Function& func);
};

class KernelLineStartsReader {
 public:
  KernelLineStartsReader(const dart::TypedData& line_starts_data,
                         dart::Zone* zone);

  ~KernelLineStartsReader() { delete helper_; }

  int32_t DeltaAt(intptr_t index) const {
    return helper_->At(line_starts_data_, index);
  }

  intptr_t LineNumberForPosition(intptr_t position) const;

  void LocationForPosition(intptr_t position,
                           intptr_t* line,
                           intptr_t* col) const;

  void TokenRangeAtLine(intptr_t source_length,
                        intptr_t line_number,
                        dart::TokenPosition* first_token_index,
                        dart::TokenPosition* last_token_index) const;

 private:
  class KernelLineStartsHelper {
   public:
    KernelLineStartsHelper() {}
    virtual ~KernelLineStartsHelper() {}
    virtual int32_t At(const dart::TypedData& data, intptr_t index) const = 0;

   private:
    DISALLOW_COPY_AND_ASSIGN(KernelLineStartsHelper);
  };

  class KernelInt8LineStartsHelper : public KernelLineStartsHelper {
   public:
    KernelInt8LineStartsHelper() {}
    virtual int32_t At(const dart::TypedData& data, intptr_t index) const;

   private:
    DISALLOW_COPY_AND_ASSIGN(KernelInt8LineStartsHelper);
  };

  class KernelInt16LineStartsHelper : public KernelLineStartsHelper {
   public:
    KernelInt16LineStartsHelper() {}
    virtual int32_t At(const dart::TypedData& data, intptr_t index) const;

   private:
    DISALLOW_COPY_AND_ASSIGN(KernelInt16LineStartsHelper);
  };

  class KernelInt32LineStartsHelper : public KernelLineStartsHelper {
   public:
    KernelInt32LineStartsHelper() {}
    virtual int32_t At(const dart::TypedData& data, intptr_t index) const;

   private:
    DISALLOW_COPY_AND_ASSIGN(KernelInt32LineStartsHelper);
  };

  const dart::TypedData& line_starts_data_;
  KernelLineStartsHelper* helper_;

  DISALLOW_COPY_AND_ASSIGN(KernelLineStartsReader);
};

RawFunction* CreateFieldInitializerFunction(Thread* thread,
                                            Zone* zone,
                                            const Field& field);

ParsedFunction* ParseStaticFieldInitializer(Zone* zone, const Field& field);

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
