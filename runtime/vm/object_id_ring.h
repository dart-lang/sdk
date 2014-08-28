// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_ID_RING_H_
#define VM_OBJECT_ID_RING_H_

namespace dart {

// Forward declarations.
class RawObject;
class Isolate;
class ObjectPointerVisitor;

// A ring buffer of object pointers that have been given an id. An object
// may be pointed to by multiple ids. Objects contained in the ring will
// be preserved across scavenges but not old space collections.
// When the ring buffer wraps around older objects will be replaced and their
// ids will be invalidated.
class ObjectIdRing {
 public:
  enum LookupResult {
    kValid = 0,
    kInvalid,    // Malformed ring id (used in service.cc).
    kCollected,  // Entry was reclaimed due to a full GC (entries are weak).
    kExpired,    // Entry was evicted during an insertion into a full ring.
  };

  static const int32_t kMaxId = 0x3FFFFFFF;
  static const int32_t kInvalidId = -1;
  static const int32_t kDefaultCapacity = 1024;

  static void Init(Isolate* isolate, int32_t capacity = kDefaultCapacity);

  ~ObjectIdRing();

  // Adds the argument to the ring and returns its id. Note we do not allow
  // adding Object::null().
  int32_t GetIdForObject(RawObject* raw_obj);

  // Returns Object::null() when the result is not kValid.
  RawObject* GetObjectForId(int32_t id, LookupResult* kind);

  void VisitPointers(ObjectPointerVisitor* visitor);

 private:
  friend class ObjectIdRingTestHelper;

  void SetCapacityAndMaxSerial(int32_t capacity, int32_t max_serial);

  ObjectIdRing(Isolate* isolate, int32_t capacity);
  Isolate* isolate_;
  RawObject** table_;
  int32_t max_serial_;
  int32_t capacity_;
  int32_t serial_num_;
  bool wrapped_;

  RawObject** table() {
    return table_;
  }
  int32_t table_size() {
    return capacity_;
  }

  int32_t NextSerial();
  int32_t AllocateNewId(RawObject* object);
  int32_t IndexOfId(int32_t id);
  bool IsValidContiguous(int32_t id);
  bool IsValidId(int32_t id);

  DISALLOW_COPY_AND_ASSIGN(ObjectIdRing);
};

}  // namespace dart

#endif  // VM_OBJECT_ID_RING_H_
