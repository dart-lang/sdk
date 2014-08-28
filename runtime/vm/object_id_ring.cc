// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/dart_api_state.h"
#include "vm/object_id_ring.h"

namespace dart {

void ObjectIdRing::Init(Isolate* isolate, int32_t capacity) {
  ObjectIdRing* ring = new ObjectIdRing(isolate, capacity);
  isolate->set_object_id_ring(ring);
}


ObjectIdRing::~ObjectIdRing() {
  ASSERT(table_ != NULL);
  free(table_);
  table_ = NULL;
  if (isolate_ != NULL) {
    isolate_->set_object_id_ring(NULL);
    isolate_ = NULL;
  }
}


int32_t ObjectIdRing::GetIdForObject(RawObject* object) {
  // We do not allow inserting null because null is how we detect as entry was
  // reclaimed by the GC.
  ASSERT(object != Object::null());
  return AllocateNewId(object);
}


RawObject* ObjectIdRing::GetObjectForId(int32_t id, LookupResult* kind) {
  int32_t index = IndexOfId(id);
  if (index == kInvalidId) {
    *kind = kExpired;
    return Object::null();
  }
  ASSERT(index >= 0);
  ASSERT(index < capacity_);
  if (table_[index] == Object::null()) {
    *kind = kCollected;
    return Object::null();
  }
  *kind = kValid;
  return table_[index];
}


void ObjectIdRing::VisitPointers(ObjectPointerVisitor* visitor) {
  ASSERT(table_ != NULL);
  visitor->VisitPointers(table_, capacity_);
}


ObjectIdRing::ObjectIdRing(Isolate* isolate, int32_t capacity) {
  ASSERT(capacity > 0);
  isolate_ = isolate;
  serial_num_ = 0;
  wrapped_ = false;
  table_ = NULL;
  SetCapacityAndMaxSerial(capacity, kMaxId);
}


void ObjectIdRing::SetCapacityAndMaxSerial(int32_t capacity,
                                           int32_t max_serial) {
  ASSERT(max_serial <= kMaxId);
  capacity_ = capacity;
  if (table_ != NULL) {
    free(table_);
  }
  table_ = reinterpret_cast<RawObject**>(calloc(capacity_, kWordSize));
  for (int i = 0; i < capacity_; i++) {
    table_[i] = Object::null();
  }
  // The maximum serial number is a multiple of the capacity, so that when
  // the serial number wraps, the index into table_ wraps with it.
  max_serial_ = max_serial - (max_serial % capacity_);
}


int32_t ObjectIdRing::NextSerial() {
  int32_t r = serial_num_;
  serial_num_++;
  if (serial_num_ >= max_serial_) {
    serial_num_ = 0;
    wrapped_ = true;
  }
  return r;
}


int32_t ObjectIdRing::AllocateNewId(RawObject* raw_obj) {
  ASSERT(raw_obj->IsHeapObject());
  int32_t id = NextSerial();
  ASSERT(id != kInvalidId);
  int32_t cursor = IndexOfId(id);
  ASSERT(cursor != kInvalidId);
  if (table_[cursor] != Object::null()) {
    // Free old handle.
    table_[cursor] = Object::null();
  }
  ASSERT(table_[cursor] == Object::null());
  table_[cursor] = raw_obj;
  return id;
}


int32_t ObjectIdRing::IndexOfId(int32_t id) {
  if (!IsValidId(id)) {
    return kInvalidId;
  }
  ASSERT((id >= 0) && (id < max_serial_));
  return id % capacity_;
}


bool ObjectIdRing::IsValidContiguous(int32_t id) {
  ASSERT(id != kInvalidId);
  ASSERT((id >= 0) && (id < max_serial_));
  if (id >= serial_num_) {
    // Too large.
    return false;
  }
  int32_t bottom = 0;
  if (serial_num_ >= capacity_) {
    bottom = serial_num_ - capacity_;
  }
  return id >= bottom;
}


bool ObjectIdRing::IsValidId(int32_t id) {
  if (id == kInvalidId) {
    return false;
  }
  if (id < 0) {
    return false;
  }
  if (id >= max_serial_) {
    return false;
  }
  ASSERT((id >= 0) && (id < max_serial_));
  if (wrapped_) {
    // Serial number has wrapped around to 0.
    if (serial_num_ >= capacity_) {
      // Serial number is larger than capacity, the serial
      // numbers are contiguous again.
      wrapped_ = false;
      return IsValidContiguous(id);
    } else {
      // When the serial number first wraps, the valid serial number range
      // spans two intervals:
      // #1 [0, serial_num_)
      // #2 [max_serial_ - (capacity_ - serial_num), max_serial_)
      //
      // Check for both.
      if (id < serial_num_) {
        // Interval #1
        return true;
      }
      // Interval #2
      const int32_t max_serial_num = max_serial_;
      const int32_t bottom = max_serial_num - (capacity_ - serial_num_);
      return id >= bottom && bottom < max_serial_num;
    }
  }
  ASSERT(wrapped_ == false);
  return IsValidContiguous(id);
}

}  // namespace dart
