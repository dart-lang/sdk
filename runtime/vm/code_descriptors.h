// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_DESCRIPTORS_H_
#define RUNTIME_VM_CODE_DESCRIPTORS_H_

#include "vm/ast.h"
#include "vm/code_generator.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

class DescriptorList : public ZoneAllocated {
 public:
  explicit DescriptorList(intptr_t initial_capacity)
    : encoded_data_(initial_capacity),
      prev_pc_offset(0),
      prev_deopt_id(0),
      prev_token_pos(0) {}

  ~DescriptorList() { }

  void AddDescriptor(RawPcDescriptors::Kind kind,
                     intptr_t pc_offset,
                     intptr_t deopt_id,
                     TokenPosition token_pos,
                     intptr_t try_index);

  RawPcDescriptors* FinalizePcDescriptors(uword entry_point);

 private:
  GrowableArray<uint8_t> encoded_data_;

  intptr_t prev_pc_offset;
  intptr_t prev_deopt_id;
  intptr_t prev_token_pos;

  DISALLOW_COPY_AND_ASSIGN(DescriptorList);
};


class CodeSourceMapBuilder : public ZoneAllocated {
 public:
  explicit CodeSourceMapBuilder(intptr_t initial_capacity = 64)
    : encoded_data_(initial_capacity),
      prev_pc_offset(0),
      prev_token_pos(0) {}

  ~CodeSourceMapBuilder() { }

  void AddEntry(intptr_t pc_offset, TokenPosition token_pos);

  RawCodeSourceMap* Finalize();

 private:
  GrowableArray<uint8_t> encoded_data_;

  intptr_t prev_pc_offset;
  intptr_t prev_token_pos;

  DISALLOW_COPY_AND_ASSIGN(CodeSourceMapBuilder);
};


class StackmapTableBuilder : public ZoneAllocated {
 public:
  StackmapTableBuilder()
      : stack_map_(Stackmap::ZoneHandle()),
        list_(GrowableObjectArray::ZoneHandle(
            GrowableObjectArray::New(Heap::kOld))) { }
  ~StackmapTableBuilder() { }

  void AddEntry(intptr_t pc_offset,
                BitmapBuilder* bitmap,
                intptr_t register_bit_count);

  bool Verify();

  RawArray* FinalizeStackmaps(const Code& code);

 private:
  intptr_t Length() const { return list_.Length(); }
  RawStackmap* MapAt(intptr_t index) const;

  Stackmap& stack_map_;
  GrowableObjectArray& list_;
  DISALLOW_COPY_AND_ASSIGN(StackmapTableBuilder);
};


class ExceptionHandlerList : public ZoneAllocated {
 public:
  struct HandlerDesc {
    intptr_t outer_try_index;  // Try block in which this try block is nested.
    intptr_t pc_offset;        // Handler PC offset value.
    const Array* handler_types;   // Catch clause guards.
    bool needs_stacktrace;
  };

  ExceptionHandlerList() : list_() {}

  intptr_t Length() const {
    return list_.length();
  }

  void AddPlaceHolder() {
    struct HandlerDesc data;
    data.outer_try_index = -1;
    data.pc_offset = ExceptionHandlers::kInvalidPcOffset;
    data.handler_types = NULL;
    data.needs_stacktrace = false;
    list_.Add(data);
  }

  void AddHandler(intptr_t try_index,
                  intptr_t outer_try_index,
                  intptr_t pc_offset,
                  const Array& handler_types,
                  bool needs_stacktrace) {
    ASSERT(try_index >= 0);
    while (Length() <= try_index) {
      AddPlaceHolder();
    }
    list_[try_index].outer_try_index = outer_try_index;
    ASSERT(list_[try_index].pc_offset == ExceptionHandlers::kInvalidPcOffset);
    list_[try_index].pc_offset = pc_offset;
    ASSERT(handler_types.IsZoneHandle());
    list_[try_index].handler_types = &handler_types;
    list_[try_index].needs_stacktrace |= needs_stacktrace;
  }


  // Called by rethrows, to mark their enclosing handlers.
  void SetNeedsStacktrace(intptr_t try_index) {
    // Rethrows can be generated outside a try by the compiler.
    if (try_index == CatchClauseNode::kInvalidTryIndex) {
      return;
    }
    ASSERT(try_index >= 0);
    while (Length() <= try_index) {
      AddPlaceHolder();
    }
    list_[try_index].needs_stacktrace = true;
  }


  static bool ContainsDynamic(const Array& array) {
    for (intptr_t i = 0; i < array.Length(); i++) {
      if (array.At(i) == Type::DynamicType()) {
        return true;
      }
    }
    return false;
  }

  RawExceptionHandlers* FinalizeExceptionHandlers(uword entry_point) const;

 private:
  GrowableArray<struct HandlerDesc> list_;
  DISALLOW_COPY_AND_ASSIGN(ExceptionHandlerList);
};

}  // namespace dart

#endif  // RUNTIME_VM_CODE_DESCRIPTORS_H_
