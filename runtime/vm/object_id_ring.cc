// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_id_ring.h"

#include "platform/assert.h"
#include "vm/dart_api_state.h"
#include "vm/json_stream.h"

namespace dart {

#ifndef PRODUCT

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

int32_t ObjectIdRing::GetIdForObject(RawObject* object, IdPolicy policy) {
  // We do not allow inserting null because null is how we detect as entry was
  // reclaimed by the GC.
  ASSERT(object != Object::null());
  if (policy == kAllocateId) {
    return AllocateNewId(object);
  }
  ASSERT(policy == kReuseId);
  int32_t id = FindExistingIdForObject(object);
  if (id != kInvalidId) {
    // Return a previous id for |object|.
    return id;
  }
  return AllocateNewId(object);
}

int32_t ObjectIdRing::FindExistingIdForObject(RawObject* raw_obj) {
  for (int32_t i = 0; i < capacity_; i++) {
    if (table_[i] == raw_obj) {
      return IdOfIndex(i);
    }
  }
  return kInvalidId;
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
  ASSERT(IdOfIndex(index) == id);
  return table_[index];
}

void ObjectIdRing::VisitPointers(ObjectPointerVisitor* visitor) {
  ASSERT(table_ != NULL);
  visitor->VisitPointers(table_, capacity_);
}

void ObjectIdRing::PrintJSON(JSONStream* js) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(zone != NULL);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "_IdZone");
  jsobj.AddProperty("name", "default");
  {
    JSONArray objects(&jsobj, "objects");
    Object& obj = Object::Handle();
    for (int32_t i = 0; i < capacity_; i++) {
      obj = table_[i];
      if (obj.IsNull()) {
        // Collected object.
        continue;
      }
      objects.AddValue(obj, false);
    }
  }
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
  for (int32_t i = 0; i < capacity_; i++) {
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
  int32_t index = IndexOfId(id);
  ASSERT(index != kInvalidId);
  table_[index] = raw_obj;
  return id;
}

int32_t ObjectIdRing::IndexOfId(int32_t id) {
  if (!IsValidId(id)) {
    return kInvalidId;
  }
  ASSERT((id >= 0) && (id < max_serial_));
  return id % capacity_;
}

int32_t ObjectIdRing::IdOfIndex(int32_t index) {
  if (index < 0) {
    return kInvalidId;
  }
  if (index >= capacity_) {
    return kInvalidId;
  }
  int32_t id = kInvalidId;
  if (wrapped_) {
    // Serial numbers have wrapped around 0.
    ASSERT(serial_num_ < capacity_);
    if (index < serial_num_) {
      // index < serial_num_ have been handed out and are sequential starting
      // at 0.
      id = index;
    } else {
      // the other end of the array has the high ids.
      const int32_t bottom = max_serial_ - capacity_;
      id = bottom + index;
    }
  } else if (index < serial_num_) {
    // Index into the array where id range splits.
    int32_t split_point = serial_num_ % capacity_;
    if (index < split_point) {
      // index < split_point has serial_numbers starting at
      // serial_num_ - split_point.
      int bottom = serial_num_ - split_point;
      ASSERT(bottom >= 0);
      id = bottom + index;
    } else {
      // index >= split_point has serial_numbers starting at
      // serial_num_ - split_point - capacity_.
      int bottom = serial_num_ - capacity_ - split_point;
      ASSERT(bottom >= 0);
      id = bottom + index;
    }
  }
  ASSERT(!IsValidId(id) || (IndexOfId(id) == index));
  return id;
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

#endif  // !PRODUCT

}  // namespace dart
