// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_PRECOMPILER) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/aot/dispatch_table_generator.h"

#include <memory>

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/stub_code.h"
#include "vm/thread.h"

#define Z zone_

namespace dart {
namespace compiler {

class Interval {
 public:
  Interval() : begin_(-1), end_(-1) {}
  Interval(int32_t begin, int32_t end) : begin_(begin), end_(end) {
    ASSERT(end > begin);
  }

  int32_t begin() const { return begin_; }
  void set_begin(int32_t value) { begin_ = value; }

  int32_t end() const { return end_; }
  void set_end(int32_t value) { end_ = value; }

  int32_t length() const { return end_ - begin_; }

  Interval WithOffset(int32_t offset) const {
    return Interval(begin_ + offset, end_ + offset);
  }

  bool IsSame(const Interval other) const {
    return end() == other.end() && begin() == other.begin();
  }

  bool IsBefore(const Interval other) const { return end() <= other.begin(); }

  bool IsAfter(const Interval other) const { return begin() >= other.end(); }

  bool Overlap(const Interval other) const {
    return !IsBefore(other) && !IsAfter(other);
  }

  bool ContainsBeginOf(const Interval other) const {
    return begin() <= other.begin() && other.begin() <= end();
  }

  bool ContainsEndOf(const Interval other) const {
    return begin() <= other.end() && other.end() <= end();
  }

  bool Contains(const Interval other) const {
    return ContainsBeginOf(other) && ContainsEndOf(other);
  }

  void ExtendToIncludeInterval(const Interval& other) {
    if (other.begin() < begin_) begin_ = other.begin();
    if (other.end() > end_) end_ = other.end();
  }

 private:
  int32_t begin_;
  int32_t end_;
};

class CidInterval {
 public:
  CidInterval(classid_t cid,
              int16_t depth,
              Interval range,
              const Function* function)
      : cid_(cid), depth_(depth), range_(range), function_(function) {}

  classid_t cid() const { return cid_; }
  int16_t depth() const { return depth_; }
  const Interval& range() const { return range_; }
  Interval& range() { return range_; }
  const Function* function() const { return function_; }

 private:
  classid_t cid_;
  int16_t depth_;
  Interval range_;
  const Function* function_;
};

class SelectorRow {
 public:
  SelectorRow(Zone* zone, int32_t selector_id)
      : selector_id_(selector_id), class_ranges_(zone, 0), ranges_(zone, 0) {}

  int32_t selector_id() const { return selector_id_; }

  void DefineSelectorImplementationForInterval(classid_t cid,
                                               int16_t depth,
                                               const Interval& range,
                                               const Function& function);
  bool Finalize();

  int32_t total_size() const { return total_size_; }

  const GrowableArray<Interval>& ranges() const { return ranges_; }

  const GrowableArray<CidInterval>& class_ranges() const {
    return class_ranges_;
  }

  int32_t offset() const { return offset_; }
  void set_offset(int32_t value) { offset_ = value; }

  void FillTable(ClassTable* class_table, DispatchTable* table);

 private:
  int32_t selector_id_;
  int32_t offset_ = SelectorMap::kInvalidSelectorOffset;
  int32_t total_size_ = 0;

  GrowableArray<CidInterval> class_ranges_;
  GrowableArray<Interval> ranges_;
};

class RowFitter {
 public:
  RowFitter() { free_slots_.Add(Interval(0, INT_MAX)); }

  int32_t Fit(SelectorRow* row);

  int32_t TableSize() const { return free_slots_.Last().begin(); }

 private:
  int32_t FindOffset(const GrowableArray<Interval>& ranges,
                     intptr_t* result_slot_index);

  int32_t MatchRemaining(int32_t offset,
                         const GrowableArray<Interval>& ranges,
                         intptr_t slot_index);

  intptr_t MoveForwardToCover(const Interval range, intptr_t slot_index);

  void UpdateFreeSlots(int32_t offset,
                       const GrowableArray<Interval>& ranges,
                       intptr_t slot_index);

  intptr_t FitInFreeSlot(const Interval range, intptr_t slot_index);

  GrowableArray<Interval> free_slots_;
};

void SelectorRow::DefineSelectorImplementationForInterval(
    classid_t cid,
    int16_t depth,
    const Interval& range,
    const Function& function) {
  CidInterval cid_range(cid, depth, range, &function);
  class_ranges_.Add(cid_range);
}

bool SelectorRow::Finalize() {
  if (class_ranges_.length() == 0) {
    return false;
  }

  // Make a list of [begin, end) ranges which are disjunct and cover all
  // areas that [class_ranges_] cover (i.e. there can be holes, but no overlap).
  for (intptr_t i = 0; i < class_ranges_.length(); i++) {
    ranges_.Add(class_ranges_[i].range());
  }

  struct IntervalSorter {
    static int Compare(const Interval* a, const Interval* b) {
      if (a->begin() != b->begin()) {
        return a->begin() - b->begin();
      }
      return b->length() - a->length();
    }
  };

  ranges_.Sort(IntervalSorter::Compare);

  intptr_t current_index = 0;
  intptr_t write_index = 1;
  intptr_t read_index = 1;
  for (; read_index < ranges_.length(); read_index++) {
    Interval& current_range = ranges_[current_index];
    Interval& next_range = ranges_[read_index];
    if (current_range.Contains(next_range)) {
      // We drop the entry.
    } else if (current_range.end() == next_range.begin()) {
      // We extend the current entry and drop the entry.
      current_range.ExtendToIncludeInterval(next_range);
    } else {
      // We keep the entry.
      if (read_index != write_index) {
        ranges_[write_index] = ranges_[read_index];
      }
      current_index = write_index;
      write_index++;
    }
  }
  ranges_.TruncateTo(write_index);

  for (intptr_t i = 0; i < ranges_.length() - 1; i++) {
    const Interval& a = ranges_[i];
    const Interval& b = ranges_[i + 1];
    ASSERT(a.begin() < b.begin());
    ASSERT(a.end() < b.begin());
  }

  for (intptr_t i = 0; i < ranges_.length(); i++) {
    total_size_ += ranges_[i].length();
  }

  return true;
}

void SelectorRow::FillTable(ClassTable* class_table, DispatchTable* table) {
  // Define the entries in the table by going top-down, which means more
  // specific ones will override more general ones.

  Code& code = Code::Handle();

  // Sort by depth.
  struct IntervalSorter {
    static int Compare(const CidInterval* a, const CidInterval* b) {
      ASSERT(a == b || a->depth() != b->depth() ||
             !a->range().Overlap(b->range()));
      return a->depth() - b->depth();
    }
  };
  class_ranges_.Sort(IntervalSorter::Compare);

  for (intptr_t i = 0; i < class_ranges_.length(); i++) {
    const CidInterval& cid_range = class_ranges_[i];
    const Interval& range = cid_range.range();
    const Function* function = cid_range.function();
    if (function->HasCode()) {
      code = function->CurrentCode();
      for (classid_t cid = range.begin(); cid < range.end(); cid++) {
        table->SetCodeAt(offset_ + cid, code);
      }
    }
  }
}

int32_t RowFitter::Fit(SelectorRow* row) {
  ASSERT(row->ranges().length() > 0);
  const GrowableArray<Interval>& ranges = row->ranges();

  intptr_t slot_index;
  const int32_t offset = FindOffset(ranges, &slot_index);
  UpdateFreeSlots(offset, ranges, slot_index);

  return offset;
}

int32_t RowFitter::FindOffset(const GrowableArray<Interval>& ranges,
                              intptr_t* result_slot_index) {
  const Interval first_range = ranges[0];

  intptr_t index = 0;
  int32_t min_start = 0;

  while (index < free_slots_.length() - 1) {
    const Interval slot = free_slots_[index];

    int32_t start = Utils::Maximum(
        min_start, Utils::Maximum(slot.begin(), first_range.begin()));
    int32_t end = slot.end() - first_range.length();

    while (start <= end) {
      int32_t offset = start - first_range.begin();
      ASSERT(offset >= 0);
      ASSERT(slot.Contains(first_range.WithOffset(offset)));

      // If the first block was the only block, we are done.
      if (ranges.length() == 1) {
        *result_slot_index = index;
        return offset;
      }

      // Found an offset where the first range fits. Now match the
      // remaining ones.
      int32_t displacement = MatchRemaining(offset, ranges, index);

      // Displacement is either 0 for a match, or a minimum distance to where
      // a potential match can happen.
      if (displacement == 0) {
        *result_slot_index = index;
        return offset;
      }

      start += displacement;
    }

    min_start = start;

    index++;
  }

  ASSERT(index == (free_slots_.length() - 1));
  const Interval slot = free_slots_[index];
  ASSERT(slot.end() == INT_MAX);

  // If we are at end, we know it fits.
  int32_t offset = Utils::Maximum(0, slot.begin() - first_range.begin());

  *result_slot_index = index;
  return offset;
}

int32_t RowFitter::MatchRemaining(int32_t offset,
                                  const GrowableArray<Interval>& ranges,
                                  intptr_t slot_index) {
  intptr_t index = 1;
  intptr_t length = ranges.length();

  for (; index < length; index++) {
    const Interval range = ranges[index].WithOffset(offset);

    slot_index = MoveForwardToCover(range, slot_index);
    const Interval slot = free_slots_[slot_index];

    if (range.begin() < slot.begin()) return slot.begin() - range.begin();
  }

  return 0;
}

intptr_t RowFitter::MoveForwardToCover(const Interval range,
                                       intptr_t slot_index) {
  while (free_slots_[slot_index].end() < range.end()) {
    slot_index++;
  }
  return slot_index;
}

void RowFitter::UpdateFreeSlots(int32_t offset,
                                const GrowableArray<Interval>& ranges,
                                intptr_t slot_index) {
  for (intptr_t i = 0; i < ranges.length(); i++) {
    ASSERT(slot_index < free_slots_.length());
    const Interval range = ranges[i].WithOffset(offset);

    ASSERT(!free_slots_[slot_index].IsAfter(range));
    slot_index = MoveForwardToCover(range, slot_index);

    // Assert that we have a valid slot.
    ASSERT(slot_index < free_slots_.length());
    ASSERT(free_slots_[slot_index].begin() < range.end());

    slot_index = FitInFreeSlot(range, slot_index);
  }

  for (intptr_t i = 0; i < free_slots_.length(); i++) {
    ASSERT(free_slots_[i].begin() < free_slots_[i].end());
  }
}

intptr_t RowFitter::FitInFreeSlot(const Interval range, intptr_t slot_index) {
  const Interval& slot = free_slots_[slot_index];
  ASSERT(slot.Contains(range));
  if (slot.begin() < range.begin()) {
    Interval free_before = Interval(slot.begin(), range.begin());
    if (slot.end() > range.end()) {
      Interval free_after(range.end(), slot.end());
      free_slots_[slot_index] = free_before;
      free_slots_.InsertAt(slot_index + 1, free_after);
    } else {
      free_slots_[slot_index] = free_before;
      slot_index++;
    }
  } else if (slot.end() <= range.end()) {
    ASSERT(slot.IsSame(range));
    free_slots_.EraseAt(slot_index);
  } else {
    Interval free_after(range.end(), slot.end());
    free_slots_[slot_index] = free_after;
  }
  return slot_index;
}

int32_t SelectorMap::SelectorId(const Function& interface_target) const {
  kernel::ProcedureAttributesMetadata metadata;
  metadata = kernel::ProcedureAttributesOf(interface_target, Z);
  return interface_target.IsGetterFunction() ||
                 interface_target.IsImplicitGetterFunction()
             ? metadata.getter_selector_id
             : metadata.method_or_setter_selector_id;
}

const TableSelector* SelectorMap::GetSelector(
    const Function& interface_target) const {
  const int32_t sid = SelectorId(interface_target);
  if (sid == kInvalidSelectorId) return nullptr;
  const TableSelector* selector = &selectors_[sid];
  if (selector->offset == kInvalidSelectorOffset) return nullptr;
  return selector;
}

void SelectorMap::SetSelectorProperties(int32_t sid,
                                        bool on_null_interface,
                                        bool requires_args_descriptor) {
  while (selectors_.length() <= sid) {
    const int32_t added_sid = selectors_.length();
    selectors_.Add(TableSelector{added_sid, kInvalidSelectorId, false, false});
  }
  selectors_[sid].on_null_interface |= on_null_interface;
  selectors_[sid].requires_args_descriptor |= requires_args_descriptor;
}

void SelectorMap::SetSelectorOffset(int32_t sid, int32_t offset) {
  selectors_[sid].offset = offset;
}

DispatchTableGenerator::DispatchTableGenerator(Zone* zone)
    : zone_(zone),
      classes_(nullptr),
      num_selectors_(-1),
      num_classes_(-1),
      selector_map_(zone) {}

void DispatchTableGenerator::Initialize(ClassTable* table) {
  classes_ = table;

  NumberSelectors();
  SetupSelectorRows();
  ComputeSelectorOffsets();
}

void DispatchTableGenerator::NumberSelectors() {
  num_classes_ = classes_->NumCids();

  Object& obj = Object::Handle(Z);
  Class& klass = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);

  for (classid_t cid = kIllegalCid + 1; cid < num_classes_; cid++) {
    obj = classes_->At(cid);
    if (obj.IsClass()) {
      klass = Class::RawCast(obj.raw());
      functions = klass.functions();
      if (!functions.IsNull()) {
        for (intptr_t j = 0; j < functions.Length(); j++) {
          function ^= functions.At(j);
          if (function.IsDynamicFunction(/*allow_abstract=*/false)) {
            const bool on_null_interface = klass.IsObjectClass();
            const bool requires_args_descriptor =
                function.IsGeneric() || function.HasOptionalParameters();
            // Get assigned selector ID for this function.
            const int32_t sid = selector_map_.SelectorId(function);
            if (sid == SelectorMap::kInvalidSelectorId) {
              // Probably gen_kernel was run in non-AOT mode or without TFA.
              FATAL("Function has no assigned selector ID.\n");
            }
            selector_map_.SetSelectorProperties(sid, on_null_interface,
                                                requires_args_descriptor);
          }
        }
      }
    }
  }

  num_selectors_ = selector_map_.NumIds();
}

void DispatchTableGenerator::SetupSelectorRows() {
  Object& obj = Object::Handle(Z);
  Class& klass = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);

  // For each class, we first need to figure out the ranges of cids that will
  // inherit methods from it (this is due to the fact that cids don't have the
  // property that they are assigned preorder and don't have holes).

  // Make a condensed array which stores parent cids.
  std::unique_ptr<classid_t[]> parent_cids(new classid_t[num_classes_]);
  std::unique_ptr<bool[]> is_concrete_class(new bool[num_classes_]);
  for (classid_t cid = kIllegalCid + 1; cid < num_classes_; cid++) {
    classid_t parent_cid = kIllegalCid;
    bool concrete = false;
    if (cid > kIllegalCid) {
      obj = classes_->At(cid);
      if (obj.IsClass()) {
        klass = Class::RawCast(obj.raw());
        concrete = !klass.is_abstract();
        klass = klass.SuperClass();
        if (!klass.IsNull()) {
          parent_cid = klass.id();
        }
      }
    }
    parent_cids[cid] = parent_cid;
    is_concrete_class[cid] = concrete;
  }

  // Precompute depth level.
  std::unique_ptr<int16_t[]> cid_depth(new int16_t[num_classes_]);
  for (classid_t cid = kIllegalCid + 1; cid < num_classes_; cid++) {
    int16_t depth = 0;
    classid_t pcid = cid;
    while (pcid != kIllegalCid) {
      pcid = parent_cids[pcid];
      depth++;
    }
    cid_depth[cid] = depth;
  }

  // Find all regions that have [cid] as parent (which should include [cid])!
  std::unique_ptr<GrowableArray<Interval>[]> cid_subclass_ranges(
      new GrowableArray<Interval>[num_classes_]());
  for (classid_t cid = kIllegalCid + 1; cid < num_classes_; cid++) {
    classid_t start = kIllegalCid;
    for (classid_t sub_cid = kIllegalCid + 1; sub_cid < num_classes_;
         sub_cid++) {
      // Is [sub_cid] a subclass of [cid]?
      classid_t pcid = sub_cid;
      while (pcid != kIllegalCid && pcid != cid) {
        pcid = parent_cids[pcid];
      }
      const bool is_subclass = cid == pcid;
      const bool in_range = is_subclass && is_concrete_class[sub_cid];

      if (start == kIllegalCid && in_range) {
        start = sub_cid;
      } else if (start != kIllegalCid && !in_range) {
        Interval range(start, sub_cid);
        cid_subclass_ranges[cid].Add(range);
        start = kIllegalCid;
      }
    }
    if (start != kIllegalCid) {
      Interval range(start, num_classes_);
      cid_subclass_ranges[cid].Add(range);
    }
  }

  // Initialize selector rows.
  SelectorRow* selector_rows = Z->Alloc<SelectorRow>(num_selectors_);
  for (intptr_t i = 0; i < num_selectors_; i++) {
    new (&selector_rows[i]) SelectorRow(Z, i);
  }

  // Add implementation intervals to the selector rows for all classes that
  // have concrete implementations of the selector.
  for (classid_t cid = kIllegalCid + 1; cid < num_classes_; cid++) {
    obj = classes_->At(cid);
    if (obj.IsClass()) {
      klass = Class::RawCast(obj.raw());
      GrowableArray<Interval>& subclasss_cid_ranges = cid_subclass_ranges[cid];

      functions = klass.functions();
      if (!functions.IsNull()) {
        const int16_t depth = cid_depth[cid];
        for (intptr_t j = 0; j < functions.Length(); j++) {
          function ^= functions.At(j);
          if (function.IsDynamicFunction(/*allow_abstract=*/false)) {
            const int32_t sid = selector_map_.SelectorId(function);

            if (sid != SelectorMap::kInvalidSelectorId) {
              // Make a function handle that survives until the table is built.
              auto& function_handle = Function::ZoneHandle(Z, function.raw());

              for (intptr_t i = 0; i < subclasss_cid_ranges.length(); i++) {
                Interval& subclass_cid_range = subclasss_cid_ranges[i];
                selector_rows[sid].DefineSelectorImplementationForInterval(
                    cid, depth, subclass_cid_range, function_handle);
              }
            }
          }
        }
      }
    }
  }

  // Retain all selectors that contain implementation intervals.
  for (intptr_t i = 0; i < num_selectors_; i++) {
    if (selector_rows[i].Finalize()) {
      table_rows_.Add(&selector_rows[i]);
    }
  }
}

void DispatchTableGenerator::ComputeSelectorOffsets() {
  ASSERT(table_rows_.length() > 0);

  // Sort the table rows according to size.
  struct SelectorRowSorter {
    static int Compare(SelectorRow* const* a, SelectorRow* const* b) {
      return (*b)->total_size() - (*a)->total_size();
    }
  };
  table_rows_.Sort(SelectorRowSorter::Compare);

  RowFitter fitter;
  for (intptr_t i = 0; i < table_rows_.length(); i++) {
    SelectorRow* row = table_rows_[i];
    const int32_t offset = fitter.Fit(row);
    row->set_offset(offset);
    selector_map_.SetSelectorOffset(row->selector_id(), offset);
  }

  table_size_ = fitter.TableSize();
}

DispatchTable* DispatchTableGenerator::BuildTable() {
  // Allocate the dispatch table and fill it in.
  DispatchTable* dispatch_table = new DispatchTable(table_size_);
  for (intptr_t i = 0; i < table_rows_.length(); i++) {
    table_rows_[i]->FillTable(classes_, dispatch_table);
  }

  return dispatch_table;
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(DART_PRECOMPILER) && !defined(DART_PRECOMPILED_RUNTIME)
