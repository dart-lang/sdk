// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_API_MESSAGE_H_
#define RUNTIME_VM_DART_API_MESSAGE_H_

#include "include/dart_native_api.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/raw_object.h"
#include "vm/snapshot.h"

namespace dart {

// Use this C structure for reading internal objects in the serialized
// data. These are objects that we need to process in order to
// generate the Dart_CObject graph but that we don't want to expose in
// that graph.
struct Dart_CObject_Internal : public Dart_CObject {
  enum Type {
    kTypeArguments = Dart_CObject_kNumberOfTypes,
    kDynamicType,
    kClass,
    kView,
    kUninitialized,
  };
  struct Dart_CObject_Internal* cls;
  union {
    struct {
      struct _Dart_CObject* library_url;
      struct _Dart_CObject* class_name;
    } as_class;
    struct {
      struct _Dart_CObject* buffer;
      int offset_in_bytes;
      int length;
    } as_view;
  } internal;
};

// Reads a message snapshot into a C structure.
class ApiMessageReader : public BaseReader {
 public:
  // The ApiMessageReader object must be enclosed by an ApiNativeScope.
  // Allocation of all C Heap objects is done in the zone associated with
  // the enclosing ApiNativeScope.
  ApiMessageReader(const uint8_t* buffer, intptr_t length);
  explicit ApiMessageReader(Message* message);
  ~ApiMessageReader() {}

  Dart_CObject* ReadMessage();

 private:
  class BackRefNode {
   public:
    BackRefNode(Dart_CObject* reference, DeserializeState state)
        : reference_(reference), state_(state) {}
    Dart_CObject* reference() const { return reference_; }
    void set_reference(Dart_CObject* reference) { reference_ = reference; }
    bool is_deserialized() const { return state_ == kIsDeserialized; }
    void set_state(DeserializeState value) { state_ = value; }

   private:
    Dart_CObject* reference_;
    DeserializeState state_;

    DISALLOW_COPY_AND_ASSIGN(BackRefNode);
  };

  // Allocates a Dart_CObject object.
  Dart_CObject* AllocateDartCObject();
  // Allocates a Dart_CObject object with the specified type.
  Dart_CObject* AllocateDartCObject(Dart_CObject_Type type);
  // Allocates a Dart_CObject object representing an unsupported
  // object in the API message.
  Dart_CObject* AllocateDartCObjectUnsupported();
  // Allocates a Dart_CObject object for the null object.
  Dart_CObject* AllocateDartCObjectNull();
  // Allocates a Dart_CObject object for a boolean object.
  Dart_CObject* AllocateDartCObjectBool(bool value);
  // Allocates a Dart_CObject object for for a 32-bit integer.
  Dart_CObject* AllocateDartCObjectInt32(int32_t value);
  // Allocates a Dart_CObject object for for a 64-bit integer.
  Dart_CObject* AllocateDartCObjectInt64(int64_t value);
  // Allocates an empty Dart_CObject object for a bigint to be filled up later.
  Dart_CObject* AllocateDartCObjectBigint();
  // Allocates a Dart_CObject object for a double.
  Dart_CObject* AllocateDartCObjectDouble(double value);
  // Allocates a Dart_CObject object for string data.
  Dart_CObject* AllocateDartCObjectString(intptr_t length);
  // Allocates a C Dart_CObject object for a typed data.
  Dart_CObject* AllocateDartCObjectTypedData(Dart_TypedData_Type type,
                                             intptr_t length);
  // Allocates a C array of Dart_CObject objects.
  Dart_CObject* AllocateDartCObjectArray(intptr_t length);
  // Allocate a C Dart_CObject object for a VM isolate object.
  Dart_CObject* AllocateDartCObjectVmIsolateObj(intptr_t id);
  // Allocates a Dart_CObject_Internal object with the specified type.
  Dart_CObject_Internal* AllocateDartCObjectInternal(
      Dart_CObject_Internal::Type type);
  // Allocates a Dart_CObject_Internal object for a class object.
  Dart_CObject_Internal* AllocateDartCObjectClass();
  // Allocates a backwards reference node.
  BackRefNode* AllocateBackRefNode(Dart_CObject* ref, DeserializeState state);

  void Init();

  intptr_t LookupInternalClass(intptr_t class_header);
  Dart_CObject* ReadVMIsolateObject(intptr_t value);
  Dart_CObject* ReadInternalVMObject(intptr_t class_id, intptr_t object_id);
  Dart_CObject* ReadInlinedObject(intptr_t object_id);
  Dart_CObject* ReadObjectImpl();
  Dart_CObject* ReadIndexedObject(intptr_t object_id);
  Dart_CObject* ReadPredefinedSymbol(intptr_t object_id);
  Dart_CObject* ReadObjectRef();
  Dart_CObject* ReadObject();

  // Add object to backward references.
  void AddBackRef(intptr_t id, Dart_CObject* obj, DeserializeState state);

  // Get an object from the backward references list.
  Dart_CObject* GetBackRef(intptr_t id);

  intptr_t NextAvailableObjectId() const;

  Dart_CObject_Internal* AsInternal(Dart_CObject* object) {
    ASSERT(object->type >= Dart_CObject_kNumberOfTypes);
    return reinterpret_cast<Dart_CObject_Internal*>(object);
  }

  RawObject* VmIsolateSnapshotObject(intptr_t index) const {
    return Object::vm_isolate_snapshot_object_table().At(index);
  }

  Dart_CObject* CreateDartCObjectString(RawObject* raw);
  Dart_CObject* GetCanonicalMintObject(Dart_CObject_Type type, int64_t value64);

  uint8_t* allocator(intptr_t size) {
    return zone_->Realloc<uint8_t>(NULL, 0, size);
  }

  Zone* zone_;  // Zone in which C heap objects are allocated.
  ApiGrowableArray<BackRefNode*> backward_references_;
  ApiGrowableArray<Dart_CObject*> vm_isolate_references_;
  Dart_CObject** vm_symbol_references_;

  Dart_CObject type_arguments_marker;
  Dart_CObject dynamic_type_marker;
  static _Dart_CObject* singleton_uint32_typed_data_;
};

class ApiMessageWriter : public BaseWriter {
 public:
  static const intptr_t kInitialSize = 512;
  ApiMessageWriter(uint8_t** buffer, ReAlloc alloc)
      : BaseWriter(buffer, alloc, NULL, kInitialSize),
        object_id_(0),
        forward_list_(NULL),
        forward_list_length_(0),
        forward_id_(0) {
    ASSERT(kDartCObjectTypeMask >= Dart_CObject_kNumberOfTypes - 1);
  }
  ~ApiMessageWriter() { ::free(forward_list_); }

  // Writes a message of integers.
  void WriteMessage(intptr_t field_count, intptr_t* data);

  // Writes a message with a single object.
  bool WriteCMessage(Dart_CObject* object);

 private:
  static const intptr_t kDartCObjectTypeBits = 4;
  static const intptr_t kDartCObjectTypeMask = (1 << kDartCObjectTypeBits) - 1;
  static const intptr_t kDartCObjectMarkMask = ~kDartCObjectTypeMask;
  static const intptr_t kDartCObjectMarkOffset = 1;

  void MarkCObject(Dart_CObject* object, intptr_t object_id);
  void UnmarkCObject(Dart_CObject* object);
  bool IsCObjectMarked(Dart_CObject* object);
  intptr_t GetMarkedCObjectMark(Dart_CObject* object);
  void UnmarkAllCObjects(Dart_CObject* object);
  void AddToForwardList(Dart_CObject* object);

  void WriteSmi(int64_t value);
  void WriteNullObject();
  void WriteMint(Dart_CObject* object, int64_t value);
  void WriteInt32(Dart_CObject* object);
  void WriteInt64(Dart_CObject* object);
  void WriteInlinedHeader(Dart_CObject* object);
  bool WriteCObject(Dart_CObject* object);
  bool WriteCObjectRef(Dart_CObject* object);
  bool WriteForwardedCObject(Dart_CObject* object);
  bool WriteCObjectInlined(Dart_CObject* object, Dart_CObject_Type type);

  intptr_t object_id_;
  Dart_CObject** forward_list_;
  intptr_t forward_list_length_;
  intptr_t forward_id_;

  DISALLOW_COPY_AND_ASSIGN(ApiMessageWriter);
};

// This class handles translation of certain RawObjects to CObjects for
// NativeMessageHandlers.
//
// TODO(zra): Expand to support not only null, but also other VM heap objects
// as well.
class ApiObjectConverter : public AllStatic {
 public:
  static bool CanConvert(const RawObject* raw_obj) {
    return !raw_obj->IsHeapObject() || (raw_obj == Object::null());
  }

  static bool Convert(const RawObject* raw_obj, Dart_CObject* c_obj) {
    if (!raw_obj->IsHeapObject()) {
      ConvertSmi(reinterpret_cast<const RawSmi*>(raw_obj), c_obj);
    } else if (raw_obj == Object::null()) {
      ConvertNull(c_obj);
    } else {
      return false;
    }
    return true;
  }

 private:
  static void ConvertSmi(const RawSmi* raw_smi, Dart_CObject* c_obj) {
    ASSERT(!raw_smi->IsHeapObject());
    intptr_t value = Smi::Value(raw_smi);
    if (Utils::IsInt(31, value)) {
      c_obj->type = Dart_CObject_kInt32;
      c_obj->value.as_int32 = static_cast<int32_t>(value);
    } else {
      c_obj->type = Dart_CObject_kInt64;
      c_obj->value.as_int64 = static_cast<int64_t>(value);
    }
  }

  static void ConvertNull(Dart_CObject* c_obj) {
    c_obj->type = Dart_CObject_kNull;
    c_obj->value.as_int64 = 0;
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_DART_API_MESSAGE_H_
