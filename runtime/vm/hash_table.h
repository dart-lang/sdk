// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HASH_TABLE_H_
#define VM_HASH_TABLE_H_

// Temporarily used when sorting the indices in EnumIndexHashTable.
// TODO(koda): Remove these dependencies before using in production.
#include <map>
#include <vector>

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
//  - EnumIndexHashTable
//  - LinkedListHashTable (TODO(koda): Implement.)
// The utility class HashTables handles growth and conversion (e.g., converting
// a compact EnumIndexHashTable to an iteration-efficient LinkedListHashTable).
// The next layer fixes the payload size and provides a natural interface:
//  - HashMap
//  - HashSet
// Combining either of these with an iteration strategy, we get the templates
// intended for use outside this file:
//  - UnorderedHashMap
//  - EnumIndexHashMap
//  - LinkedListHashMap
//  - UnorderedHashSet
//  - EnumIndexHashSet
//  - LinkedListHashSet
// Each of these can be finally specialized with KeyTraits to support any set of
// lookup key types (e.g., look up a char* in a set of String objects), and
// any equality and hash code computation.
//
// The classes all wrap an Array handle, and metods like HashSet::Insert can
// trigger growth into a new RawArray, updating the handle. Debug mode asserts
// that 'Release' was called to get the final RawArray before destruction.
//
// Example use:
//  typedef UnorderedHashMap<FooTraits> ResolvedNamesMap;
//  ...
//  ResolvedNamesMap cache(Array::Handle(resolved_names()));
//  cache.UpdateOrInsert(name0, obj0);
//  cache.UpdateOrInsert(name1, obj1);
//  ...
//  StorePointer(&raw_ptr()->resolved_names_, cache.Release());
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
template<typename KeyTraits, intptr_t kPayloadSize, intptr_t kMetaDataSize>
class HashTable : public ValueObject {
 public:
  typedef KeyTraits Traits;
  explicit HashTable(Array& data) : data_(data) {}

  RawArray* Release() {
    ASSERT(!data_.IsNull());
    RawArray* array = data_.raw();
    data_ = Array::null();
    return array;
  }

  ~HashTable() {
    ASSERT(data_.IsNull());
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
    ASSERT(data_.Length() >= ArrayLengthForNumOccupied(0));
    Smi& zero = Smi::Handle(Smi::New(0));
    data_.SetAt(kOccupiedEntriesIndex, zero);
    data_.SetAt(kDeletedEntriesIndex, zero);
    for (intptr_t i = kHeaderSize; i < data_.Length(); ++i) {
      data_.SetAt(i, Object::sentinel());
    }
  }

  // Returns whether 'key' matches any key in the table.
  template<typename Key>
  bool ContainsKey(const Key& key) const {
    return FindKey(key) != -1;
  }

  // Returns the entry that matches 'key', or -1 if none exists.
  template<typename Key>
  intptr_t FindKey(const Key& key) const {
    ASSERT(NumOccupied() < NumEntries());
    // TODO(koda): Add salt.
    intptr_t probe = static_cast<uword>(KeyTraits::Hash(key)) % NumEntries();
    Object& obj = Object::Handle();
    // TODO(koda): Consider quadratic probing.
    for (; ; probe = (probe + 1) % NumEntries()) {
      if (IsUnused(probe)) {
        return -1;
      } else if (IsDeleted(probe)) {
        continue;
      } else {
        obj = GetKey(probe);
        if (KeyTraits::IsMatch(key, obj)) {
          return probe;
        }
      }
    }
    UNREACHABLE();
    return -1;
  }

  // Sets *entry to either:
  // - an occupied entry matching 'key', and returns true, or
  // - an unused/deleted entry where a matching key may be inserted,
  //   and returns false.
  template<typename Key>
  bool FindKeyOrDeletedOrUnused(const Key& key, intptr_t* entry) const {
    ASSERT(entry != NULL);
    ASSERT(NumOccupied() < NumEntries());
    intptr_t probe = static_cast<uword>(KeyTraits::Hash(key)) % NumEntries();
    Object& obj = Object::Handle();
    intptr_t deleted = -1;
    // TODO(koda): Consider quadratic probing.
    for (; ; probe = (probe + 1) % NumEntries()) {
      if (IsUnused(probe)) {
        *entry = (deleted != -1) ? deleted : probe;
        return false;
      } else if (IsDeleted(probe)) {
        if (deleted == -1) {
          deleted = probe;
        }
      } else {
        obj = GetKey(probe);
        if (KeyTraits::IsMatch(key, obj)) {
          *entry = probe;
          return true;
        }
      }
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
    return data_.At(PayloadIndex(entry, component));
  }
  void UpdatePayload(intptr_t entry,
                     intptr_t component,
                     const Object& value) const {
    ASSERT(IsOccupied(entry));
    ASSERT(0 <= component && component < kPayloadSize);
    data_.SetAt(PayloadIndex(entry, component), value);
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
    return (data_.Length() - kFirstKeyIndex) / kEntrySize;
  }
  intptr_t NumUnused() const {
    return NumEntries() - NumOccupied() - NumDeleted();
  }
  intptr_t NumOccupied() const {
    return GetSmiValueAt(kOccupiedEntriesIndex);
  }
  intptr_t NumDeleted() const {
    return GetSmiValueAt(kDeletedEntriesIndex);
  }

 protected:
  static const intptr_t kOccupiedEntriesIndex = 0;
  static const intptr_t kDeletedEntriesIndex = 1;
  static const intptr_t kHeaderSize = kDeletedEntriesIndex + 1;
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
    return data_.At(KeyIndex(entry));
  }

  void InternalSetKey(intptr_t entry, const Object& key) const {
    data_.SetAt(KeyIndex(entry), key);
  }

  intptr_t GetSmiValueAt(intptr_t index) const {
    ASSERT(Object::Handle(data_.At(index)).IsSmi());
    return Smi::Value(Smi::RawCast(data_.At(index)));
  }

  void SetSmiValueAt(intptr_t index, intptr_t value) const {
    const Smi& smi = Smi::Handle(Smi::New(value));
    data_.SetAt(index, smi);
  }

  void AdjustSmiValueAt(intptr_t index, intptr_t delta) const {
    SetSmiValueAt(index, (GetSmiValueAt(index) + delta));
  }

  Array& data_;

  friend class HashTables;
};


// Table with unspecified iteration order. No payload overhead or metadata.
template<typename KeyTraits, intptr_t kUserPayloadSize>
class UnorderedHashTable : public HashTable<KeyTraits, kUserPayloadSize, 0> {
 public:
  typedef HashTable<KeyTraits, kUserPayloadSize, 0> BaseTable;
  static const intptr_t kPayloadSize = kUserPayloadSize;
  explicit UnorderedHashTable(Array& data) : BaseTable(data) {}
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
    intptr_t Current() {
      return entry_;
    }

   private:
    const UnorderedHashTable* table_;
    intptr_t entry_;
  };

  // No extra book-keeping needed for Initialize, InsertKey, DeleteEntry.
};


// Table with insertion order, using one payload component for the enumeration
// index, and one metadata element for the next enumeration index.
template<typename KeyTraits, intptr_t kUserPayloadSize>
class EnumIndexHashTable
    : public HashTable<KeyTraits, kUserPayloadSize + 1, 1> {
 public:
  typedef HashTable<KeyTraits, kUserPayloadSize + 1, 1> BaseTable;
  static const intptr_t kPayloadSize = kUserPayloadSize;
  static const intptr_t kNextEnumIndex = BaseTable::kMetaDataIndex;
  explicit EnumIndexHashTable(Array& data) : BaseTable(data) {}
  // Note: Does not check for concurrent modification.
  class Iterator {
   public:
    explicit Iterator(const EnumIndexHashTable* table) : index_(-1) {
      // TODO(koda): Use GrowableArray after adding stateful comparator support.
      std::map<intptr_t, intptr_t> enum_to_entry;
      for (intptr_t i = 0; i < table->NumEntries(); ++i) {
        if (table->IsOccupied(i)) {
          intptr_t enum_index =
              table->GetSmiValueAt(table->PayloadIndex(i, kPayloadSize));
          enum_to_entry[enum_index] = i;
        }
      }
      for (std::map<intptr_t, intptr_t>::iterator it = enum_to_entry.begin();
           it != enum_to_entry.end();
           ++it) {
        entries_.push_back(it->second);
      }
    }
    bool MoveNext() {
      if (index_ < (static_cast<intptr_t>(entries_.size() - 1))) {
        index_++;
        return true;
      }
      return false;
    }
    intptr_t Current() {
      return entries_[index_];
    }

   private:
    intptr_t index_;
    std::vector<intptr_t> entries_;
  };

  void Initialize() const {
    BaseTable::Initialize();
    BaseTable::SetSmiValueAt(kNextEnumIndex, 0);
  }

  void InsertKey(intptr_t entry, const Object& key) const {
    BaseTable::InsertKey(entry, key);
    const Smi& next_enum_index =
        Smi::Handle(Smi::New(BaseTable::GetSmiValueAt(kNextEnumIndex)));
    BaseTable::UpdatePayload(entry, kPayloadSize, next_enum_index);
    // TODO(koda): Handle possible Smi overflow from repeated insert/delete.
    BaseTable::AdjustSmiValueAt(kNextEnumIndex, 1);
  }

  // No extra book-keeping needed for DeleteEntry.
};


class HashTables : public AllStatic {
 public:
  // Allocates and initializes a table.
  template<typename Table>
  static RawArray* New(intptr_t initial_capacity,
                       Heap::Space space = Heap::kNew) {
    Table table(Array::Handle(Array::New(
        Table::ArrayLengthForNumOccupied(initial_capacity), space)));
    table.Initialize();
    return table.Release();
  }

  // Clears 'to' and inserts all elements from 'from', in iteration order.
  // The tables must have the same user payload size.
  template<typename From, typename To>
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

  template<typename Table>
  static void EnsureLoadFactor(double low, double high, const Table& table) {
    double current = (1 + table.NumOccupied() + table.NumDeleted()) /
        static_cast<double>(table.NumEntries());
    if (low <= current && current < high) {
      return;
    }
    double target = (low + high) / 2.0;
    intptr_t new_capacity = (1 + table.NumOccupied()) / target;
    Table new_table(Array::Handle(New<Table>(
        new_capacity,
        table.data_.IsOld() ? Heap::kOld : Heap::kNew)));
    Copy(table, new_table);
    table.data_ = new_table.Release();
  }

  // Serializes a table by concatenating its entries as an array.
  template<typename Table>
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


template<typename BaseIterTable>
class HashMap : public BaseIterTable {
 public:
  explicit HashMap(Array& data) : BaseIterTable(data) {}
  template<typename Key>
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
  template<typename Key>
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
  template<typename Key>
  RawObject* InsertNewOrGetValue(const Key& key,
                                 const Object& value_if_absent) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      Object& new_key = Object::Handle(
          BaseIterTable::BaseTable::Traits::NewKey(key));
      BaseIterTable::InsertKey(entry, new_key);
      BaseIterTable::UpdatePayload(entry, 0, value_if_absent);
      return value_if_absent.raw();
    } else {
      return BaseIterTable::GetPayload(entry, 0);
    }
  }

  template<typename Key>
  bool Remove(const Key& key) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (entry == -1) {
      return false;
    } else {
      BaseIterTable::DeleteEntry(entry);
      return true;
    }
  }

 protected:
  void EnsureCapacity() const {
    static const double kMaxLoadFactor = 0.75;
    HashTables::EnsureLoadFactor(0.0, kMaxLoadFactor, *this);
  }
};


template<typename KeyTraits>
class UnorderedHashMap : public HashMap<UnorderedHashTable<KeyTraits, 1> > {
 public:
  typedef HashMap<UnorderedHashTable<KeyTraits, 1> > BaseMap;
  explicit UnorderedHashMap(Array& data) : BaseMap(data) {}
};


template<typename KeyTraits>
class EnumIndexHashMap : public HashMap<EnumIndexHashTable<KeyTraits, 1> > {
 public:
  typedef HashMap<EnumIndexHashTable<KeyTraits, 1> > BaseMap;
  explicit EnumIndexHashMap(Array& data) : BaseMap(data) {}
};


template<typename BaseIterTable>
class HashSet : public BaseIterTable {
 public:
  explicit HashSet(Array& data) : BaseIterTable(data) {}
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
      return BaseIterTable::GetPayload(entry, 0);
    }
  }

  // Like InsertOrGet, but calls NewKey to allocate a key object if needed.
  template<typename Key>
  RawObject* InsertNewOrGet(const Key& key) const {
    EnsureCapacity();
    intptr_t entry = -1;
    if (!BaseIterTable::FindKeyOrDeletedOrUnused(key, &entry)) {
      Object& new_key = Object::Handle(
          BaseIterTable::BaseTable::Traits::NewKey(key));
      BaseIterTable::InsertKey(entry, new_key);
      return new_key.raw();
    } else {
      return BaseIterTable::GetKey(entry);
    }
  }

  template<typename Key>
  RawObject* GetOrNull(const Key& key, bool* present = NULL) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (present != NULL) {
      *present = (entry != -1);
    }
    return (entry == -1) ? Object::null() : BaseIterTable::GetKey(entry);
  }

  template<typename Key>
  bool Remove(const Key& key) const {
    intptr_t entry = BaseIterTable::FindKey(key);
    if (entry == -1) {
      return false;
    } else {
      BaseIterTable::DeleteEntry(entry);
      return true;
    }
  }

 protected:
  void EnsureCapacity() const {
    static const double kMaxLoadFactor = 0.75;
    HashTables::EnsureLoadFactor(0.0, kMaxLoadFactor, *this);
  }
};


template<typename KeyTraits>
class UnorderedHashSet : public HashSet<UnorderedHashTable<KeyTraits, 0> > {
 public:
  typedef HashSet<UnorderedHashTable<KeyTraits, 0> > BaseSet;
  explicit UnorderedHashSet(Array& data) : BaseSet(data) {}
};


template<typename KeyTraits>
class EnumIndexHashSet : public HashSet<EnumIndexHashTable<KeyTraits, 0> > {
 public:
  typedef HashSet<EnumIndexHashTable<KeyTraits, 0> > BaseSet;
  explicit EnumIndexHashSet(Array& data) : BaseSet(data) {}
};

}  // namespace dart

#endif  // VM_HASH_TABLE_H_
