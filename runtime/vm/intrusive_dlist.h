// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_INTRUSIVE_DLIST_H_
#define RUNTIME_VM_INTRUSIVE_DLIST_H_

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

// Abstraction for "intrusive" doubly-linked list in a type-safe way in C++.
//
// By "intrusive" we mean that a class Item containing various field members
// has also next/previous pointers to the next/previous Item.
//
// To change a class Item to be part of such a doubly-linked list, one only
// needs to inherit from IntrusiveDListEntry<Item> (in addition to the normal
// base class).
//
// To change a class Item to be part of multiple doubly-linked lists, one can
// inherit multiple times from IntrusiveDListEntry<Item, N>, each time with a
// different value for <N>.
//
// To insert an object into a list, one uses a IntrusiveDList<Item, N>. It
// provides support for insertion/iteration/deletion.
//
// Usage example:
//
//    class Base {
//      <arbitrary state here>
//    };
//
//    class Item : public Base,
//                 public IntrusiveDListEntry<Item>,
//                 public IntrusiveDListEntry<Item, 2> {
//      <arbitrary state here>
//    };
//
//    Item a1, a2, a3;
//
//    IntrusiveDList<Item> all;
//    all.Append(a2);
//    all.Prepend(a1);
//    all.Append(a3);
//
//    IntrusiveDList<Item, 2> idle, ready;
//    idle.Append(a1);
//    ready.Append(a2);
//    ready.Append(a3);
//

template <typename T, int N>
class IntrusiveDList;

template <typename T, int N = 1>
class IntrusiveDListEntry {
 public:
  IntrusiveDListEntry() {}

  ~IntrusiveDListEntry() {
    // Either this is an unlinked entry or a head/anchor.
    ASSERT((next_ == nullptr && prev_ == nullptr) ||
           (next_ == this && prev_ == this));
  }

 private:
  void MakeHead() {
    ASSERT(next_ == nullptr && prev_ == nullptr);
    next_ = prev_ = this;
  }

  // This uses the C++ compiler's ability to convert between classes inside a
  // (possibly multi-) inheritance hierarchy.
  //
  // The non-typesafe C equivalent of this is:
  //
  //     ((uint8*)this) - offsetof(ContainerType, list_entry);
  //
  T* container() { return static_cast<T*>(this); }

  void Append(IntrusiveDListEntry<T, N>* entry) {
    ASSERT(entry->next_ == nullptr && entry->prev_ == nullptr);
    entry->next_ = next_;
    entry->prev_ = this;
    next_ = entry;
    entry->next_->prev_ = entry;
  }

  void Prepend(IntrusiveDListEntry<T, N>* entry) {
    ASSERT(entry->next_ == nullptr && entry->prev_ == nullptr);
    entry->next_ = this;
    entry->prev_ = prev_;
    prev_ = entry;
    entry->prev_->next_ = entry;
  }

  void Remove() {
    ASSERT(prev_->next_ == this);
    ASSERT(next_->prev_ == this);
    ASSERT(prev_ != this && next_ != this);

    prev_->next_ = next_;
    next_->prev_ = prev_;

    next_ = nullptr;
    prev_ = nullptr;
  }

  bool IsEmpty() const {
    bool result = next_ == this;
    ASSERT(result == (prev_ == this));
    return result;
  }

  bool IsLinked() const {
    ASSERT((next_ == nullptr) == (prev_ == nullptr));
    return next_ != nullptr;
  }

  IntrusiveDListEntry<T, N>* Prev() const { return prev_; }

  IntrusiveDListEntry<T, N>* Next() const { return next_; }

  friend class IntrusiveDList<T, N>;

  IntrusiveDListEntry<T, N>* next_ = nullptr;
  IntrusiveDListEntry<T, N>* prev_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(IntrusiveDListEntry);
};

template <typename T, int N = 1>
class IntrusiveDList {
 public:
  typedef IntrusiveDListEntry<T, N> Entry;

  template <typename ContainerType, int I = 1>
  class Iterator {
   public:
    Iterator(IntrusiveDList<ContainerType, I>* head,
             IntrusiveDListEntry<ContainerType, I>* entry)
        : head_(head), entry_(entry) {}

    inline ContainerType* operator->() const { return entry_->container(); }

    inline ContainerType* operator*() const { return entry_->container(); }

    inline bool operator==(const Iterator<ContainerType, I>& other) const {
      return entry_ == other.entry_;
    }

    inline bool operator!=(const Iterator<ContainerType, I>& other) const {
      return !(*this == other);
    }

    inline Iterator<ContainerType, I>& operator++() {
      entry_ = entry_->Next();
      return *this;
    }

    inline Iterator<ContainerType, I>& operator--() {
      entry_ = entry_->Prev();
      return *this;
    }

   private:
    friend IntrusiveDList;

    IntrusiveDList<ContainerType, I>* head_;
    IntrusiveDListEntry<ContainerType, I>* entry_;
  };

  inline IntrusiveDList() { head_.MakeHead(); }

  inline void Append(T* a) { head_.Prepend(convert(a)); }

  inline void Prepend(T* a) { head_.Append(convert(a)); }

  // NOTE: This function only checks whether [a] is linked inside *a*
  // [IntrusiveDList].
  inline bool IsInList(T* a) const { return convert(a)->IsLinked(); }

  inline void Remove(T* a) { convert(a)->Remove(); }

  inline bool IsEmpty() const { return head_.IsEmpty(); }

  inline T* First() const {
    ASSERT(!IsEmpty());
    return head_.Next()->container();
  }

  inline T* Last() const {
    ASSERT(!IsEmpty());
    return head_.Prev()->container();
  }

  inline T* RemoveFirst() {
    ASSERT(!IsEmpty());
    auto entry = head_.Next();
    T* container = entry->container();
    entry->Remove();
    return container;
  }

  inline T* RemoveLast() {
    ASSERT(!IsEmpty());
    auto entry = head_.Prev();
    T* container = entry->container();
    entry->Remove();
    return container;
  }

  inline Iterator<T, N> Begin() { return Iterator<T, N>(this, head_.Next()); }

  inline Iterator<T, N> End() { return Iterator<T, N>(this, &head_); }

  inline Iterator<T, N> begin() { return Begin(); }

  inline Iterator<T, N> end() { return End(); }

  inline Iterator<T, N> Erase(const Iterator<T, N>& iterator) {
    ASSERT(iterator.head_ == this);
    Iterator<T, N> next(this, iterator.entry_->Next());
    iterator.entry_->Remove();
    return next;
  }

  bool ContainsForDebugging(const T* a) {
    for (auto entry : *this) {
      if (entry == a) return true;
    }
    return false;
  }

  void AppendList(IntrusiveDList<T, N>* other) {
    if (other->IsEmpty()) return;

    auto other_first = other->head_.Next();
    auto other_last = other->head_.Prev();
    other->head_.next_ = &other->head_;
    other->head_.prev_ = &other->head_;

    auto prev = head_.prev_;

    prev->next_ = other_first;
    other_first->prev_ = prev;

    other_last->next_ = &head_;
    head_.prev_ = other_last;
  }

 private:
  Entry head_;

  Entry* convert(T* entry) const { return static_cast<Entry*>(entry); }
};

}  // namespace dart.

#endif  // RUNTIME_VM_INTRUSIVE_DLIST_H_
