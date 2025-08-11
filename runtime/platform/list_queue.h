// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_LIST_QUEUE_H_
#define RUNTIME_PLATFORM_LIST_QUEUE_H_

#include <functional>
#include <memory>
#include <utility>

#include "platform/assert.h"
#include "platform/globals.h"

// A queue backed by a circular buffer similar to dart:collection's ListQueue.
template <typename T>
class ListQueue {
 public:
  static constexpr intptr_t kInitialCapacity = 64;

  ListQueue()
      : buffer_(std::make_unique<T[]>(kInitialCapacity)),
        capacity_(kInitialCapacity) {}

  void PushBack(T&& element) {
    buffer_[tail_] = std::move(element);
    tail_ = (tail_ + 1) % capacity_;
    if (head_ == tail_) {
      Grow();
    }
    ++length_;
  }

  T&& PopFront() {
    ASSERT(head_ != tail_);
    T&& element = std::move(buffer_[head_]);
    head_ = (head_ + 1) % capacity_;
    --length_;
    return std::move(element);
  }

  // The number of elements currently in the queue.
  intptr_t Length() { return length_; }

  void ForEach(std::function<void(const T&)> callback) const {
    for (intptr_t i = head_; i != tail_; i = (i + 1) % capacity_) {
      callback(buffer_[i]);
    }
  }

 private:
  std::unique_ptr<T[]> buffer_;
  intptr_t capacity_;
  intptr_t length_ = 0;
  intptr_t head_ = 0;
  intptr_t tail_ = 0;

  void Grow() {
    intptr_t split = capacity_ - head_;

    intptr_t new_capacity = capacity_ << 1;
    std::unique_ptr<T[]> new_buffer = std::make_unique<T[]>(new_capacity);

    for (intptr_t i = 0; i < split; ++i) {
      new_buffer[i] = std::move(buffer_[head_ + i]);
    }
    for (intptr_t i = split; i < split + head_; ++i) {
      new_buffer[i] = std::move(buffer_[i - split]);
    }

    head_ = 0;
    tail_ = capacity_;
    buffer_.swap(new_buffer);
    capacity_ = new_capacity;
  }

  DISALLOW_COPY_AND_ASSIGN(ListQueue);
};

#endif  // RUNTIME_PLATFORM_LIST_QUEUE_H_
