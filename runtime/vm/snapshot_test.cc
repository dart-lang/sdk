// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "platform/unicode.h"
#include "vm/class_finalizer.h"
#include "vm/clustered_snapshot.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/debugger_api_impl_test.h"
#include "vm/flags.h"
#include "vm/malloc_hooks.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
#include "vm/timer.h"
#include "vm/unit_test.h"

namespace dart {

// Check if serialized and deserialized objects are equal.
static bool Equals(const Object& expected, const Object& actual) {
  if (expected.IsNull()) {
    return actual.IsNull();
  }
  if (expected.IsSmi()) {
    if (actual.IsSmi()) {
      return expected.raw() == actual.raw();
    }
    return false;
  }
  if (expected.IsDouble()) {
    if (actual.IsDouble()) {
      Double& dbl1 = Double::Handle();
      Double& dbl2 = Double::Handle();
      dbl1 ^= expected.raw();
      dbl2 ^= actual.raw();
      return dbl1.value() == dbl2.value();
    }
    return false;
  }
  if (expected.IsBool()) {
    if (actual.IsBool()) {
      return expected.raw() == actual.raw();
    }
    return false;
  }
  return false;
}

// Compare two Dart_CObject object graphs rooted in first and
// second. The second graph will be destroyed by this operation no matter
// whether the graphs are equal or not.
static void CompareDartCObjects(Dart_CObject* first, Dart_CObject* second) {
  // Return immediately if entering a cycle.
  if (second->type == Dart_CObject_kNumberOfTypes) return;

  EXPECT_NE(first, second);
  EXPECT_EQ(first->type, second->type);
  switch (first->type) {
    case Dart_CObject_kNull:
      // Nothing more to compare.
      break;
    case Dart_CObject_kBool:
      EXPECT_EQ(first->value.as_bool, second->value.as_bool);
      break;
    case Dart_CObject_kInt32:
      EXPECT_EQ(first->value.as_int32, second->value.as_int32);
      break;
    case Dart_CObject_kInt64:
      EXPECT_EQ(first->value.as_int64, second->value.as_int64);
      break;
    case Dart_CObject_kDouble:
      EXPECT_EQ(first->value.as_double, second->value.as_double);
      break;
    case Dart_CObject_kString:
      EXPECT_STREQ(first->value.as_string, second->value.as_string);
      break;
    case Dart_CObject_kTypedData:
      EXPECT_EQ(first->value.as_typed_data.length,
                second->value.as_typed_data.length);
      for (int i = 0; i < first->value.as_typed_data.length; i++) {
        EXPECT_EQ(first->value.as_typed_data.values[i],
                  second->value.as_typed_data.values[i]);
      }
      break;
    case Dart_CObject_kArray:
      // Use invalid type as a visited marker to avoid infinite
      // recursion on graphs with cycles.
      second->type = Dart_CObject_kNumberOfTypes;
      EXPECT_EQ(first->value.as_array.length, second->value.as_array.length);
      for (int i = 0; i < first->value.as_array.length; i++) {
        CompareDartCObjects(first->value.as_array.values[i],
                            second->value.as_array.values[i]);
      }
      break;
    case Dart_CObject_kCapability:
      EXPECT_EQ(first->value.as_capability.id, second->value.as_capability.id);
      break;
    default:
      EXPECT(false);
  }
}

static void CheckEncodeDecodeMessage(Dart_CObject* root) {
  // Encode and decode the message.
  ApiMessageWriter writer;
  std::unique_ptr<Message> message =
      writer.WriteCMessage(root, ILLEGAL_PORT, Message::kNormalPriority);

  ApiMessageReader api_reader(message.get());
  Dart_CObject* new_root = api_reader.ReadMessage();

  // Check that the two messages are the same.
  CompareDartCObjects(root, new_root);
}

static void ExpectEncodeFail(Dart_CObject* root) {
  ApiMessageWriter writer;
  std::unique_ptr<Message> message =
      writer.WriteCMessage(root, ILLEGAL_PORT, Message::kNormalPriority);
  EXPECT(message == nullptr);
}

ISOLATE_UNIT_TEST_CASE(SerializeNull) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Object& null_object = Object::Handle();
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(null_object, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(null_object, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kNull, root->type);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeSmi1) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Smi& smi = Smi::Handle(Smi::New(124));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(smi, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeSmi2) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Smi& smi = Smi::Handle(Smi::New(-1));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(smi, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}

Dart_CObject* SerializeAndDeserializeMint(const Mint& mint) {
  // Write snapshot with object content.
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(mint, ILLEGAL_PORT, Message::kNormalPriority);

  {
    // Switch to a regular zone, where VM handle allocation is allowed.
    Thread* thread = Thread::Current();
    StackZone zone(thread);
    // Read object back from the snapshot.
    MessageSnapshotReader reader(message.get(), thread);
    const Object& serialized_object = Object::Handle(reader.ReadObject());
    EXPECT(serialized_object.IsMint());
  }

  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  CheckEncodeDecodeMessage(root);
  return root;
}

void CheckMint(int64_t value) {
  ApiNativeScope scope;
  StackZone zone(Thread::Current());

  Mint& mint = Mint::Handle();
  mint ^= Integer::New(value);
  Dart_CObject* mint_cobject = SerializeAndDeserializeMint(mint);
// On 64-bit platforms mints always require 64-bits as the smi range
// here covers most of the 64-bit range. On 32-bit platforms the smi
// range covers most of the 32-bit range and values outside that
// range are also represented as mints.
#if defined(ARCH_IS_64_BIT)
  EXPECT_EQ(Dart_CObject_kInt64, mint_cobject->type);
  EXPECT_EQ(value, mint_cobject->value.as_int64);
#else
  if (kMinInt32 < value && value < kMaxInt32) {
    EXPECT_EQ(Dart_CObject_kInt32, mint_cobject->type);
    EXPECT_EQ(value, mint_cobject->value.as_int32);
  } else {
    EXPECT_EQ(Dart_CObject_kInt64, mint_cobject->type);
    EXPECT_EQ(value, mint_cobject->value.as_int64);
  }
#endif
}

ISOLATE_UNIT_TEST_CASE(SerializeMints) {
  // Min positive mint.
  CheckMint(Smi::kMaxValue + 1);
  // Min positive mint + 1.
  CheckMint(Smi::kMaxValue + 2);
  // Max negative mint.
  CheckMint(Smi::kMinValue - 1);
  // Max negative mint - 1.
  CheckMint(Smi::kMinValue - 2);
  // Max positive mint.
  CheckMint(kMaxInt64);
  // Max positive mint - 1.
  CheckMint(kMaxInt64 - 1);
  // Min negative mint.
  CheckMint(kMinInt64);
  // Min negative mint + 1.
  CheckMint(kMinInt64 + 1);
}

ISOLATE_UNIT_TEST_CASE(SerializeDouble) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Double& dbl = Double::Handle(Double::New(101.29));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(dbl, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(dbl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kDouble, root->type);
  EXPECT_EQ(dbl.value(), root->value.as_double);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeTrue) {
  StackZone zone(thread);

  // Write snapshot with true object.
  const Bool& bl = Bool::True();
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(bl, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  fprintf(stderr, "%s / %s\n", bl.ToCString(), serialized_object.ToCString());

  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kBool, root->type);
  EXPECT_EQ(true, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeFalse) {
  StackZone zone(thread);

  // Write snapshot with false object.
  const Bool& bl = Bool::False();
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(bl, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kBool, root->type);
  EXPECT_EQ(false, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeCapability) {
  // Write snapshot with object content.
  const Capability& capability = Capability::Handle(Capability::New(12345));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(capability, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  Capability& obj = Capability::Handle();
  obj ^= reader.ReadObject();

  EXPECT_EQ(static_cast<uint64_t>(12345), obj.Id());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kCapability, root->type);
  int64_t id = root->value.as_capability.id;
  EXPECT_EQ(12345, id);
  CheckEncodeDecodeMessage(root);
}

#define TEST_ROUND_TRIP_IDENTICAL(object)                                      \
  {                                                                            \
    MessageWriter writer(true);                                                \
    std::unique_ptr<Message> message = writer.WriteMessage(                    \
        Object::Handle(object), ILLEGAL_PORT, Message::kNormalPriority);       \
    MessageSnapshotReader reader(message.get(), thread);                       \
    EXPECT(reader.ReadObject() == object);                                     \
  }

ISOLATE_UNIT_TEST_CASE(SerializeSingletons) {
  TEST_ROUND_TRIP_IDENTICAL(Object::class_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::type_arguments_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::function_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::field_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::script_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::library_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::code_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::instructions_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::pc_descriptors_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::exception_handlers_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::context_class());
  TEST_ROUND_TRIP_IDENTICAL(Object::context_scope_class());
}

static void TestString(const char* cstr) {
  Thread* thread = Thread::Current();
  EXPECT(Utf8::IsValid(reinterpret_cast<const uint8_t*>(cstr), strlen(cstr)));
  // Write snapshot with object content.
  String& str = String::Handle(String::New(cstr));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(str, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  String& serialized_str = String::Handle();
  serialized_str ^= reader.ReadObject();
  EXPECT(str.Equals(serialized_str));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kString, root->type);
  EXPECT_STREQ(cstr, root->value.as_string);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeString) {
  TestString("This string shall be serialized");
  TestString("æøå");  // This file is UTF-8 encoded.
  const char* data =
      "\x01"
      "\x7F"
      "\xC2\x80"       // U+0080
      "\xDF\xBF"       // U+07FF
      "\xE0\xA0\x80"   // U+0800
      "\xEF\xBF\xBF";  // U+FFFF

  TestString(data);
  // TODO(sgjesse): Add tests with non-BMP characters.
}

ISOLATE_UNIT_TEST_CASE(SerializeArray) {
  // Write snapshot with object content.
  const int kArrayLength = 10;
  Array& array = Array::Handle(Array::New(kArrayLength));
  Smi& smi = Smi::Handle();
  for (int i = 0; i < kArrayLength; i++) {
    smi ^= Smi::New(i);
    array.SetAt(i, smi);
  }
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(array, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.CanonicalizeEquals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = root->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject_kInt32, element->type);
    EXPECT_EQ(i, element->value.as_int32);
  }
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeArrayWithTypeArgument) {
  // Write snapshot with object content.
  const int kArrayLength = 10;
  Array& array =
      Array::Handle(Array::New(kArrayLength, Type::Handle(Type::ObjectType())));

  Smi& smi = Smi::Handle();
  for (int i = 0; i < kArrayLength; i++) {
    smi ^= Smi::New(i);
    array.SetAt(i, smi);
  }
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(array, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.CanonicalizeEquals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = root->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject_kInt32, element->type);
    EXPECT_EQ(i, element->value.as_int32);
  }
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(FailSerializeLargeArray) {
  Dart_CObject root;
  root.type = Dart_CObject_kArray;
  root.value.as_array.length = Array::kMaxElements + 1;
  root.value.as_array.values = NULL;
  ExpectEncodeFail(&root);
}

TEST_CASE(FailSerializeLargeNestedArray) {
  Dart_CObject parent;
  Dart_CObject child;
  Dart_CObject* values[1] = {&child};

  parent.type = Dart_CObject_kArray;
  parent.value.as_array.length = 1;
  parent.value.as_array.values = values;
  child.type = Dart_CObject_kArray;
  child.value.as_array.length = Array::kMaxElements + 1;
  ExpectEncodeFail(&parent);
}

TEST_CASE(FailSerializeLargeTypedDataInt8) {
  Dart_CObject root;
  root.type = Dart_CObject_kTypedData;
  root.value.as_typed_data.type = Dart_TypedData_kInt8;
  root.value.as_typed_data.length =
      TypedData::MaxElements(kTypedDataInt8ArrayCid) + 1;
  ExpectEncodeFail(&root);
}

TEST_CASE(FailSerializeLargeTypedDataUint8) {
  Dart_CObject root;
  root.type = Dart_CObject_kTypedData;
  root.value.as_typed_data.type = Dart_TypedData_kUint8;
  root.value.as_typed_data.length =
      TypedData::MaxElements(kTypedDataUint8ArrayCid) + 1;
  ExpectEncodeFail(&root);
}

TEST_CASE(FailSerializeLargeExternalTypedData) {
  Dart_CObject root;
  root.type = Dart_CObject_kExternalTypedData;
  root.value.as_typed_data.length =
      ExternalTypedData::MaxElements(kExternalTypedDataUint8ArrayCid) + 1;
  ExpectEncodeFail(&root);
}

ISOLATE_UNIT_TEST_CASE(SerializeEmptyArray) {
  // Write snapshot with object content.
  const int kArrayLength = 0;
  Array& array = Array::Handle(Array::New(kArrayLength));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(array, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.CanonicalizeEquals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  EXPECT(root->value.as_array.values == NULL);
  CheckEncodeDecodeMessage(root);
}

ISOLATE_UNIT_TEST_CASE(SerializeByteArray) {
  // Write snapshot with object content.
  const int kTypedDataLength = 256;
  TypedData& typed_data = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, kTypedDataLength));
  for (int i = 0; i < kTypedDataLength; i++) {
    typed_data.SetUint8(i, i);
  }
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(typed_data, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  TypedData& serialized_typed_data = TypedData::Handle();
  serialized_typed_data ^= reader.ReadObject();
  EXPECT(serialized_typed_data.IsTypedData());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kTypedData, root->type);
  EXPECT_EQ(kTypedDataLength, root->value.as_typed_data.length);
  for (int i = 0; i < kTypedDataLength; i++) {
    EXPECT(root->value.as_typed_data.values[i] == i);
  }
  CheckEncodeDecodeMessage(root);
}

#define TEST_TYPED_ARRAY(darttype, ctype)                                      \
  {                                                                            \
    StackZone zone(thread);                                                    \
    const int kArrayLength = 127;                                              \
    TypedData& array = TypedData::Handle(                                      \
        TypedData::New(kTypedData##darttype##ArrayCid, kArrayLength));         \
    intptr_t scale = array.ElementSizeInBytes();                               \
    for (int i = 0; i < kArrayLength; i++) {                                   \
      array.Set##darttype((i * scale), i);                                     \
    }                                                                          \
    MessageWriter writer(true);                                                \
    std::unique_ptr<Message> message =                                         \
        writer.WriteMessage(array, ILLEGAL_PORT, Message::kNormalPriority);    \
    MessageSnapshotReader reader(message.get(), thread);                       \
    TypedData& serialized_array = TypedData::Handle();                         \
    serialized_array ^= reader.ReadObject();                                   \
    for (int i = 0; i < kArrayLength; i++) {                                   \
      EXPECT_EQ(static_cast<ctype>(i),                                         \
                serialized_array.Get##darttype(i* scale));                     \
    }                                                                          \
  }

#define TEST_EXTERNAL_TYPED_ARRAY(darttype, ctype)                             \
  {                                                                            \
    StackZone zone(thread);                                                    \
    ctype data[] = {0, 11, 22, 33, 44, 55, 66, 77};                            \
    intptr_t length = ARRAY_SIZE(data);                                        \
    ExternalTypedData& array = ExternalTypedData::Handle(                      \
        ExternalTypedData::New(kExternalTypedData##darttype##ArrayCid,         \
                               reinterpret_cast<uint8_t*>(data), length));     \
    intptr_t scale = array.ElementSizeInBytes();                               \
    MessageWriter writer(true);                                                \
    std::unique_ptr<Message> message =                                         \
        writer.WriteMessage(array, ILLEGAL_PORT, Message::kNormalPriority);    \
    MessageSnapshotReader reader(message.get(), thread);                       \
    ExternalTypedData& serialized_array = ExternalTypedData::Handle();         \
    serialized_array ^= reader.ReadObject();                                   \
    for (int i = 0; i < length; i++) {                                         \
      EXPECT_EQ(static_cast<ctype>(data[i]),                                   \
                serialized_array.Get##darttype(i* scale));                     \
    }                                                                          \
  }

ISOLATE_UNIT_TEST_CASE(SerializeTypedArray) {
  TEST_TYPED_ARRAY(Int8, int8_t);
  TEST_TYPED_ARRAY(Uint8, uint8_t);
  TEST_TYPED_ARRAY(Int16, int16_t);
  TEST_TYPED_ARRAY(Uint16, uint16_t);
  TEST_TYPED_ARRAY(Int32, int32_t);
  TEST_TYPED_ARRAY(Uint32, uint32_t);
  TEST_TYPED_ARRAY(Int64, int64_t);
  TEST_TYPED_ARRAY(Uint64, uint64_t);
  TEST_TYPED_ARRAY(Float32, float);
  TEST_TYPED_ARRAY(Float64, double);
}

ISOLATE_UNIT_TEST_CASE(SerializeExternalTypedArray) {
  TEST_EXTERNAL_TYPED_ARRAY(Int8, int8_t);
  TEST_EXTERNAL_TYPED_ARRAY(Uint8, uint8_t);
  TEST_EXTERNAL_TYPED_ARRAY(Int16, int16_t);
  TEST_EXTERNAL_TYPED_ARRAY(Uint16, uint16_t);
  TEST_EXTERNAL_TYPED_ARRAY(Int32, int32_t);
  TEST_EXTERNAL_TYPED_ARRAY(Uint32, uint32_t);
  TEST_EXTERNAL_TYPED_ARRAY(Int64, int64_t);
  TEST_EXTERNAL_TYPED_ARRAY(Uint64, uint64_t);
  TEST_EXTERNAL_TYPED_ARRAY(Float32, float);
  TEST_EXTERNAL_TYPED_ARRAY(Float64, double);
}

ISOLATE_UNIT_TEST_CASE(SerializeEmptyByteArray) {
  // Write snapshot with object content.
  const int kTypedDataLength = 0;
  TypedData& typed_data = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, kTypedDataLength));
  MessageWriter writer(true);
  std::unique_ptr<Message> message =
      writer.WriteMessage(typed_data, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot.
  MessageSnapshotReader reader(message.get(), thread);
  TypedData& serialized_typed_data = TypedData::Handle();
  serialized_typed_data ^= reader.ReadObject();
  EXPECT(serialized_typed_data.IsTypedData());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kTypedData, root->type);
  EXPECT_EQ(Dart_TypedData_kUint8, root->value.as_typed_data.type);
  EXPECT_EQ(kTypedDataLength, root->value.as_typed_data.length);
  EXPECT(root->value.as_typed_data.values == NULL);
  CheckEncodeDecodeMessage(root);
}

VM_UNIT_TEST_CASE(FullSnapshot) {
  // clang-format off
  auto kScriptChars = Utils::CStringUniquePtr(
      OS::SCreate(
          nullptr,
          "class Fields  {\n"
          "  Fields(int i, int j) : fld1 = i, fld2 = j {}\n"
          "  int fld1;\n"
          "  final int fld2;\n"
          "  final int bigint_fld = 0xfffffffffff;\n"
          "  static int%s fld3;\n"
          "  static const int smi_sfld = 10;\n"
          "  static const int bigint_sfld = 0xfffffffffff;\n"
          "}\n"
          "class Expect {\n"
          "  static void equals(x, y) {\n"
          "    if (x != y) throw new ArgumentError('not equal');\n"
          "  }\n"
          "}\n"
          "class FieldsTest {\n"
          "  static Fields testMain() {\n"
          "    Expect.equals(true, Fields.bigint_sfld == 0xfffffffffff);\n"
          "    Fields obj = new Fields(10, 20);\n"
          "    Expect.equals(true, obj.bigint_fld == 0xfffffffffff);\n"
          "    return obj;\n"
          "  }\n"
          "}\n",
          TestCase::NullableTag()),
      std::free);
  // clang-format on
  Dart_Handle result;

  uint8_t* isolate_snapshot_data_buffer;

  // Start an Isolate, load a script and create a full snapshot.
  Timer timer1(true, "Snapshot_test");
  timer1.Start();
  {
    TestIsolateScope __test_isolate__;

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars.get(), NULL);

    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    HandleScope scope(thread);

    Dart_Handle result = Api::CheckAndFinalizePendingClasses(thread);
    {
      TransitionVMToNative to_native(thread);
      EXPECT_VALID(result);
    }
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %" Pd64 "us\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    MallocWriteStream isolate_snapshot_data(FullSnapshotWriter::kInitialSize);
    FullSnapshotWriter writer(
        Snapshot::kFull, /*vm_snapshot_data=*/nullptr, &isolate_snapshot_data,
        /*vm_image_writer=*/nullptr, /*iso_image_writer=*/nullptr);
    writer.WriteFullSnapshot();
    // Take ownership so it doesn't get freed by the stream destructor.
    intptr_t unused;
    isolate_snapshot_data_buffer = isolate_snapshot_data.Steal(&unused);
  }

  // Now Create another isolate using the snapshot and execute a method
  // from the script.
  Timer timer2(true, "Snapshot_test");
  timer2.Start();
  TestCase::CreateTestIsolateFromSnapshot(isolate_snapshot_data_buffer);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    timer2.Stop();
    OS::PrintErr("From Snapshot: %" Pd64 "us\n", timer2.TotalElapsedTime());

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(TestCase::lib(), NewString("FieldsTest"));
    result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(isolate_snapshot_data_buffer);
}

// Helper function to call a top level Dart function and serialize the result.
static std::unique_ptr<Message> GetSerialized(Dart_Handle lib,
                                              const char* dart_function) {
  Dart_Handle result;
  {
    TransitionVMToNative transition(Thread::Current());
    result = Dart_Invoke(lib, NewString(dart_function), 0, NULL);
    EXPECT_VALID(result);
  }
  Object& obj = Object::Handle(Api::UnwrapHandle(result));

  // Serialize the object into a message.
  MessageWriter writer(false);
  return writer.WriteMessage(obj, ILLEGAL_PORT, Message::kNormalPriority);
}

// Helper function to deserialize the result into a Dart_CObject structure.
static Dart_CObject* GetDeserialized(Message* message) {
  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(message);
  return api_reader.ReadMessage();
}

static void CheckString(Dart_Handle dart_string, const char* expected) {
  StackZone zone(Thread::Current());
  String& str = String::Handle();
  str ^= Api::UnwrapHandle(dart_string);
  MessageWriter writer(false);
  std::unique_ptr<Message> message =
      writer.WriteMessage(str, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kString, root->type);
  EXPECT_STREQ(expected, root->value.as_string);
  CheckEncodeDecodeMessage(root);
}

static void CheckStringInvalid(Dart_Handle dart_string) {
  StackZone zone(Thread::Current());
  String& str = String::Handle();
  str ^= Api::UnwrapHandle(dart_string);
  MessageWriter writer(false);
  std::unique_ptr<Message> message =
      writer.WriteMessage(str, ILLEGAL_PORT, Message::kNormalPriority);

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(message.get());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kUnsupported, root->type);
}

VM_UNIT_TEST_CASE(DartGeneratedMessages) {
  static const char* kCustomIsolateScriptChars =
      "final int kArrayLength = 10;\n"
      "getSmi() {\n"
      "  return 42;\n"
      "}\n"
      "getAsciiString() {\n"
      "  return \"Hello, world!\";\n"
      "}\n"
      "getNonAsciiString() {\n"
      "  return \"Blåbærgrød\";\n"
      "}\n"
      "getNonBMPString() {\n"
      "  return \"\\u{10000}\\u{1F601}\\u{1F637}\\u{20000}\";\n"
      "}\n"
      "getLeadSurrogateString() {\n"
      "  return String.fromCharCodes([0xd800]);\n"
      "}\n"
      "getTrailSurrogateString() {\n"
      "  return \"\\u{10000}\".substring(1);\n"
      "}\n"
      "getSurrogatesString() {\n"
      "  return String.fromCharCodes([0xdc00, 0xdc00, 0xd800, 0xd800]);\n"
      "}\n"
      "getCrappyString() {\n"
      "  return String.fromCharCodes([0xd800, 32, 0xdc00, 32]);\n"
      "}\n"
      "getList() {\n"
      "  return List.filled(kArrayLength, null);\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kCustomIsolateScriptChars, NULL);
  EXPECT_VALID(lib);
  Dart_Handle smi_result;
  smi_result = Dart_Invoke(lib, NewString("getSmi"), 0, NULL);
  EXPECT_VALID(smi_result);

  Dart_Handle ascii_string_result;
  ascii_string_result = Dart_Invoke(lib, NewString("getAsciiString"), 0, NULL);
  EXPECT_VALID(ascii_string_result);
  EXPECT(Dart_IsString(ascii_string_result));

  Dart_Handle non_ascii_string_result;
  non_ascii_string_result =
      Dart_Invoke(lib, NewString("getNonAsciiString"), 0, NULL);
  EXPECT_VALID(non_ascii_string_result);
  EXPECT(Dart_IsString(non_ascii_string_result));

  Dart_Handle non_bmp_string_result;
  non_bmp_string_result =
      Dart_Invoke(lib, NewString("getNonBMPString"), 0, NULL);
  EXPECT_VALID(non_bmp_string_result);
  EXPECT(Dart_IsString(non_bmp_string_result));

  Dart_Handle lead_surrogate_string_result;
  lead_surrogate_string_result =
      Dart_Invoke(lib, NewString("getLeadSurrogateString"), 0, NULL);
  EXPECT_VALID(lead_surrogate_string_result);
  EXPECT(Dart_IsString(lead_surrogate_string_result));

  Dart_Handle trail_surrogate_string_result;
  trail_surrogate_string_result =
      Dart_Invoke(lib, NewString("getTrailSurrogateString"), 0, NULL);
  EXPECT_VALID(trail_surrogate_string_result);
  EXPECT(Dart_IsString(trail_surrogate_string_result));

  Dart_Handle surrogates_string_result;
  surrogates_string_result =
      Dart_Invoke(lib, NewString("getSurrogatesString"), 0, NULL);
  EXPECT_VALID(surrogates_string_result);
  EXPECT(Dart_IsString(surrogates_string_result));

  Dart_Handle crappy_string_result;
  crappy_string_result =
      Dart_Invoke(lib, NewString("getCrappyString"), 0, NULL);
  EXPECT_VALID(crappy_string_result);
  EXPECT(Dart_IsString(crappy_string_result));

  {
    Thread* thread = Thread::Current();
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);

    {
      StackZone zone(thread);
      Smi& smi = Smi::Handle();
      smi ^= Api::UnwrapHandle(smi_result);
      MessageWriter writer(false);
      std::unique_ptr<Message> message =
          writer.WriteMessage(smi, ILLEGAL_PORT, Message::kNormalPriority);

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(message.get());
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kInt32, root->type);
      EXPECT_EQ(42, root->value.as_int32);
      CheckEncodeDecodeMessage(root);
    }
    CheckString(ascii_string_result, "Hello, world!");
    CheckString(non_ascii_string_result, "Blåbærgrød");
    CheckString(non_bmp_string_result,
                "\xf0\x90\x80\x80"
                "\xf0\x9f\x98\x81"
                "\xf0\x9f\x98\xb7"
                "\xf0\xa0\x80\x80");
    CheckStringInvalid(lead_surrogate_string_result);
    CheckStringInvalid(trail_surrogate_string_result);
    CheckStringInvalid(crappy_string_result);
    CheckStringInvalid(surrogates_string_result);
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(DartGeneratedListMessages) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "final int kArrayLength = 10;\n"
      "getList() {\n"
      "  return List.filled(kArrayLength, null);\n"
      "}\n"
      "getIntList() {\n"
      "  var list = List<int>.filled(kArrayLength, 0);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = i;\n"
      "  return list;\n"
      "}\n"
      "getStringList() {\n"
      "  var list = List<String>.filled(kArrayLength, '');\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = i.toString();\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = List<dynamic>.filled(kArrayLength, null);\n"
      "  list[0] = 0;\n"
      "  list[1] = '1';\n"
      "  list[2] = 2.2;\n"
      "  list[3] = true;\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    {
      // Generate a list of nulls from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kNull, root->value.as_array.values[i]->type);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of ints from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getIntList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kInt32, root->value.as_array.values[i]->type);
        EXPECT_EQ(i, root->value.as_array.values[i]->value.as_int32);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of strings from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getStringList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kString, root->value.as_array.values[i]->type);
        char buffer[3];
        snprintf(buffer, sizeof(buffer), "%d", i);
        EXPECT_STREQ(buffer, root->value.as_array.values[i]->value.as_string);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMixedList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);

      EXPECT_EQ(Dart_CObject_kInt32, root->value.as_array.values[0]->type);
      EXPECT_EQ(0, root->value.as_array.values[0]->value.as_int32);
      EXPECT_EQ(Dart_CObject_kString, root->value.as_array.values[1]->type);
      EXPECT_STREQ("1", root->value.as_array.values[1]->value.as_string);
      EXPECT_EQ(Dart_CObject_kDouble, root->value.as_array.values[2]->type);
      EXPECT_EQ(2.2, root->value.as_array.values[2]->value.as_double);
      EXPECT_EQ(Dart_CObject_kBool, root->value.as_array.values[3]->type);
      EXPECT_EQ(true, root->value.as_array.values[3]->value.as_bool);

      for (int i = 0; i < kArrayLength; i++) {
        if (i > 3) {
          EXPECT_EQ(Dart_CObject_kNull, root->value.as_array.values[i]->type);
        }
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(DartGeneratedArrayLiteralMessages) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "final int kArrayLength = 10;\n"
      "getList() {\n"
      "  return [null, null, null, null, null, null, null, null, null, null];\n"
      "}\n"
      "getIntList() {\n"
      "  return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];\n"
      "}\n"
      "getStringList() {\n"
      "  return ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];\n"
      "}\n"
      "getListList() {\n"
      "  return <dynamic>[[],"
      "                   [0],"
      "                   [0, 1],"
      "                   [0, 1, 2],"
      "                   [0, 1, 2, 3],"
      "                   [0, 1, 2, 3, 4],"
      "                   [0, 1, 2, 3, 4, 5],"
      "                   [0, 1, 2, 3, 4, 5, 6],"
      "                   [0, 1, 2, 3, 4, 5, 6, 7],"
      "                   [0, 1, 2, 3, 4, 5, 6, 7, 8]];\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = [];\n"
      "  list.add(0);\n"
      "  list.add('1');\n"
      "  list.add(2.2);\n"
      "  list.add(true);\n"
      "  list.add([]);\n"
      "  list.add(<dynamic>[[]]);\n"
      "  list.add(<dynamic>[<dynamic>[[]]]);\n"
      "  list.add(<dynamic>[1, <dynamic>[2, [3]]]);\n"
      "  list.add(<dynamic>[1, <dynamic>[1, 2, [1, 2, 3]]]);\n"
      "  list.add([1, 2, 3]);\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    {
      // Generate a list of nulls from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kNull, root->value.as_array.values[i]->type);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of ints from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getIntList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kInt32, root->value.as_array.values[i]->type);
        EXPECT_EQ(i, root->value.as_array.values[i]->value.as_int32);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of strings from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getStringList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject_kString, root->value.as_array.values[i]->type);
        char buffer[3];
        snprintf(buffer, sizeof(buffer), "%d", i);
        EXPECT_STREQ(buffer, root->value.as_array.values[i]->value.as_string);
      }
    }
    {
      // Generate a list of lists from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getListList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kArray, element->type);
        EXPECT_EQ(i, element->value.as_array.length);
        for (int j = 0; j < i; j++) {
          EXPECT_EQ(Dart_CObject_kInt32,
                    element->value.as_array.values[j]->type);
          EXPECT_EQ(j, element->value.as_array.values[j]->value.as_int32);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMixedList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);

      EXPECT_EQ(Dart_CObject_kInt32, root->value.as_array.values[0]->type);
      EXPECT_EQ(0, root->value.as_array.values[0]->value.as_int32);
      EXPECT_EQ(Dart_CObject_kString, root->value.as_array.values[1]->type);
      EXPECT_STREQ("1", root->value.as_array.values[1]->value.as_string);
      EXPECT_EQ(Dart_CObject_kDouble, root->value.as_array.values[2]->type);
      EXPECT_EQ(2.2, root->value.as_array.values[2]->value.as_double);
      EXPECT_EQ(Dart_CObject_kBool, root->value.as_array.values[3]->type);
      EXPECT_EQ(true, root->value.as_array.values[3]->value.as_bool);

      for (int i = 0; i < kArrayLength; i++) {
        if (i > 3) {
          EXPECT_EQ(Dart_CObject_kArray, root->value.as_array.values[i]->type);
        }
      }

      Dart_CObject* element;
      Dart_CObject* e;

      // []
      element = root->value.as_array.values[4];
      EXPECT_EQ(0, element->value.as_array.length);

      // [[]]
      element = root->value.as_array.values[5];
      EXPECT_EQ(1, element->value.as_array.length);
      element = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(0, element->value.as_array.length);

      // [[[]]]"
      element = root->value.as_array.values[6];
      EXPECT_EQ(1, element->value.as_array.length);
      element = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(1, element->value.as_array.length);
      element = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(0, element->value.as_array.length);

      // [1, [2, [3]]]
      element = root->value.as_array.values[7];
      EXPECT_EQ(2, element->value.as_array.length);
      e = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kInt32, e->type);
      EXPECT_EQ(1, e->value.as_int32);
      element = element->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(2, element->value.as_array.length);
      e = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kInt32, e->type);
      EXPECT_EQ(2, e->value.as_int32);
      element = element->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(1, element->value.as_array.length);
      e = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kInt32, e->type);
      EXPECT_EQ(3, e->value.as_int32);

      // [1, [1, 2, [1, 2, 3]]]
      element = root->value.as_array.values[8];
      EXPECT_EQ(2, element->value.as_array.length);
      e = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kInt32, e->type);
      e = element->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kInt32, e->type);
      EXPECT_EQ(1, e->value.as_int32);
      element = element->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(3, element->value.as_array.length);
      for (int i = 0; i < 2; i++) {
        e = element->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kInt32, e->type);
        EXPECT_EQ(i + 1, e->value.as_int32);
      }
      element = element->value.as_array.values[2];
      EXPECT_EQ(Dart_CObject_kArray, element->type);
      EXPECT_EQ(3, element->value.as_array.length);
      for (int i = 0; i < 3; i++) {
        e = element->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kInt32, e->type);
        EXPECT_EQ(i + 1, e->value.as_int32);
      }

      // [1, 2, 3]
      element = root->value.as_array.values[9];
      EXPECT_EQ(3, element->value.as_array.length);
      for (int i = 0; i < 3; i++) {
        e = element->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kInt32, e->type);
        EXPECT_EQ(i + 1, e->value.as_int32);
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(DartGeneratedListMessagesWithBackref) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "final int kArrayLength = 10;\n"
      "getStringList() {\n"
      "  var s = 'Hello, world!';\n"
      "  var list = List<String>.filled(kArrayLength, '');\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = s;\n"
      "  return list;\n"
      "}\n"
      "getMintList() {\n"
      "  var mint = 0x7FFFFFFFFFFFFFFF;\n"
      "  var list = List.filled(kArrayLength, 0);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = mint;\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = List<double>.filled(kArrayLength, 0.0);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = d;\n"
      "  return list;\n"
      "}\n"
      "getTypedDataList() {\n"
      "  var byte_array = Uint8List(256);\n"
      "  var list = List<dynamic>.filled(kArrayLength, null);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = byte_array;\n"
      "  return list;\n"
      "}\n"
      "getTypedDataViewList() {\n"
      "  var uint8_list = Uint8List(256);\n"
      "  uint8_list[64] = 1;\n"
      "  var uint8_list_view =\n"
      "      Uint8List.view(uint8_list.buffer, 64, 128);\n"
      "  var list = List<dynamic>.filled(kArrayLength, null);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = uint8_list_view;\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = List<dynamic>.filled(kArrayLength, null);\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list[i] = ((i % 2) == 0) ? 'A' : 2.72;\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getSelfRefList() {\n"
      "  var list = List<dynamic>.filled(kArrayLength, null, growable: true);\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list[i] = list;\n"
      "  }\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    {
      // Generate a list of strings from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getStringList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kString, element->type);
        EXPECT_STREQ("Hello, world!", element->value.as_string);
      }
    }
    {
      // Generate a list of medium ints from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMintList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kInt64, element->type);
        EXPECT_EQ(DART_INT64_C(0x7FFFFFFFFFFFFFFF), element->value.as_int64);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getDoubleList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_EQ(3.14, element->value.as_double);
      for (int i = 1; i < kArrayLength; i++) {
        element = root->value.as_array.values[i];
        // Double values are expected to not be canonicalized in messages.
        EXPECT_NE(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kDouble, element->type);
        EXPECT_EQ(3.14, element->value.as_double);
      }
    }
    {
      // Generate a list of Uint8Lists from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getTypedDataList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kTypedData, element->type);
        EXPECT_EQ(Dart_TypedData_kUint8, element->value.as_typed_data.type);
        EXPECT_EQ(256, element->value.as_typed_data.length);
      }
    }
    {
      // Generate a list of Uint8List views from Dart code.
      std::unique_ptr<Message> message =
          GetSerialized(lib, "getTypedDataViewList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kTypedData, element->type);
        EXPECT_EQ(Dart_TypedData_kUint8, element->value.as_typed_data.type);
        EXPECT_EQ(128, element->value.as_typed_data.length);
        EXPECT_EQ(1, element->value.as_typed_data.values[0]);
        EXPECT_EQ(0, element->value.as_typed_data.values[1]);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMixedList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kString, element->type);
      EXPECT_STREQ("A", element->value.as_string);
      element = root->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_EQ(2.72, element->value.as_double);
      for (int i = 2; i < kArrayLength; i++) {
        element = root->value.as_array.values[i];
        if ((i % 2) == 0) {
          EXPECT_EQ(root->value.as_array.values[0], element);
          EXPECT_EQ(Dart_CObject_kString, element->type);
          EXPECT_STREQ("A", element->value.as_string);
        } else {
          // Double values are expected to not be canonicalized in messages.
          EXPECT_NE(root->value.as_array.values[1], element);
          EXPECT_EQ(Dart_CObject_kDouble, element->type);
          EXPECT_EQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getSelfRefList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kArray, element->type);
        EXPECT_EQ(root, element);
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(DartGeneratedArrayLiteralMessagesWithBackref) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "final int kArrayLength = 10;\n"
      "getStringList() {\n"
      "  var s = 'Hello, world!';\n"
      "  var list = [s, s, s, s, s, s, s, s, s, s];\n"
      "  return list;\n"
      "}\n"
      "getMintList() {\n"
      "  var mint = 0x7FFFFFFFFFFFFFFF;\n"
      "  var list = [mint, mint, mint, mint, mint,\n"
      "              mint, mint, mint, mint, mint];\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = [3.14, 3.14, 3.14, 3.14, 3.14, 3.14];\n"
      "  list.add(3.14);\n"
      "  list.add(3.14);\n"
      "  list.add(3.14);\n"
      "  list.add(3.14);\n"
      "  return list;\n"
      "}\n"
      "getTypedDataList() {\n"
      "  var byte_array = new Uint8List(256);\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(byte_array);\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getTypedDataViewList() {\n"
      "  var uint8_list = new Uint8List(256);\n"
      "  uint8_list[64] = 1;\n"
      "  var uint8_list_view =\n"
      "      new Uint8List.view(uint8_list.buffer, 64, 128);\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(uint8_list_view);\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(((i % 2) == 0) ? '.' : 2.72);\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getSelfRefList() {\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(list);\n"
      "  }\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    {
      // Generate a list of strings from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getStringList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kString, element->type);
        EXPECT_STREQ("Hello, world!", element->value.as_string);
      }
    }
    {
      // Generate a list of medium ints from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMintList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kInt64, element->type);
        EXPECT_EQ(DART_INT64_C(0x7FFFFFFFFFFFFFFF), element->value.as_int64);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getDoubleList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      // Double values are expected to not be canonicalized in messages.
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_EQ(3.14, element->value.as_double);
      for (int i = 1; i < kArrayLength; i++) {
        element = root->value.as_array.values[i];
        // Double values are expected to not be canonicalized in messages.
        EXPECT_NE(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kDouble, element->type);
        EXPECT_EQ(3.14, element->value.as_double);
      }
    }
    {
      // Generate a list of Uint8Lists from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getTypedDataList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kTypedData, element->type);
        EXPECT_EQ(Dart_TypedData_kUint8, element->value.as_typed_data.type);
        EXPECT_EQ(256, element->value.as_typed_data.length);
      }
    }
    {
      // Generate a list of Uint8List views from Dart code.
      std::unique_ptr<Message> message =
          GetSerialized(lib, "getTypedDataViewList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kTypedData, element->type);
        EXPECT_EQ(Dart_TypedData_kUint8, element->value.as_typed_data.type);
        EXPECT_EQ(128, element->value.as_typed_data.length);
        EXPECT_EQ(1, element->value.as_typed_data.values[0]);
        EXPECT_EQ(0, element->value.as_typed_data.values[1]);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getMixedList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kString, element->type);
      EXPECT_STREQ(".", element->value.as_string);
      element = root->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_EQ(2.72, element->value.as_double);
      for (int i = 2; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        if ((i % 2) == 0) {
          EXPECT_EQ(root->value.as_array.values[0], element);
          EXPECT_EQ(Dart_CObject_kString, element->type);
          EXPECT_STREQ(".", element->value.as_string);
        } else {
          // Double values are expected to not be canonicalized in messages.
          EXPECT_NE(root->value.as_array.values[1], element);
          EXPECT_EQ(Dart_CObject_kDouble, element->type);
          EXPECT_EQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getSelfRefList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject_kArray, element->type);
        EXPECT_EQ(root, element);
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

static void CheckTypedData(Dart_CObject* object,
                           Dart_TypedData_Type typed_data_type,
                           int len) {
  EXPECT_EQ(Dart_CObject_kTypedData, object->type);
  EXPECT_EQ(typed_data_type, object->value.as_typed_data.type);
  EXPECT_EQ(len, object->value.as_typed_data.length);
}

VM_UNIT_TEST_CASE(DartGeneratedListMessagesWithTypedData) {
  static const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "getTypedDataList() {\n"
      "  var list = List<dynamic>.filled(13, null);\n"
      "  var index = 0;\n"
      "  list[index++] = Int8List(256);\n"
      "  list[index++] = Uint8List(256);\n"
      "  list[index++] = Int16List(256);\n"
      "  list[index++] = Uint16List(256);\n"
      "  list[index++] = Int32List(256);\n"
      "  list[index++] = Uint32List(256);\n"
      "  list[index++] = Int64List(256);\n"
      "  list[index++] = Uint64List(256);\n"
      "  list[index++] = Float32List(256);\n"
      "  list[index++] = Float64List(256);\n"
      "  list[index++] = Int32x4List(256);\n"
      "  list[index++] = Float32x4List(256);\n"
      "  list[index++] = Float64x2List(256);\n"
      "  return list;\n"
      "}\n"
      "getTypedDataViewList() {\n"
      "  var list = List<dynamic>.filled(45, null);\n"
      "  var index = 0;\n"
      "  list[index++] = Int8List.view(Int8List(256).buffer);\n"
      "  list[index++] = Uint8List.view(Uint8List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Int16List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Uint16List(256).buffer);\n"
      "  list[index++] = Int32List.view(new Int32List(256).buffer);\n"
      "  list[index++] = Uint32List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = Int64List.view(new Int64List(256).buffer);\n"
      "  list[index++] = Uint64List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = Float32List.view(new Float32List(256).buffer);\n"
      "  list[index++] = Float64List.view(new Float64List(256).buffer);\n"
      "  list[index++] = Int32x4List.view(new Int32x4List(256).buffer);\n"
      "  list[index++] = Float32x4List.view(new Float32x4List(256).buffer);\n"
      "  list[index++] = Float64x2List.view(new Float64x2List(256).buffer);\n"

      "  list[index++] = Int8List.view(new Int16List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Uint16List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Int32List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Int64List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Float32List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Float32List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Float64List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Float64List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Int32x4List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Int32x4List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Float32x4List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Float32x4List(256).buffer);\n"
      "  list[index++] = Int8List.view(new Float64x2List(256).buffer);\n"
      "  list[index++] = Uint8List.view(new Float64x2List(256).buffer);\n"

      "  list[index++] = Int16List.view(new Int8List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Uint8List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Int32List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Int64List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Float32List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Float32List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Float64List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Float64List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Int32x4List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Int32x4List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Float32x4List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Float32x4List(256).buffer);\n"
      "  list[index++] = Int16List.view(new Float64x2List(256).buffer);\n"
      "  list[index++] = Uint16List.view(new Float64x2List(256).buffer);\n"
      "  return list;\n"
      "}\n"
      "getMultipleTypedDataViewList() {\n"
      "  var list = List<dynamic>.filled(13, null);\n"
      "  var index = 0;\n"
      "  var data = Uint8List(256).buffer;\n"
      "  list[index++] = Int8List.view(data);\n"
      "  list[index++] = Uint8List.view(data);\n"
      "  list[index++] = Int16List.view(data);\n"
      "  list[index++] = Uint16List.view(data);\n"
      "  list[index++] = Int32List.view(data);\n"
      "  list[index++] = Uint32List.view(data);\n"
      "  list[index++] = Int64List.view(data);\n"
      "  list[index++] = Uint64List.view(data);\n"
      "  list[index++] = Float32List.view(data);\n"
      "  list[index++] = Float64List.view(data);\n"
      "  list[index++] = Int32x4List.view(data);\n"
      "  list[index++] = Float32x4List.view(data);\n"
      "  list[index++] = Float64x2List.view(data);\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    TransitionNativeToVM transition(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    {
      // Generate a list of Uint8Lists from Dart code.
      std::unique_ptr<Message> message = GetSerialized(lib, "getTypedDataList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},       {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 512},      {Dart_TypedData_kUint16, 512},
          {Dart_TypedData_kInt32, 1024},     {Dart_TypedData_kUint32, 1024},
          {Dart_TypedData_kInt64, 2048},     {Dart_TypedData_kUint64, 2048},
          {Dart_TypedData_kFloat32, 1024},   {Dart_TypedData_kFloat64, 2048},
          {Dart_TypedData_kInt32x4, 4096},   {Dart_TypedData_kFloat32x4, 4096},
          {Dart_TypedData_kFloat64x2, 4096}, {Dart_TypedData_kInvalid, -1}};

      int i = 0;
      while (expected[i].type != Dart_TypedData_kInvalid) {
        CheckTypedData(root->value.as_array.values[i], expected[i].type,
                       expected[i].size);
        i++;
      }
      EXPECT_EQ(i, root->value.as_array.length);
    }
    {
      // Generate a list of Uint8List views from Dart code.
      std::unique_ptr<Message> message =
          GetSerialized(lib, "getTypedDataViewList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},       {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 512},      {Dart_TypedData_kUint16, 512},
          {Dart_TypedData_kInt32, 1024},     {Dart_TypedData_kUint32, 1024},
          {Dart_TypedData_kInt64, 2048},     {Dart_TypedData_kUint64, 2048},
          {Dart_TypedData_kFloat32, 1024},   {Dart_TypedData_kFloat64, 2048},
          {Dart_TypedData_kInt32x4, 4096},   {Dart_TypedData_kFloat32x4, 4096},
          {Dart_TypedData_kFloat64x2, 4096},

          {Dart_TypedData_kInt8, 512},       {Dart_TypedData_kUint8, 512},
          {Dart_TypedData_kInt8, 1024},      {Dart_TypedData_kUint8, 1024},
          {Dart_TypedData_kInt8, 2048},      {Dart_TypedData_kUint8, 2048},
          {Dart_TypedData_kInt8, 1024},      {Dart_TypedData_kUint8, 1024},
          {Dart_TypedData_kInt8, 2048},      {Dart_TypedData_kUint8, 2048},
          {Dart_TypedData_kInt8, 4096},      {Dart_TypedData_kUint8, 4096},
          {Dart_TypedData_kInt8, 4096},      {Dart_TypedData_kUint8, 4096},
          {Dart_TypedData_kInt8, 4096},      {Dart_TypedData_kUint8, 4096},

          {Dart_TypedData_kInt16, 256},      {Dart_TypedData_kUint16, 256},
          {Dart_TypedData_kInt16, 1024},     {Dart_TypedData_kUint16, 1024},
          {Dart_TypedData_kInt16, 2048},     {Dart_TypedData_kUint16, 2048},
          {Dart_TypedData_kInt16, 1024},     {Dart_TypedData_kUint16, 1024},
          {Dart_TypedData_kInt16, 2048},     {Dart_TypedData_kUint16, 2048},
          {Dart_TypedData_kInt16, 4096},     {Dart_TypedData_kUint16, 4096},
          {Dart_TypedData_kInt16, 4096},     {Dart_TypedData_kUint16, 4096},
          {Dart_TypedData_kInt16, 4096},     {Dart_TypedData_kUint16, 4096},

          {Dart_TypedData_kInvalid, -1}};

      int i = 0;
      while (expected[i].type != Dart_TypedData_kInvalid) {
        CheckTypedData(root->value.as_array.values[i], expected[i].type,
                       expected[i].size);
        i++;
      }
      EXPECT_EQ(i, root->value.as_array.length);
    }
    {
      // Generate a list of Uint8Lists from Dart code.
      std::unique_ptr<Message> message =
          GetSerialized(lib, "getMultipleTypedDataViewList");
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(message.get());
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},      {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 256},     {Dart_TypedData_kUint16, 256},
          {Dart_TypedData_kInt32, 256},     {Dart_TypedData_kUint32, 256},
          {Dart_TypedData_kInt64, 256},     {Dart_TypedData_kUint64, 256},
          {Dart_TypedData_kFloat32, 256},   {Dart_TypedData_kFloat64, 256},
          {Dart_TypedData_kInt32x4, 256},   {Dart_TypedData_kFloat32x4, 256},
          {Dart_TypedData_kFloat64x2, 256}, {Dart_TypedData_kInvalid, -1}};

      int i = 0;
      while (expected[i].type != Dart_TypedData_kInvalid) {
        CheckTypedData(root->value.as_array.values[i], expected[i].type,
                       expected[i].size);

        // All views point to the same data.
        EXPECT_EQ(root->value.as_array.values[0]->value.as_typed_data.values,
                  root->value.as_array.values[i]->value.as_typed_data.values);
        i++;
      }
      EXPECT_EQ(i, root->value.as_array.length);
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(PostCObject) {
  // Create a native port for posting from C to Dart
  TestIsolateScope __test_isolate__;
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "main() {\n"
      "  var messageCount = 0;\n"
      "  var exception = '';\n"
      "  var port = new RawReceivePort();\n"
      "  var sendPort = port.sendPort;\n"
      "  port.handler = (message) {\n"
      "    if (messageCount < 9) {\n"
      "      exception = '$exception${message}';\n"
      "    } else {\n"
      "      exception = '$exception${message.length}';\n"
      "      for (int i = 0; i < message.length; i++) {\n"
      "        exception = '$exception${message[i]}';\n"
      "      }\n"
      "    }\n"
      "    messageCount++;\n"
      "    if (messageCount == 10) throw new Exception(exception);\n"
      "  };\n"
      "  return sendPort;\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  Dart_Handle send_port = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(send_port);
  Dart_Port port_id;
  Dart_Handle result = Dart_SendPortGetId(send_port, &port_id);
  ASSERT(!Dart_IsError(result));

  // Setup single object message.
  Dart_CObject object;

  object.type = Dart_CObject_kNull;
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kBool;
  object.value.as_bool = true;
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kBool;
  object.value.as_bool = false;
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kInt32;
  object.value.as_int32 = 123;
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kString;
  object.value.as_string = const_cast<char*>("456");
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kString;
  object.value.as_string = const_cast<char*>("æøå");
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kString;
  object.value.as_string = const_cast<char*>("");
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kDouble;
  object.value.as_double = 3.14;
  EXPECT(Dart_PostCObject(port_id, &object));

  object.type = Dart_CObject_kArray;
  object.value.as_array.length = 0;
  EXPECT(Dart_PostCObject(port_id, &object));

  static const int kArrayLength = 10;
  Dart_CObject* array = reinterpret_cast<Dart_CObject*>(Dart_ScopeAllocate(
      sizeof(Dart_CObject) + sizeof(Dart_CObject*) * kArrayLength));  // NOLINT
  array->type = Dart_CObject_kArray;
  array->value.as_array.length = kArrayLength;
  array->value.as_array.values = reinterpret_cast<Dart_CObject**>(array + 1);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = reinterpret_cast<Dart_CObject*>(
        Dart_ScopeAllocate(sizeof(Dart_CObject)));
    element->type = Dart_CObject_kInt32;
    element->value.as_int32 = i;
    array->value.as_array.values[i] = element;
  }
  EXPECT(Dart_PostCObject(port_id, array));

  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: nulltruefalse123456æøå3.14[]100123456789\n",
                   Dart_GetError(result));

  Dart_ExitScope();
}

ISOLATE_UNIT_TEST_CASE(OmittedObjectEncodingLength) {
  StackZone zone(Thread::Current());
  MessageWriter writer(true);
  writer.WriteInlinedObjectHeader(kOmittedObjectId);
  // For performance, we'd like single-byte headers when ids are omitted.
  // If this starts failing, consider renumbering the snapshot ids.
  EXPECT_EQ(1, writer.BytesWritten());
}

TEST_CASE(IsKernelNegative) {
  EXPECT(!Dart_IsKernel(NULL, 0));

  uint8_t buffer[4] = {0, 0, 0, 0};
  EXPECT(!Dart_IsKernel(buffer, ARRAY_SIZE(buffer)));
}

VM_UNIT_TEST_CASE(LegacyErasureDetectionInFullSnapshot) {
  const char* kScriptChars =
      "class Generic<T> {\n"
      "  const Generic();\n"
      "  static const Generic<int> g = const Generic<int>();\n"
      "  static testMain() => g.runtimeType;\n"
      "}\n";

  // Start an Isolate, load and execute a script and check if legacy erasure is
  // required, preventing to write a full snapshot.
  {
    TestIsolateScope __test_isolate__;

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
    EXPECT_VALID(lib);

    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    ASSERT(isolate == __test_isolate__.isolate());
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    HandleScope scope(thread);

    Dart_Handle result = Api::CheckAndFinalizePendingClasses(thread);
    Dart_Handle cls;
    {
      TransitionVMToNative to_native(thread);
      EXPECT_VALID(result);

      // Invoke a function so that the constant is evaluated.
      cls = Dart_GetClass(TestCase::lib(), NewString("Generic"));
      result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
      EXPECT_VALID(result);
    }
    // Verify that legacy erasure is required in strong mode.
    Type& type = Type::Handle();
    type ^= Api::UnwrapHandle(cls);  // Dart_GetClass actually returns a Type.
    const Class& clazz = Class::Handle(type.type_class());
    const bool required = clazz.RequireLegacyErasureOfConstants(zone.GetZone());
    EXPECT(required == isolate->null_safety());

    // Verify that snapshot writing succeeds if erasure is not required.
    if (!required) {
      // Write snapshot with object content.
      MallocWriteStream isolate_snapshot_data(FullSnapshotWriter::kInitialSize);
      FullSnapshotWriter writer(
          Snapshot::kFullCore, /*vm_snapshot_data=*/nullptr,
          &isolate_snapshot_data,
          /*vm_image_writer=*/nullptr, /*iso_image_writer=*/nullptr);
      writer.WriteFullSnapshot();
    }
  }
}

}  // namespace dart
