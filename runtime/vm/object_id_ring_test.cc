// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_id_ring.h"
#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/service.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

class ObjectIdRingTestHelper {
 public:
  static void SetMaxSerial(ObjectIdRing& ring, int32_t max_serial) {
    ring.max_serial_ = max_serial;
  }

  static void ExpectIdIsValid(ObjectIdRing& ring, intptr_t id) {
    EXPECT(ring.IsValidId(id));
  }

  static void ExpectIdIsInvalid(ObjectIdRing& ring, intptr_t id) {
    EXPECT(!ring.IsValidId(id));
  }

  static void ExpectIndexId(ObjectIdRing& ring, intptr_t index, intptr_t id) {
    EXPECT_EQ(id, ring.IdOfIndex(index));
  }

  static void ExpectInvalidIndex(ObjectIdRing& ring, intptr_t index) {
    EXPECT_EQ(-1, ring.IdOfIndex(index));
  }

  static ObjectPtr MakeString(const char* s) {
    return Symbols::New(Thread::Current(), s);
  }

  static void ExpectString(ObjectPtr obj, const char* s) {
    String& str = String::Handle();
    str ^= obj;
    EXPECT(str.Equals(s));
  }
};

// Test that serial number wrapping works.
ISOLATE_UNIT_TEST_CASE(ObjectIdRingSerialWrapTest) {
  ObjectIdRing ring(/*capacity=*/2);
  ObjectIdRingTestHelper::SetMaxSerial(ring, 4);
  intptr_t id;
  ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("0"));
  EXPECT_EQ(0, id);
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 0);
  ObjectIdRingTestHelper::ExpectInvalidIndex(ring, 1);
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("1"));
  EXPECT_EQ(1, id);
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 0);
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 1);
  // Test that id 1 gives us the "1" string.
  ObjectIdRingTestHelper::ExpectString(ring.GetObjectForId(id, &kind), "1");
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 0);
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 0);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 1);
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 1);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 2);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 3);
  // We have wrapped, index 0 is being reused.
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("2"));
  EXPECT_EQ(2, id);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 0);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 1);
  // Index 0 has id 2.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 2);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 2);
  // Index 1 has id 1.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 1);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 3);
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("3"));
  EXPECT_EQ(3, id);
  // Index 0 has id 2.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 2);
  // Index 1 has id 3.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 3);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 0);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 1);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 2);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 3);
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("4"));
  EXPECT_EQ(0, id);
  // Index 0 has id 0.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 0);
  // Index 1 has id 3.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 3);
  ObjectIdRingTestHelper::ExpectString(ring.GetObjectForId(id, &kind), "4");
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 0);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 1);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 2);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 3);
  id = ring.GetIdForObject(ObjectIdRingTestHelper::MakeString("5"));
  EXPECT_EQ(1, id);
  // Index 0 has id 0.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 0, 0);
  // Index 1 has id 1.
  ObjectIdRingTestHelper::ExpectIndexId(ring, 1, 1);
  ObjectIdRingTestHelper::ExpectString(ring.GetObjectForId(id, &kind), "5");
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 0);
  ObjectIdRingTestHelper::ExpectIdIsValid(ring, 1);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 2);
  ObjectIdRingTestHelper::ExpectIdIsInvalid(ring, 3);
}

class ServiceIdZonePolicyOverrideScope : public ValueObject {
 public:
  explicit ServiceIdZonePolicyOverrideScope(ServiceIdZone& id_zone,
                                            ObjectIdRing::IdPolicy new_policy)
      : id_zone_(id_zone), original_policy_(id_zone.policy()) {
    id_zone_.policy_ = new_policy;
  }

  ~ServiceIdZonePolicyOverrideScope() { id_zone_.policy_ = original_policy_; }

 private:
  ServiceIdZone& id_zone_;
  ObjectIdRing::IdPolicy original_policy_;
};

// Test that the ring table is updated when the scavenger moves an object.
TEST_CASE(ObjectIdRingScavengeMoveTest) {
  const char* kScriptChars =
      "main() {\n"
      "  return [1, 2, 3];\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  Dart_Handle moved_handle;
  intptr_t list_length = 0;
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  EXPECT_VALID(Dart_ListLength(result, &list_length));
  EXPECT_EQ(3, list_length);

  ServiceIdZone& default_id_zone =
      thread->isolate()->EnsureDefaultServiceIdZone();
  ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;

  {
    TransitionNativeToVM to_vm(thread);
    const ObjectPtr raw_obj = Api::UnwrapHandle(result);
    // Located in new heap.
    EXPECT(raw_obj->IsNewObject());
    EXPECT_NE(Object::null(), raw_obj);

    intptr_t raw_obj_id1 = default_id_zone.GetIdForObject(raw_obj);
    EXPECT_EQ(0, raw_obj_id1);
    {
      ServiceIdZonePolicyOverrideScope override(
          default_id_zone, ObjectIdRing::IdPolicy::kReuseId);
      // Get id 0 again.
      EXPECT_EQ(raw_obj_id1, default_id_zone.GetIdForObject(raw_obj));
    }

    // Add to ring a second time.
    intptr_t raw_obj_id2 = default_id_zone.GetIdForObject(raw_obj);
    EXPECT_EQ(1, raw_obj_id2);
    {
      ServiceIdZonePolicyOverrideScope override(
          default_id_zone, ObjectIdRing::IdPolicy::kReuseId);
      // Get id 0 again.
      EXPECT_EQ(raw_obj_id1, default_id_zone.GetIdForObject(raw_obj));
    }

    const ObjectPtr raw_obj1 =
        default_id_zone.GetObjectForId(raw_obj_id1, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    const ObjectPtr raw_obj2 =
        default_id_zone.GetObjectForId(raw_obj_id2, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    EXPECT_NE(Object::null(), raw_obj1);
    EXPECT_NE(Object::null(), raw_obj2);
    EXPECT_EQ(UntaggedObject::ToAddr(raw_obj),
              UntaggedObject::ToAddr(raw_obj1));
    EXPECT_EQ(UntaggedObject::ToAddr(raw_obj),
              UntaggedObject::ToAddr(raw_obj2));

    // Force a scavenge.
    GCTestHelper::CollectNewSpace();
    const ObjectPtr raw_object_moved1 =
        default_id_zone.GetObjectForId(raw_obj_id1, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    const ObjectPtr raw_object_moved2 =
        default_id_zone.GetObjectForId(raw_obj_id2, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    EXPECT_NE(Object::null(), raw_object_moved1);
    EXPECT_NE(Object::null(), raw_object_moved2);
    EXPECT_EQ(UntaggedObject::ToAddr(raw_object_moved1),
              UntaggedObject::ToAddr(raw_object_moved2));
    // Test that objects have moved.
    EXPECT_NE(UntaggedObject::ToAddr(raw_obj1),
              UntaggedObject::ToAddr(raw_object_moved1));
    EXPECT_NE(UntaggedObject::ToAddr(raw_obj2),
              UntaggedObject::ToAddr(raw_object_moved2));
    // Test that we still point at the same list.
    moved_handle = Api::NewHandle(thread, raw_object_moved1);
    // Test id reuse.

    {
      ServiceIdZonePolicyOverrideScope override(
          default_id_zone, ObjectIdRing::IdPolicy::kReuseId);
      EXPECT_EQ(raw_obj_id1, default_id_zone.GetIdForObject(raw_object_moved1));
    }
  }
  EXPECT_VALID(moved_handle);
  EXPECT(!Dart_IsNull(moved_handle));
  EXPECT(Dart_IsList(moved_handle));
  EXPECT_VALID(Dart_ListLength(moved_handle, &list_length));
  EXPECT_EQ(3, list_length);
}

// Test that the ring table is updated when major GC runs.
ISOLATE_UNIT_TEST_CASE(ObjectIdRingOldGCTest) {
  ServiceIdZone& default_id_zone =
      thread->isolate()->EnsureDefaultServiceIdZone();

  ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;
  intptr_t raw_obj_id1 = -1;
  intptr_t raw_obj_id2 = -1;
  {
    HandleScope handle_scope(thread);
    const String& str = String::Handle(String::New("old", Heap::kOld));
    EXPECT(!str.IsNull());
    EXPECT_EQ(3, str.Length());

    const ObjectPtr raw_obj = Object::RawCast(str.ptr());
    // Verify that it is located in old heap.
    EXPECT(raw_obj->IsOldObject());
    EXPECT_NE(Object::null(), raw_obj);

    raw_obj_id1 = default_id_zone.GetIdForObject(raw_obj);
    EXPECT_EQ(0, raw_obj_id1);
    raw_obj_id2 = default_id_zone.GetIdForObject(raw_obj);
    EXPECT_EQ(1, raw_obj_id2);

    const ObjectPtr raw_obj1 =
        default_id_zone.GetObjectForId(raw_obj_id1, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    const ObjectPtr raw_obj2 =
        default_id_zone.GetObjectForId(raw_obj_id2, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    EXPECT_NE(Object::null(), raw_obj1);
    EXPECT_NE(Object::null(), raw_obj2);
    EXPECT_EQ(UntaggedObject::ToAddr(raw_obj),
              UntaggedObject::ToAddr(raw_obj1));
    EXPECT_EQ(UntaggedObject::ToAddr(raw_obj),
              UntaggedObject::ToAddr(raw_obj2));
    // Exit scope. Freeing String handle.
  }
  // Force a GC. No other reference to the old string exists, but the service id
  // should keep it alive.
  GCTestHelper::CollectOldSpace();
  const ObjectPtr raw_object_moved1 =
      default_id_zone.GetObjectForId(raw_obj_id1, &kind);
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  EXPECT(raw_object_moved1->IsOneByteString());
  const ObjectPtr raw_object_moved2 =
      default_id_zone.GetObjectForId(raw_obj_id2, &kind);
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  EXPECT(raw_object_moved2->IsOneByteString());
  EXPECT_EQ(raw_object_moved1, raw_object_moved2);
}

// Test that the ring table correctly reports an entry as expired when it is
// overridden by new entries.
ISOLATE_UNIT_TEST_CASE(ObjectIdRingExpiredEntryTest) {
  ObjectIdRing ring(RingServiceIdZone::kFallbackCapacityForCreateIdZone);

  // Insert an object and check we can look it up.
  String& obj = String::Handle(String::New("I will expire"));
  intptr_t obj_id = ring.GetIdForObject(obj.ptr());
  ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;
  ObjectPtr obj_lookup = ring.GetObjectForId(obj_id, &kind);
  EXPECT_EQ(ObjectIdRing::kValid, kind);
  EXPECT_EQ(obj.ptr(), obj_lookup);

  // Insert as many new objects as the ring size to bump out our first entry.
  Object& new_obj = Object::Handle();
  for (intptr_t i = 0; i < RingServiceIdZone::kFallbackCapacityForCreateIdZone;
       i++) {
    new_obj = String::New("Bump");
    intptr_t new_obj_id = ring.GetIdForObject(new_obj.ptr());
    ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;
    ObjectPtr new_obj_lookup = ring.GetObjectForId(new_obj_id, &kind);
    EXPECT_EQ(ObjectIdRing::kValid, kind);
    EXPECT_EQ(new_obj.ptr(), new_obj_lookup);
  }

  // Check our first entry reports it has expired.
  obj_lookup = ring.GetObjectForId(obj_id, &kind);
  EXPECT_EQ(ObjectIdRing::kExpired, kind);
  EXPECT_NE(obj.ptr(), obj_lookup);
  EXPECT_EQ(Object::null(), obj_lookup);
}

#endif  // !PRODUCT

}  // namespace dart
