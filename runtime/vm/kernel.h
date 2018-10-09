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
struct ProcedureAttributesMetadata;

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
  // Read a kernel Program from the given Reader. Note the returned Program
  // can potentially contain several "sub programs", though the library count
  // etc will reference the last "sub program" only.
  static Program* ReadFrom(Reader* reader, const char** error = nullptr);

  static Program* ReadFromFile(const char* script_uri);
  static Program* ReadFromBuffer(const uint8_t* buffer,
                                 intptr_t buffer_length,
                                 const char** error = nullptr);
  static Program* ReadFromTypedData(const ExternalTypedData& typed_data,
                                    const char** error = nullptr);

  bool is_single_program() { return single_program_; }
  NameIndex main_method() { return main_method_reference_; }
  intptr_t source_table_offset() const { return source_table_offset_; }
  intptr_t string_table_offset() const { return string_table_offset_; }
  intptr_t name_table_offset() const { return name_table_offset_; }
  intptr_t metadata_payloads_offset() const {
    return metadata_payloads_offset_;
  }
  intptr_t metadata_mappings_offset() const {
    return metadata_mappings_offset_;
  }
  intptr_t constant_table_offset() { return constant_table_offset_; }
  const uint8_t* kernel_data() { return kernel_data_; }
  intptr_t kernel_data_size() { return kernel_data_size_; }
  intptr_t library_count() { return library_count_; }

 private:
  Program() : kernel_data_(NULL), kernel_data_size_(-1) {}

  bool single_program_;
  NameIndex main_method_reference_;  // Procedure.
  intptr_t library_count_;

  // The offset from the start of the binary to the start of the source table.
  intptr_t source_table_offset_;

  // The offset from the start of the binary to the start of the constant table.
  intptr_t constant_table_offset_;

  // The offset from the start of the binary to the canonical name table.
  intptr_t name_table_offset_;

  // The offset from the start of the binary to the metadata payloads.
  intptr_t metadata_payloads_offset_;

  // The offset from the start of the binary to the metadata mappings.
  intptr_t metadata_mappings_offset_;

  // The offset from the start of the binary to the start of the string table.
  intptr_t string_table_offset_;

  const uint8_t* kernel_data_;
  intptr_t kernel_data_size_;

  DISALLOW_COPY_AND_ASSIGN(Program);
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

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end);

void CollectTokenPositionsFor(const Script& script);

RawObject* EvaluateMetadata(const Field& metadata_field,
                            bool is_annotations_offset);
RawObject* BuildParameterDescriptor(const Function& function);

// Returns true if the given function needs dynamic invocation forwarder:
// that is if any of the arguments require checking on the dynamic
// call-site: if function has no parameters or has only covariant parameters
// as such function already checks all of its parameters.
bool NeedsDynamicInvocationForwarder(const Function& function);

bool IsFieldInitializer(const Function& function, Zone* zone);

ProcedureAttributesMetadata ProcedureAttributesOf(const Function& function,
                                                  Zone* zone);

ProcedureAttributesMetadata ProcedureAttributesOf(const Field& field,
                                                  Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
