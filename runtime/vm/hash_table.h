// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_TABLE_H_
#define RUNTIME_VM_HASH_TABLE_H_

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

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
//  ASSERT(cache.Release().raw() == get_foo_cache());
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
// Any object except Object::sentinel() and Object::transition_sentinel()
// may be stored as a key. Any object may be stored in a payload.
//
// Parameters
//  KeyTraits: defines static methods
//    bool IsMatch(const Key& key, const Object& obj) and
//    uword Hash(const Key& key) for any number of desired lookup key types.
//  kPayloadSize: number of components of the payload in each entry.
//  kMetaDataSize: number of elements reserved (e.g., for iteration order data).
template <typename KeyTraits, intptr_t kPayloadSize, intptr_t kMetaDataSize>
class HashTable : public ValueObject {
 public:
  typedef KeyTraits Traits;
  // Uses the passed in handles for all handle operations.
  // 'Release' must be called at the end to obtain the final table
  // after potential growth/shrinkage.
  HashTable(Object* key, Smi* index, Array* data)
      : key_handle_(key),
        smi_handle_(index),
        data_(data),
        released_data_(NULL) {}
  // Uses 'zone' for handle allocation. 'Release' must be called at the end
  // to obtain the final table after potential growth/shrinkage.
  HashTable(Zone* zone, RawArray* data)
      : key_handle_(&Object::Handle(zone)),
        smi_handle_(&Smi::Handle(zone)),
        data_(&Array::Handle(zone, data)),
        released_data_(NULL) {}

  // Returns the final table. The handle is cleared when this HashTable is
  // destroyed.
  Array& Release() {
    ASSERT(data_ != NULL);
    ASSERT(released_data_ == NULL);
    // Ensure that no methods are called after 'Release'.
    released_data_ = data_;
    data_ = NULL;
    return *released_data_;
  }

  ~HashTable() {
    // In DEBUG mode, calling 'Release' is mandatory.
    ASSERT(data_ == NULL);
    if (released_data_ != NULL) {
      *released_data_ = Array::null();
    }
  }

  // Returns a backing storage size such that 'num_occupied' distinct keys can
  // be inserted into the table.
  static intptr_t ArrayLengthForNumOccupied(intptr_t num_occupied) {
    // The current invariant requires at least one unoccupied entry.
    // TODO(koda): Adjust if moving to quadratic probing.
    intptr_t num_entries = num_occupied + 1;
    return kFirstKeyIndex + (kEntrySize * num_entries);
  }

  // Initializes an empty table.
  void Initialize() const {
    ASSERT(data_->Length() >= ArrayLengthForNumOccupied(0));
    *smi_handle_ = Smi::New(0);
    data_->SetAt(kOccupiedEntriesIndex, *smi_handle_);
    data_->SetAt(kDeletedEntriesIndex, *smi_handle_);

#if !defined(PRODUCT)
    data_->SetAt(kNumGrowsIndex, *smi_handle_);
    data_->SetAt(kNumLT5LookupsIndex, *smi_handle_);
    data_->SetAt(kNumLT25LookupsIndex, *smi_handle_);
    data_->SetAt(kNumGT25LookupsIndex, *smi_handle_);
#endif  // !defined(PRODUCT)

    for (intptr_t i = kHeaderSize; i < data_->Length(); ++i) {
      data_->SetAt(i, Object::sentinel());
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
    ASSERT(NumOccupied() < num_entries);
    // TODO(koda): Add salt.
    NOT_IN_PRODUCT(intptr_t collisions = 0;)
    uword hash = KeyTraits::Hash(key);
    intptr_t probe = hash % num_entries;
    // TODO(koda): Consider quadratic probing.
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
      // Advance probe.
      probe++;
      probe = (probe == num_entries) ? 0 : probe;
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
    ASSERT(entry != NULL);
    ASSERT(NumOccupied() < num_entries);
    NOT_IN_PRODUCT(intptr_t collisions = 0;)
    uword hash = KeyTraits::Hash(key);
    intptr_t probe = hash % num_entries;
    intptr_t deleted = -1;
    // TODO(koda): Consider quadratic probing.
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
      // Advance probe.
      probe++;
      probe = (probe == num_entries) ? 0 : probe;
    }
    UNREACHABLE();
    return false;
  }

  // Sets the key of a previously unoccupied entry. This must not be the last
  // unoccupied entry.
  void InsertKey(intptr_t entry, const Object& key) const {
    ASSERT(!IsOccupied(entry));
    AdjustSmiValueAt(kOccupiedEntriesIndex, 1);
    if (IsDeleted(entry)) {
      AdjustSmiValueAt(kDeletedEntriesIndex, -1);
    } else {
      ASSERT(IsUnused(entry));
    }
    InternalSetKey(entry, key);
    ASSERT(IsOccupied(entry));
    ASSERT(NumOccupied() < NumEntries());
  }

  bool IsUnused(intptr_t entry) const {
    return InternalGetKey(entry) == Object::sentinel().raw();
  }
  bool IsOccupied(intptr_t entry) const {
    return !IsUnused(entry) && !IsDeleted(entry);
  }
  bool IsDeleted(intptr_t entry) const {
    return InternalGetKey(entry) == Object::transition_sentinel().raw();
  }

  RawObject* GetKey(intptr_t entry) const {
    ASSERT(IsOccupied(entry));
    return InternalGetKey(entry);
  }
  RawObject* GetPayload(intptr_t entry, intptr_t component) const {
    ASSERT(IsOccupied(entry));
    return data_->At(PayloadIndex(entry, component));
  }
  void UpdatePayload(intptr_t entry,
                     intptr_t component,
                     const Object& value) const {
    ASSERT(IsOccupied(entry));
    ASSERT(0 <= component && component < kPayloadSize);
    data_->SetAt(PayloadIndex(entry, component), value);
  }
  // Deletes both the key and payload of the specified entry.
  void DeleteEntry(intptr_t entry) const {
    ASSERT(IsOccupied(entry));
    for (intptr_t i = 0; i < kPayloadSize; ++i) {
      UpdatePayload(entry, i, Object::transition_sentinel());
    }
    InternalSetKey(entry, Object::transition_sentinel());
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
  void UpdateGrowth() const {
    if (KeyTraits::ReportStats()) {
      AdjustSmiValueAt(kNumGrowsIndex, 1);
    }
  }
  void UpdateCollisions(intptr_t collisions) const {
    if (KeyTraits::ReportStats()) {
      if (data_->raw()->IsVMHeapObject()) {
        return;
      }
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
    // clang-format off
    OS::Print("Stats for %s table :\n"
              " Size of table = %" Pd ",Number of Occupied entries = %" Pd "\n"
              " Number of Grows = %" Pd "\n"
              " Number of look ups with < 5 collisions = %" Pd "\n"
              " Number of look ups with < 25 collisions = %" Pd "\n"
              " Number of look ups with > 25 collisions = %" Pd "\n",
              KeyTraits::Name(),
              NumEntries(), NumOccupied(),
              NumGrows(),
              NumLT5Collisions(), NumLT25Collisions(), NumGT25Collisions());
    // clang-format on
  }
#endif  // !PRODUCT

 protected:
  static const intptr_t kOccupiedEntriesIndex = 0;
  static const intptr_t kDeletedEntriesIndex = 1;
#if defined(PRODUCT)
  static const intptr_t kHeaderSize = kDeletedEntriesIndex + 1;
#else
  static const intptr_t kNumGrowsIndex = 2;
  static const intptr_t kNumLT5LookupsIndex = 3;
  static const intptr_t kNumLT25LookupsIndex = 4;
  static const intptr_t kNumGT25LookupsIndex = 5;
  static const intptr_t kHeaderSize = kNumGT25LookupsIndex + 1;
#endif
  static const intptr_t kMetaDataIndex = kHeaderSize;
  static const intptr_t kFirstKeyIndex = kHeaderSize + kMetaDataSize;
  static const intptr_t kEntrySize = 1 + kPayloadSize;

  intptr_t KeyIndex(intptr_t entry) const {
    ASSERT(0 <= entry && entry < NumEntries());
    return kFirstKeyIndex + (kEntrySize * entry);
  }

  intptr_t PayloadIndex(intptr_t entry, intptr_t component) const {
    ASSERT(0 <= component && component < kPayloadSize);
    return KeyIndex(entry) + 1 + component;
  }

  RawObject* InternalGetKey(intptr_t entry) const {
    return data_->At(KeyIndex(entry));
  }

  void InternalSetKey(intptr_t entry, const Object& key) const {
    data_->SetAt(KeyIndex(entry), key);
  }

  intptr_t GetSmiValueAt(intptr_t index) const {
    ASSERT(!data_->IsNull());
    ASSERT(!data_->At(index)->IsHeapObject());
    return Smi::Value(Smi::RawCast(data_->At(index)));
  }

  void SetSmiValueAt(intptr_t index, intptr_t value) const {
    *smi_handle_ = Smi::New(value);
    data_->SetAt(index, *smi_handle_);
  }

  void AdjustSmiValueAt(intptr_t index, intptr_t delta) const {
    SetSmiValueAt(index, (GetSmiValueAt(index) + delta));
  }

  Object* key_handle_;
  Smi* smi_handle_;
  // Exactly one of these is non-NULL, depending on whether Release was called.
  Array* data_;
  Array* released_data_;

  friend class HashTables;
};

// Table with unspecified iteration order. No payload overhead or metadata.
template <typename KeyTraits, intptr_t kUserPayloadSize>
class UnorderedHashTable : public HashTable<KeyTraits, kUserPayloadSize, 0> {
 public:
  typedef HashTable<KeyTraits, kUserPayloadSize, 0> BaseTable;
  static const intptr_t kPayloadSize = kUserPayloadSize;
  explicit UnorderedHashTable(RawArray* data)
      : BaseTable(Thread::Current()->zone(), data) {}
  UnorderedHashTable(Zone* zone, RawArray* data) : BaseTable(zone, data) {}
  UnorderedHashTable(Object* key, Smi* value, Array* data)
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
  static RawArray* New(intptr_t initial_capacity,
                       Heap::Space space = Heap::kNew) {
    Table table(
        Thread::Current()->zone(),
        Array::New(Table::ArrayLengthForNumOccupied(initial_capacity), space));
    table.Initialize();
    return table.Release().raw();
  }

  template <typename Table>
  static RawArray* New(const Array& array) {
    Table table(Thread::Current()->zone(), array.raw());
    table.Initialize();
    return table.Release().raw();
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

  template <typename Table>
  static void EnsureLoadFactor(double low, double high, const Table& table) {
    double current = (1 + table.NumOccupied() + table.NumDeleted()) /
                     static_cast<double>(table.NumEntries());
    if (low <= current && current < high) {
      return;
    }
    double target = (low + high) / 2.0;
    intptr_t new_capacity = (1 + table.NumOccupied()) / target;
    Table new_table(New<Table>(new_capacity,
                               table.data_->IsOld() ? Heap::kOld : Heap::kNew));
    Copy(table, new_table);
    *table.data_ = new_table.Release().raw();
    NOT_IN_PRODUCT(table.UpdateGrowth(); table.PrintStats();)
  }

  // Serializes a table by concatenating its entries as an array.
  template <typename Table>
  static RawArray* ToArray(const Table& table, bool include_payload) {
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
    return result.raw();
  }
};

template <typename BaseIterTable>
class HashMap : public BaseIterTable {
 public:
  explicit HashMap(RawArray* data)
      : BaseIterTable(Thread::Current()->zone(), data) {}
  HashMap(Zone* zone, RawArray* data) : BaseIterTable(zone, data) {}
  HashMap(Object* key, Smi* value, Array* data)
      : BaseIterTable(key, value, data) {}
  template <typename Key>
  RawObject* GetOrNull(const Key& key, bool* present = NULL) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (present != NULL) {
      *present = (entry != -1);
    }
    return (entry == -1) ? Object::null() : BaseIterTable::GetPayload(entry, 0);
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
  RawObject* InsertOrGetValue(const Object& key,
                              const Object& value_if_absent) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::InsertKey(entry, key);
      BaseIterTable::UpdatePayload(entry, 0, value_if_absent);
      return value_if_absent.raw();
    } else {
      return BaseIterTable::GetPayload(entry, 0);
    }
  }
  // Like InsertOrGetValue, but calls NewKey to allocate a key object if needed.
  template <typename Key>
  RawObject* InsertNewOrGetValue(const Key& key,
                                 const Object& value_if_absent) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::KeyHandle() =
          BaseIterTable::BaseTable::Traits::NewKey(key);
      BaseIterTable::InsertKey(entry, BaseIterTable::KeyHandle());
      BaseIterTable::UpdatePayload(entry, 0, value_if_absent);
      return value_if_absent.raw();
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
    static const double kMaxLoadFactor = 0.75;
    // We currently never shrink.
    HashTables::EnsureLoadFactor(0.0, kMaxLoadFactor, *this);
  }
};

template <typename KeyTraits>
class UnorderedHashMap : public HashMap<UnorderedHashTable<KeyTraits, 1> > {
 public:
  typedef HashMap<UnorderedHashTable<KeyTraits, 1> > BaseMap;
  explicit UnorderedHashMap(RawArray* data)
      : BaseMap(Thread::Current()->zone(), data) {}
  UnorderedHashMap(Zone* zone, RawArray* data) : BaseMap(zone, data) {}
  UnorderedHashMap(Object* key, Smi* value, Array* data)
      : BaseMap(key, value, data) {}
};

template <typename BaseIterTable>
class HashSet : public BaseIterTable {
 public:
  explicit HashSet(RawArray* data)
      : BaseIterTable(Thread::Current()->zone(), data) {}
  HashSet(Zone* zone, RawArray* data) : BaseIterTable(zone, data) {}
  HashSet(Object* key, Smi* value, Array* data)
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
  RawObject* InsertOrGet(const Object& key) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::InsertKey(entry, key);
      return key.raw();
    } else {
      return BaseIterTable::GetKey(entry);
    }
  }

  // Like InsertOrGet, but calls NewKey to allocate a key object if needed.
  template <typename Key>
  RawObject* InsertNewOrGet(const Key& key) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      BaseIterTable::KeyHandle() =
          BaseIterTable::BaseTable::Traits::NewKey(key);
      BaseIterTable::InsertKey(entry, BaseIterTable::KeyHandle());
      return BaseIterTable::KeyHandle().raw();
    } else {
      return BaseIterTable::GetKey(entry);
    }
  }

  template <typename Key>
  RawObject* GetOrNull(const Key& key, bool* present = NULL) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (present != NULL) {
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
    static const double kMaxLoadFactor = 0.75;
    // We currently never shrink.
    HashTables::EnsureLoadFactor(0.0, kMaxLoadFactor, *this);
  }
};

template <typename KeyTraits>
class UnorderedHashSet : public HashSet<UnorderedHashTable<KeyTraits, 0> > {
 public:
  typedef HashSet<UnorderedHashTable<KeyTraits, 0> > BaseSet;
  explicit UnorderedHashSet(RawArray* data)
      : BaseSet(Thread::Current()->zone(), data) {
    ASSERT(data != Array::null());
  }
  UnorderedHashSet(Zone* zone, RawArray* data) : BaseSet(zone, data) {}
  UnorderedHashSet(Object* key, Smi* value, Array* data)
      : BaseSet(key, value, data) {}
};

}  // namespace dart

#endif  // RUNTIME_VM_HASH_TABLE_H_
