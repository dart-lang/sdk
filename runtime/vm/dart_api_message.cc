// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_message.h"
#include "vm/object.h"
#include "vm/snapshot_ids.h"
#include "vm/symbols.h"
#include "vm/unicode.h"

namespace dart {

static const int kNumInitialReferences = 4;

ApiMessageReader::ApiMessageReader(const uint8_t* buffer,
                                   intptr_t length,
                                   ReAlloc alloc)
    : BaseReader(buffer, length),
      alloc_(alloc),
      backward_references_(kNumInitialReferences),
      vm_symbol_references_(NULL) {
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


static int GetTypedDataSizeInBytes(Dart_CObject::TypedDataType type) {
  switch (type) {
    case Dart_CObject::kInt8Array:
    case Dart_CObject::kUint8Array:
    case Dart_CObject::kUint8ClampedArray:
      return 1;
    case Dart_CObject::kInt16Array:
    case Dart_CObject::kUint16Array:
      return 2;
    case Dart_CObject::kInt32Array:
    case Dart_CObject::kUint32Array:
    case Dart_CObject::kFloat32Array:
      return 4;
    case Dart_CObject::kInt64Array:
    case Dart_CObject::kUint64Array:
    case Dart_CObject::kFloat64Array:
      return 8;
    default:
      break;
  }
  UNREACHABLE();
  return -1;
}


Dart_CObject* ApiMessageReader::AllocateDartCObjectTypedData(
    Dart_CObject::TypedDataType type, intptr_t length) {
  // Allocate a Dart_CObject structure followed by an array of bytes
  // for the byte array content. The pointer to the byte array content
  // is set up to this area.
  intptr_t length_in_bytes = GetTypedDataSizeInBytes(type) * length;
  Dart_CObject* value =
      reinterpret_cast<Dart_CObject*>(
          alloc_(NULL, 0, sizeof(Dart_CObject) + length_in_bytes));
  ASSERT(value != NULL);
  value->type = Dart_CObject::kTypedData;
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


Dart_CObject_Internal* ApiMessageReader::AllocateDartCObjectInternal(
    Dart_CObject_Internal::Type type) {
  Dart_CObject_Internal* value =
      reinterpret_cast<Dart_CObject_Internal*>(
          alloc_(NULL, 0, sizeof(Dart_CObject_Internal)));
  ASSERT(value != NULL);
  value->type = static_cast<Dart_CObject::Type>(type);
  return value;
}


Dart_CObject_Internal* ApiMessageReader::AllocateDartCObjectClass() {
  return AllocateDartCObjectInternal(Dart_CObject_Internal::kClass);
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


static Dart_CObject::TypedDataType GetTypedDataTypeFromView(
    Dart_CObject_Internal* object) {
  struct {
    const char* name;
    Dart_CObject::TypedDataType type;
  } view_class_names[] = {
    { "_Int8ArrayView", Dart_CObject::kInt8Array },
    { "_Uint8ArrayView", Dart_CObject::kUint8Array },
    { "_Uint8ClampedArrayView", Dart_CObject::kUint8ClampedArray },
    { "_Int16ArrayView", Dart_CObject::kInt16Array },
    { "_Uint16ArrayView", Dart_CObject::kUint16Array },
    { "_Int32ArrayView", Dart_CObject::kInt32Array },
    { "_Uint32ArrayView", Dart_CObject::kUint32Array },
    { "_Int64ArrayView", Dart_CObject::kInt64Array },
    { "_Uint64ArrayView", Dart_CObject::kUint64Array },
    { "_ByteDataView", Dart_CObject::kUint8Array },
    { "_Float32ArrayView", Dart_CObject::kFloat32Array },
    { "_Float64ArrayView", Dart_CObject::kFloat64Array },
    { NULL, Dart_CObject::kNumberOfTypedDataTypes },
  };

  char* library_url =
      object->cls->internal.as_class.library_url->value.as_string;
  char* class_name =
      object->cls->internal.as_class.class_name->value.as_string;
  if (strcmp("dart:typeddata", library_url) != 0) {
    return Dart_CObject::kNumberOfTypedDataTypes;
  }
  int i = 0;
  while (view_class_names[i].name != NULL) {
    if (strncmp(view_class_names[i].name,
                class_name,
                strlen(view_class_names[i].name)) == 0) {
      return view_class_names[i].type;
    }
    i++;
  }
  return Dart_CObject::kNumberOfTypedDataTypes;
}


Dart_CObject* ApiMessageReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();
  intptr_t tags = ReadIntptrValue();
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
             static_cast<Dart_CObject::Type>(Dart_CObject_Internal::kClass));
    }
    ASSERT(object->type ==
           static_cast<Dart_CObject::Type>(
               Dart_CObject_Internal::kUninitialized));

    // Handle typed data views.
    Dart_CObject::TypedDataType type = GetTypedDataTypeFromView(object);
    if (type != Dart_CObject::kNumberOfTypedDataTypes) {
      object->type =
          static_cast<Dart_CObject::Type>(Dart_CObject_Internal::kView);
      ReadObjectImpl();  // Skip type arguments.
      object->internal.as_view.buffer = ReadObjectImpl();
      object->internal.as_view.offset_in_bytes = ReadSmiValue();
      object->internal.as_view.length = ReadSmiValue();
      ReadObjectImpl();  // Skip last field.

      // The buffer is fully read now as typed data objects are
      // serialized in-line.
      Dart_CObject* buffer = object->internal.as_view.buffer;
      ASSERT(buffer->type == Dart_CObject::kTypedData);

      // Now turn the view into a byte array.
      object->type = Dart_CObject::kTypedData;
      object->value.as_typed_data.type = type;
      object->value.as_typed_data.length =
          object->internal.as_view.length *
          GetTypedDataSizeInBytes(type);
      object->value.as_typed_data.values =
          buffer->value.as_typed_data.values +
          object->internal.as_view.offset_in_bytes;
    } else {
      // TODO(sgjesse): Handle other instances. Currently this will
      // skew the reading as the fields of the instance is not read.
    }
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
  ASSERT(Symbols::IsVMSymbolId(object_id));
  intptr_t symbol_id = object_id - kMaxPredefinedObjectIds;
  Dart_CObject* object;
  if (vm_symbol_references_ != NULL &&
      (object = vm_symbol_references_[symbol_id]) != NULL) {
    return object;
  }

  if (vm_symbol_references_ == NULL) {
    intptr_t size =
        (sizeof(*vm_symbol_references_) * Symbols::kMaxPredefinedId);
    vm_symbol_references_ =
        reinterpret_cast<Dart_CObject**>(alloc_(NULL, 0, size));
    memset(vm_symbol_references_, 0, size);
  }

  RawOneByteString* str =
      reinterpret_cast<RawOneByteString*>(Symbols::GetVMSymbol(object_id));
  intptr_t len = Smi::Value(str->ptr()->length_);
  object = AllocateDartCObjectString(len);
  char* p = object->value.as_string;
  memmove(p, str->ptr()->data_, len);
  p[len] = '\0';
  ASSERT(vm_symbol_references_[symbol_id] == NULL);
  vm_symbol_references_[symbol_id] = object;
  return object;
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
    return ReadVMIsolateObject(value);
  }
  if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();

  // Reading of regular dart instances has limited support in order to
  // read typed data views.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    intptr_t object_id = SerializedHeaderData::decode(value);
    Dart_CObject_Internal* object =
        AllocateDartCObjectInternal(Dart_CObject_Internal::kUninitialized);
    AddBackRef(object_id, object, kIsNotDeserialized);
    // Read class of object.
    object->cls = reinterpret_cast<Dart_CObject_Internal*>(ReadObjectImpl());
    ASSERT(object->cls->type ==
           static_cast<Dart_CObject::Type>(Dart_CObject_Internal::kClass));
    return object;
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
  if (Symbols::IsVMSymbolId(object_id)) {
    return ReadVMSymbol(object_id);
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
             Dart_CObject::kString);
      object->internal.as_class.class_name = ReadObjectImpl();
      ASSERT(object->internal.as_class.class_name->type ==
             Dart_CObject::kString);
      return object;
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
      uint8_t *latin1 =
          reinterpret_cast<uint8_t*>(::malloc(len * sizeof(uint8_t)));
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
      ::free(latin1);
      return object;
    }
    case kTwoByteStringCid: {
      intptr_t len = ReadSmiValue();
      intptr_t hash = ReadSmiValue();
      USE(hash);
      uint16_t *utf16 =
          reinterpret_cast<uint16_t*>(::malloc(len * sizeof(uint16_t)));
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
      ::free(utf16);
      return object;
    }

#define READ_TYPED_DATA(type, ctype)                                           \
    {                                                                          \
      intptr_t len = ReadSmiValue();                                           \
      Dart_CObject* object =                                                   \
          AllocateDartCObjectTypedData(Dart_CObject::k##type##Array, len);     \
      AddBackRef(object_id, object, kIsDeserialized);                          \
      if (len > 0) {                                                           \
        ctype* p =                                                             \
            reinterpret_cast<ctype*>(object->value.as_typed_data.values);      \
        for (intptr_t i = 0; i < len; i++) {                                   \
          p[i] = Read<ctype>();                                                \
        }                                                                      \
      }                                                                        \
      return object;                                                           \
    }                                                                          \

    case kTypedDataInt8ArrayCid:
    case kExternalTypedDataInt8ArrayCid:
      READ_TYPED_DATA(Int8, int8_t);

    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
      READ_TYPED_DATA(Uint8, uint8_t);

    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      READ_TYPED_DATA(Uint8Clamped, uint8_t);

    case kTypedDataInt16ArrayCid:
    case kExternalTypedDataInt16ArrayCid:
      READ_TYPED_DATA(Int16, int16_t);

    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint16ArrayCid:
      READ_TYPED_DATA(Uint16, uint16_t);

    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      READ_TYPED_DATA(Int32, int32_t);

    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      READ_TYPED_DATA(Uint32, uint32_t);

    case kTypedDataInt64ArrayCid:
    case kExternalTypedDataInt64ArrayCid:
      READ_TYPED_DATA(Int64, int64_t);

    case kTypedDataUint64ArrayCid:
    case kExternalTypedDataUint64ArrayCid:
      READ_TYPED_DATA(Uint64, uint64_t);

    case kTypedDataFloat32ArrayCid:
    case kExternalTypedDataFloat32ArrayCid:
      READ_TYPED_DATA(Float32, float);

    case kTypedDataFloat64ArrayCid:
    case kExternalTypedDataFloat64ArrayCid:
      READ_TYPED_DATA(Float64, double);

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
      Dart_CObject* value = AllocateDartCObjectUnsupported();
      AddBackRef(object_id, value, kIsDeserialized);
      return value;
  }
}


Dart_CObject* ApiMessageReader::ReadIndexedObject(intptr_t object_id) {
  if (object_id == kDynamicType ||
      object_id == kDoubleType ||
      object_id == kIntType ||
      object_id == kBoolType ||
      object_id == kStringType) {
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
    return ReadVMIsolateObject(value);
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


bool ApiMessageWriter::WriteCObject(Dart_CObject* object) {
  if (IsCObjectMarked(object)) {
    intptr_t object_id = GetMarkedCObjectMark(object);
    WriteIndexedObject(kMaxPredefinedObjectIds + object_id);
    return true;
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
    return true;
  }
  return WriteCObjectInlined(object, type);
}


bool ApiMessageWriter::WriteForwardedCObject(Dart_CObject* object) {
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
    bool success = WriteCObjectRef(object->value.as_array.values[i]);
    if (!success) return false;
  }
  return true;
}


bool ApiMessageWriter::WriteCObjectInlined(Dart_CObject* object,
                                           Dart_CObject::Type type) {
  switch (type) {
    case Dart_CObject::kNull:
      WriteNullObject();
      break;
    case Dart_CObject::kBool:
      if (object->value.as_bool) {
        WriteVMIsolateObject(kTrueValue);
      } else {
        WriteVMIsolateObject(kFalseValue);
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
      const uint8_t* utf8_str =
          reinterpret_cast<const uint8_t*>(object->value.as_string);
      intptr_t utf8_len = strlen(object->value.as_string);
      if (!Utf8::IsValid(utf8_str, utf8_len)) {
        return false;
      }

      Utf8::Type type;
      intptr_t len = Utf8::CodeUnitCount(utf8_str, utf8_len, &type);

      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      WriteIndexedObject(type == Utf8::kLatin1 ? kOneByteStringCid
                                               : kTwoByteStringCid);
      WriteIntptrValue(0);
      // Write string length, hash and content
      WriteSmi(len);
      WriteSmi(0);  // TODO(sgjesse): Hash - not written.
      if (type == Utf8::kLatin1) {
        uint8_t* latin1_str =
            reinterpret_cast<uint8_t*>(::malloc(len * sizeof(uint8_t)));
        bool success = Utf8::DecodeToLatin1(utf8_str,
                                            utf8_len,
                                            latin1_str,
                                            len);
        ASSERT(success);
        for (intptr_t i = 0; i < len; i++) {
          Write<uint8_t>(latin1_str[i]);
        }
        ::free(latin1_str);
      } else {
        uint16_t* utf16_str =
            reinterpret_cast<uint16_t*>(::malloc(len * sizeof(uint16_t)));
        bool success = Utf8::DecodeToUTF16(utf8_str, utf8_len, utf16_str, len);
        ASSERT(success);
        for (intptr_t i = 0; i < len; i++) {
          Write<uint16_t>(utf16_str[i]);
        }
        ::free(utf16_str);
      }
      break;
    }
    case Dart_CObject::kTypedData: {
      // Write out the serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tags information.
      intptr_t class_id;
      switch (object->value.as_typed_data.type) {
        case Dart_CObject::kInt8Array:
          class_id = kTypedDataInt8ArrayCid;
          break;
        case Dart_CObject::kUint8Array:
          class_id = kTypedDataUint8ArrayCid;
          break;
        default:
          class_id = kTypedDataUint8ArrayCid;
          UNIMPLEMENTED();
      }

      WriteIndexedObject(class_id);
      WriteIntptrValue(RawObject::ClassIdTag::update(class_id, 0));
      uint8_t* bytes = object->value.as_typed_data.values;
      intptr_t len = object->value.as_typed_data.length;
      WriteSmi(len);
      for (intptr_t i = 0; i < len; i++) {
        Write<uint8_t>(bytes[i]);
      }
      break;
    }
    case Dart_CObject::kExternalTypedData: {
      // TODO(ager): we are writing C pointers into the message in
      // order to post external arrays through ports. We need to make
      // sure that messages containing pointers can never be posted
      // to other processes.

      // Write out serialization header value for this object.
      WriteInlinedHeader(object);
      // Write out the class and tag information.
      WriteIndexedObject(kExternalTypedDataUint8ArrayCid);
      WriteIntptrValue(RawObject::ClassIdTag::update(
          kExternalTypedDataUint8ArrayCid, 0));
      int length = object->value.as_external_typed_data.length;
      uint8_t* data = object->value.as_external_typed_data.data;
      void* peer = object->value.as_external_typed_data.peer;
      Dart_WeakPersistentHandleFinalizer callback =
          object->value.as_external_typed_data.callback;
      WriteSmi(length);
      WriteIntptrValue(reinterpret_cast<intptr_t>(data));
      WriteIntptrValue(reinterpret_cast<intptr_t>(peer));
      WriteIntptrValue(reinterpret_cast<intptr_t>(callback));
      break;
    }
    default:
      UNREACHABLE();
  }

  return true;
}


bool ApiMessageWriter::WriteCMessage(Dart_CObject* object) {
  bool success = WriteCObject(object);
  if (!success) {
    UnmarkAllCObjects(object);
    return false;
  }
  // Write out all objects that were added to the forward list and have
  // not been serialized yet. These would typically be fields of arrays.
  // NOTE: The forward list might grow as we process the list.
  for (intptr_t i = 0; i < forward_id_; i++) {
    success = WriteForwardedCObject(forward_list_[i]);
    if (!success) {
      UnmarkAllCObjects(object);
      return false;
    }
  }
  UnmarkAllCObjects(object);
  return true;
}

}  // namespace dart
