// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_TABLE_H_
#define RUNTIME_VM_CLASS_TABLE_H_

#include <memory>

#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/utils.h"

#include "vm/bitfield.h"
#include "vm/class_id.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/tagged_pointer.h"

namespace dart {

class Class;
class ClassTable;
class Isolate;
class IsolateGroup;
class IsolateGroupReloadContext;
class IsolateReloadContext;
class JSONArray;
class JSONObject;
class JSONStream;
template <typename T>
class MallocGrowableArray;
class ObjectPointerVisitor;

// Wraps a 64-bit integer to represent the bitmap of unboxed fields
// stored in the shared class table.
class UnboxedFieldBitmap {
 public:
  UnboxedFieldBitmap() : bitmap_(0) {}
  explicit UnboxedFieldBitmap(uint64_t bitmap) : bitmap_(bitmap) {}
  UnboxedFieldBitmap(const UnboxedFieldBitmap&) = default;
  UnboxedFieldBitmap& operator=(const UnboxedFieldBitmap&) = default;

  DART_FORCE_INLINE bool Get(intptr_t position) const {
    if (position >= Length()) return false;
    return Utils::TestBit(bitmap_, position);
  }
  DART_FORCE_INLINE void Set(intptr_t position) {
    ASSERT(position < Length());
    bitmap_ |= Utils::Bit<decltype(bitmap_)>(position);
  }
  DART_FORCE_INLINE uint64_t Value() const { return bitmap_; }
  DART_FORCE_INLINE bool IsEmpty() const { return bitmap_ == 0; }
  DART_FORCE_INLINE void Reset() { bitmap_ = 0; }

  DART_FORCE_INLINE static constexpr intptr_t Length() {
    return sizeof(decltype(bitmap_)) * kBitsPerByte;
  }

 private:
  uint64_t bitmap_;
};

// Registry of all known classes and their sizes.
//
// The GC will only need the information in this shared class table to scan
// object pointers.
class SharedClassTable {
 public:
  SharedClassTable();
  ~SharedClassTable();

  // Thread-safe.
  intptr_t SizeAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_.load()[index];
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    ASSERT(table_.load()[index] >= 0);
    return table_.load()[index] != 0;
  }

  void SetSizeAt(intptr_t index, intptr_t size) {
    ASSERT(IsValidIndex(index));

    // Ensure we never change size for a given cid from one non-zero size to
    // another non-zero size.
    intptr_t old_size = 0;
    if (!table_.load()[index].compare_exchange_strong(old_size, size)) {
      RELEASE_ASSERT(old_size == size);
    }
  }

  bool IsValidIndex(intptr_t index) const { return index > 0 && index < top_; }

  intptr_t NumCids() const { return top_; }
  intptr_t Capacity() const { return capacity_; }

  UnboxedFieldBitmap GetUnboxedFieldsMapAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return FLAG_precompiled_mode ? unboxed_fields_map_[index]
                                 : UnboxedFieldBitmap();
  }

  void SetUnboxedFieldsMapAt(intptr_t index,
                             UnboxedFieldBitmap unboxed_fields_map) {
    ASSERT(IsValidIndex(index));
    ASSERT(unboxed_fields_map_[index].IsEmpty());
    unboxed_fields_map_[index] = unboxed_fields_map;
  }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids) {
    ASSERT(num_cids <= top_);
    top_ = num_cids;
  }

#if !defined(PRODUCT)
  void SetTraceAllocationFor(intptr_t cid, bool trace) {
    ASSERT(cid > 0);
    ASSERT(cid < top_);
    trace_allocation_table_.load()[cid] = trace ? 1 : 0;
  }
  bool TraceAllocationFor(intptr_t cid) {
    ASSERT(cid > 0);
    ASSERT(cid < top_);
    return trace_allocation_table_.load()[cid] != 0;
  }
#endif  // !defined(PRODUCT)

  void CopyBeforeHotReload(intptr_t** copy, intptr_t* copy_num_cids) {
    // The [IsolateGroupReloadContext] will need to maintain a copy of the old
    // class table until instances have been morphed.
    const intptr_t num_cids = NumCids();
    const intptr_t bytes = sizeof(intptr_t) * num_cids;
    auto size_table = static_cast<intptr_t*>(malloc(bytes));
    auto table = table_.load();
    for (intptr_t i = 0; i < num_cids; i++) {
      // Don't use memmove, which changes this from a relaxed atomic operation
      // to a non-atomic operation.
      size_table[i] = table[i];
    }
    *copy_num_cids = num_cids;
    *copy = size_table;
  }

  void ResetBeforeHotReload() {
    // The [IsolateReloadContext] is now source-of-truth for GC.
    auto table = table_.load();
    for (intptr_t i = 0; i < top_; i++) {
      // Don't use memset, which changes this from a relaxed atomic operation
      // to a non-atomic operation.
      table[i] = 0;
    }
  }

  void ResetAfterHotReload(intptr_t* old_table,
                           intptr_t num_old_cids,
                           bool is_rollback) {
    // The [IsolateReloadContext] is no longer source-of-truth for GC after we
    // return, so we restore size information for all classes.
    if (is_rollback) {
      SetNumCids(num_old_cids);
      auto table = table_.load();
      for (intptr_t i = 0; i < num_old_cids; i++) {
        // Don't use memmove, which changes this from a relaxed atomic operation
        // to a non-atomic operation.
        table[i] = old_table[i];
      }
    }

    // Can't free this table immediately as another thread (e.g., concurrent
    // marker or sweeper) may be between loading the table pointer and loading
    // the table element. The table will be freed at the next major GC or
    // isolate shutdown.
    AddOldTable(old_table);
  }

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

  // Deallocates bitmap copies. Do not call during concurrent access to table.
  void FreeOldUnboxedFieldsMaps();

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool IsReloading() const { return reload_context_ != nullptr; }

  IsolateGroupReloadContext* reload_context() { return reload_context_; }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Returns the newly allocated cid.
  //
  // [index] is kIllegalCid or a predefined cid.
  intptr_t Register(intptr_t index, intptr_t size);
  void AllocateIndex(intptr_t index);
  void Unregister(intptr_t index);

  void Remap(intptr_t* old_to_new_cids);

  // Used by the generated code.
#ifndef PRODUCT
  static intptr_t class_heap_stats_table_offset() {
    return OFFSET_OF(SharedClassTable, trace_allocation_table_);
  }
#endif

  // Used by the generated code.
  static intptr_t ClassOffsetFor(intptr_t cid);

  static const int kInitialCapacity = 512;
  static const int kCapacityIncrement = 256;

 private:
  friend class ClassTable;
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class Scavenger;
  friend class ScavengerWeakVisitor;

  static bool ShouldUpdateSizeForClassId(intptr_t cid);

#ifndef PRODUCT
  // Copy-on-write is used for trace_allocation_table_, with old copies stored
  // in old_tables_.
  AcqRelAtomic<uint8_t*> trace_allocation_table_ = {nullptr};
#endif  // !PRODUCT

  void AddOldTable(intptr_t* old_table);

  void Grow(intptr_t new_capacity);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in old_tables_.
  // Maps the cid to the instance size.
  AcqRelAtomic<RelaxedAtomic<intptr_t>*> table_ = {nullptr};
  MallocGrowableArray<void*>* old_tables_;

  IsolateGroupReloadContext* reload_context_ = nullptr;

  // Stores a 64-bit bitmap for each class. There is one bit for each word in an
  // instance of the class. A 0 bit indicates that the word contains a pointer
  // the GC has to scan, a 1 indicates that the word is part of e.g. an unboxed
  // double and does not need to be scanned. (see Class::Calculate...() where
  // the bitmap is constructed)
  UnboxedFieldBitmap* unboxed_fields_map_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(SharedClassTable);
};

class ClassTable {
 public:
  explicit ClassTable(SharedClassTable* shared_class_table_);
  ~ClassTable();

  SharedClassTable* shared_class_table() const { return shared_class_table_; }

  void CopyBeforeHotReload(ClassPtr** copy, intptr_t* copy_num_cids) {
    // The [IsolateReloadContext] will need to maintain a copy of the old class
    // table until instances have been morphed.
    const intptr_t num_cids = NumCids();
    const intptr_t bytes = sizeof(ClassPtr) * num_cids;
    auto class_table = static_cast<ClassPtr*>(malloc(bytes));
    auto table = table_.load();
    for (intptr_t i = 0; i < num_cids; i++) {
      // Don't use memmove, which changes this from a relaxed atomic operation
      // to a non-atomic operation.
      class_table[i] = table[i];
    }
    *copy_num_cids = num_cids;
    *copy = class_table;
  }

  void ResetBeforeHotReload() {
    // We cannot clear out the class pointers, because a hot-reload
    // contains only a diff: If e.g. a class included in the hot-reload has a
    // super class not included in the diff, it will look up in this class table
    // to find the super class (e.g. `cls.SuperClass` will cause us to come
    // here).
  }

  void ResetAfterHotReload(ClassPtr* old_table,
                           intptr_t num_old_cids,
                           bool is_rollback) {
    // The [IsolateReloadContext] is no longer source-of-truth for GC after we
    // return, so we restore size information for all classes.
    if (is_rollback) {
      SetNumCids(num_old_cids);
      auto table = table_.load();
      for (intptr_t i = 0; i < num_old_cids; i++) {
        // Don't use memmove, which changes this from a relaxed atomic operation
        // to a non-atomic operation.
        table[i] = old_table[i];
      }
    } else {
      CopySizesFromClassObjects();
    }

    // Can't free this table immediately as another thread (e.g., concurrent
    // marker or sweeper) may be between loading the table pointer and loading
    // the table element. The table will be freed at the next major GC or
    // isolate shutdown.
    AddOldTable(old_table);
  }

  // Thread-safe.
  ClassPtr At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_.load()[index];
  }

  intptr_t SizeAt(intptr_t index) const {
    return shared_class_table_->SizeAt(index);
  }

  void SetAt(intptr_t index, ClassPtr raw_cls);

  bool IsValidIndex(intptr_t index) const {
    return shared_class_table_->IsValidIndex(index);
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_.load()[index] != nullptr;
  }

  intptr_t NumCids() const { return shared_class_table_->NumCids(); }
  intptr_t Capacity() const { return shared_class_table_->Capacity(); }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids) {
    shared_class_table_->SetNumCids(num_cids);

    ASSERT(num_cids <= top_);
    top_ = num_cids;
  }

  void Register(const Class& cls);
  void AllocateIndex(intptr_t index);
  void Unregister(intptr_t index);

  void Remap(intptr_t* old_to_new_cids);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // If a snapshot reader has populated the class table then the
  // sizes in the class table are not correct. Iterates through the
  // table, updating the sizes.
  void CopySizesFromClassObjects();

  void Validate();

  void Print();

#ifndef PRODUCT
  // Describes layout of heap stats for code generation. See offset_extractor.cc
  struct ArrayTraits {
    static intptr_t elements_start_offset() { return 0; }

    static constexpr intptr_t kElementSize = sizeof(uint8_t);
  };
#endif

#ifndef PRODUCT

  void AllocationProfilePrintJSON(JSONStream* stream, bool internal);

  void PrintToJSONObject(JSONObject* object);
#endif  // !PRODUCT

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

 private:
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class Scavenger;
  friend class ScavengerWeakVisitor;
  friend class Dart;
  friend Isolate* CreateWithinExistingIsolateGroup(IsolateGroup* group,
                                                   const char* name,
                                                   char** error);
  friend class Isolate;  // for table()
  static const int kInitialCapacity = SharedClassTable::kInitialCapacity;
  static const int kCapacityIncrement = SharedClassTable::kCapacityIncrement;

  void AddOldTable(ClassPtr* old_table);

  void Grow(intptr_t index);

  ClassPtr* table() { return table_.load(); }
  void set_table(ClassPtr* table);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in
  // old_class_tables_.
  AcqRelAtomic<ClassPtr*> table_;
  MallocGrowableArray<ClassPtr*>* old_class_tables_;
  SharedClassTable* shared_class_table_;

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_TABLE_H_
