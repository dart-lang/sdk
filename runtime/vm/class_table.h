// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_TABLE_H_
#define RUNTIME_VM_CLASS_TABLE_H_

#include <memory>
#include <tuple>
#include <utility>

#include "platform/allocation.h"
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
class JSONArray;
class JSONObject;
class JSONStream;
template <typename T>
class MallocGrowableArray;
class ObjectPointerVisitor;
class PersistentHandle;

// A 64-bit bitmap describing unboxed fields in a class.
//
// There is a bit for each word in an instance of the class.
//
// Words corresponding to set bits must be ignored by the GC because they
// don't contain pointers. All words beyond the first 64 words of an object
// are expected to contain pointers.
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
  DART_FORCE_INLINE void Clear(intptr_t position) {
    ASSERT(position < Length());
    bitmap_ &= ~Utils::Bit<decltype(bitmap_)>(position);
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

// Allocator used to manage memory for ClassTable arrays and ClassTable
// objects themselves.
//
// This allocator provides delayed free functionality: normally class tables
// can't be freed unless all mutator and helper threads are stopped because
// some of these threads might be holding a pointer to a table which we
// want to free. Instead of stopping the world whenever we need to free
// a table (e.g. freeing old table after growing) we delay freeing until an
// occasional GC which will need to stop the world anyway.
class ClassTableAllocator : public ValueObject {
 public:
  ClassTableAllocator();
  ~ClassTableAllocator();

  // Allocate an array of T with |len| elements.
  //
  // Does *not* initialize the memory.
  template <class T>
  inline T* Alloc(intptr_t len) {
    return reinterpret_cast<T*>(dart::malloc(len * sizeof(T)));
  }

  // Allocate a zero initialized array of T with |len| elements.
  template <class T>
  inline T* AllocZeroInitialized(intptr_t len) {
    return reinterpret_cast<T*>(dart::calloc(len, sizeof(T)));
  }

  // Clone the given |array| with |size| elements.
  template <class T>
  inline T* Clone(T* array, intptr_t size) {
    if (array == nullptr) {
      ASSERT(size == 0);
      return nullptr;
    }
    auto result = Alloc<T>(size);
    memmove(result, array, size * sizeof(T));
    return result;
  }

  // Copy |size| elements from the given |array| into a new
  // array with space for |new_size| elements. Then |Free|
  // the original |array|.
  //
  // |new_size| is expected to be larger than |size|.
  template <class T>
  inline T* Realloc(T* array, intptr_t size, intptr_t new_size) {
    ASSERT(size < new_size);
    auto result = AllocZeroInitialized<T>(new_size);
    if (size != 0) {
      ASSERT(result != nullptr);
      memmove(result, array, size * sizeof(T));
    }
    Free(array);
    return result;
  }

  // Schedule deletion of the given ClassTable.
  void Free(ClassTable* table);

  // Schedule freeing of the given pointer.
  void Free(void* ptr);

  // Free all objects which were scheduled by |Free|. Expected to only be
  // called on |IsolateGroup| shutdown or when the world is stopped and no
  // thread can be using a stale class table pointer.
  void FreePending();

 private:
  typedef void (*Deleter)(void*);
  MallocGrowableArray<std::pair<void*, Deleter>>* pending_freed_;
};

// A table with the given |Columns| indexed by class id.
//
// Each column is a continuous array of a the given type. All columns have
// the same number of used elements (|num_cids()|) and the same capacity.
template <typename CidType, typename... Columns>
class CidIndexedTable {
 public:
  explicit CidIndexedTable(ClassTableAllocator* allocator)
      : allocator_(allocator) {}

  ~CidIndexedTable() {
    std::apply([&](auto&... column) { (allocator_->Free(column.load()), ...); },
               columns_);
  }

  CidIndexedTable(const CidIndexedTable& other) = delete;

  void SetNumCidsAndCapacity(intptr_t new_num_cids, intptr_t new_capacity) {
    columns_ = std::apply(
        [&](auto&... column) {
          return std::make_tuple(
              allocator_->Realloc(column.load(), num_cids_, new_capacity)...);
        },
        columns_);
    capacity_ = new_capacity;
    SetNumCids(new_num_cids);
  }

  void AllocateIndex(intptr_t index, bool* did_grow) {
    *did_grow = EnsureCapacity(index);
    SetNumCids(Utils::Maximum(num_cids_, index + 1));
  }

  intptr_t AddRow(bool* did_grow) {
    *did_grow = EnsureCapacity(num_cids_);
    intptr_t id = num_cids_;
    SetNumCids(num_cids_ + 1);
    return id;
  }

  void ShrinkTo(intptr_t new_num_cids) {
    ASSERT(new_num_cids <= num_cids_);
    num_cids_ = new_num_cids;
  }

  bool IsValidIndex(intptr_t index) const {
    return 0 <= index && index < num_cids_;
  }

  void CopyFrom(const CidIndexedTable& other) {
    ASSERT(allocator_ == other.allocator_);

    std::apply([&](auto&... column) { (allocator_->Free(column.load()), ...); },
               columns_);

    columns_ = std::apply(
        [&](auto&... column) {
          return std::make_tuple(
              allocator_->Clone(column.load(), other.num_cids_)...);
        },
        other.columns_);
    capacity_ = num_cids_ = other.num_cids_;
  }

  void Remap(intptr_t* old_to_new_cid) {
    CidIndexedTable clone(allocator_);
    clone.CopyFrom(*this);
    RemapAllColumns(clone, old_to_new_cid,
                    std::index_sequence_for<Columns...>{});
  }

  template <
      intptr_t kColumnIndex,
      typename T = std::tuple_element_t<kColumnIndex, std::tuple<Columns...>>>
  T* GetColumn() {
    return std::get<kColumnIndex>(columns_).load();
  }

  template <
      intptr_t kColumnIndex,
      typename T = std::tuple_element_t<kColumnIndex, std::tuple<Columns...>>>
  const T* GetColumn() const {
    return std::get<kColumnIndex>(columns_).load();
  }

  template <
      intptr_t kColumnIndex,
      typename T = std::tuple_element_t<kColumnIndex, std::tuple<Columns...>>>
  T& At(intptr_t index) {
    ASSERT(IsValidIndex(index));
    return GetColumn<kColumnIndex>()[index];
  }

  template <
      intptr_t kColumnIndex,
      typename T = std::tuple_element_t<kColumnIndex, std::tuple<Columns...>>>
  const T& At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return GetColumn<kColumnIndex>()[index];
  }

  intptr_t num_cids() const { return num_cids_; }
  intptr_t capacity() const { return capacity_; }

 private:
  friend class ClassTable;

  // Wrapper around AcqRelAtomic<T*> which makes it assignable and copyable
  // so that we could put it inside an std::tuple.
  template <typename T>
  struct Ptr {
    Ptr() : ptr(nullptr) {}
    Ptr(T* ptr) : ptr(ptr) {}  // NOLINT

    Ptr(const Ptr& other) { ptr.store(other.ptr.load()); }

    Ptr& operator=(const Ptr& other) {
      ptr.store(other.load());
      return *this;
    }

    T* load() const { return ptr.load(); }

    AcqRelAtomic<T*> ptr = {nullptr};
  };

  void SetNumCids(intptr_t new_num_cids) {
    if (new_num_cids > kClassIdTagMax) {
      FATAL("Too many classes");
    }
    num_cids_ = new_num_cids;
  }

  bool EnsureCapacity(intptr_t index) {
    if (index >= capacity_) {
      SetNumCidsAndCapacity(num_cids_, index + kCapacityIncrement);
      return true;
    }
    return false;
  }

  template <intptr_t kColumnIndex>
  void RemapColumn(const CidIndexedTable& old, intptr_t* old_to_new_cid) {
    auto new_column = GetColumn<kColumnIndex>();
    auto old_column = old.GetColumn<kColumnIndex>();
    for (intptr_t i = 0; i < num_cids_; i++) {
      new_column[old_to_new_cid[i]] = old_column[i];
    }
  }

  template <std::size_t... Is>
  void RemapAllColumns(const CidIndexedTable& old,
                       intptr_t* old_to_new_cid,
                       std::index_sequence<Is...>) {
    (RemapColumn<Is>(old, old_to_new_cid), ...);
  }

  static constexpr intptr_t kCapacityIncrement = 256;

  ClassTableAllocator* allocator_;
  intptr_t num_cids_ = 0;
  intptr_t capacity_ = 0;
  std::tuple<Ptr<Columns>...> columns_;
};

// Registry of all known classes.
//
// The GC will only use information about instance size and unboxed field maps
// to scan instances and will not access class objects themselves. This
// information is stored in separate columns of the |classes_| table.
//
// # Concurrency & atomicity
//
// This table is read concurrently without locking (e.g. by GC threads) so
// there are some invariants that need to be observed when working with it.
//
// * When table is updated (e.g. when the table is grown or a new class is
// registered in a table) there must be a release barrier after the update.
// Such barrier will ensure that stores which populate the table are not
// reordered past the store which exposes the new grown table or exposes
// a new class id;
// * Old versions of the table can only be freed when the world is stopped:
// no mutator and no helper threads are running. To avoid freeing a table
// which some other thread is reading from.
//
// Note that torn reads are not a concern (e.g. it is fine to use
// memmove to copy class table contents) as long as an appropriate
// barrier is issued before the copy of the table can be observed.
//
// # Hot reload
//
// Each IsolateGroup contains two ClassTable fields: |class_table| and
// |heap_walk_class_table|. GC visitors use the second field to get ClassTable
// instance which they will use for visiting pointers inside instances in
// the heap. Usually these two fields will be pointing to the same table,
// except when IsolateGroup is in the middle of reload.
//
// When reloading |class_table| will be pointing to a copy of the original
// table. Kernel loading will be modifying this table, while GC
// workers can continue using original table still available through
// |heap_walk_class_table|. If hot reload succeeds, |heap_walk_class_table|
// will be dropped and |class_table| will become the source of truth. Otherwise,
// original table will be restored from |heap_walk_class_table|.
//
// See IsolateGroup methods CloneClassTableForReload, RestoreOriginalClassTable,
// DropOriginalClassTable.
class ClassTable : public MallocAllocated {
 public:
  explicit ClassTable(ClassTableAllocator* allocator);

  ~ClassTable();

  ClassTable* Clone() const { return new ClassTable(*this); }

  ClassPtr At(intptr_t cid) const {
    if (IsTopLevelCid(cid)) {
      return top_level_classes_.At<kClassIndex>(IndexFromTopLevelCid(cid));
    }
    return classes_.At<kClassIndex>(cid);
  }

  int32_t SizeAt(intptr_t index) const {
    if (IsTopLevelCid(index)) {
      return 0;
    }
    return classes_.At<kSizeIndex>(index);
  }

  void SetAt(intptr_t index, ClassPtr raw_cls);
  void UpdateClassSize(intptr_t cid, ClassPtr raw_cls);

  bool IsValidIndex(intptr_t cid) const {
    if (IsTopLevelCid(cid)) {
      return top_level_classes_.IsValidIndex(IndexFromTopLevelCid(cid));
    }
    return classes_.IsValidIndex(cid);
  }

  bool HasValidClassAt(intptr_t cid) const { return At(cid) != nullptr; }

  UnboxedFieldBitmap GetUnboxedFieldsMapAt(intptr_t cid) const {
    ASSERT(IsValidIndex(cid));
    return classes_.At<kUnboxedFieldBitmapIndex>(cid);
  }

  void SetUnboxedFieldsMapAt(intptr_t cid, UnboxedFieldBitmap map) {
    ASSERT(IsValidIndex(cid));
    classes_.At<kUnboxedFieldBitmapIndex>(cid) = map;
  }

#if !defined(PRODUCT)
  bool ShouldTraceAllocationFor(intptr_t cid) {
    return !IsTopLevelCid(cid) &&
           (classes_.At<kAllocationTracingStateIndex>(cid) != kTracingDisabled);
  }

  void SetTraceAllocationFor(intptr_t cid, bool trace) {
    classes_.At<kAllocationTracingStateIndex>(cid) =
        trace ? kTraceAllocationBit : kTracingDisabled;
  }

  void SetCollectInstancesFor(intptr_t cid, bool trace) {
    auto& slot = classes_.At<kAllocationTracingStateIndex>(cid);
    if (trace) {
      slot |= kCollectInstancesBit;
    } else {
      slot &= ~kCollectInstancesBit;
    }
  }

  bool CollectInstancesFor(intptr_t cid) {
    auto& slot = classes_.At<kAllocationTracingStateIndex>(cid);
    return (slot & kCollectInstancesBit) != 0;
  }

  void UpdateCachedAllocationTracingStateTablePointer() {
    cached_allocation_tracing_state_table_.store(
        classes_.GetColumn<kAllocationTracingStateIndex>());
  }
#else
  void UpdateCachedAllocationTracingStateTablePointer() {}
#endif  // !defined(PRODUCT)

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  void PopulateUserVisibleNames();

  const char* UserVisibleNameFor(intptr_t cid) {
    if (!classes_.IsValidIndex(cid)) {
      return nullptr;
    }
    return classes_.At<kClassNameIndex>(cid);
  }

  void SetUserVisibleNameFor(intptr_t cid, const char* name) {
    ASSERT(classes_.At<kClassNameIndex>(cid) == nullptr);
    classes_.At<kClassNameIndex>(cid) = name;
  }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

  intptr_t NumCids() const {
    return classes_.num_cids();
  }
  intptr_t Capacity() const {
    return classes_.capacity();
  }

  intptr_t NumTopLevelCids() const {
    return top_level_classes_.num_cids();
  }

  void Register(const Class& cls);
  void AllocateIndex(intptr_t index);

  void RegisterTopLevel(const Class& cls);
  void UnregisterTopLevel(intptr_t index);

  void Remap(intptr_t* old_to_new_cids);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // If a snapshot reader has populated the class table then the
  // sizes in the class table are not correct. Iterates through the
  // table, updating the sizes.
  void CopySizesFromClassObjects();

  void Validate();

  void Print();

#if defined(DART_PRECOMPILER)
  void PrintObjectLayout(const char* filename);
#endif

#ifndef PRODUCT
  // Describes layout of heap stats for code generation. See offset_extractor.cc
  struct ArrayTraits {
    static intptr_t elements_start_offset() { return 0; }

    static constexpr intptr_t kElementSize = sizeof(uint8_t);
  };

  static intptr_t allocation_tracing_state_table_offset() {
    static_assert(sizeof(cached_allocation_tracing_state_table_) == kWordSize);
    return OFFSET_OF(ClassTable, cached_allocation_tracing_state_table_);
  }

  void AllocationProfilePrintJSON(JSONStream* stream, bool internal);

  void PrintToJSONObject(JSONObject* object);
#endif  // !PRODUCT

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

  static bool IsTopLevelCid(intptr_t cid) { return cid >= kTopLevelCidOffset; }

  static intptr_t IndexFromTopLevelCid(intptr_t cid) {
    ASSERT(IsTopLevelCid(cid));
    return cid - kTopLevelCidOffset;
  }

  static intptr_t CidFromTopLevelIndex(intptr_t index) {
    return kTopLevelCidOffset + index;
  }

 private:
  friend class ClassTableAllocator;
  friend class Dart;
  friend Isolate* CreateWithinExistingIsolateGroup(IsolateGroup* group,
                                                   const char* name,
                                                   char** error);
  friend class IsolateGroup;  // for table()
  static constexpr int kInitialCapacity = 512;

  static constexpr intptr_t kTopLevelCidOffset = kClassIdTagMax + 1;

  ClassTable(const ClassTable& original)
      : allocator_(original.allocator_),
        classes_(original.allocator_),
        top_level_classes_(original.allocator_) {
    classes_.CopyFrom(original.classes_);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    // Copying classes_ doesn't perform a deep copy. Ensure we duplicate
    // the class names to avoid double free crashes at shutdown.
    for (intptr_t cid = 1; cid < classes_.num_cids(); ++cid) {
      if (classes_.IsValidIndex(cid)) {
        const char* cls_name = classes_.At<kClassNameIndex>(cid);
        if (cls_name != nullptr) {
          classes_.At<kClassNameIndex>(cid) = Utils::StrDup(cls_name);
        }
      }
    }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

    top_level_classes_.CopyFrom(original.top_level_classes_);
    UpdateCachedAllocationTracingStateTablePointer();
  }

  void AllocateTopLevelIndex(intptr_t index);

  ClassPtr* table() {
    return classes_.GetColumn<kClassIndex>();
  }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids, intptr_t num_tlc_cids) {
    classes_.ShrinkTo(num_cids);
    top_level_classes_.ShrinkTo(num_tlc_cids);
  }

  ClassTableAllocator* allocator_;

  // Unfortunately std::tuple used by CidIndexedTable does not have a stable
  // layout so we can't refer to its elements from generated code.
  NOT_IN_PRODUCT(AcqRelAtomic<uint8_t*> cached_allocation_tracing_state_table_ =
                     {nullptr});

  enum {
    kClassIndex = 0,
    kSizeIndex,
    kUnboxedFieldBitmapIndex,
#if !defined(PRODUCT)
    kAllocationTracingStateIndex,
#endif
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    kClassNameIndex,
#endif
  };

#if !defined(PRODUCT)
  CidIndexedTable<ClassIdTagType,
                  ClassPtr,
                  uint32_t,
                  UnboxedFieldBitmap,
                  uint8_t,
                  const char*>
      classes_;
#elif defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  CidIndexedTable<ClassIdTagType,
                  ClassPtr,
                  uint32_t,
                  UnboxedFieldBitmap,
                  const char*>
      classes_;
#else
  CidIndexedTable<ClassIdTagType, ClassPtr, uint32_t, UnboxedFieldBitmap>
      classes_;
#endif

#ifndef PRODUCT
  enum {
      kTracingDisabled = 0,
      kTraceAllocationBit = (1 << 0),
      kCollectInstancesBit = (1 << 1),
  };
#endif  // !PRODUCT

  CidIndexedTable<classid_t, ClassPtr> top_level_classes_;
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_TABLE_H_
