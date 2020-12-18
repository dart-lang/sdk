// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_H_
#define RUNTIME_VM_KERNEL_H_

#include <memory>

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

class BitVector;
class Field;
class ParsedFunction;
class Zone;

namespace kernel {

class Reader;
struct ProcedureAttributesMetadata;
class TableSelectorMetadata;

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
  static std::unique_ptr<Program> ReadFrom(Reader* reader,
                                           const char** error = nullptr);

  static std::unique_ptr<Program> ReadFromFile(const char* script_uri,
                                               const char** error = nullptr);
  static std::unique_ptr<Program> ReadFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length,
                                                 const char** error = nullptr);
  static std::unique_ptr<Program> ReadFromTypedData(
      const ExternalTypedData& typed_data, const char** error = nullptr);

  bool is_single_program() { return single_program_; }
  uint32_t binary_version() { return binary_version_; }
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
  const ExternalTypedData* typed_data() { return typed_data_; }
  const uint8_t* kernel_data() { return kernel_data_; }
  intptr_t kernel_data_size() { return kernel_data_size_; }
  intptr_t library_count() { return library_count_; }
  NNBDCompiledMode compilation_mode() const { return compilation_mode_; }

 private:
  Program() : typed_data_(NULL), kernel_data_(NULL), kernel_data_size_(-1) {}

  bool single_program_;
  uint32_t binary_version_;
  NameIndex main_method_reference_;  // Procedure.
  NNBDCompiledMode compilation_mode_;
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

  const ExternalTypedData* typed_data_;
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

  int32_t MaxPosition() const;

  // Returns whether the given offset corresponds to a valid source offset
  // If it does, then *line and *column (if column is not nullptr) are set
  // to the line and column the token starts at.
  DART_WARN_UNUSED_RESULT bool LocationForPosition(
      intptr_t position,
      intptr_t* line,
      intptr_t* col = nullptr) const;

  // Returns whether any tokens were found for the given line. When found,
  // *first_token_index and *last_token_index are set to the first and
  // last token on the line, respectively.
  DART_WARN_UNUSED_RESULT bool TokenRangeAtLine(
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

void CollectTokenPositionsFor(const Script& script);

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
ArrayPtr CollectConstConstructorCoverageFrom(const Script& interesting_script);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

ObjectPtr EvaluateStaticConstFieldInitializer(const Field& field);
ObjectPtr EvaluateMetadata(const Library& library,
                           intptr_t kernel_offset,
                           bool is_annotations_offset);
ObjectPtr BuildParameterDescriptor(const Function& function);

// Fills in [is_covariant] and [is_generic_covariant_impl] vectors
// according to covariance attributes of [function] parameters.
//
// [is_covariant] and [is_generic_covariant_impl] should contain bitvectors
// of function.NumParameters() length.
void ReadParameterCovariance(const Function& function,
                             BitVector* is_covariant,
                             BitVector* is_generic_covariant_impl);

// Returns true if the given function needs dynamic invocation forwarder:
// that is if any of the arguments require checking on the dynamic
// call-site: if function has no parameters or has only covariant parameters
// as such function already checks all of its parameters.
bool NeedsDynamicInvocationForwarder(const Function& function);

ProcedureAttributesMetadata ProcedureAttributesOf(const Function& function,
                                                  Zone* zone);

ProcedureAttributesMetadata ProcedureAttributesOf(const Field& field,
                                                  Zone* zone);

TableSelectorMetadata* TableSelectorMetadataForProgram(
    const KernelProgramInfo& info,
    Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
