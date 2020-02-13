// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_AOT_DISPATCH_TABLE_GENERATOR_H_
#define RUNTIME_VM_COMPILER_AOT_DISPATCH_TABLE_GENERATOR_H_

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/dispatch_table.h"
#include "vm/object.h"

namespace dart {

class ClassTable;
class Precompiler;

namespace compiler {

class SelectorRow;

struct TableSelector {
  TableSelector(int32_t id, int32_t call_count, int32_t offset)
      : id(id), call_count(call_count), offset(offset) {}

  bool IsUsed() const { return call_count > 0; }

  int32_t id;
  int32_t call_count;
  int32_t offset;
  bool on_null_interface = false;
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

  void AddSelector(int32_t call_count);
  void SetSelectorProperties(int32_t sid,
                             bool on_null_interface,
                             bool requires_args_descriptor);
  void SetSelectorOffset(int32_t sid, int32_t offset);

  int32_t NumIds() const { return selectors_.length(); }

  friend class dart::Precompiler;
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

  // Build up the table.
  DispatchTable* BuildTable();

 private:
  void ReadTableSelectorInfo();
  void NumberSelectors();
  void SetupSelectorRows();
  void ComputeSelectorOffsets();

  Zone* zone_;
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
