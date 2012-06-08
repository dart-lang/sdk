// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_message.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

// TODO(sgjesse): When the external message format is done these
// duplicate constants from snapshot.cc should be removed.
enum {
  kInstanceId = ObjectStore::kMaxId,
  kMaxPredefinedObjectIds,
};
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
  SerializedHeaderType header_type = SerializedHeaderTag::decode(class_header);
  ASSERT(header_type == kObjectId);
  intptr_t header_value = SerializedHeaderData::decode(class_header);
  return header_value;
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


Dart_CObject* ApiMessageReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();
  intptr_t tags = ReadIntptrValue();
  USE(tags);
  intptr_t class_id;

  // Reading of regular dart instances is not supported.
  if (SerializedHeaderData::decode(class_header) == kInstanceId) {
    return AllocateDartCObjectUnsupported();
  }

  ASSERT((class_header & kSmiTagMask) != 0);
  class_id = LookupInternalClass(class_header);
  switch (class_id) {
    case Object::kClassClass: {
      return AllocateDartCObjectUnsupported();
    }
    case Object::kTypeArgumentsClass: {
      // TODO(sjesse): Remove this when message serialization format is
      // updated (currently length is leaked).
      Dart_CObject* value = &type_arguments_marker;
      AddBackwardReference(object_id, value);
      Dart_CObject* length = ReadObject();
      ASSERT(length->type == Dart_CObject::kInt32);
      for (int i = 0; i < length->value.as_int32; i++) {
        Dart_CObject* type = ReadObject();
        if (type != &dynamic_type_marker) {
          return AllocateDartCObjectUnsupported();
        }
      }
      return value;
    }
    case Object::kTypeParameterClass: {
      // TODO(sgjesse): Fix this workaround ignoring the type parameter.
      Dart_CObject* value = &dynamic_type_marker;
      AddBackwardReference(object_id, value);
      intptr_t index = ReadIntptrValue();
      USE(index);
      intptr_t token_index = ReadIntptrValue();
      USE(token_index);
      int8_t type_state = Read<int8_t>();
      USE(type_state);
      Dart_CObject* parameterized_class = ReadObject();
      // The type parameter is finalized, therefore parameterized_class is null.
      ASSERT(parameterized_class->type == Dart_CObject::kNull);
      Dart_CObject* name = ReadObject();
      ASSERT(name->type == Dart_CObject::kString);
      return value;
    }
    case ObjectStore::kArrayClass: {
      intptr_t len = ReadSmiValue();
      Dart_CObject* value = AllocateDartCObjectArray(len);
      AddBackwardReference(object_id, value);
      // Skip type arguments.
      // TODO(sjesse): Remove this when message serialization format is
      // updated (currently type_arguments is leaked).
      Dart_CObject* type_arguments = ReadObject();
      if (type_arguments != &type_arguments_marker &&
          type_arguments->type != Dart_CObject::kNull) {
        return AllocateDartCObjectUnsupported();
      }
      for (int i = 0; i < len; i++) {
        value->value.as_array.values[i] = ReadObject();
      }
      return value;
    }
    case ObjectStore::kMintClass: {
      int64_t value = Read<int64_t>();
      Dart_CObject* object;
      if (kMinInt32 <= value && value <= kMaxInt32) {
        object = AllocateDartCObjectInt32(value);
      } else {
        object = AllocateDartCObjectInt64(value);
      }
      AddBackwardReference(object_id, object);
      return object;
    }
    case ObjectStore::kBigintClass: {
      // Read in the hex string representation of the bigint.
      intptr_t len = ReadIntptrValue();
      Dart_CObject* object = AllocateDartCObjectBigint(len);
      AddBackwardReference(object_id, object);
      char* p = object->value.as_bigint;
      for (intptr_t i = 0; i < len; i++) {
        p[i] = Read<uint8_t>();
      }
      p[len] = '\0';
      return object;
    }
    case ObjectStore::kDoubleClass: {
      // Read the double value for the object.
      Dart_CObject* object = AllocateDartCObjectDouble(Read<double>());
      AddBackwardReference(object_id, object);
      return object;
    }
    case ObjectStore::kOneByteStringClass: {
      intptr_t len = ReadSmiValue();
      intptr_t hash = ReadSmiValue();
      USE(hash);
      Dart_CObject* object = AllocateDartCObjectString(len);
      AddBackwardReference(object_id, object);
      char* p = object->value.as_string;
      for (intptr_t i = 0; i < len; i++) {
        p[i] = Read<uint8_t>();
      }
      p[len] = '\0';
      return object;
    }
    case ObjectStore::kTwoByteStringClass:
      // Two byte strings not supported.
      return AllocateDartCObjectUnsupported();
    case ObjectStore::kFourByteStringClass:
      // Four byte strings not supported.
      return AllocateDartCObjectUnsupported();
    case ObjectStore::kUint8ArrayClass: {
      intptr_t len = ReadSmiValue();
      Dart_CObject* object = AllocateDartCObjectUint8Array(len);
      AddBackwardReference(object_id, object);
      if (len > 0) {
        uint8_t* p = object->value.as_byte_array.values;
        for (intptr_t i = 0; i < len; i++) {
          p[i] = Read<uint8_t>();
        }
      }
      return object;
    }
    default:
      // Everything else not supported.
      return AllocateDartCObjectUnsupported();
  }
}


Dart_CObject* ApiMessageReader::ReadIndexedObject(intptr_t object_id) {
  if (object_id == Object::kNullObject) {
    return AllocateDartCObjectNull();
  }
  if (object_id == ObjectStore::kTrueValue) {
    return AllocateDartCObjectBool(true);
  }
  if (object_id == ObjectStore::kFalseValue) {
    return AllocateDartCObjectBool(false);
  }
  if (object_id == ObjectStore::kDynamicType ||
      object_id == ObjectStore::kDoubleInterface ||
      object_id == ObjectStore::kIntInterface ||
      object_id == ObjectStore::kBoolInterface ||
      object_id == ObjectStore::kStringInterface) {
    // Always return dynamic type (this is only a marker).
    return &dynamic_type_marker;
  }
  intptr_t index = object_id - kMaxPredefinedObjectIds;
  ASSERT((0 <= index) && (index < backward_references_.length()));
  ASSERT(backward_references_[index] != NULL);
  return backward_references_[index];
}


Dart_CObject* ApiMessageReader::ReadObjectImpl(intptr_t header) {
  SerializedHeaderType header_type = SerializedHeaderTag::decode(header);
  intptr_t header_value = SerializedHeaderData::decode(header);

  if (header_type == kObjectId) {
    return ReadIndexedObject(header_value);
  }
  ASSERT(header_type == kInlined);
  return ReadInlinedObject(header_value);
}


Dart_CObject* ApiMessageReader::ReadObject() {
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
  return ReadObjectImpl(value);
}


void ApiMessageReader::AddBackwardReference(intptr_t id, Dart_CObject* obj) {
  ASSERT((id - kMaxPredefinedObjectIds) == backward_references_.length());
  backward_references_.Add(obj);
}

void ApiMessageWriter::WriteMessage(intptr_t field_count, intptr_t *data) {
  // Write out the serialization header value for this object.
  WriteSerializationMarker(kInlined, kMaxPredefinedObjectIds);

  // Write out the class and tags information.
  WriteObjectHeader(ObjectStore::kArrayClass, 0);

  // Write out the length field.
  Write<RawObject*>(Smi::New(field_count));

  // Write out the type arguments.
  WriteIndexedObject(Object::kNullObject);

  // Write out the individual Smis.
  for (int i = 0; i < field_count; i++) {
    Write<RawObject*>(Integer::New(data[i]));
  }

  FinalizeBuffer();
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


void ApiMessageWriter::WriteSmi(int64_t value) {
  ASSERT(Smi::IsValid64(value));
  Write<RawObject*>(Smi::New(value));
}


void ApiMessageWriter::WriteMint(Dart_CObject* object, int64_t value) {
  ASSERT(!Smi::IsValid64(value));
  // Write out the serialization header value for mint object.
  WriteInlinedHeader(object);
  // Write out the class and tags information.
  WriteObjectHeader(ObjectStore::kMintClass, 0);
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
  WriteSerializationMarker(kInlined, kMaxPredefinedObjectIds + object_id_);
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

  switch (object->type) {
    case Dart_CObject::kNull:
      WriteIndexedObject(Object::kNullObject);
      break;
    case Dart_CObject::kBool:
      if (object->value.as_bool) {
        WriteIndexedObject(ObjectStore::kTrueValue);
      } else {
        WriteIndexedObject(ObjectStore::kFalseValue);
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
      WriteObjectHeader(ObjectStore::kBigintClass, 0);
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
      WriteObjectHeader(ObjectStore::kDoubleClass, 0);
      // Write double value.
      Write<double>(object->value.as_double);
      break;
    case Dart_CObject::kString: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteObjectHeader(ObjectStore::kOneByteStringClass, 0);
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
    case Dart_CObject::kArray: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteObjectHeader(ObjectStore::kArrayClass, 0);
      WriteSmi(object->value.as_array.length);
      // Write out the type arguments.
      WriteIndexedObject(Object::kNullObject);
      // Write out array elements.
      for (int i = 0; i < object->value.as_array.length; i++) {
        WriteCObject(object->value.as_array.values[i]);
      }
      break;
    }
    case Dart_CObject::kUint8Array: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteObjectHeader(ObjectStore::kUint8ArrayClass, 0);
      uint8_t* bytes = object->value.as_byte_array.values;
      intptr_t len = object->value.as_byte_array.length;
      WriteSmi(len);
      for (intptr_t i = 0; i < len; i++) {
        Write<uint8_t>(bytes[i]);
      }
      break;
    }
    default:
      UNREACHABLE();
  }
}


void ApiMessageWriter::WriteCMessage(Dart_CObject* object) {
  WriteCObject(object);
  UnmarkAllCObjects(object);
  FinalizeBuffer();
}

}  // namespace dart
