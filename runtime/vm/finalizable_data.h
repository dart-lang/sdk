// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FINALIZABLE_DATA_H_
#define RUNTIME_VM_FINALIZABLE_DATA_H_

#include "include/dart_api.h"
#include "platform/growable_array.h"
#include "vm/globals.h"

namespace dart {

struct FinalizableData {
  void* data;
  void* peer;
  Dart_HandleFinalizer callback;
  Dart_HandleFinalizer successful_write_callback;
};

class MessageFinalizableData {
 public:
  MessageFinalizableData()
      : records_(0), get_position_(0), take_position_(0), external_size_(0) {}

  ~MessageFinalizableData() {
    for (intptr_t i = take_position_; i < records_.length(); i++) {
      records_[i].callback(nullptr, records_[i].peer);
    }
  }

  /// If [successful_write_callback] is provided, it's invoked when message
  /// was serialized successfully.
  /// [callback] is invoked when serialization failed.
  void Put(intptr_t external_size,
           void* data,
           void* peer,
           Dart_HandleFinalizer callback,
           Dart_HandleFinalizer successful_write_callback = nullptr) {
    FinalizableData finalizable_data;
    finalizable_data.data = data;
    finalizable_data.peer = peer;
    finalizable_data.callback = callback;
    finalizable_data.successful_write_callback = successful_write_callback;
    records_.Add(finalizable_data);
    external_size_ += external_size;
  }

  // Retrieve the next FinalizableData, but still run its finalizer when |this|
  // is destroyed.
  FinalizableData Get() {
    ASSERT(get_position_ < records_.length());
    return records_[get_position_++];
  }

  // Retrieve the next FinalizableData, and skip its finalizer when |this| is
  // destroyed.
  FinalizableData Take() {
    ASSERT(take_position_ < records_.length());
    return records_[take_position_++];
  }

  void SerializationSucceeded() {
    for (intptr_t i = 0; i < records_.length(); i++) {
      if (records_[i].successful_write_callback != nullptr) {
        records_[i].successful_write_callback(nullptr, records_[i].peer);
      }
    }
  }

  void DropFinalizers() {
    records_.Clear();
    get_position_ = 0;
    take_position_ = 0;
    external_size_ = 0;
  }

  intptr_t external_size() const { return external_size_; }

 private:
  MallocGrowableArray<FinalizableData> records_;
  intptr_t get_position_;
  intptr_t take_position_;
  intptr_t external_size_;

  DISALLOW_COPY_AND_ASSIGN(MessageFinalizableData);
};

}  // namespace dart

#endif  // RUNTIME_VM_FINALIZABLE_DATA_H_
