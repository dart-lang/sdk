// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_message.h"
#include "vm/object.h"
#include "vm/snapshot_ids.h"
#include "vm/symbols.h"

namespace dart {

static const int kNumInitialReferences = 4;

ApiMessageReader::ApiMessageReader(const uint8_t* buffer,
                                   intptr_t length,
                                   ReAlloc alloc)
    : BaseReader(buffer, length),
      alloc_(alloc),
      backward_references_(kNumInitialReferences) {
  Init();
}


void ApiMessageReader::Init() {
  // Initialize marker objects used to handle Lists.
  // TODO(sjesse): Remove this when message serialization format is
  // updated.
  memset(&type_arguments_marker, 0, sizeof(type_arguments_marker));
  memset(&dynamic_type_marker, 0, sizeof(dynamic_type_marker));
  type_arguments_marker.type =
      static_cast<Dart_CObject::Type>(Dart_CObject_Internal::kTypeArguments);
  dynamic_type_marker.type =
      static_cast<Dart_CObject::Type>(Dart_CObject_Internal::kDynamicType);
}


Dart_CObject* ApiMessageReader::ReadMessage() {
  // Read the object out of the message.
  return ReadObject();
}


intptr_t ApiMessageReader::LookupInternalClass(intptr_t class_header) {
  if (IsVMIsolateObject(class_header)) {
    return GetVMIsolateObjectId(class_header);
  }
  ASSERT(SerializedHeaderTag::decode(class_header) == kObjectId);
  return SerializedHeaderData::decode(class_header);
}


Dart_CObject* ApiMessageReader::AllocateDartCObject(Dart_CObject::Type type) {
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(alloc_(NULL, 0, sizeof(Dart_CObject)));
  ASSERT(value != NULL);
  value->type = type;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectUnsupported() {
  return AllocateDartCObject(Dart_CObject::kUnsupported);
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectNull() {
  return AllocateDartCObject(Dart_CObject::kNull);
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectBool(bool val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject::kBool);
  value->value.as_bool = val;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectInt32(int32_t val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject::kInt32);
  value->value.as_int32 = val;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectInt64(int64_t val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject::kInt64);
  value->value.as_int64 = val;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectBigint(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of chars
  // for the bigint hex string content. The pointer to the bigint
  // content is set up to this area.
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(
          alloc_(NULL, 0, sizeof(Dart_CObject) + length + 1));
  value->value.as_bigint = reinterpret_cast<char*>(value) + sizeof(*value);
  value->type = Dart_CObject::kBigint;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectDouble(double val) {
  Dart_CObject* value = AllocateDartCObject(Dart_CObject::kDouble);
  value->value.as_double = val;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectString(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of chars
  // for the string content. The pointer to the string content is set
  // up to this area.
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(
          alloc_(NULL, 0, sizeof(Dart_CObject) + length + 1));
  ASSERT(value != NULL);
  value->value.as_string = reinterpret_cast<char*>(value) + sizeof(*value);
  value->type = Dart_CObject::kString;
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectUint8Array(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of bytes
  // for the byte array content. The pointer to the byte array content
  // is set up to this area.
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(
          alloc_(NULL, 0, sizeof(Dart_CObject) + length));
  ASSERT(value != NULL);
  value->type = Dart_CObject::kUint8Array;
  value->value.as_array.length = length;
  if (length > 0) {
    value->value.as_byte_array.values =
        reinterpret_cast<uint8_t*>(value) + sizeof(*value);
  } else {
    value->value.as_byte_array.values = NULL;
  }
  return value;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectArray(intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of
  // pointers to Dart_CObject structures. The pointer to the array
  // content is set up to this area.
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(
          alloc_(NULL, 0, sizeof(Dart_CObject) + length * sizeof(value)));
  ASSERT(value != NULL);
  value->type = Dart_CObject::kArray;
  value->value.as_array.length = length;
  if (length > 0) {
    value->value.as_array.values = reinterpret_cast<Dart_CObject**>(value + 1);
  } else {
    value->value.as_array.values = NULL;
  }
  return value;
}


ApiMessageReader::BackRefNode* ApiMessageReader::AllocateBackRefNode(
    Dart_CObject* reference,
    DeserializeState state) {
  BackRefNode* value =
      reinterpret_cast<BackRefNode*>(alloc_(NULL, 0, sizeof(BackRefNode)));
  value->set_reference(reference);
  value->set_state(state);
  return value;
}


Dart_CObject* ApiMessageReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();
  intptr_t tags = ReadIntptrValue();
  USE(tags);
  intptr_t class_id;

  // Reading of regular dart instances is not supported.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    return AllocateDartCObjectUnsupported();
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
        type_arguments->type != Dart_CObject::kNull) {
      return AllocateDartCObjectUnsupported();
    }
    for (int i = 0; i < len; i++) {
      value->value.as_array.values[i] = ReadObjectRef();
    }
    return value;
  }

  return ReadInternalVMObject(class_id, object_id);
}


Dart_CObject* ApiMessageReader::ReadVMSymbol(intptr_t object_id) {
  if (Symbols::IsVMSymbolId(object_id)) {
    RawOneByteString* str =
        reinterpret_cast<RawOneByteString*>(Symbols::GetVMSymbol(object_id));
    intptr_t len = Smi::Value(str->ptr()->length_);
    Dart_CObject* object = AllocateDartCObjectString(len);
    char* p = object->value.as_string;
    memmove(p, str->ptr()->data_, len);
    p[len] = '\0';
    return object;
  }
  // No other VM isolate objects are supported.
  return AllocateDartCObjectNull();
}


Dart_CObject* ApiMessageReader::ReadObjectRef() {
  int64_t value = Read<int64_t>();
  if ((value & kSmiTagMask) == 0) {
    int64_t untagged_value = value >> kSmiTagShift;
    if (kMinInt32 <= untagged_value && untagged_value <= kMaxInt32) {
      return AllocateDartCObjectInt32(untagged_value);
    } else {
      return AllocateDartCObjectInt64(untagged_value);
    }
  }
  ASSERT((value <= kIntptrMax) && (value >= kIntptrMin));
  if (IsVMIsolateObject(value)) {
    intptr_t object_id = GetVMIsolateObjectId(value);
    if (object_id == kNullObject) {
      return AllocateDartCObjectNull();
    }
    return ReadVMSymbol(object_id);
  }
  if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();

  // Reading of regular dart instances is not supported.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    return AllocateDartCObjectUnsupported();
  }
  ASSERT((class_header & kSmiTagMask) != 0);
  intptr_t object_id = SerializedHeaderData::decode(value);
  intptr_t class_id = LookupInternalClass(class_header);
  if ((class_id == kArrayCid) || (class_id == kImmutableArrayCid)) {
    ASSERT(GetBackRef(object_id) == NULL);
    intptr_t len = ReadSmiValue();
    Dart_CObject* value = AllocateDartCObjectArray(len);
    AddBackRef(object_id, value, kIsNotDeserialized);
    return value;
  }

  intptr_t tags = ReadIntptrValue();
  USE(tags);

  return ReadInternalVMObject(class_id, object_id);
}


Dart_CObject* ApiMessageReader::ReadInternalVMObject(intptr_t class_id,
                                                     intptr_t object_id) {
  switch (class_id) {
    case kClassCid: {
      return AllocateDartCObjectUnsupported();
    }
    case kTypeArgumentsCid: {
      // TODO(sjesse): Remove this when message serialization format is
      // updated (currently length is leaked).
      Dart_CObject* value = &type_arguments_marker;
      AddBackRef(object_id, value, kIsDeserialized);
      Dart_CObject* length = ReadObjectImpl();
      ASSERT(length->type == Dart_CObject::kInt32);
      for (int i = 0; i < length->value.as_int32; i++) {
        Dart_CObject* type = ReadObjectImpl();
        if (type != &dynamic_type_marker) {
          return AllocateDartCObjectUnsupported();
        }
      }
      return value;
    }
    case kTypeParameterCid: {
      // TODO(sgjesse): Fix this workaround ignoring the type parameter.
      Dart_CObject* value = &dynamic_type_marker;
      AddBackRef(object_id, value, kIsDeserialized);
      intptr_t index = ReadIntptrValue();
      USE(index);
      intptr_t token_index = ReadIntptrValue();
      USE(token_index);
      int8_t type_state = Read<int8_t>();
      USE(type_state);
      Dart_CObject* parameterized_class = ReadObjectImpl();
      // The type parameter is finalized, therefore parameterized_class is null.
      ASSERT(parameterized_class->type == Dart_CObject::kNull);
      Dart_CObject* name = ReadObjectImpl();
      ASSERT(name->type == Dart_CObject::kString);
      return value;
    }
    case kMintCid: {
      int64_t value = Read<int64_t>();
      Dart_CObject* object;
      if (kMinInt32 <= value && value <= kMaxInt32) {
        object = AllocateDartCObjectInt32(value);
      } else {
        object = AllocateDartCObjectInt64(value);
      }
      AddBackRef(object_id, object, kIsDeserialized);
      return object;
    }
    case kBigintCid: {
      // Read in the hex string representation of the bigint.
      intptr_t len = ReadIntptrValue();
      Dart_CObject* object = AllocateDartCObjectBigint(len);
      AddBackRef(object_id, object, kIsDeserialized);
      char* p = object->value.as_bigint;
      for (intptr_t i = 0; i < len; i++) {
        p[i] = Read<uint8_t>();
      }
      p[len] = '\0';
      return object;
    }
    case kDoubleCid: {
      // Read the double value for the object.
      Dart_CObject* object = AllocateDartCObjectDouble(Read<double>());
      AddBackRef(object_id, object, kIsDeserialized);
      return object;
    }
    case kOneByteStringCid: {
      intptr_t len = ReadSmiValue();
      intptr_t hash = ReadSmiValue();
      USE(hash);
      Dart_CObject* object = AllocateDartCObjectString(len);
      AddBackRef(object_id, object, kIsDeserialized);
      char* p = object->value.as_string;
      for (intptr_t i = 0; i < len; i++) {
        p[i] = Read<uint8_t>();
      }
      p[len] = '\0';
      return object;
    }
    case kTwoByteStringCid:
      // Two byte strings not supported.
      return AllocateDartCObjectUnsupported();
    case kUint8ArrayCid: {
      intptr_t len = ReadSmiValue();
      Dart_CObject* object = AllocateDartCObjectUint8Array(len);
      AddBackRef(object_id, object, kIsDeserialized);
      if (len > 0) {
        uint8_t* p = object->value.as_byte_array.values;
        for (intptr_t i = 0; i < len; i++) {
          p[i] = Read<uint8_t>();
        }
      }
      return object;
    }
    case kGrowableObjectArrayCid: {
      // A GrowableObjectArray is serialized as its length followed by
      // its backing store. The backing store is an array with a
      // length which might be longer than the length of the
      // GrowableObjectArray.
      intptr_t len = ReadSmiValue();

      Dart_CObject* value = GetBackRef(object_id);
      ASSERT(value == NULL);
      // Allocate an empty array for the GrowableObjectArray which
      // will be updated to point to the content when the backing
      // store has been deserialized.
      value = AllocateDartCObjectArray(0);
      AddBackRef(object_id, value, kIsDeserialized);
      // Read the content of the GrowableObjectArray.
      Dart_CObject* content = ReadObjectImpl();
      ASSERT(content->type == Dart_CObject::kArray);
      // Make the empty array allocated point to the backing store content.
      value->value.as_array.length = len;
      value->value.as_array.values = content->value.as_array.values;
      return value;
    }
    default:
      // Everything else not supported.
      return AllocateDartCObjectUnsupported();
  }
}


Dart_CObject* ApiMessageReader::ReadIndexedObject(intptr_t object_id) {
  if (object_id == kTrueValue) {
    return AllocateDartCObjectBool(true);
  }
  if (object_id == kFalseValue) {
    return AllocateDartCObjectBool(false);
  }
  if (object_id == kDynamicType ||
      object_id == kDoubleType ||
      object_id == kIntType ||
      object_id == kBoolType ||
      object_id == kStringInterface) {
    // Always return dynamic type (this is only a marker).
    return &dynamic_type_marker;
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
  int64_t value = Read<int64_t>();
  if ((value & kSmiTagMask) == 0) {
    int64_t untagged_value = value >> kSmiTagShift;
    if (kMinInt32 <= untagged_value && untagged_value <= kMaxInt32) {
      return AllocateDartCObjectInt32(untagged_value);
    } else {
      return AllocateDartCObjectInt64(untagged_value);
    }
  }
  ASSERT((value <= kIntptrMax) && (value >= kIntptrMin));
  if (IsVMIsolateObject(value)) {
    intptr_t object_id = GetVMIsolateObjectId(value);
    if (object_id == kNullObject) {
      return AllocateDartCObjectNull();
    }
    return ReadVMSymbol(object_id);
  }
  if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);
  return ReadInlinedObject(SerializedHeaderData::decode(value));
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


void ApiMessageWriter::WriteMessage(intptr_t field_count, intptr_t *data) {
  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(kMaxPredefinedObjectIds);

  // Write out the class and tags information.
  WriteIndexedObject(kArrayCid);
  WriteIntptrValue(0);

  // Write out the length field.
  Write<RawObject*>(Smi::New(field_count));

  // Write out the type arguments.
  WriteNullObject();

  // Write out the individual Smis.
  for (int i = 0; i < field_count; i++) {
    Write<RawObject*>(Integer::New(data[i]));
  }
}


void ApiMessageWriter::MarkCObject(Dart_CObject* object, intptr_t object_id) {
  // Mark the object as serialized by adding the object id to the
  // upper bits of the type field in the Dart_CObject structure. Add
  // an offset for making marking of object id 0 possible.
  ASSERT(!IsCObjectMarked(object));
  intptr_t mark_value = object_id + kDartCObjectMarkOffset;
  object->type = static_cast<Dart_CObject::Type>(
      ((mark_value) << kDartCObjectTypeBits) | object->type);
}


void ApiMessageWriter::UnmarkCObject(Dart_CObject* object) {
  ASSERT(IsCObjectMarked(object));
  object->type = static_cast<Dart_CObject::Type>(
      object->type & kDartCObjectTypeMask);
}


bool ApiMessageWriter::IsCObjectMarked(Dart_CObject* object) {
  return (object->type & kDartCObjectMarkMask) != 0;
}


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
  if (object->type == Dart_CObject::kArray) {
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
      intptr_t new_size = 4 * sizeof(object);
      new_list = ::malloc(new_size);
    } else {
      intptr_t new_size = (forward_list_length_ * sizeof(object)) * 2;
      new_list = ::realloc(forward_list_, new_size);
    }
    ASSERT(new_list != NULL);
    forward_list_ = reinterpret_cast<Dart_CObject**>(new_list);
  }
  forward_list_[forward_id_] = object;
  forward_id_ += 1;
}


void ApiMessageWriter::WriteSmi(int64_t value) {
  ASSERT(Smi::IsValid64(value));
  Write<RawObject*>(Smi::New(value));
}


void ApiMessageWriter::WriteNullObject() {
  WriteVMIsolateObject(kNullObject);
}


void ApiMessageWriter::WriteMint(Dart_CObject* object, int64_t value) {
  ASSERT(!Smi::IsValid64(value));
  // Write out the serialization header value for mint object.
  WriteInlinedHeader(object);
  // Write out the class and tags information.
  WriteIndexedObject(kMintCid);
  WriteIntptrValue(0);
  // Write the 64-bit value.
  Write<int64_t>(value);
}


void ApiMessageWriter::WriteInt32(Dart_CObject* object) {
  int64_t value = object->value.as_int32;
  if (Smi::IsValid64(value)) {
    WriteSmi(value);
  } else {
    WriteMint(object, value);
  }
}


void ApiMessageWriter::WriteInt64(Dart_CObject* object) {
  int64_t value = object->value.as_int64;
  if (Smi::IsValid64(value)) {
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


void ApiMessageWriter::WriteCObject(Dart_CObject* object) {
  if (IsCObjectMarked(object)) {
    intptr_t object_id = GetMarkedCObjectMark(object);
    WriteIndexedObject(kMaxPredefinedObjectIds + object_id);
    return;
  }

  Dart_CObject::Type type = object->type;
  if (type == Dart_CObject::kArray) {
    // Write out the serialization header value for this object.
    WriteInlinedHeader(object);
    // Write out the class and tags information.
    WriteIndexedObject(kArrayCid);
    WriteIntptrValue(0);

    WriteSmi(object->value.as_array.length);
    // Write out the type arguments.
    WriteNullObject();
    // Write out array elements.
    for (int i = 0; i < object->value.as_array.length; i++) {
      WriteCObjectRef(object->value.as_array.values[i]);
    }
    return;
  }
  WriteCObjectInlined(object, type);
}


void ApiMessageWriter::WriteCObjectRef(Dart_CObject* object) {
  if (IsCObjectMarked(object)) {
    intptr_t object_id = GetMarkedCObjectMark(object);
    WriteIndexedObject(kMaxPredefinedObjectIds + object_id);
    return;
  }

  Dart_CObject::Type type = object->type;
  if (type == Dart_CObject::kArray) {
    // Write out the serialization header value for this object.
    WriteInlinedHeader(object);
    // Write out the class information.
    WriteIndexedObject(kArrayCid);
    // Write out the length information.
    WriteSmi(object->value.as_array.length);
    // Add object to forward list so that this object is serialized later.
    AddToForwardList(object);
    return;
  }
  WriteCObjectInlined(object, type);
}


void ApiMessageWriter::WriteForwardedCObject(Dart_CObject* object) {
  ASSERT(IsCObjectMarked(object));
  Dart_CObject::Type type =
      static_cast<Dart_CObject::Type>(object->type & kDartCObjectTypeMask);
  ASSERT(type == Dart_CObject::kArray);

  // Write out the serialization header value for this object.
  intptr_t object_id = GetMarkedCObjectMark(object);
  WriteInlinedObjectHeader(kMaxPredefinedObjectIds + object_id);
  // Write out the class and tags information.
  WriteIndexedObject(kArrayCid);
  WriteIntptrValue(0);

  WriteSmi(object->value.as_array.length);
  // Write out the type arguments.
  WriteNullObject();
  // Write out array elements.
  for (int i = 0; i < object->value.as_array.length; i++) {
    WriteCObjectRef(object->value.as_array.values[i]);
  }
}


void ApiMessageWriter::WriteCObjectInlined(Dart_CObject* object,
                                           Dart_CObject::Type type) {
  switch (type) {
    case Dart_CObject::kNull:
      WriteNullObject();
      break;
    case Dart_CObject::kBool:
      if (object->value.as_bool) {
        WriteIndexedObject(kTrueValue);
      } else {
        WriteIndexedObject(kFalseValue);
      }
      break;
    case Dart_CObject::kInt32:
      WriteInt32(object);
      break;
    case Dart_CObject::kInt64:
      WriteInt64(object);
      break;
    case Dart_CObject::kBigint: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(kBigintCid);
      WriteIntptrValue(0);
      // Write hex string length and content
      char* hex_string = object->value.as_bigint;
      intptr_t len = strlen(hex_string);
      WriteIntptrValue(len);
      for (intptr_t i = 0; i < len; i++) {
        Write<uint8_t>(hex_string[i]);
      }
      break;
    }
    case Dart_CObject::kDouble:
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(kDoubleCid);
      WriteIntptrValue(0);
      // Write double value.
      Write<double>(object->value.as_double);
      break;
    case Dart_CObject::kString: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(kOneByteStringCid);
      WriteIntptrValue(0);
      // Write string length, hash and content
      char* str = object->value.as_string;
      intptr_t len = strlen(str);
      WriteSmi(len);
      WriteSmi(0);  // TODO(sgjesse): Hash - not written.
      for (intptr_t i = 0; i < len; i++) {
        Write<uint8_t>(str[i]);
      }
      break;
    }
    case Dart_CObject::kUint8Array: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(kUint8ArrayCid);
      WriteIntptrValue(0);
      uint8_t* bytes = object->value.as_byte_array.values;
      intptr_t len = object->value.as_byte_array.length;
      WriteSmi(len);
      for (intptr_t i = 0; i < len; i++) {
        Write<uint8_t>(bytes[i]);
      }
      break;
    }
    case Dart_CObject::kExternalUint8Array: {
      // TODO(ager): we are writing C pointers into the message in
      // order to post external arrays through ports. We need to make
      // sure that messages containing pointers can never be posted
      // to other processes.

      // Write out serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tag information.
      WriteIndexedObject(kExternalUint8ArrayCid);
      WriteIntptrValue(0);
      int length = object->value.as_external_byte_array.length;
      uint8_t* data = object->value.as_external_byte_array.data;
      void* peer = object->value.as_external_byte_array.peer;
      Dart_PeerFinalizer callback =
          object->value.as_external_byte_array.callback;
      WriteSmi(length);
      WriteIntptrValue(reinterpret_cast<intptr_t>(data));
      WriteIntptrValue(reinterpret_cast<intptr_t>(peer));
      WriteIntptrValue(reinterpret_cast<intptr_t>(callback));
      break;
    }
    default:
      UNREACHABLE();
  }
}


void ApiMessageWriter::WriteCMessage(Dart_CObject* object) {
  WriteCObject(object);
  // Write out all objects that were added to the forward list and have
  // not been serialized yet. These would typically be fields of arrays.
  // NOTE: The forward list might grow as we process the list.
  for (intptr_t i = 0; i < forward_id_; i++) {
    WriteForwardedCObject(forward_list_[i]);
  }
  UnmarkAllCObjects(object);
}

}  // namespace dart
