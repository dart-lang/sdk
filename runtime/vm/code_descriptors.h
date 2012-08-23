// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_DESCRIPTORS_H_
#define VM_CODE_DESCRIPTORS_H_

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

class DescriptorList : public ZoneAllocated {
 public:
  struct PcDesc {
    intptr_t pc_offset;        // PC offset value of the descriptor.
    PcDescriptors::Kind kind;  // Descriptor kind (kDeopt, kOther).
    intptr_t deopt_id;         // Deoptimization id.
    intptr_t token_index;      // Token position in source of PC.
    intptr_t try_index;        // Try block index of PC or deopt array index.
  };

  explicit DescriptorList(intptr_t initial_capacity) : list_(initial_capacity) {
  }
  ~DescriptorList() { }

  intptr_t Length() const {
    return list_.length();
  }

  intptr_t PcOffset(int index) const {
    return list_[index].pc_offset;
  }
  PcDescriptors::Kind Kind(int index) const {
    return list_[index].kind;
  }
  intptr_t DeoptId(int index) const {
    return list_[index].deopt_id;
  }
  intptr_t TokenPos(int index) const {
    return list_[index].token_index;
  }
  intptr_t TryIndex(int index) const {
    return list_[index].try_index;
  }

  void AddDescriptor(PcDescriptors::Kind kind,
                     intptr_t pc_offset,
                     intptr_t deopt_id,
                     intptr_t token_index,
                     intptr_t try_index);
  void AddDeoptInfo(intptr_t pc_offset,
                    intptr_t deopt_id,
                    intptr_t token_index,
                    intptr_t deopt_array_index);

  RawPcDescriptors* FinalizePcDescriptors(uword entry_point);

 private:
  GrowableArray<struct PcDesc> list_;
  DISALLOW_COPY_AND_ASSIGN(DescriptorList);
};


class StackmapTableBuilder : public ZoneAllocated {
 public:
  explicit StackmapTableBuilder(intptr_t entry_length)
      : entry_length_(entry_length),
        stack_map_(Stackmap::ZoneHandle()),
        list_(GrowableObjectArray::ZoneHandle(
            GrowableObjectArray::New(Heap::kOld))) { }
  ~StackmapTableBuilder() { }

  void AddEntry(intptr_t pc_offset, BitmapBuilder* bitmap);

  bool Verify();

  RawArray* FinalizeStackmaps(const Code& code);

 private:
  intptr_t Length() const { return list_.Length(); }
  RawStackmap* MapAt(int index) const;

  // All the stackmaps in a function have the same length.
  const intptr_t entry_length_;
  Stackmap& stack_map_;
  GrowableObjectArray& list_;
  DISALLOW_COPY_AND_ASSIGN(StackmapTableBuilder);
};


class ExceptionHandlerList : public ZoneAllocated {
 public:
  struct HandlerDesc {
    intptr_t try_index;  // Try block index handled by the handler.
    intptr_t pc_offset;  // Handler PC offset value.
  };

  ExceptionHandlerList() : list_() {}

  intptr_t Length() const {
    return list_.length();
  }

  intptr_t TryIndex(int index) const {
    return list_[index].try_index;
  }
  intptr_t PcOffset(int index) const {
    return list_[index].pc_offset;
  }
  void SetPcOffset(int index, intptr_t handler_pc) {
    list_[index].pc_offset = handler_pc;
  }

  void AddHandler(intptr_t try_index, intptr_t pc_offset) {
    struct HandlerDesc data;
    data.try_index = try_index;
    data.pc_offset = pc_offset;
    list_.Add(data);
  }

  RawExceptionHandlers* FinalizeExceptionHandlers(uword entry_point) {
    intptr_t num_handlers = Length();
    const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(ExceptionHandlers::New(num_handlers));
    for (intptr_t i = 0; i < num_handlers; i++) {
      handlers.SetHandlerEntry(i, TryIndex(i), (entry_point + PcOffset(i)));
    }
    return handlers.raw();
  }

 private:
  GrowableArray<struct HandlerDesc> list_;
  DISALLOW_COPY_AND_ASSIGN(ExceptionHandlerList);
};

}  // namespace dart

#endif  // VM_CODE_DESCRIPTORS_H_
