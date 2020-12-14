// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>

#include "vm/dart_api_message.h"

#include "platform/undefined_behavior_sanitizer.h"
#include "platform/unicode.h"
#include "vm/object.h"
#include "vm/snapshot_ids.h"
#include "vm/symbols.h"

namespace dart {

static const int kNumInitialReferences = 4;

ApiMessageReader::ApiMessageReader(Message* msg)
    : BaseReader(msg->IsRaw() ? reinterpret_cast<uint8_t*>(
                                    static_cast<uword>(msg->raw_obj()))
                              : msg->snapshot(),
                 msg->snapshot_length()),
      zone_(NULL),
      backward_references_(kNumInitialReferences),
      vm_isolate_references_(kNumInitialReferences),
      vm_symbol_references_(NULL),
      finalizable_data_(msg->finalizable_data()) {}

ApiMessageReader::~ApiMessageReader() {}

void ApiMessageReader::Init() {
  // We need to have an enclosing ApiNativeScope.
  ASSERT(ApiNativeScope::Current() != NULL);
  zone_ = ApiNativeScope::Current()->zone();
  ASSERT(zone_ != NULL);

  // Initialize marker objects used to handle Lists.
  // TODO(sjesse): Remove this when message serialization format is
  // updated.
  memset(&type_arguments_marker, 0, sizeof(type_arguments_marker));
  memset(&dynamic_type_marker, 0, sizeof(dynamic_type_marker));
  type_arguments_marker.type =
      static_cast<Dart_CObject_Type>(Dart_CObject_Internal::kTypeArguments);
  dynamic_type_marker.type =
      static_cast<Dart_CObject_Type>(Dart_CObject_Internal::kDynamicType);
}

Dart_CObject* ApiMessageReader::ReadMessage() {
  Init();
  if (PendingBytes() > 0) {
    // Read the object out of the message.
    return ReadObject();
  } else {
    const ObjectPtr raw_obj = static_cast<const ObjectPtr>(
        reinterpret_cast<uword>(CurrentBufferAddress()));
    ASSERT(ApiObjectConverter::CanConvert(raw_obj));
    Dart_CObject* cobj =
        reinterpret_cast<Dart_CObject*>(allocator(sizeof(Dart_CObject)));
    ApiObjectConverter::Convert(raw_obj, cobj);
    return cobj;
  }
}

intptr_t ApiMessageReader::LookupInternalClass(intptr_t class_header) {
  if (IsVMIsolateObject(class_header)) {
    return GetVMIsolateObjectId(class_header);
  }
  ASSERT(SerializedHeaderTag::decode(class_header) == kObjectId);
  return SerializedHeaderData::decode(class_header);
}

Dart_CObject* ApiMessageReader::AllocateDartCObject(Dart_CObject_Type type) {
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(allocator(sizeof(Dart_CObject)));
  ASSERT(value != NULL);
  value->type = type;
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectUnsupported() {
  return AllocateDartCObject(Dart_CObject_kUnsupported);
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectNull() {
  return AllocateDartCObject(Dart_CObject_kNull);
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectBool(bool val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject_kBool);
  value->value.as_bool = val;
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectInt32(int32_t val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject_kInt32);
  value->value.as_int32 = val;
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectInt64(int64_t val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject_kInt64);
  value->value.as_int64 = val;
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectDouble(double val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject_kDouble);
  value->value.as_double = val;
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectString(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of chars
  // for the string content. The pointer to the string content is set
  // up to this area.
  Dart_CObject* value = reinterpret_cast<Dart_CObject*>(
      allocator(sizeof(Dart_CObject) + length + 1));
  ASSERT(value != NULL);
  value->value.as_string = reinterpret_cast<char*>(value) + sizeof(*value);
  value->type = Dart_CObject_kString;
  return value;
}

static int GetTypedDataSizeInBytes(Dart_TypedData_Type type) {
  switch (type) {
    case Dart_TypedData_kInt8:
    case Dart_TypedData_kUint8:
    case Dart_TypedData_kUint8Clamped:
      return 1;
    case Dart_TypedData_kInt16:
    case Dart_TypedData_kUint16:
      return 2;
    case Dart_TypedData_kInt32:
    case Dart_TypedData_kUint32:
    case Dart_TypedData_kFloat32:
      return 4;
    case Dart_TypedData_kInt64:
    case Dart_TypedData_kUint64:
    case Dart_TypedData_kFloat64:
      return 8;
    case Dart_TypedData_kInt32x4:
    case Dart_TypedData_kFloat32x4:
    case Dart_TypedData_kFloat64x2:
      return 16;
    default:
      break;
  }
  UNREACHABLE();
  return -1;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectTypedData(
    Dart_TypedData_Type type,
    intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of bytes
  // for the byte array content. The pointer to the byte array content
  // is set up to this area.
  intptr_t length_in_bytes = GetTypedDataSizeInBytes(type) * length;
  Dart_CObject* value = reinterpret_cast<Dart_CObject*>(
      allocator(sizeof(Dart_CObject) + length_in_bytes));
  ASSERT(value != NULL);
  value->type = Dart_CObject_kTypedData;
  value->value.as_typed_data.type = type;
  value->value.as_typed_data.length = length_in_bytes;
  if (length > 0) {
    value->value.as_typed_data.values =
        reinterpret_cast<uint8_t*>(value) + sizeof(*value);
  } else {
    value->value.as_typed_data.values = NULL;
  }
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectArray(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of
  // pointers to Dart_CObject structures. The pointer to the array
  // content is set up to this area.
  Dart_CObject* value = reinterpret_cast<Dart_CObject*>(
      allocator(sizeof(Dart_CObject) + length * sizeof(value)));
  ASSERT(value != NULL);
  value->type = Dart_CObject_kArray;
  value->value.as_array.length = length;
  if (length > 0) {
    value->value.as_array.values = reinterpret_cast<Dart_CObject**>(value + 1);
  } else {
    value->value.as_array.values = NULL;
  }
  return value;
}

Dart_CObject* ApiMessageReader::AllocateDartCObjectVmIsolateObj(intptr_t id) {
  ObjectPtr raw = VmIsolateSnapshotObject(id);
  intptr_t cid = raw->GetClassId();
  switch (cid) {
    case kOneByteStringCid: {
      OneByteStringPtr raw_str = static_cast<OneByteStringPtr>(raw);
      const char* str = reinterpret_cast<const char*>(raw_str->ptr()->data());
      ASSERT(str != NULL);
      Dart_CObject* object = NULL;
      for (intptr_t i = 0; i < vm_isolate_references_.length(); i++) {
        object = vm_isolate_references_.At(i);
        if (object->type == Dart_CObject_kString) {
          if (strcmp(str, object->value.as_string) == 0) {
            return object;
          }
        }
      }
      object = CreateDartCObjectString(raw);
      vm_isolate_references_.Add(object);
      return object;
    }

    case kMintCid: {
      const Mint& obj = Mint::Handle(static_cast<MintPtr>(raw));
      int64_t value64 = obj.value();
      if ((kMinInt32 <= value64) && (value64 <= kMaxInt32)) {
        return GetCanonicalMintObject(Dart_CObject_kInt32, value64);
      } else {
        return GetCanonicalMintObject(Dart_CObject_kInt64, value64);
      }
    }

    default:
      UNREACHABLE();
      return NULL;
  }
}

Dart_CObject_Internal* ApiMessageReader::AllocateDartCObjectInternal(
    Dart_CObject_Internal::Type type) {
  Dart_CObject_Internal* value = reinterpret_cast<Dart_CObject_Internal*>(
      allocator(sizeof(Dart_CObject_Internal)));
  ASSERT(value != NULL);
  value->type = static_cast<Dart_CObject_Type>(type);
  return value;
}

Dart_CObject_Internal* ApiMessageReader::AllocateDartCObjectClass() {
  return AllocateDartCObjectInternal(Dart_CObject_Internal::kClass);
}

ApiMessageReader::BackRefNode* ApiMessageReader::AllocateBackRefNode(
    Dart_CObject* reference,
    DeserializeState state) {
  BackRefNode* value =
      reinterpret_cast<BackRefNode*>(allocator(sizeof(BackRefNode)));
  value->set_reference(reference);
  value->set_state(state);
  return value;
}

Dart_CObject* ApiMessageReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();
  intptr_t tags = ReadTags();
  USE(tags);
  intptr_t class_id;

  // There is limited support for reading regular dart instances. Only
  // typed data views are currently handled.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    Dart_CObject_Internal* object =
        reinterpret_cast<Dart_CObject_Internal*>(GetBackRef(object_id));
    if (object == NULL) {
      object =
          AllocateDartCObjectInternal(Dart_CObject_Internal::kUninitialized);
      AddBackRef(object_id, object, kIsDeserialized);
      // Read class of object.
      object->cls = reinterpret_cast<Dart_CObject_Internal*>(ReadObjectImpl());
      ASSERT(object->cls->type ==
             static_cast<Dart_CObject_Type>(Dart_CObject_Internal::kClass));
    }
    ASSERT(object->type == static_cast<Dart_CObject_Type>(
                               Dart_CObject_Internal::kUninitialized));
    return object;
  }

  ASSERT((class_header & kSmiTagMask) != 0);
  class_id = LookupInternalClass(class_header);
  if ((class_id == kArrayCid) || (class_id == kImmutableArrayCid)) {
    intptr_t len = ReadSmiValue();
    Dart_CObject* value = GetBackRef(object_id);
    if (value == NULL) {
      value = AllocateDartCObjectArray(len);
      AddBackRef(object_id, value, kIsDeserialized);
    }
    // Skip type arguments.
    // TODO(sjesse): Remove this when message serialization format is
    // updated (currently type_arguments is leaked).
    Dart_CObject* type_arguments = ReadObjectImpl();
    if (type_arguments != &type_arguments_marker &&
        type_arguments->type != Dart_CObject_kNull) {
      return AllocateDartCObjectUnsupported();
    }
    for (int i = 0; i < len; i++) {
      value->value.as_array.values[i] = ReadObjectRef();
    }
    return value;
  }

  return ReadInternalVMObject(class_id, object_id);
}

Dart_CObject* ApiMessageReader::ReadPredefinedSymbol(intptr_t object_id) {
  ASSERT(Symbols::IsPredefinedSymbolId(object_id));
  intptr_t symbol_id = object_id - kMaxPredefinedObjectIds;
  Dart_CObject* object;
  if (vm_symbol_references_ != NULL &&
      (object = vm_symbol_references_[symbol_id]) != NULL) {
    return object;
  }

  if (vm_symbol_references_ == NULL) {
    intptr_t size =
        (sizeof(*vm_symbol_references_) * Symbols::kMaxPredefinedId);
    vm_symbol_references_ = reinterpret_cast<Dart_CObject**>(allocator(size));
    memset(vm_symbol_references_, 0, size);
  }

  object = CreateDartCObjectString(Symbols::GetPredefinedSymbol(object_id));
  ASSERT(vm_symbol_references_[symbol_id] == NULL);
  vm_symbol_references_[symbol_id] = object;
  return object;
}

intptr_t ApiMessageReader::NextAvailableObjectId() const {
  return backward_references_.length() + kMaxPredefinedObjectIds;
}

Dart_CObject* ApiMessageReader::CreateDartCObjectString(ObjectPtr raw) {
  ASSERT(IsOneByteStringClassId(raw->GetClassId()));
  OneByteStringPtr raw_str = static_cast<OneByteStringPtr>(raw);
  intptr_t len = Smi::Value(raw_str->ptr()->length());
  Dart_CObject* object = AllocateDartCObjectString(len);
  char* p = object->value.as_string;
  memmove(p, raw_str->ptr()->data(), len);
  p[len] = '\0';
  return object;
}

Dart_CObject* ApiMessageReader::GetCanonicalMintObject(Dart_CObject_Type type,
                                                       int64_t value64) {
  Dart_CObject* object = NULL;
  for (intptr_t i = 0; i < vm_isolate_references_.length(); i++) {
    object = vm_isolate_references_.At(i);
    if (object->type == type) {
      if (value64 == object->value.as_int64) {
        return object;
      }
    }
  }
  if (type == Dart_CObject_kInt32) {
    object = AllocateDartCObjectInt32(static_cast<int32_t>(value64));
  } else {
    object = AllocateDartCObjectInt64(value64);
  }
  vm_isolate_references_.Add(object);
  return object;
}

Dart_CObject* ApiMessageReader::ReadObjectRef() {
  int64_t value64 = Read<int64_t>();
  if ((value64 & kSmiTagMask) == 0) {
    int64_t untagged_value = value64 >> kSmiTagShift;
    if ((kMinInt32 <= untagged_value) && (untagged_value <= kMaxInt32)) {
      return AllocateDartCObjectInt32(static_cast<int32_t>(untagged_value));
    } else {
      return AllocateDartCObjectInt64(untagged_value);
    }
  }
  ASSERT((value64 <= kIntptrMax) && (value64 >= kIntptrMin));
  intptr_t value = static_cast<intptr_t>(value64);
  if (IsVMIsolateObject(value)) {
    return ReadVMIsolateObject(value);
  }
  if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();

  intptr_t object_id = SerializedHeaderData::decode(value);
  if (object_id == kOmittedObjectId) {
    object_id = NextAvailableObjectId();
  }

  intptr_t tags = ReadTags();
  USE(tags);

  // Reading of regular dart instances has limited support in order to
  // read typed data views.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    Dart_CObject_Internal* object =
        AllocateDartCObjectInternal(Dart_CObject_Internal::kUninitialized);
    AddBackRef(object_id, object, kIsNotDeserialized);
    // Read class of object.
    object->cls = reinterpret_cast<Dart_CObject_Internal*>(ReadObjectImpl());
    ASSERT(object->cls->type ==
           static_cast<Dart_CObject_Type>(Dart_CObject_Internal::kClass));
    return object;
  }
  ASSERT((class_header & kSmiTagMask) != 0);
  intptr_t class_id = LookupInternalClass(class_header);
  if ((class_id == kArrayCid) || (class_id == kImmutableArrayCid)) {
    ASSERT(GetBackRef(object_id) == NULL);
    intptr_t len = ReadSmiValue();
    Dart_CObject* value = AllocateDartCObjectArray(len);
    AddBackRef(object_id, value, kIsNotDeserialized);
    return value;
  }
  return ReadInternalVMObject(class_id, object_id);
}

Dart_CObject* ApiMessageReader::ReadVMIsolateObject(intptr_t value) {
  intptr_t object_id = GetVMIsolateObjectId(value);
  if (object_id == kNullObject) {
    return AllocateDartCObjectNull();
  }
  if (object_id == kTrueValue) {
    return AllocateDartCObjectBool(true);
  }
  if (object_id == kFalseValue) {
    return AllocateDartCObjectBool(false);
  }
  if (object_id == kDoubleObject) {
    return AllocateDartCObjectDouble(ReadDouble());
  }
  if (Symbols::IsPredefinedSymbolId(object_id)) {
    return ReadPredefinedSymbol(object_id);
  }
  // No other VM isolate objects are supported.
  return AllocateDartCObjectNull();
}

Dart_CObject* ApiMessageReader::ReadInternalVMObject(intptr_t class_id,
                                                     intptr_t object_id) {
  switch (class_id) {
    case kClassCid: {
      Dart_CObject_Internal* object = AllocateDartCObjectClass();
      AddBackRef(object_id, object, kIsDeserialized);
      object->internal.as_class.library_url = ReadObjectImpl();
      ASSERT(object->internal.as_class.library_url->type ==
             Dart_CObject_kString);
      object->internal.as_class.class_name = ReadObjectImpl();
      ASSERT(object->internal.as_class.class_name->type ==
             Dart_CObject_kString);
      return object;
    }
    case kTypeArgumentsCid: {
      // TODO(sjesse): Remove this when message serialization format is
      // updated (currently length is leaked).
      Dart_CObject* value = &type_arguments_marker;
      AddBackRef(object_id, value, kIsDeserialized);
      Dart_CObject* length = ReadObjectImpl();
      ASSERT(length->type == Dart_CObject_kInt32);
      // The instantiations_ field is only written to a full snapshot.
      for (int i = 0; i < length->value.as_int32; i++) {
        Dart_CObject* type = ReadObjectImpl();
        if (type != &dynamic_type_marker) {
          return AllocateDartCObjectUnsupported();
        }
      }
      return value;
    }
    case kTypeParameterCid: {
      Dart_CObject* value = &dynamic_type_marker;
      AddBackRef(object_id, value, kIsDeserialized);
      intptr_t index = Read<int32_t>();
      USE(index);
      intptr_t token_index = Read<int32_t>();
      USE(token_index);
      int8_t type_state = Read<int8_t>();
      USE(type_state);
      Dart_CObject* parameterized_class = ReadObjectImpl();
      // The type parameter is finalized, therefore parameterized_class is null.
      ASSERT(parameterized_class->type == Dart_CObject_kNull);
      Dart_CObject* name = ReadObjectImpl();
      ASSERT(name->type == Dart_CObject_kString);
      return value;
    }
    case kMintCid: {
      int64_t value64 = Read<int64_t>();
      Dart_CObject* object;
      if ((kMinInt32 <= value64) && (value64 <= kMaxInt32)) {
        object = AllocateDartCObjectInt32(static_cast<int32_t>(value64));
      } else {
        object = AllocateDartCObjectInt64(value64);
      }
      AddBackRef(object_id, object, kIsDeserialized);
      return object;
    }
    case kDoubleCid: {
      // Doubles are handled specially when being sent as part of message
      // snapshots.
      UNREACHABLE();
    }
    case kOneByteStringCid: {
      intptr_t len = ReadSmiValue();
      uint8_t* latin1 =
          reinterpret_cast<uint8_t*>(allocator(len * sizeof(uint8_t)));
      intptr_t utf8_len = 0;
      for (intptr_t i = 0; i < len; i++) {
        latin1[i] = Read<uint8_t>();
        utf8_len += Utf8::Length(latin1[i]);
      }
      Dart_CObject* object = AllocateDartCObjectString(utf8_len);
      AddBackRef(object_id, object, kIsDeserialized);
      char* p = object->value.as_string;
      for (intptr_t i = 0; i < len; i++) {
        p += Utf8::Encode(latin1[i], p);
      }
      *p = '\0';
      ASSERT(p == (object->value.as_string + utf8_len));
      return object;
    }
    case kTwoByteStringCid: {
      intptr_t len = ReadSmiValue();
      uint16_t* utf16 =
          reinterpret_cast<uint16_t*>(allocator(len * sizeof(uint16_t)));
      intptr_t utf8_len = 0;
      // Read all the UTF-16 code units.
      for (intptr_t i = 0; i < len; i++) {
        utf16[i] = Read<uint16_t>();
      }
      // Calculate the UTF-8 length and check if the string can be
      // UTF-8 encoded.
      bool valid = true;
      intptr_t i = 0;
      while (i < len && valid) {
        int32_t ch = Utf16::Next(utf16, &i, len);
        utf8_len += Utf8::Length(ch);
        valid = !Utf16::IsSurrogate(ch);
      }
      if (!valid) {
        return AllocateDartCObjectUnsupported();
      }
      Dart_CObject* object = AllocateDartCObjectString(utf8_len);
      AddBackRef(object_id, object, kIsDeserialized);
      char* p = object->value.as_string;
      i = 0;
      while (i < len) {
        p += Utf8::Encode(Utf16::Next(utf16, &i, len), p);
      }
      *p = '\0';
      ASSERT(p == (object->value.as_string + utf8_len));
      return object;
    }
    case kSendPortCid: {
      int64_t value64 = Read<int64_t>();
      int64_t originId = Read<uint64_t>();
      Dart_CObject* object = AllocateDartCObject(Dart_CObject_kSendPort);
      object->value.as_send_port.id = value64;
      object->value.as_send_port.origin_id = originId;
      AddBackRef(object_id, object, kIsDeserialized);
      return object;
    }
    case kCapabilityCid: {
      int64_t id = Read<int64_t>();
      Dart_CObject* object = AllocateDartCObject(Dart_CObject_kCapability);
      object->value.as_capability.id = id;
      AddBackRef(object_id, object, kIsDeserialized);
      return object;
    }

#define READ_TYPED_DATA(tname, ctype)                                          \
  {                                                                            \
    intptr_t len = ReadSmiValue();                                             \
    auto type = Dart_TypedData_k##tname;                                       \
    intptr_t length_in_bytes = GetTypedDataSizeInBytes(type) * len;            \
    Dart_CObject* object =                                                     \
        reinterpret_cast<Dart_CObject*>(allocator(sizeof(Dart_CObject)));      \
    ASSERT(object != NULL);                                                    \
    object->type = Dart_CObject_kTypedData;                                    \
    object->value.as_typed_data.type = type;                                   \
    object->value.as_typed_data.length = length_in_bytes;                      \
    if (len > 0) {                                                             \
      Align(Zone::kAlignment);                                                 \
      object->value.as_typed_data.values =                                     \
          const_cast<uint8_t*>(CurrentBufferAddress());                        \
      Advance(length_in_bytes);                                                \
    } else {                                                                   \
      object->value.as_typed_data.values = NULL;                               \
    }                                                                          \
    AddBackRef(object_id, object, kIsDeserialized);                            \
    return object;                                                             \
  }

#define READ_EXTERNAL_TYPED_DATA(tname, ctype)                                 \
  {                                                                            \
    intptr_t len = ReadSmiValue();                                             \
    auto type = Dart_TypedData_k##tname;                                       \
    intptr_t length_in_bytes = GetTypedDataSizeInBytes(type) * len;            \
    Dart_CObject* object =                                                     \
        reinterpret_cast<Dart_CObject*>(allocator(sizeof(Dart_CObject)));      \
    ASSERT(object != NULL);                                                    \
    object->type = Dart_CObject_kTypedData;                                    \
    object->value.as_typed_data.type = type;                                   \
    object->value.as_typed_data.length = length_in_bytes;                      \
    object->value.as_typed_data.values =                                       \
        reinterpret_cast<uint8_t*>(finalizable_data_->Get().data);             \
    AddBackRef(object_id, object, kIsDeserialized);                            \
    return object;                                                             \
  }

#define READ_TYPED_DATA_VIEW(tname, ctype)                                     \
  {                                                                            \
    Dart_CObject_Internal* object =                                            \
        AllocateDartCObjectInternal(Dart_CObject_Internal::kUninitialized);    \
    AddBackRef(object_id, object, kIsDeserialized);                            \
    object->type =                                                             \
        static_cast<Dart_CObject_Type>(Dart_CObject_Internal::kView);          \
    object->internal.as_view.offset_in_bytes = ReadSmiValue();                 \
    object->internal.as_view.length = ReadSmiValue();                          \
    object->internal.as_view.buffer = ReadObjectImpl();                        \
    Dart_CObject* buffer = object->internal.as_view.buffer;                    \
    RELEASE_ASSERT(buffer->type == Dart_CObject_kTypedData);                   \
                                                                               \
    /* Now turn the view into a byte array.*/                                  \
    const Dart_TypedData_Type type = Dart_TypedData_k##tname;                  \
    object->type = Dart_CObject_kTypedData;                                    \
    object->value.as_typed_data.type = type;                                   \
    object->value.as_typed_data.length =                                       \
        object->internal.as_view.length * GetTypedDataSizeInBytes(type);       \
    object->value.as_typed_data.values =                                       \
        buffer->value.as_typed_data.values +                                   \
        object->internal.as_view.offset_in_bytes;                              \
    return object;                                                             \
  }

#define TYPED_DATA_LIST(V)                                                     \
  V(Int8, int8_t)                                                              \
  V(Uint8, uint8_t)                                                            \
  V(Uint8Clamped, uint8_t)                                                     \
  V(Int16, int16_t)                                                            \
  V(Uint16, uint16_t)                                                          \
  V(Int32, int32_t)                                                            \
  V(Uint32, uint32_t)                                                          \
  V(Int64, int64_t)                                                            \
  V(Uint64, uint64_t)                                                          \
  V(Float32, float)                                                            \
  V(Float64, double)                                                           \
  V(Int32x4, simd128_value_t)                                                  \
  V(Float32x4, simd128_value_t)                                                \
  V(Float64x2, simd128_value_t)

#define EMIT_TYPED_DATA_CASES(type, c_type)                                    \
  case kTypedData##type##ArrayCid:                                             \
    READ_TYPED_DATA(type, c_type);                                             \
  case kExternalTypedData##type##ArrayCid:                                     \
    READ_EXTERNAL_TYPED_DATA(type, c_type);                                    \
  case kTypedData##type##ArrayViewCid:                                         \
    READ_TYPED_DATA_VIEW(type, c_type);

      TYPED_DATA_LIST(EMIT_TYPED_DATA_CASES)
#undef EMIT_TYPED_DATA_CASES
#undef TYPED_DATA_LIST
#undef READ_TYPED_DATA
#undef READ_EXTERNAL_TYPED_DATA
#undef READ_TYPED_DATA_VIEW

    case kGrowableObjectArrayCid: {
      // A GrowableObjectArray is serialized as its type arguments and
      // length followed by its backing store. The backing store is an
      // array with a length which might be longer than the length of
      // the GrowableObjectArray.
      Dart_CObject* value = GetBackRef(object_id);
      ASSERT(value == NULL);
      // Allocate an empty array for the GrowableObjectArray which
      // will be updated to point to the content when the backing
      // store has been deserialized.
      value = AllocateDartCObjectArray(0);
      AddBackRef(object_id, value, kIsDeserialized);

      // Read and skip the type arguments field.
      // TODO(sjesse): Remove this when message serialization format is
      // updated (currently type_arguments is leaked).
      Dart_CObject* type_arguments = ReadObjectImpl();
      if (type_arguments != &type_arguments_marker &&
          type_arguments->type != Dart_CObject_kNull) {
        return AllocateDartCObjectUnsupported();
      }

      // Read the length field.
      intptr_t len = ReadSmiValue();

      // Read the content of the GrowableObjectArray.
      Dart_CObject* content = ReadObjectRef();
      ASSERT(content->type == Dart_CObject_kArray);
      // Make the empty array allocated point to the backing store content.
      value->value.as_array.length = len;
      value->value.as_array.values = content->value.as_array.values;
      return value;
    }
    default:
      // Everything else not supported.
      Dart_CObject* value = AllocateDartCObjectUnsupported();
      AddBackRef(object_id, value, kIsDeserialized);
      return value;
  }
}

Dart_CObject* ApiMessageReader::ReadIndexedObject(intptr_t object_id) {
  if (object_id >= kFirstTypeSnapshotId && object_id <= kLastTypeSnapshotId) {
    // Always return dynamic type (this is only a marker).
    return &dynamic_type_marker;
  }
  if (object_id >= kFirstTypeArgumentsSnapshotId &&
      object_id <= kLastTypeArgumentsSnapshotId) {
    return &type_arguments_marker;
  }

  intptr_t index = object_id - kMaxPredefinedObjectIds;
  ASSERT((0 <= index) && (index < backward_references_.length()));
  ASSERT(backward_references_[index]->reference() != NULL);
  return backward_references_[index]->reference();
}

Dart_CObject* ApiMessageReader::ReadObject() {
  Dart_CObject* value = ReadObjectImpl();
  for (intptr_t i = 0; i < backward_references_.length(); i++) {
    if (!backward_references_[i]->is_deserialized()) {
      ReadObjectImpl();
      backward_references_[i]->set_state(kIsDeserialized);
    }
  }
  return value;
}

Dart_CObject* ApiMessageReader::ReadObjectImpl() {
  int64_t value64 = Read<int64_t>();
  if ((value64 & kSmiTagMask) == 0) {
    int64_t untagged_value = value64 >> kSmiTagShift;
    if ((kMinInt32 <= untagged_value) && (untagged_value <= kMaxInt32)) {
      return AllocateDartCObjectInt32(static_cast<int32_t>(untagged_value));
    } else {
      return AllocateDartCObjectInt64(untagged_value);
    }
  }
  ASSERT((value64 <= kIntptrMax) && (value64 >= kIntptrMin));
  intptr_t value = static_cast<intptr_t>(value64);
  if (IsVMIsolateObject(value)) {
    return ReadVMIsolateObject(value);
  }
  if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);

  intptr_t object_id = SerializedHeaderData::decode(value);
  if (object_id == kOmittedObjectId) {
    object_id = NextAvailableObjectId();
  }
  return ReadInlinedObject(object_id);
}

void ApiMessageReader::AddBackRef(intptr_t id,
                                  Dart_CObject* obj,
                                  DeserializeState state) {
  intptr_t index = (id - kMaxPredefinedObjectIds);
  ASSERT(index == backward_references_.length());
  BackRefNode* node = AllocateBackRefNode(obj, state);
  ASSERT(node != NULL);
  backward_references_.Add(node);
}

Dart_CObject* ApiMessageReader::GetBackRef(intptr_t id) {
  ASSERT(id >= kMaxPredefinedObjectIds);
  intptr_t index = (id - kMaxPredefinedObjectIds);
  if (index < backward_references_.length()) {
    return backward_references_[index]->reference();
  }
  return NULL;
}

ApiMessageWriter::ApiMessageWriter()
    : BaseWriter(kInitialSize),
      object_id_(0),
      forward_list_(NULL),
      forward_list_length_(0),
      forward_id_(0),
      finalizable_data_(new MessageFinalizableData()) {
  ASSERT(kDartCObjectTypeMask >= Dart_CObject_kNumberOfTypes - 1);
}

ApiMessageWriter::~ApiMessageWriter() {
  ::free(forward_list_);
  delete finalizable_data_;
}

NO_SANITIZE_UNDEFINED(
    "enum")  // TODO(https://github.com/dart-lang/sdk/issues/39427)
void ApiMessageWriter::MarkCObject(Dart_CObject* object, intptr_t object_id) {
  // Mark the object as serialized by adding the object id to the
  // upper bits of the type field in the Dart_CObject structure. Add
  // an offset for making marking of object id 0 possible.
  ASSERT(!IsCObjectMarked(object));
  intptr_t mark_value = object_id + kDartCObjectMarkOffset;
  object->type = static_cast<Dart_CObject_Type>(
      ((mark_value) << kDartCObjectTypeBits) | object->type);
}

NO_SANITIZE_UNDEFINED(
    "enum")  // TODO(https://github.com/dart-lang/sdk/issues/39427)
void ApiMessageWriter::UnmarkCObject(Dart_CObject* object) {
  ASSERT(IsCObjectMarked(object));
  object->type =
      static_cast<Dart_CObject_Type>(object->type & kDartCObjectTypeMask);
}

NO_SANITIZE_UNDEFINED(
    "enum")  // TODO(https://github.com/dart-lang/sdk/issues/39427)
bool ApiMessageWriter::IsCObjectMarked(Dart_CObject* object) {
  return (object->type & kDartCObjectMarkMask) != 0;
}

NO_SANITIZE_UNDEFINED(
    "enum")  // TODO(https://github.com/dart-lang/sdk/issues/39427)
intptr_t ApiMessageWriter::GetMarkedCObjectMark(Dart_CObject* object) {
  ASSERT(IsCObjectMarked(object));
  intptr_t mark_value =
      ((object->type & kDartCObjectMarkMask) >> kDartCObjectTypeBits);
  // An offset was added to object id for making marking object id 0 possible.
  return mark_value - kDartCObjectMarkOffset;
}

void ApiMessageWriter::UnmarkAllCObjects(Dart_CObject* object) {
  if (!IsCObjectMarked(object)) return;
  UnmarkCObject(object);
  if (object->type == Dart_CObject_kArray) {
    for (int i = 0; i < object->value.as_array.length; i++) {
      Dart_CObject* element = object->value.as_array.values[i];
      UnmarkAllCObjects(element);
    }
  }
}

void ApiMessageWriter::AddToForwardList(Dart_CObject* object) {
  if (forward_id_ >= forward_list_length_) {
    void* new_list = NULL;
    if (forward_list_length_ == 0) {
      forward_list_length_ = 4;
      intptr_t new_size = forward_list_length_ * sizeof(object);
      new_list = dart::malloc(new_size);
    } else {
      forward_list_length_ *= 2;
      intptr_t new_size = (forward_list_length_ * sizeof(object));
      new_list = dart::realloc(forward_list_, new_size);
    }
    ASSERT(new_list != NULL);
    forward_list_ = reinterpret_cast<Dart_CObject**>(new_list);
  }
  forward_list_[forward_id_] = object;
  forward_id_ += 1;
}

void ApiMessageWriter::WriteSmi(int64_t value) {
  ASSERT(Smi::IsValid(value));
  Write<ObjectPtr>(Smi::New(static_cast<intptr_t>(value)));
}

void ApiMessageWriter::WriteNullObject() {
  WriteVMIsolateObject(kNullObject);
}

void ApiMessageWriter::WriteMint(Dart_CObject* object, int64_t value) {
  ASSERT(!Smi::IsValid(value));
  // Write out the serialization header value for mint object.
  WriteInlinedHeader(object);
  // Write out the class and tags information.
  WriteIndexedObject(kMintCid);
  WriteTags(0);
  // Write the 64-bit value.
  Write<int64_t>(value);
}

void ApiMessageWriter::WriteInt32(Dart_CObject* object) {
  int64_t value = object->value.as_int32;
  if (Smi::IsValid(value)) {
    WriteSmi(value);
  } else {
    WriteMint(object, value);
  }
}

void ApiMessageWriter::WriteInt64(Dart_CObject* object) {
  int64_t value = object->value.as_int64;
  if (Smi::IsValid(value)) {
    WriteSmi(value);
  } else {
    WriteMint(object, value);
  }
}

void ApiMessageWriter::WriteInlinedHeader(Dart_CObject* object) {
  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(kMaxPredefinedObjectIds + object_id_);
  // Mark object with its object id.
  MarkCObject(object, object_id_);
  // Advance object id.
  object_id_++;
}

bool ApiMessageWriter::WriteCObject(Dart_CObject* object) {
  if (IsCObjectMarked(object)) {
    intptr_t object_id = GetMarkedCObjectMark(object);
    WriteIndexedObject(kMaxPredefinedObjectIds + object_id);
    return true;
  }

  Dart_CObject_Type type = object->type;
  if (type == Dart_CObject_kArray) {
    const intptr_t array_length = object->value.as_array.length;
    if (!Array::IsValidLength(array_length)) {
      return false;
    }

    // Write out the serialization header value for this object.
    WriteInlinedHeader(object);
    // Write out the class and tags information.
    WriteIndexedObject(kArrayCid);
    WriteTags(0);
    // Write out the length information.
    WriteSmi(array_length);
    // Write out the type arguments.
    WriteNullObject();
    // Write out array elements.
    for (int i = 0; i < array_length; i++) {
      bool success = WriteCObjectRef(object->value.as_array.values[i]);
      if (!success) return false;
    }
    return true;
  }
  return WriteCObjectInlined(object, type);
}

bool ApiMessageWriter::WriteCObjectRef(Dart_CObject* object) {
  if (IsCObjectMarked(object)) {
    intptr_t object_id = GetMarkedCObjectMark(object);
    WriteIndexedObject(kMaxPredefinedObjectIds + object_id);
    return true;
  }

  Dart_CObject_Type type = object->type;
  if (type == Dart_CObject_kArray) {
    const intptr_t array_length = object->value.as_array.length;
    if (!Array::IsValidLength(array_length)) {
      return false;
    }
    // Write out the serialization header value for this object.
    WriteInlinedHeader(object);
    // Write out the class information.
    WriteIndexedObject(kArrayCid);
    WriteTags(0);
    // Write out the length information.
    WriteSmi(array_length);
    // Add object to forward list so that this object is serialized later.
    AddToForwardList(object);
    return true;
  }
  return WriteCObjectInlined(object, type);
}

NO_SANITIZE_UNDEFINED(
    "enum")  // TODO(https://github.com/dart-lang/sdk/issues/39427)
bool ApiMessageWriter::WriteForwardedCObject(Dart_CObject* object) {
  ASSERT(IsCObjectMarked(object));
  Dart_CObject_Type type =
      static_cast<Dart_CObject_Type>(object->type & kDartCObjectTypeMask);
  ASSERT(type == Dart_CObject_kArray);
  const intptr_t array_length = object->value.as_array.length;
  if (!Array::IsValidLength(array_length)) {
    return false;
  }

  // Write out the serialization header value for this object.
  intptr_t object_id = GetMarkedCObjectMark(object);
  WriteInlinedObjectHeader(kMaxPredefinedObjectIds + object_id);
  // Write out the class and tags information.
  WriteIndexedObject(kArrayCid);
  WriteTags(0);
  // Write out the length information.
  WriteSmi(array_length);
  // Write out the type arguments.
  WriteNullObject();
  // Write out array elements.
  for (int i = 0; i < array_length; i++) {
    bool success = WriteCObjectRef(object->value.as_array.values[i]);
    if (!success) return false;
  }
  return true;
}

bool ApiMessageWriter::WriteCObjectInlined(Dart_CObject* object,
                                           Dart_CObject_Type type) {
  switch (type) {
    case Dart_CObject_kNull:
      WriteNullObject();
      break;
    case Dart_CObject_kBool:
      if (object->value.as_bool) {
        WriteVMIsolateObject(kTrueValue);
      } else {
        WriteVMIsolateObject(kFalseValue);
      }
      break;
    case Dart_CObject_kInt32:
      WriteInt32(object);
      break;
    case Dart_CObject_kInt64:
      WriteInt64(object);
      break;
    case Dart_CObject_kDouble:
      WriteVMIsolateObject(kDoubleObject);
      WriteDouble(object->value.as_double);
      break;
    case Dart_CObject_kString: {
      const uint8_t* utf8_str =
          reinterpret_cast<const uint8_t*>(object->value.as_string);
      intptr_t utf8_len = strlen(object->value.as_string);
      if (!Utf8::IsValid(utf8_str, utf8_len)) {
        return false;
      }

      Utf8::Type type = Utf8::kLatin1;
      intptr_t len = Utf8::CodeUnitCount(utf8_str, utf8_len, &type);
      if (len > String::kMaxElements) {
        return false;
      }

      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(type == Utf8::kLatin1 ? kOneByteStringCid
                                               : kTwoByteStringCid);
      WriteTags(0);
      // Write string length and content.
      WriteSmi(len);
      if (type == Utf8::kLatin1) {
        uint8_t* latin1_str =
            reinterpret_cast<uint8_t*>(dart::malloc(len * sizeof(uint8_t)));
        bool success =
            Utf8::DecodeToLatin1(utf8_str, utf8_len, latin1_str, len);
        ASSERT(success);
        for (intptr_t i = 0; i < len; i++) {
          Write<uint8_t>(latin1_str[i]);
        }
        ::free(latin1_str);
      } else {
        uint16_t* utf16_str =
            reinterpret_cast<uint16_t*>(dart::malloc(len * sizeof(uint16_t)));
        bool success = Utf8::DecodeToUTF16(utf8_str, utf8_len, utf16_str, len);
        ASSERT(success);
        for (intptr_t i = 0; i < len; i++) {
          Write<uint16_t>(utf16_str[i]);
        }
        ::free(utf16_str);
      }
      break;
    }
    case Dart_CObject_kTypedData: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      intptr_t class_id;
      switch (object->value.as_typed_data.type) {
        case Dart_TypedData_kInt8:
          class_id = kTypedDataInt8ArrayCid;
          break;
        case Dart_TypedData_kUint8:
          class_id = kTypedDataUint8ArrayCid;
          break;
        case Dart_TypedData_kUint32:
          class_id = kTypedDataUint32ArrayCid;
          break;
        default:
          class_id = kTypedDataUint8ArrayCid;
          UNIMPLEMENTED();
      }

      intptr_t len = object->value.as_typed_data.length;
      if (len < 0 || len > TypedData::MaxElements(class_id)) {
        return false;
      }

      WriteIndexedObject(class_id);
      WriteTags(0);
      WriteSmi(len);
      switch (class_id) {
        case kTypedDataInt8ArrayCid:
        case kTypedDataUint8ArrayCid: {
          uint8_t* bytes = object->value.as_typed_data.values;
          Align(Zone::kAlignment);
          WriteBytes(bytes, len);
          break;
        }
        case kTypedDataUint32ArrayCid: {
          uint8_t* bytes = object->value.as_typed_data.values;
          Align(Zone::kAlignment);
          WriteBytes(bytes, len * sizeof(uint32_t));
          break;
        }
        default:
          UNIMPLEMENTED();
      }
      break;
    }
    case Dart_CObject_kExternalTypedData: {
      // TODO(ager): we are writing C pointers into the message in
      // order to post external arrays through ports. We need to make
      // sure that messages containing pointers can never be posted
      // to other processes.

      // Write out serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tag information.
      WriteIndexedObject(kExternalTypedDataUint8ArrayCid);
      WriteTags(0);
      intptr_t length = object->value.as_external_typed_data.length;
      if (length < 0 || length > ExternalTypedData::MaxElements(
                                     kExternalTypedDataUint8ArrayCid)) {
        return false;
      }
      uint8_t* data = object->value.as_external_typed_data.data;
      void* peer = object->value.as_external_typed_data.peer;
      Dart_HandleFinalizer callback =
          object->value.as_external_typed_data.callback;
      if (callback == NULL) {
        return false;
      }
      WriteSmi(length);
      finalizable_data_->Put(length, reinterpret_cast<void*>(data), peer,
                             callback);
      break;
    }
    case Dart_CObject_kSendPort: {
      WriteInlinedHeader(object);
      WriteIndexedObject(kSendPortCid);
      WriteTags(0);
      Write<int64_t>(object->value.as_send_port.id);
      Write<uint64_t>(object->value.as_send_port.origin_id);
      break;
    }
    case Dart_CObject_kCapability: {
      WriteInlinedHeader(object);
      WriteIndexedObject(kCapabilityCid);
      WriteTags(0);
      Write<uint64_t>(object->value.as_capability.id);
      break;
    }
    default:
      FATAL1("Unexpected Dart_CObject_Type %d\n", type);
  }

  return true;
}

std::unique_ptr<Message> ApiMessageWriter::WriteCMessage(
    Dart_CObject* object,
    Dart_Port dest_port,
    Message::Priority priority) {
  bool success = WriteCObject(object);
  if (!success) {
    UnmarkAllCObjects(object);
    intptr_t unused;
    free(Steal(&unused));
    return nullptr;
  }

  // Write out all objects that were added to the forward list and have
  // not been serialized yet. These would typically be fields of arrays.
  // NOTE: The forward list might grow as we process the list.
  for (intptr_t i = 0; i < forward_id_; i++) {
    success = WriteForwardedCObject(forward_list_[i]);
    if (!success) {
      UnmarkAllCObjects(object);
      intptr_t unused;
      free(Steal(&unused));
      return nullptr;
    }
  }

  UnmarkAllCObjects(object);
  MessageFinalizableData* finalizable_data = finalizable_data_;
  finalizable_data_ = nullptr;
  intptr_t size;
  uint8_t* buffer = Steal(&size);
  return Message::New(dest_port, buffer, size, finalizable_data, priority);
}

}  // namespace dart
