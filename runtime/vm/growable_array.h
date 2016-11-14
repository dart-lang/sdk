// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Defines growable array classes, that differ where they are allocated:
// - GrowableArray: allocated on stack.
// - ZoneGrowableArray: allocated in the zone.
// - MallocGrowableArray: allocates using malloc/realloc; free is only called
//   at destruction.

#ifndef RUNTIME_VM_GROWABLE_ARRAY_H_
#define RUNTIME_VM_GROWABLE_ARRAY_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

template <typename T, typename B, typename Allocator = Zone>
class BaseGrowableArray : public B {
 public:
  explicit BaseGrowableArray(Allocator* allocator)
      : length_(0), capacity_(0), data_(NULL), allocator_(allocator) {}

  BaseGrowableArray(intptr_t initial_capacity, Allocator* allocator)
      : length_(0), capacity_(0), data_(NULL), allocator_(allocator) {
    if (initial_capacity > 0) {
      capacity_ = Utils::RoundUpToPowerOfTwo(initial_capacity);
      data_ = allocator_->template Alloc<T>(capacity_);
    }
  }

  ~BaseGrowableArray() { allocator_->template Free<T>(data_, capacity_); }

  intptr_t length() const { return length_; }
  T* data() const { return data_; }
  bool is_empty() const { return length_ == 0; }

  void TruncateTo(intptr_t length) {
    ASSERT(length_ >= length);
    length_ = length;
  }

  void Add(const T& value) {
    Resize(length() + 1);
    Last() = value;
  }

  T& RemoveLast() {
    ASSERT(length_ > 0);
    T& result = operator[](length_ - 1);
    length_--;
    return result;
  }

  T& operator[](intptr_t index) const {
    ASSERT(0 <= index);
    ASSERT(index < length_);
    ASSERT(length_ <= capacity_);
    return data_[index];
  }

  const T& At(intptr_t index) const { return operator[](index); }

  T& Last() const {
    ASSERT(length_ > 0);
    return operator[](length_ - 1);
  }

  void AddArray(const BaseGrowableArray<T, B>& src) {
    for (intptr_t i = 0; i < src.length(); i++) {
      Add(src[i]);
    }
  }

  void Clear() { length_ = 0; }

  void InsertAt(intptr_t idx, const T& value) {
    Resize(length() + 1);
    for (intptr_t i = length_ - 2; i >= idx; i--) {
      data_[i + 1] = data_[i];
    }
    data_[idx] = value;
  }

  void Reverse() {
    for (intptr_t i = 0; i < length_ / 2; i++) {
      const intptr_t j = length_ - 1 - i;
      T temp = data_[i];
      data_[i] = data_[j];
      data_[j] = temp;
    }
  }

  // Swap entries |i| and |j|.
  void Swap(intptr_t i, intptr_t j) {
    ASSERT(i >= 0);
    ASSERT(j >= 0);
    ASSERT(i < length_);
    ASSERT(j < length_);
    T temp = data_[i];
    data_[i] = data_[j];
    data_[j] = temp;
  }

  // NOTE: Does not preserve array order.
  void RemoveAt(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < length_);
    intptr_t last = length_ - 1;
    if (i < last) {
      Swap(i, last);
    }
    RemoveLast();
  }

  // The content is uninitialized after calling it.
  void SetLength(intptr_t new_length);

  // Sort the array in place.
  inline void Sort(int compare(const T*, const T*));

 private:
  intptr_t length_;
  intptr_t capacity_;
  T* data_;
  Allocator* allocator_;  // Used to (re)allocate the array.

  // Used for growing the array.
  void Resize(intptr_t new_length);

  DISALLOW_COPY_AND_ASSIGN(BaseGrowableArray);
};


template <typename T, typename B, typename Allocator>
inline void BaseGrowableArray<T, B, Allocator>::Sort(int compare(const T*,
                                                                 const T*)) {
  typedef int (*CompareFunction)(const void*, const void*);
  qsort(data_, length_, sizeof(T), reinterpret_cast<CompareFunction>(compare));
}


template <typename T, typename B, typename Allocator>
void BaseGrowableArray<T, B, Allocator>::Resize(intptr_t new_length) {
  if (new_length > capacity_) {
    intptr_t new_capacity = Utils::RoundUpToPowerOfTwo(new_length);
    T* new_data =
        allocator_->template Realloc<T>(data_, capacity_, new_capacity);
    ASSERT(new_data != NULL);
    data_ = new_data;
    capacity_ = new_capacity;
  }
  length_ = new_length;
}


template <typename T, typename B, typename Allocator>
void BaseGrowableArray<T, B, Allocator>::SetLength(intptr_t new_length) {
  if (new_length > capacity_) {
    T* new_data = allocator_->template Alloc<T>(new_length);
    ASSERT(new_data != NULL);
    data_ = new_data;
    capacity_ = new_length;
  }
  length_ = new_length;
}


template <typename T>
class GrowableArray : public BaseGrowableArray<T, ValueObject> {
 public:
  GrowableArray(Zone* zone, intptr_t initial_capacity)
      : BaseGrowableArray<T, ValueObject>(initial_capacity,
                                          ASSERT_NOTNULL(zone)) {}
  explicit GrowableArray(intptr_t initial_capacity)
      : BaseGrowableArray<T, ValueObject>(
            initial_capacity,
            ASSERT_NOTNULL(Thread::Current()->zone())) {}
  GrowableArray()
      : BaseGrowableArray<T, ValueObject>(
            ASSERT_NOTNULL(Thread::Current()->zone())) {}
};


template <typename T>
class ZoneGrowableArray : public BaseGrowableArray<T, ZoneAllocated> {
 public:
  ZoneGrowableArray(Zone* zone, intptr_t initial_capacity)
      : BaseGrowableArray<T, ZoneAllocated>(initial_capacity,
                                            ASSERT_NOTNULL(zone)) {}
  explicit ZoneGrowableArray(intptr_t initial_capacity)
      : BaseGrowableArray<T, ZoneAllocated>(
            initial_capacity,
            ASSERT_NOTNULL(Thread::Current()->zone())) {}
  ZoneGrowableArray()
      : BaseGrowableArray<T, ZoneAllocated>(
            ASSERT_NOTNULL(Thread::Current()->zone())) {}
};


// T must be a Handle type.
template <typename T, typename B>
class BaseGrowableHandlePtrArray : public B {
 public:
  BaseGrowableHandlePtrArray(Zone* zone, intptr_t initial_capacity)
      : zone_(zone), array_(zone, initial_capacity) {}

  // Use unique zone handles to store objects.
  void Add(const T& t) { array_.Add(&T::ZoneHandle(zone_, t.raw())); }

  T& operator[](intptr_t index) const { return *array_[index]; }

  const T& At(intptr_t index) const { return operator[](index); }

  void SetAt(intptr_t index, const T& t) {
    array_[index] = &T::ZoneHandle(zone_, t.raw());
  }

  intptr_t length() const { return array_.length(); }

  const GrowableArray<T*>& growable_array() const { return array_; }

 private:
  Zone* zone_;
  GrowableArray<T*> array_;

  DISALLOW_COPY_AND_ASSIGN(BaseGrowableHandlePtrArray);
};


template <typename T>
class GrowableHandlePtrArray
    : public BaseGrowableHandlePtrArray<T, ValueObject> {
 public:
  GrowableHandlePtrArray(Zone* zone, intptr_t initial_capacity)
      : BaseGrowableHandlePtrArray<T, ValueObject>(zone, initial_capacity) {}
};


template <typename T>
class ZoneGrowableHandlePtrArray
    : public BaseGrowableHandlePtrArray<T, ZoneAllocated> {
 public:
  ZoneGrowableHandlePtrArray(Zone* zone, intptr_t initial_capacity)
      : BaseGrowableHandlePtrArray<T, ZoneAllocated>(zone, initial_capacity) {}
};


class Malloc : public AllStatic {
 public:
  template <class T>
  static inline T* Alloc(intptr_t len) {
    return reinterpret_cast<T*>(malloc(len * sizeof(T)));
  }

  template <class T>
  static inline T* Realloc(T* old_array, intptr_t old_len, intptr_t new_len) {
    return reinterpret_cast<T*>(realloc(old_array, new_len * sizeof(T)));
  }

  template <class T>
  static inline void Free(T* old_array, intptr_t old_len) {
    free(old_array);
  }
};


class EmptyBase {};


template <typename T>
class MallocGrowableArray : public BaseGrowableArray<T, EmptyBase, Malloc> {
 public:
  explicit MallocGrowableArray(intptr_t initial_capacity)
      : BaseGrowableArray<T, EmptyBase, Malloc>(initial_capacity, NULL) {}
  MallocGrowableArray() : BaseGrowableArray<T, EmptyBase, Malloc>(NULL) {}
};

}  // namespace dart

#endif  // RUNTIME_VM_GROWABLE_ARRAY_H_
