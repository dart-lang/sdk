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
  Dart_WeakPersistentHandleFinalizer callback;
  Dart_WeakPersistentHandleFinalizer successful_write_callback;
};

class MessageFinalizableData {
 public:
  MessageFinalizableData() : records_(0), position_(0), external_size_(0) {}

  ~MessageFinalizableData() {
    for (intptr_t i = position_; i < records_.length(); i++) {
      records_[i].callback(nullptr, nullptr, records_[i].peer);
    }
  }

  /// If [successful_write_callback] is provided, it's invoked when message
  /// was serialized successfully.
  /// [callback] is invoked when serialization failed.
  void Put(
      intptr_t external_size,
      void* data,
      void* peer,
      Dart_WeakPersistentHandleFinalizer callback,
      Dart_WeakPersistentHandleFinalizer successful_write_callback = nullptr) {
    FinalizableData finalizable_data;
    finalizable_data.data = data;
    finalizable_data.peer = peer;
    finalizable_data.callback = callback;
    finalizable_data.successful_write_callback = successful_write_callback;
    records_.Add(finalizable_data);
    external_size_ += external_size;
  }

  FinalizableData Take() {
    ASSERT(position_ < records_.length());
    return records_[position_++];
  }

  void SerializationSucceeded() {
    for (intptr_t i = position_; i < records_.length(); i++) {
      if (records_[i].successful_write_callback != nullptr) {
        records_[i].successful_write_callback(nullptr, nullptr,
                                              records_[i].peer);
      }
    }
  }

  intptr_t external_size() const { return external_size_; }

 private:
  MallocGrowableArray<FinalizableData> records_;
  intptr_t position_;
  intptr_t external_size_;

  DISALLOW_COPY_AND_ASSIGN(MessageFinalizableData);
};

}  // namespace dart

#endif  // RUNTIME_VM_FINALIZABLE_DATA_H_
