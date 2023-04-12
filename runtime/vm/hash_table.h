// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_TABLE_H_
#define RUNTIME_VM_HASH_TABLE_H_

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

// Storage traits control how memory is allocated for HashTable.
// Default ArrayStorageTraits use an Array to store HashTable contents.
struct ArrayStorageTraits {
  using ArrayHandle = Array;
  using ArrayPtr = dart::ArrayPtr;
  static constexpr intptr_t ArrayCid = kArrayCid;

  static ArrayHandle& PtrToHandle(ArrayPtr ptr) { return Array::Handle(ptr); }

  static void SetHandle(ArrayHandle& dst, const ArrayHandle& src) {  // NOLINT
    dst = src.ptr();
  }

  static void ClearHandle(ArrayHandle& handle) {  // NOLINT
    handle = Array::null();
  }

  static ArrayPtr New(Zone* zone, intptr_t length, Heap::Space space) {
    return Array::New(length, space);
  }

  static bool IsImmutable(const ArrayHandle& handle) {
    return handle.ptr()->untag()->InVMIsolateHeap();
  }

  static ObjectPtr At(ArrayHandle* array, intptr_t index) {
    return array->At(index);
  }

  static void SetAt(ArrayHandle* array, intptr_t index, const Object& value) {
    array->SetAt(index, value);
  }
};

struct WeakArrayStorageTraits {
  using ArrayHandle = WeakArray;
  using ArrayPtr = dart::WeakArrayPtr;
  static constexpr intptr_t ArrayCid = kWeakArrayCid;

  static ArrayHandle& PtrToHandle(ArrayPtr ptr) {
    return WeakArray::Handle(ptr);
  }

  static void SetHandle(ArrayHandle& dst, const ArrayHandle& src) {  // NOLINT
    dst = src.ptr();
  }

  static void ClearHandle(ArrayHandle& handle) {  // NOLINT
    handle = WeakArray::null();
  }

  static ArrayPtr New(Zone* zone, intptr_t length, Heap::Space space) {
    return WeakArray::New(length, space);
  }

  static bool IsImmutable(const ArrayHandle& handle) {
    return handle.ptr()->untag()->InVMIsolateHeap();
  }

  static ObjectPtr At(ArrayHandle* array, intptr_t index) {
    return array->At(index);
  }

  static void SetAt(ArrayHandle* array, intptr_t index, const Object& value) {
    array->SetAt(index, value);
  }
};

struct AcqRelStorageTraits : ArrayStorageTraits {
  static ObjectPtr At(ArrayHandle* array, intptr_t index) {
    return array->AtAcquire(index);
  }

  static void SetAt(ArrayHandle* array, intptr_t index, const Object& value) {
    array->SetAtRelease(index, value);
  }
};

struct WeakAcqRelStorageTraits : WeakArrayStorageTraits {
  static ObjectPtr At(ArrayHandle* array, intptr_t index) {
    return array->AtAcquire(index);
  }

  static void SetAt(ArrayHandle* array, intptr_t index, const Object& value) {
    array->SetAtRelease(index, value);
  }
};

class HashTableBase : public ValueObject {
 public:
  static const Object& UnusedMarker() { return Object::transition_sentinel(); }
  static const Object& DeletedMarker() { return Object::null_object(); }
};

// OVERVIEW:
//
// Hash maps and hash sets all use RawArray as backing storage. At the lowest
// level is a generic open-addressing table that supports deletion.
//  - HashTable
// The next layer provides ordering and iteration functionality:
//  - UnorderedHashTable
//  - LinkedListHashTable (TODO(koda): Implement.)
// The utility class HashTables handles growth and conversion.
// The next layer fixes the payload size and provides a natural interface:
//  - HashMap
//  - HashSet
// Combining either of these with an iteration strategy, we get the templates
// intended for use outside this file:
//  - UnorderedHashMap
//  - LinkedListHashMap
//  - UnorderedHashSet
//  - LinkedListHashSet
// Each of these can be finally specialized with KeyTraits to support any set of
// lookup key types (e.g., look up a char* in a set of String objects), and
// any equality and hash code computation.
//
// The classes all wrap an Array handle, and methods like HashSet::Insert can
// trigger growth into a new RawArray, updating the handle. Debug mode asserts
// that 'Release' was called once to access the final array before destruction.
// NOTE: The handle returned by 'Release' is cleared by ~HashTable.
//
// Example use:
//  typedef UnorderedHashMap<FooTraits> FooMap;
//  ...
//  FooMap cache(get_foo_cache());
//  cache.UpdateOrInsert(name0, obj0);
//  cache.UpdateOrInsert(name1, obj1);
//  ...
//  set_foo_cache(cache.Release());
//
// If you *know* that no mutating operations were called, you can optimize:
//  ...
//  obj ^= cache.GetOrNull(name);
//  ASSERT(cache.Release().ptr() == get_foo_cache());
//
// TODO(koda): When exposing these to Dart code, document and assert that
// KeyTraits methods must not run Dart code (since the C++ code doesn't check
// for concurrent modification).

// Open-addressing hash table template using a RawArray as backing storage.
//
// The elements of the array are partitioned into entries:
//  [ header | metadata | entry0 | entry1 | ... | entryN ]
// Each entry contains a key, followed by zero or more payload components,
// and has 3 possible states: unused, occupied, or deleted.
// The header tracks the number of entries in each state.
// Any object except the backing storage array and Object::transition_sentinel()
// may be stored as a key. Any object may be stored in a payload.
//
// Parameters
//  KeyTraits: defines static methods
//    bool IsMatch(const Key& key, const Object& obj) and
//    uword Hash(const Key& key) for any number of desired lookup key types.
//  kPayloadSize: number of components of the payload in each entry.
//  kMetaDataSize: number of elements reserved (e.g., for iteration order data).
template <typename KeyTraits,
          intptr_t kPayloadSize,
          intptr_t kMetaDataSize,
          typename StorageTraits = ArrayStorageTraits>
class HashTable : public HashTableBase {
 public:
  typedef KeyTraits Traits;
  typedef StorageTraits Storage;

  // Uses the passed in handles for all handle operations.
  // 'Release' must be called at the end to obtain the final table
  // after potential growth/shrinkage.
  HashTable(Object* key, Smi* index, typename StorageTraits::ArrayHandle* data)
      : key_handle_(key),
        smi_handle_(index),
        data_(data),
        released_data_(nullptr) {}
  // Uses 'zone' for handle allocation. 'Release' must be called at the end
  // to obtain the final table after potential growth/shrinkage.
  HashTable(Zone* zone, typename StorageTraits::ArrayPtr data)
      : key_handle_(&Object::Handle(zone)),
        smi_handle_(&Smi::Handle(zone)),
        data_(&StorageTraits::PtrToHandle(data)),
        released_data_(nullptr) {}

  // Returns the final table. The handle is cleared when this HashTable is
  // destroyed.
  typename StorageTraits::ArrayHandle& Release() {
    ASSERT(data_ != nullptr);
    ASSERT(released_data_ == nullptr);
    // Ensure that no methods are called after 'Release'.
    released_data_ = data_;
    data_ = nullptr;
    return *released_data_;
  }

  ~HashTable() {
    // In DEBUG mode, calling 'Release' is mandatory.
    ASSERT(data_ == nullptr);
    if (released_data_ != nullptr) {
      StorageTraits::ClearHandle(*released_data_);
    }
  }

  // Returns a backing storage size such that 'num_occupied' distinct keys can
  // be inserted into the table.
  static intptr_t ArrayLengthForNumOccupied(intptr_t num_occupied) {
    // Because we use quadratic (actually triangle number) probing it is
    // important that the size is a power of two (otherwise we could fail to
    // find an empty slot).  This is described in Knuth's The Art of Computer
    // Programming Volume 2, Chapter 6.4, exercise 20 (solution in the
    // appendix, 2nd edition).
    intptr_t num_entries = Utils::RoundUpToPowerOfTwo(num_occupied + 1);
    return kFirstKeyIndex + (kEntrySize * num_entries);
  }

  // Initializes an empty table.
  void Initialize() const {
    ASSERT(data_->Length() >= ArrayLengthForNumOccupied(0));
    *smi_handle_ = Smi::New(0);
    StorageTraits::SetAt(data_, kOccupiedEntriesIndex, *smi_handle_);
    StorageTraits::SetAt(data_, kDeletedEntriesIndex, *smi_handle_);

#if !defined(PRODUCT)
    StorageTraits::SetAt(data_, kNumGrowsIndex, *smi_handle_);
    StorageTraits::SetAt(data_, kNumLT5LookupsIndex, *smi_handle_);
    StorageTraits::SetAt(data_, kNumLT25LookupsIndex, *smi_handle_);
    StorageTraits::SetAt(data_, kNumGT25LookupsIndex, *smi_handle_);
    StorageTraits::SetAt(data_, kNumProbesIndex, *smi_handle_);
#endif  // !defined(PRODUCT)

    for (intptr_t i = kHeaderSize; i < data_->Length(); ++i) {
      StorageTraits::SetAt(data_, i, UnusedMarker());
    }
  }

  // Returns whether 'key' matches any key in the table.
  template <typename Key>
  bool ContainsKey(const Key& key) const {
    return FindKey(key) != -1;
  }

  // Returns the entry that matches 'key', or -1 if none exists.
  template <typename Key>
  intptr_t FindKey(const Key& key) const {
    const intptr_t num_entries = NumEntries();
    // TODO(koda): Add salt.
    NOT_IN_PRODUCT(intptr_t collisions = 0;)
    uword hash = KeyTraits::Hash(key);
    ASSERT(Utils::IsPowerOfTwo(num_entries));
    intptr_t probe = hash & (num_entries - 1);
    int probe_distance = 1;
    while (true) {
      if (IsUnused(probe)) {
        NOT_IN_PRODUCT(UpdateCollisions(collisions);)
        return -1;
      } else if (!IsDeleted(probe)) {
        *key_handle_ = GetKey(probe);
        if (KeyTraits::IsMatch(key, *key_handle_)) {
          NOT_IN_PRODUCT(UpdateCollisions(collisions);)
          return probe;
        }
        NOT_IN_PRODUCT(collisions += 1;)
      }
      // Advance probe.  See ArrayLengthForNumOccupied comment for
      // explanation of how we know this hits all slots.
      probe = (probe + probe_distance) & (num_entries - 1);
      probe_distance++;
    }
    UNREACHABLE();
    return -1;
  }

  // Sets *entry to either:
  // - an occupied entry matching 'key', and returns true, or
  // - an unused/deleted entry where a matching key may be inserted,
  //   and returns false.
  template <typename Key>
  bool FindKeyOrDeletedOrUnused(const Key& key, intptr_t* entry) const {
    const intptr_t num_entries = NumEntries();
    ASSERT(entry != nullptr);
    NOT_IN_PRODUCT(intptr_t collisions = 0;)
    uword hash = KeyTraits::Hash(key);
    ASSERT(Utils::IsPowerOfTwo(num_entries));
    intptr_t probe = hash & (num_entries - 1);
    int probe_distance = 1;
    intptr_t deleted = -1;
    while (true) {
      if (IsUnused(probe)) {
        *entry = (deleted != -1) ? deleted : probe;
        NOT_IN_PRODUCT(UpdateCollisions(collisions);)
        return false;
      } else if (IsDeleted(probe)) {
        if (deleted == -1) {
          deleted = probe;
        }
      } else {
        *key_handle_ = GetKey(probe);
        if (KeyTraits::IsMatch(key, *key_handle_)) {
          *entry = probe;
          NOT_IN_PRODUCT(UpdateCollisions(collisions);)
          return true;
        }
        NOT_IN_PRODUCT(collisions += 1;)
      }
      // Advance probe.  See ArrayLengthForNumOccupied comment for
      // explanation of how we know this hits all slots.
      probe = (probe + probe_distance) & (num_entries - 1);
      probe_distance++;
    }
    UNREACHABLE();
    return false;
  }

  // Sets the key of a previously unoccupied entry. This must not be the last
  // unoccupied entry.
  void InsertKey(intptr_t entry, const Object& key) const {
    ASSERT(key.ptr() != UnusedMarker().ptr());
    ASSERT(key.ptr() != DeletedMarker().ptr());
    ASSERT(!IsOccupied(entry));
    AdjustSmiValueAt(kOccupiedEntriesIndex, 1);
    if (IsDeleted(entry)) {
      AdjustSmiValueAt(kDeletedEntriesIndex, -1);
    } else {
      ASSERT(IsUnused(entry));
    }
    InternalSetKey(entry, key);
    ASSERT(IsOccupied(entry));
  }

  bool IsUnused(intptr_t entry) const {
    return InternalGetKey(entry) == UnusedMarker().ptr();
  }
  bool IsOccupied(intptr_t entry) const {
    return !IsUnused(entry) && !IsDeleted(entry);
  }
  bool IsDeleted(intptr_t entry) const {
    return InternalGetKey(entry) == DeletedMarker().ptr();
  }

  ObjectPtr GetKey(intptr_t entry) const {
    ASSERT(IsOccupied(entry));
    return InternalGetKey(entry);
  }
  ObjectPtr GetPayload(intptr_t entry, intptr_t component) const {
    ASSERT(IsOccupied(entry));
    return WeakSerializationReference::Unwrap(
        StorageTraits::At(data_, PayloadIndex(entry, component)));
  }
  void UpdatePayload(intptr_t entry,
                     intptr_t component,
                     const Object& value) const {
    ASSERT(IsOccupied(entry));
    ASSERT(0 <= component && component < kPayloadSize);
    StorageTraits::SetAt(data_, PayloadIndex(entry, component), value);
  }
  // Deletes both the key and payload of the specified entry.
  void DeleteEntry(intptr_t entry) const {
    ASSERT(IsOccupied(entry));
    for (intptr_t i = 0; i < kPayloadSize; ++i) {
      UpdatePayload(entry, i, DeletedMarker());
    }
    InternalSetKey(entry, DeletedMarker());
    AdjustSmiValueAt(kOccupiedEntriesIndex, -1);
    AdjustSmiValueAt(kDeletedEntriesIndex, 1);
  }
  intptr_t NumEntries() const {
    return (data_->Length() - kFirstKeyIndex) / kEntrySize;
  }
  intptr_t NumUnused() const {
    return NumEntries() - NumOccupied() - NumDeleted();
  }
  intptr_t NumOccupied() const { return GetSmiValueAt(kOccupiedEntriesIndex); }
  intptr_t NumDeleted() const { return GetSmiValueAt(kDeletedEntriesIndex); }
  Object& KeyHandle() const { return *key_handle_; }
  Smi& SmiHandle() const { return *smi_handle_; }

#if !defined(PRODUCT)
  intptr_t NumGrows() const { return GetSmiValueAt(kNumGrowsIndex); }
  intptr_t NumLT5Collisions() const {
    return GetSmiValueAt(kNumLT5LookupsIndex);
  }
  intptr_t NumLT25Collisions() const {
    return GetSmiValueAt(kNumLT25LookupsIndex);
  }
  intptr_t NumGT25Collisions() const {
    return GetSmiValueAt(kNumGT25LookupsIndex);
  }
  intptr_t NumProbes() const { return GetSmiValueAt(kNumProbesIndex); }
  void UpdateGrowth() const {
    if (KeyTraits::ReportStats()) {
      AdjustSmiValueAt(kNumGrowsIndex, 1);
    }
  }
  void UpdateCollisions(intptr_t collisions) const {
    if (KeyTraits::ReportStats()) {
      if (Storage::IsImmutable(*data_)) {
        return;
      }
      AdjustSmiValueAt(kNumProbesIndex, collisions + 1);
      if (collisions < 5) {
        AdjustSmiValueAt(kNumLT5LookupsIndex, 1);
      } else if (collisions < 25) {
        AdjustSmiValueAt(kNumLT25LookupsIndex, 1);
      } else {
        AdjustSmiValueAt(kNumGT25LookupsIndex, 1);
      }
    }
  }
  void PrintStats() const {
    if (!KeyTraits::ReportStats()) {
      return;
    }
    const intptr_t num5 = NumLT5Collisions();
    const intptr_t num25 = NumLT25Collisions();
    const intptr_t num_more = NumGT25Collisions();
    // clang-format off
    OS::PrintErr("Stats for %s table :\n"
              " Size of table = %" Pd ",Number of Occupied entries = %" Pd "\n"
              " Number of Grows = %" Pd "\n"
              " Number of lookups with < 5 collisions = %" Pd "\n"
              " Number of lookups with < 25 collisions = %" Pd "\n"
              " Number of lookups with > 25 collisions = %" Pd "\n"
              " Average number of probes = %g\n",
              KeyTraits::Name(),
              NumEntries(), NumOccupied(), NumGrows(),
              num5, num25, num_more,
              static_cast<double>(NumProbes()) / (num5 + num25 + num_more));
    // clang-format on
  }
#endif  // !PRODUCT

  void UpdateWeakDeleted() const {
    if (StorageTraits::ArrayCid != kWeakArrayCid) return;

    // As entries are deleted by GC, NumOccupied and NumDeleted become stale.
    // Re-count before growing/rehashing to prevent table growth when the
    // number of live entries is not increasing.
    intptr_t num_occupied = 0;
    intptr_t num_deleted = 0;
    for (intptr_t i = 0, n = NumEntries(); i < n; i++) {
      if (IsDeleted(i)) {
        num_deleted++;
      }
      if (IsOccupied(i)) {
        num_occupied++;
      }
    }
    SetSmiValueAt(kOccupiedEntriesIndex, num_occupied);
    SetSmiValueAt(kDeletedEntriesIndex, num_deleted);
  }

 protected:
  static constexpr intptr_t kOccupiedEntriesIndex = 0;
  static constexpr intptr_t kDeletedEntriesIndex = 1;
#if defined(PRODUCT)
  static constexpr intptr_t kHeaderSize = kDeletedEntriesIndex + 1;
#else
  static constexpr intptr_t kNumGrowsIndex = 2;
  static constexpr intptr_t kNumLT5LookupsIndex = 3;
  static constexpr intptr_t kNumLT25LookupsIndex = 4;
  static constexpr intptr_t kNumGT25LookupsIndex = 5;
  static constexpr intptr_t kNumProbesIndex = 6;
  static constexpr intptr_t kHeaderSize = kNumProbesIndex + 1;
#endif
  static constexpr intptr_t kMetaDataIndex = kHeaderSize;
  static constexpr intptr_t kFirstKeyIndex = kHeaderSize + kMetaDataSize;
  static constexpr intptr_t kEntrySize = 1 + kPayloadSize;

  intptr_t KeyIndex(intptr_t entry) const {
    ASSERT(0 <= entry && entry < NumEntries());
    return kFirstKeyIndex + (kEntrySize * entry);
  }

  intptr_t PayloadIndex(intptr_t entry, intptr_t component) const {
    ASSERT(0 <= component && component < kPayloadSize);
    return KeyIndex(entry) + 1 + component;
  }

  ObjectPtr InternalGetKey(intptr_t entry) const {
    return WeakSerializationReference::Unwrap(
        StorageTraits::At(data_, KeyIndex(entry)));
  }

  void InternalSetKey(intptr_t entry, const Object& key) const {
    StorageTraits::SetAt(data_, KeyIndex(entry), key);
  }

  intptr_t GetSmiValueAt(intptr_t index) const {
    ASSERT(!data_->IsNull());
    if (StorageTraits::At(data_, index)->IsHeapObject()) {
      Object::Handle(StorageTraits::At(data_, index)).Print();
    }
    ASSERT(!StorageTraits::At(data_, index)->IsHeapObject());
    return Smi::Value(Smi::RawCast(StorageTraits::At(data_, index)));
  }

  void SetSmiValueAt(intptr_t index, intptr_t value) const {
    *smi_handle_ = Smi::New(value);
    StorageTraits::SetAt(data_, index, *smi_handle_);
  }

  void AdjustSmiValueAt(intptr_t index, intptr_t delta) const {
    SetSmiValueAt(index, (GetSmiValueAt(index) + delta));
  }

  Object* key_handle_;
  Smi* smi_handle_;
  // Exactly one of these is non-null, depending on whether Release was called.
  typename StorageTraits::ArrayHandle* data_;
  typename StorageTraits::ArrayHandle* released_data_;

  friend class HashTables;
  template <typename Table, bool kAllCanonicalObjectsAreIncludedIntoSet>
  friend class CanonicalSetDeserializationCluster;
  template <typename Table,
            typename HandleType,
            typename PointerType,
            bool kAllCanonicalObjectsAreIncludedIntoSet>
  friend class CanonicalSetSerializationCluster;
};

// Table with unspecified iteration order. No payload overhead or metadata.
template <typename KeyTraits,
          intptr_t kUserPayloadSize,
          typename StorageTraits = ArrayStorageTraits>
class UnorderedHashTable
    : public HashTable<KeyTraits, kUserPayloadSize, 0, StorageTraits> {
 public:
  typedef HashTable<KeyTraits, kUserPayloadSize, 0, StorageTraits> BaseTable;
  typedef typename StorageTraits::ArrayPtr ArrayPtr;
  typedef typename StorageTraits::ArrayHandle ArrayHandle;
  static constexpr intptr_t kPayloadSize = kUserPayloadSize;
  explicit UnorderedHashTable(ArrayPtr data)
      : BaseTable(Thread::Current()->zone(), data) {}
  UnorderedHashTable(Zone* zone, ArrayPtr data) : BaseTable(zone, data) {}
  UnorderedHashTable(Object* key, Smi* value, ArrayHandle* data)
      : BaseTable(key, value, data) {}
  // Note: Does not check for concurrent modification.
  class Iterator {
   public:
    explicit Iterator(const UnorderedHashTable* table)
        : table_(table), entry_(-1) {}
    bool MoveNext() {
      while (entry_ < (table_->NumEntries() - 1)) {
        ++entry_;
        if (table_->IsOccupied(entry_)) {
          return true;
        }
      }
      return false;
    }
    intptr_t Current() { return entry_; }

   private:
    const UnorderedHashTable* table_;
    intptr_t entry_;
  };

  // No extra book-keeping needed for Initialize, InsertKey, DeleteEntry.
};

class HashTables : public AllStatic {
 public:
  // Allocates and initializes a table.
  template <typename Table>
  static typename Table::Storage::ArrayPtr New(intptr_t initial_capacity,
                                               Heap::Space space = Heap::kNew) {
    auto zone = Thread::Current()->zone();
    Table table(
        zone,
        Table::Storage::New(
            zone, Table::ArrayLengthForNumOccupied(initial_capacity), space));
    table.Initialize();
    return table.Release().ptr();
  }

  template <typename Table>
  static typename Table::Storage::ArrayPtr New(
      const typename Table::Storage::ArrayHandle& array) {
    Table table(Thread::Current()->zone(), array.ptr());
    table.Initialize();
    return table.Release().ptr();
  }

  // Clears 'to' and inserts all elements from 'from', in iteration order.
  // The tables must have the same user payload size.
  template <typename From, typename To>
  static void Copy(const From& from, const To& to) {
    COMPILE_ASSERT(From::kPayloadSize == To::kPayloadSize);
    to.Initialize();
    ASSERT(from.NumOccupied() < to.NumEntries());
    typename From::Iterator it(&from);
    Object& obj = Object::Handle();
    while (it.MoveNext()) {
      intptr_t from_entry = it.Current();
      obj = from.GetKey(from_entry);
      intptr_t to_entry = -1;
      const Object& key = obj;
      bool present = to.FindKeyOrDeletedOrUnused(key, &to_entry);
      ASSERT(!present);
      to.InsertKey(to_entry, obj);
      for (intptr_t i = 0; i < From::kPayloadSize; ++i) {
        obj = from.GetPayload(from_entry, i);
        to.UpdatePayload(to_entry, i, obj);
      }
    }
  }

  static constexpr double kMaxLoadFactor = 0.71;

  template <typename Table>
  static void EnsureLoadFactor(double high, const Table& table) {
    // We count deleted elements because they take up space just
    // like occupied slots in order to cause a rehashing.
    const double current = (1 + table.NumOccupied() + table.NumDeleted()) /
                           static_cast<double>(table.NumEntries());
    const bool too_many_deleted = table.NumOccupied() <= table.NumDeleted();
    if (current < high && !too_many_deleted) {
      return;
    }

    table.UpdateWeakDeleted();

    // Normally we double the size here, but if less than half are occupied
    // then it won't grow (this would imply that there were quite a lot of
    // deleted slots).  We don't want to constantly rehash if we are adding
    // and deleting entries at just under the load factor limit, so we may
    // double the size even though the number of occupied slots would not
    // necessarily justify it.  For example if the max load factor is 71% and
    // the table is 70% full we will double the size to avoid a rehash every
    // time 1% has been added and deleted.
    const intptr_t new_capacity = table.NumOccupied() * 2 + 1;
    ASSERT(table.NumOccupied() == 0 ||
           ((1.0 + table.NumOccupied()) /
            Utils::RoundUpToPowerOfTwo(new_capacity)) <= high);
    Table new_table(New<Table>(new_capacity,  // Is rounded up to power of 2.
                               table.data_->IsOld() ? Heap::kOld : Heap::kNew));
    Copy(table, new_table);
    Table::Storage::SetHandle(*table.data_, new_table.Release());
    NOT_IN_PRODUCT(table.UpdateGrowth(); table.PrintStats();)
  }

  // Serializes a table by concatenating its entries as an array.
  template <typename Table>
  static ArrayPtr ToArray(const Table& table, bool include_payload) {
    const intptr_t entry_size = include_payload ? (1 + Table::kPayloadSize) : 1;
    Array& result = Array::Handle(Array::New(table.NumOccupied() * entry_size));
    typename Table::Iterator it(&table);
    Object& obj = Object::Handle();
    intptr_t result_index = 0;
    while (it.MoveNext()) {
      intptr_t entry = it.Current();
      obj = table.GetKey(entry);
      result.SetAt(result_index++, obj);
      if (include_payload) {
        for (intptr_t i = 0; i < Table::kPayloadSize; ++i) {
          obj = table.GetPayload(entry, i);
          result.SetAt(result_index++, obj);
        }
      }
    }
    return result.ptr();
  }

#if defined(DART_PRECOMPILER)
  // Replace elements of this set with WeakSerializationReferences.
  static void Weaken(const Array& table) {
    if (!table.IsNull()) {
      Object& element = Object::Handle();
      for (intptr_t i = 0; i < table.Length(); i++) {
        element = table.At(i);
        if (!element.IsSmi()) {
          element = WeakSerializationReference::New(
              element, HashTableBase::DeletedMarker());
          table.SetAt(i, element);
        }
      }
    }
  }
#endif
};

template <typename BaseIterTable>
class HashMap : public BaseIterTable {
 public:
  explicit HashMap(ArrayPtr data)
      : BaseIterTable(Thread::Current()->zone(), data) {}
  HashMap(Zone* zone, ArrayPtr data) : BaseIterTable(zone, data) {}
  HashMap(Object* key, Smi* value, Array* data)
      : BaseIterTable(key, value, data) {}
  template <typename Key>
  ObjectPtr GetOrNull(const Key& key, bool* present = nullptr) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (present != nullptr) {
      *present = (entry != -1);
    }
    return (entry == -1) ? Object::null() : BaseIterTable::GetPayload(entry, 0);
  }
  template <typename Key>
  ObjectPtr GetOrDie(const Key& key) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (entry == -1) UNREACHABLE();
    return BaseIterTable::GetPayload(entry, 0);
  }
  bool UpdateOrInsert(const Object& key, const Object& value) const {
    EnsureCapacity();
    intptr_t entry = -1;
    bool present = BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry);
    if (!present) {
      BaseIterTable::InsertKey(entry, key);
    }
    BaseIterTable::UpdatePayload(entry, 0, value);
    return present;
  }
  // Update the value of an existing key. Note that 'key' need not be an Object.
  template <typename Key>
  void UpdateValue(const Key& key, const Object& value) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    ASSERT(entry != -1);
    BaseIterTable::UpdatePayload(entry, 0, value);
  }
  // If 'key' is not present, maps it to 'value_if_absent'. Returns the final
  // value in the map.
  ObjectPtr InsertOrGetValue(const Object& key,
                             const Object& value_if_absent) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::InsertKey(entry, key);
      BaseIterTable::UpdatePayload(entry, 0, value_if_absent);
      return value_if_absent.ptr();
    } else {
      return BaseIterTable::GetPayload(entry, 0);
    }
  }
  // Like InsertOrGetValue, but calls NewKey to allocate a key object if needed.
  template <typename Key>
  ObjectPtr InsertNewOrGetValue(const Key& key,
                                const Object& value_if_absent) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::KeyHandle() =
          BaseIterTable::BaseTable::Traits::NewKey(key);
      BaseIterTable::InsertKey(entry, BaseIterTable::KeyHandle());
      BaseIterTable::UpdatePayload(entry, 0, value_if_absent);
      return value_if_absent.ptr();
    } else {
      return BaseIterTable::GetPayload(entry, 0);
    }
  }

  template <typename Key>
  bool Remove(const Key& key) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (entry == -1) {
      return false;
    } else {
      BaseIterTable::DeleteEntry(entry);
      return true;
    }
  }

  void Clear() const { BaseIterTable::Initialize(); }

 protected:
  void EnsureCapacity() const {
    HashTables::EnsureLoadFactor(HashTables::kMaxLoadFactor, *this);
  }
};

template <typename KeyTraits>
class UnorderedHashMap : public HashMap<UnorderedHashTable<KeyTraits, 1> > {
 public:
  typedef HashMap<UnorderedHashTable<KeyTraits, 1> > BaseMap;
  explicit UnorderedHashMap(ArrayPtr data)
      : BaseMap(Thread::Current()->zone(), data) {}
  UnorderedHashMap(Zone* zone, ArrayPtr data) : BaseMap(zone, data) {}
  UnorderedHashMap(Object* key, Smi* value, Array* data)
      : BaseMap(key, value, data) {}
};

template <typename BaseIterTable, typename StorageTraits>
class HashSet : public BaseIterTable {
 public:
  typedef typename StorageTraits::ArrayPtr ArrayPtr;
  typedef typename StorageTraits::ArrayHandle ArrayHandle;
  explicit HashSet(ArrayPtr data)
      : BaseIterTable(Thread::Current()->zone(), data) {}
  HashSet(Zone* zone, ArrayPtr data) : BaseIterTable(zone, data) {}
  HashSet(Object* key, Smi* value, ArrayHandle* data)
      : BaseIterTable(key, value, data) {}
  bool Insert(const Object& key) {
    EnsureCapacity();
    intptr_t entry = -1;
    bool present = BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry);
    if (!present) {
      BaseIterTable::InsertKey(entry, key);
    }
    return present;
  }

  // If 'key' is not present, insert and return it. Else, return the existing
  // key in the set (useful for canonicalization).
  ObjectPtr InsertOrGet(const Object& key) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::InsertKey(entry, key);
      return key.ptr();
    } else {
      return BaseIterTable::GetKey(entry);
    }
  }

  // Like InsertOrGet, but calls NewKey to allocate a key object if needed.
  template <typename Key>
  ObjectPtr InsertNewOrGet(const Key& key) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::KeyHandle() =
          BaseIterTable::BaseTable::Traits::NewKey(key);
      BaseIterTable::InsertKey(entry, BaseIterTable::KeyHandle());
      return BaseIterTable::KeyHandle().ptr();
    } else {
      return BaseIterTable::GetKey(entry);
    }
  }

  template <typename Key>
  ObjectPtr GetOrNull(const Key& key, bool* present = nullptr) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (present != nullptr) {
      *present = (entry != -1);
    }
    return (entry == -1) ? Object::null() : BaseIterTable::GetKey(entry);
  }

  template <typename Key>
  bool Remove(const Key& key) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (entry == -1) {
      return false;
    } else {
      BaseIterTable::DeleteEntry(entry);
      return true;
    }
  }

  void Clear() const { BaseIterTable::Initialize(); }

 protected:
  void EnsureCapacity() const {
    HashTables::EnsureLoadFactor(HashTables::kMaxLoadFactor, *this);
  }
};

template <typename KeyTraits, typename TableStorageTraits = ArrayStorageTraits>
class UnorderedHashSet
    : public HashSet<UnorderedHashTable<KeyTraits, 0, TableStorageTraits>,
                     TableStorageTraits> {
  using UnderlyingTable = UnorderedHashTable<KeyTraits, 0, TableStorageTraits>;

 public:
  typedef HashSet<UnderlyingTable, TableStorageTraits> BaseSet;
  typedef typename TableStorageTraits::ArrayPtr ArrayPtr;
  typedef typename TableStorageTraits::ArrayHandle ArrayHandle;
  explicit UnorderedHashSet(ArrayPtr data)
      : BaseSet(Thread::Current()->zone(), data) {
    ASSERT(data != Object::null());
  }
  UnorderedHashSet(Zone* zone, ArrayPtr data) : BaseSet(zone, data) {}
  UnorderedHashSet(Object* key, Smi* value, ArrayHandle* data)
      : BaseSet(key, value, data) {}

  void Dump() const {
    Object& entry = Object::Handle();
    for (intptr_t i = 0; i < this->data_->Length(); i++) {
      entry = WeakSerializationReference::Unwrap(
          TableStorageTraits::At(this->data_, i));
      if (entry.ptr() == BaseSet::UnusedMarker().ptr() ||
          entry.ptr() == BaseSet::DeletedMarker().ptr() || entry.IsSmi()) {
        // empty, deleted, num_used/num_deleted
        OS::PrintErr("%" Pd ": %s\n", i, entry.ToCString());
      } else {
        intptr_t hash = KeyTraits::Hash(entry);
        OS::PrintErr("%" Pd ": %" Pd ", %s\n", i, hash, entry.ToCString());
      }
    }
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_HASH_TABLE_H_
