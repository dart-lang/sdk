// Copyright 2014 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_BASE_VECTOR_H_
#define V8_BASE_VECTOR_H_

#include <algorithm>
#include <iterator>
#include <limits>

#include "platform/allocation.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/regexp/base.h"

namespace base {

template <typename T>
class Vector {
 public:
  using value_type = T;
  using iterator = T*;
  using const_iterator = const T*;

  constexpr Vector() : start_(nullptr), length_(0) {}

  constexpr Vector(T* data, size_t length) : start_(data), length_(length) {
    ASSERT(length == 0 || data != nullptr);
  }

  static Vector<T> New(size_t length) {
    return Vector<T>(new T[length], length);
  }

  // Returns a vector using the same backing storage as this one,
  // spanning from and including 'from', to but not including 'to'.
  Vector<T> SubVector(size_t from, size_t to) const {
    DCHECK_LE(from, to);
    DCHECK_LE(to, length_);
    return Vector<T>(begin() + from, to - from);
  }
  Vector<T> SubVectorFrom(size_t from) const {
    return SubVector(from, length_);
  }

  template <class U>
  void OverwriteWith(Vector<U> other) {
    DCHECK_EQ(size(), other.size());
    std::copy(other.begin(), other.end(), begin());
  }

  template <class U, size_t n>
  void OverwriteWith(const std::array<U, n>& other) {
    DCHECK_EQ(size(), other.size());
    std::copy(other.begin(), other.end(), begin());
  }

  // Returns the length of the vector. Only use this if you really need an
  // integer return value. Use {size()} otherwise.
  int length() const {
    DCHECK_GE(std::numeric_limits<int>::max(), length_);
    return static_cast<int>(length_);
  }

  // Returns the length of the vector as a size_t.
  constexpr size_t size() const { return length_; }

  // Returns whether or not the vector is empty.
  constexpr bool empty() const { return length_ == 0; }

  // Access individual vector elements - checks bounds in debug mode.
  T& operator[](size_t index) const {
    DCHECK_LT(index, length_);
    return start_[index];
  }

  const T& at(size_t index) const { return operator[](index); }

  T& first() { return start_[0]; }
  const T& first() const { return start_[0]; }

  T& last() {
    DCHECK_LT(0, length_);
    return start_[length_ - 1];
  }
  const T& last() const {
    DCHECK_LT(0, length_);
    return start_[length_ - 1];
  }

  // Returns a pointer to the start of the data in the vector.
  constexpr T* begin() const { return start_; }
  constexpr const T* cbegin() const { return start_; }

  // For consistency with other containers, do also provide a {data} accessor.
  constexpr T* data() const { return start_; }

  // Returns a pointer past the end of the data in the vector.
  constexpr T* end() const { return start_ + length_; }
  constexpr const T* cend() const { return start_ + length_; }

  constexpr std::reverse_iterator<T*> rbegin() const {
    return std::make_reverse_iterator(end());
  }
  constexpr std::reverse_iterator<T*> rend() const {
    return std::make_reverse_iterator(begin());
  }

  // Returns a clone of this vector with a new backing store.
  Vector<T> Clone() const {
    T* result = new T[length_];
    for (size_t i = 0; i < length_; i++)
      result[i] = start_[i];
    return Vector<T>(result, length_);
  }

  void Truncate(size_t length) {
    ASSERT(length <= length_);
    length_ = length;
  }

  // Releases the array underlying this vector. Once disposed the
  // vector is empty.
  void Dispose() {
    delete[] start_;
    start_ = nullptr;
    length_ = 0;
  }

  const Vector<T> operator+(size_t offset) const {
    DCHECK_LE(offset, length_);
    return Vector<T>(start_ + offset, length_ - offset);
  }

  Vector<T> operator+=(size_t offset) {
    DCHECK_LE(offset, length_);
    start_ += offset;
    length_ -= offset;
    return *this;
  }

  // Implicit conversion from Vector<T> to Vector<const U> if
  // - T* is convertible to const U*, and
  // - U and T have the same size.
  // Note that this conversion is only safe for `*const* U`; writes would
  // violate covariance.
  template <typename U>
    requires std::is_convertible_v<T*, const U*> && (sizeof(U) == sizeof(T))
  operator Vector<const U>() const {
    return {start_, length_};
  }

  template <typename S>
  static Vector<T> cast(Vector<S> input) {
    // Casting is potentially dangerous, so be really restrictive here. This
    // might be lifted once we have use cases for that.
    static_assert(std::is_trivial_v<S> && std::is_standard_layout_v<S>);
    static_assert(std::is_trivial_v<T> && std::is_standard_layout_v<T>);
    DCHECK_EQ(0, (input.size() * sizeof(S)) % sizeof(T));
    DCHECK_EQ(0, reinterpret_cast<uintptr_t>(input.begin()) % alignof(T));
    return Vector<T>(reinterpret_cast<T*>(input.begin()),
                     input.size() * sizeof(S) / sizeof(T));
  }

  bool operator==(const Vector<T>& other) const {
    return std::equal(begin(), end(), other.begin(), other.end());
  }

  template <typename TT = T>
    requires(!std::is_const_v<TT>)
  bool operator==(const Vector<const T>& other) const {
    return std::equal(begin(), end(), other.begin(), other.end());
  }

 private:
  T* start_;
  size_t length_;
};

// For string literals, ArrayVector("foo") returns a vector ['f', 'o', 'o', \0]
// with length 4 and null-termination.
// If you want ['f', 'o', 'o'], use CStrVector("foo").
template <typename T, size_t N>
inline constexpr Vector<T> ArrayVector(T (&arr)[N]) {
  return {arr, N};
}

// Construct a Vector from a start pointer and a size.
template <typename T>
inline constexpr Vector<T> VectorOf(T* start, size_t size) {
  return {start, size};
}

}  // namespace base

#endif  // V8_BASE_VECTOR_H_
