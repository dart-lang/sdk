// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_ID_RING_H_
#define RUNTIME_VM_OBJECT_ID_RING_H_

#include "platform/globals.h"
#include "vm/tagged_pointer.h"

namespace dart {

// Forward declarations.
class ObjectPointerVisitor;
class JSONStream;

// A ring buffer of object pointers that have been given temporary Service IDs.
// An object may be pointed to by multiple IDs. The objects associated with the
// pointers in the ring will be preserved across garbage collections. When the
// ring buffer wraps around, older objects will be replaced and their IDs will
// become expired.
class ObjectIdRing {
 public:
  enum LookupResult {
    kValid = 0,
    kInvalid,    // Malformed ring id (used in service.cc).
    kCollected,  // Entry was reclaimed due to a full GC (entries are weak).
    kExpired,    // Entry was evicted during an insertion into a full ring.
  };

  enum BackingBufferKind {
    kRing,
  };

  enum IdPolicy {
    kAllocateId,  // Always allocate a new object id.
    kReuseId,     // If the object is already in the ring, reuse id.
                  // Otherwise allocate a new object id.
  };

  static constexpr int32_t kMaxId = 0x3FFFFFFF;
  static constexpr int32_t kInvalidId = -1;

  explicit ObjectIdRing(int32_t capacity);
  ~ObjectIdRing();

  // Invalidate all the Service IDs currently living in this ring.
  void Invalidate();

  // Adds the argument to the ring and returns its id. Note we do not allow
  // adding Object::null().
  int32_t GetIdForObject(ObjectPtr raw_obj, IdPolicy policy = kAllocateId);

  // Returns Object::null() when the result is not kValid.
  ObjectPtr GetObjectForId(int32_t id, LookupResult* kind);

  void VisitPointers(ObjectPointerVisitor* visitor) const;

  void PrintJSON(JSONStream* js);

 private:
  friend class ObjectIdRingTestHelper;

  void SetCapacityAndMaxSerial(int32_t capacity, int32_t max_serial);
  int32_t FindExistingIdForObject(ObjectPtr raw_obj);

  ObjectPtr* table_;
  int32_t max_serial_;
  int32_t capacity_;
  int32_t serial_num_;
  bool wrapped_;

  ObjectPtr* table() { return table_; }
  int32_t table_size() { return capacity_; }

  int32_t NextSerial();
  int32_t AllocateNewId(ObjectPtr object);
  int32_t IndexOfId(int32_t id);
  int32_t IdOfIndex(int32_t index);
  bool IsValidContiguous(int32_t id) const;
  bool IsValidId(int32_t id);

  DISALLOW_COPY_AND_ASSIGN(ObjectIdRing);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_ID_RING_H_
