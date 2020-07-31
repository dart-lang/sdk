// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_AOT_DISPATCH_TABLE_GENERATOR_H_
#define RUNTIME_VM_COMPILER_AOT_DISPATCH_TABLE_GENERATOR_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/object.h"

namespace dart {

class ClassTable;
class Precompiler;
class PrecompilerTracer;

namespace compiler {

class SelectorRow;

struct TableSelector {
  TableSelector(int32_t _id,
                int32_t _call_count,
                int32_t _offset,
                bool _called_on_null,
                bool _torn_off)
      : id(_id),
        call_count(_call_count),
        offset(_offset),
        called_on_null(_called_on_null),
        torn_off(_torn_off) {}

  bool IsUsed() const { return call_count > 0; }

  // ID assigned to the selector.
  int32_t id;
  // Number of dispatch table call sites with this selector (conservative:
  // number may be bigger, but not smaller, than actual number of call sites).
  int32_t call_count;
  // Table offset assigned to the selector by the dispatch table generator.
  int32_t offset;
  // Are there any call sites with this selector where the receiver may be null?
  bool called_on_null;
  // Is this method ever torn off, i.e. is its method extractor accessed?
  bool torn_off;
  // Is the selector part of the interface on Null (same as Object)?
  bool on_null_interface = false;
  // Do any targets of this selector assume that an args descriptor is passed?
  bool requires_args_descriptor = false;
};

class SelectorMap {
 public:
  explicit SelectorMap(Zone* zone) : zone_(zone) {}

  // Get the selector for this interface target, or null if the function does
  // not have a selector assigned.
  const TableSelector* GetSelector(const Function& interface_target) const;

 private:
  static const int32_t kInvalidSelectorId =
      kernel::ProcedureAttributesMetadata::kInvalidSelectorId;
  static const int32_t kInvalidSelectorOffset = -1;

  int32_t SelectorId(const Function& interface_target) const;

  void AddSelector(int32_t call_count, bool called_on_null, bool torn_off);
  void SetSelectorProperties(int32_t sid,
                             bool on_null_interface,
                             bool requires_args_descriptor);

  int32_t NumIds() const { return selectors_.length(); }

  friend class dart::Precompiler;
  friend class dart::PrecompilerTracer;
  friend class DispatchTableGenerator;
  friend class SelectorRow;

  Zone* zone_;
  GrowableArray<TableSelector> selectors_;
};

class DispatchTableGenerator {
 public:
  explicit DispatchTableGenerator(Zone* zone);

  SelectorMap* selector_map() { return &selector_map_; }

  // Find suitable selectors and compute offsets for them.
  void Initialize(ClassTable* table);

  // Build up an array of Code objects, used to serialize the information
  // deserialized as a DispatchTable at runtime.
  ArrayPtr BuildCodeArray();

 private:
  void ReadTableSelectorInfo();
  void NumberSelectors();
  void SetupSelectorRows();
  void ComputeSelectorOffsets();

  Zone* const zone_;
  ClassTable* classes_;
  int32_t num_selectors_;
  int32_t num_classes_;
  int32_t table_size_;

  GrowableArray<SelectorRow*> table_rows_;

  SelectorMap selector_map_;
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_AOT_DISPATCH_TABLE_GENERATOR_H_
