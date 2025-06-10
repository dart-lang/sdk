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
  static constexpr int kInvalidName = -1;

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
class UnboxingInfoMetadata;

class StringIndex {
 public:
  StringIndex() : value_(-1) {}
  explicit StringIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};

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
      const ExternalTypedData& typed_data,
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
  intptr_t component_index_offset() { return component_index_offset_; }
  intptr_t library_count() { return library_count_; }

  // The data of the kernel file (single or multiple encoded components).
  const TypedDataBase& binary() { return *binary_; }

 private:
  explicit Program(const TypedDataBase* binary) : binary_(binary) {}

  bool single_program_;
  NameIndex main_method_reference_;  // Procedure.
  intptr_t library_count_;

  // The offset from the start of the binary to the start of the source table.
  intptr_t source_table_offset_;

  // The offset from the start of the binary to the start of the constant table.
  intptr_t constant_table_offset_;

  // The offset from the start of the binary to the start of the ending-index.
  intptr_t component_index_offset_;

  // The offset from the start of the binary to the canonical name table.
  intptr_t name_table_offset_;

  // The offset from the start of the binary to the metadata payloads.
  intptr_t metadata_payloads_offset_;

  // The offset from the start of the binary to the metadata mappings.
  intptr_t metadata_mappings_offset_;

  // The offset from the start of the binary to the start of the string table.
  intptr_t string_table_offset_;

  const TypedDataBase* binary_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(Program);
};

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

ProcedureAttributesMetadata ProcedureAttributesOf(const Function& function,
                                                  Zone* zone);

ProcedureAttributesMetadata ProcedureAttributesOf(const Field& field,
                                                  Zone* zone);

UnboxingInfoMetadata* UnboxingInfoMetadataOf(const Function& function,
                                             Zone* zone);

TableSelectorMetadata* TableSelectorMetadataForProgram(
    const KernelProgramInfo& info,
    Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
