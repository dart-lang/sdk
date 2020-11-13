// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Defines growable array classes, that differ where they are allocated:
// - GrowableArray: allocated on stack.
// - ZoneGrowableArray: allocated in the zone.
// - MallocGrowableArray: allocates using malloc/realloc; free is only called
//   at destruction.

#ifndef RUNTIME_PLATFORM_GROWABLE_ARRAY_H_
#define RUNTIME_PLATFORM_GROWABLE_ARRAY_H_

#include "platform/allocation.h"
#include "platform/utils.h"

namespace dart {

template <typename T, typename B, typename Allocator>
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

  BaseGrowableArray(BaseGrowableArray&& other)
      : length_(other.length_),
        capacity_(other.capacity_),
        data_(other.data_),
        allocator_(other.allocator_) {
    other.length_ = 0;
    other.capacity_ = 0;
    other.data_ = NULL;
  }

  ~BaseGrowableArray() { allocator_->template Free<T>(data_, capacity_); }

  BaseGrowableArray& operator=(BaseGrowableArray&& other) {
    intptr_t temp = other.length_;
    other.length_ = length_;
    length_ = temp;
    temp = other.capacity_;
    other.capacity_ = capacity_;
    capacity_ = temp;
    T* temp_data = other.data_;
    other.data_ = data_;
    data_ = temp_data;
    Allocator* temp_allocator = other.allocator_;
    other.allocator_ = allocator_;
    allocator_ = temp_allocator;
    return *this;
  }

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

  void FillWith(const T& value, intptr_t start, intptr_t length) {
    ASSERT(start >= 0);
    ASSERT(length >= 0);
    ASSERT(start <= length_);

    Resize(start + length);
    for (intptr_t i = 0; i < length; ++i) {
      data_[start + i] = value;
    }
  }

  void EnsureLength(intptr_t new_length, const T& default_value) {
    const intptr_t old_length = length_;
    if (old_length < new_length) {
      Resize(new_length);
      for (intptr_t i = old_length; i < new_length; ++i) {
        (*this)[i] = default_value;
      }
    }
  }

  const T& At(intptr_t index) const { return operator[](index); }

  T& Last() const {
    ASSERT(length_ > 0);
    return operator[](length_ - 1);
  }

  void AddArray(const BaseGrowableArray<T, B, Allocator>& src) {
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

  // Preserves array order.
  void EraseAt(intptr_t idx) {
    ASSERT(idx >= 0);
    ASSERT(idx < length_);
    for (intptr_t i = idx; i < length_ - 1; i++) {
      data_[i] = data_[i + 1];
    }
    RemoveLast();
  }

  // The content is uninitialized after calling it.
  void SetLength(intptr_t new_length);

  // Sort the array in place.
  inline void Sort(int compare(const T*, const T*));

  void StealBuffer(T** buffer, intptr_t* length) {
    *buffer = data_;
    *length = length_;
    data_ = NULL;
    length_ = 0;
    capacity_ = 0;
  }

  T* begin() { return &data_[0]; }
  const T* begin() const { return &data_[0]; }

  T* end() { return &data_[length_]; }
  const T* end() const { return &data_[length_]; }

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
  // Avoid calling qsort with a null array.
  if (length_ == 0) return;

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

class Malloc : public AllStatic {
 public:
  template <class T>
  static inline T* Alloc(intptr_t len) {
    return reinterpret_cast<T*>(dart::malloc(len * sizeof(T)));
  }

  template <class T>
  static inline T* Realloc(T* old_array, intptr_t old_len, intptr_t new_len) {
    return reinterpret_cast<T*>(dart::realloc(old_array, new_len * sizeof(T)));
  }

  template <class T>
  static inline void Free(T* old_array, intptr_t old_len) {
    free(old_array);
  }
};

template <typename T>
class MallocGrowableArray
    : public BaseGrowableArray<T, MallocAllocated, Malloc> {
 public:
  explicit MallocGrowableArray(intptr_t initial_capacity)
      : BaseGrowableArray<T, MallocAllocated, Malloc>(initial_capacity, NULL) {}
  MallocGrowableArray() : BaseGrowableArray<T, MallocAllocated, Malloc>(NULL) {}
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_GROWABLE_ARRAY_H_
