// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/clustered_snapshot.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/malloc_hooks.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
#include "vm/unicode.h"
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

static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  return reinterpret_cast<uint8_t*>(realloc(ptr, new_size));
}

static void malloc_deallocator(uint8_t* ptr) {
  free(ptr);
}

static uint8_t* zone_allocator(uint8_t* ptr,
                               intptr_t old_size,
                               intptr_t new_size) {
  Zone* zone = Thread::Current()->zone();
  return zone->Realloc<uint8_t>(ptr, old_size, new_size);
}

static void zone_deallocator(uint8_t* ptr) {}

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
    case Dart_CObject_kBigint: {
      char* first_hex_value = TestCase::BigintToHexValue(first);
      char* second_hex_value = TestCase::BigintToHexValue(second);
      EXPECT_STREQ(first_hex_value, second_hex_value);
      free(first_hex_value);
      free(second_hex_value);
      break;
    }
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
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, &malloc_allocator);
  writer.WriteCMessage(root);

  ApiMessageReader api_reader(buffer, writer.BytesWritten());
  Dart_CObject* new_root = api_reader.ReadMessage();

  // Check that the two messages are the same.
  CompareDartCObjects(root, new_root);

  free(buffer);
}

static void ExpectEncodeFail(Dart_CObject* root) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, &malloc_allocator);
  const bool result = writer.WriteCMessage(root);
  EXPECT_EQ(false, result);
  free(buffer);
}

TEST_CASE(SerializeNull) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Object& null_object = Object::Handle();
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(null_object);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(null_object, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kNull, root->type);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeSmi1) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Smi& smi = Smi::Handle(Smi::New(124));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(smi);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeSmi2) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Smi& smi = Smi::Handle(Smi::New(-1));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(smi);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}

Dart_CObject* SerializeAndDeserializeMint(const Mint& mint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(mint);
  intptr_t buffer_len = writer.BytesWritten();

  {
    // Switch to a regular zone, where VM handle allocation is allowed.
    Thread* thread = Thread::Current();
    StackZone zone(thread);
    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    const Object& serialized_object = Object::Handle(reader.ReadObject());
    EXPECT(serialized_object.IsMint());
  }

  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(buffer, buffer_len);
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

TEST_CASE(SerializeMints) {
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

TEST_CASE(SerializeDouble) {
  StackZone zone(thread);

  // Write snapshot with object content.
  const Double& dbl = Double::Handle(Double::New(101.29));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(dbl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(dbl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kDouble, root->type);
  EXPECT_EQ(dbl.value(), root->value.as_double);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeTrue) {
  StackZone zone(thread);

  // Write snapshot with true object.
  const Bool& bl = Bool::True();
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(bl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  fprintf(stderr, "%s / %s\n", bl.ToCString(), serialized_object.ToCString());

  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kBool, root->type);
  EXPECT_EQ(true, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeFalse) {
  StackZone zone(thread);

  // Write snapshot with false object.
  const Bool& bl = Bool::False();
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(bl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kBool, root->type);
  EXPECT_EQ(false, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeCapability) {
  // Write snapshot with object content.
  const Capability& capability = Capability::Handle(Capability::New(12345));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(capability);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  Capability& obj = Capability::Handle();
  obj ^= reader.ReadObject();

  EXPECT_STREQ(12345, obj.Id());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kCapability, root->type);
  int64_t id = root->value.as_capability.id;
  EXPECT_EQ(12345, id);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeBigint) {
  if (Bigint::IsDisabled()) {
    return;
  }
  // Write snapshot with object content.
  const char* cstr = "0x270FFFFFFFFFFFFFD8F0";
  const String& str = String::Handle(String::New(cstr));
  Bigint& bigint = Bigint::Handle();
  bigint ^= Integer::NewCanonical(str);
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(bigint);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  Bigint& obj = Bigint::Handle();
  obj ^= reader.ReadObject();

  Zone* zone = Thread::Current()->zone();
  EXPECT_STREQ(bigint.ToHexCString(zone), obj.ToHexCString(zone));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kBigint, root->type);
  char* hex_value = TestCase::BigintToHexValue(root);
  EXPECT_STREQ(cstr, hex_value);
  free(hex_value);
  CheckEncodeDecodeMessage(root);
}

Dart_CObject* SerializeAndDeserializeBigint(const Bigint& bigint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(bigint);
  intptr_t buffer_len = writer.BytesWritten();

  {
    // Switch to a regular zone, where VM handle allocation is allowed.
    Thread* thread = Thread::Current();
    StackZone zone(thread);
    // Read object back from the snapshot.
    MessageSnapshotReader reader(buffer, buffer_len, thread);
    Bigint& serialized_bigint = Bigint::Handle();
    serialized_bigint ^= reader.ReadObject();
    const char* str1 = bigint.ToHexCString(thread->zone());
    const char* str2 = serialized_bigint.ToHexCString(thread->zone());
    EXPECT_STREQ(str1, str2);
  }

  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  // Bigint not supported.
  EXPECT_NOTNULL(root);
  CheckEncodeDecodeMessage(root);
  return root;
}

void CheckBigint(const char* bigint_value) {
  ApiNativeScope scope;
  StackZone zone(Thread::Current());
  Bigint& bigint = Bigint::Handle();
  bigint ^= Bigint::NewFromCString(bigint_value);
  Dart_CObject* bigint_cobject = SerializeAndDeserializeBigint(bigint);
  EXPECT_EQ(Dart_CObject_kBigint, bigint_cobject->type);
  char* hex_value = TestCase::BigintToHexValue(bigint_cobject);
  EXPECT_STREQ(bigint_value, hex_value);
  free(hex_value);
}

TEST_CASE(SerializeBigint2) {
  if (Bigint::IsDisabled()) {
    return;
  }
  CheckBigint("0x0");
  CheckBigint("0x1");
  CheckBigint("-0x1");
  CheckBigint("0x11111111111111111111");
  CheckBigint("-0x11111111111111111111");
  CheckBigint("0x9876543210987654321098765432109876543210");
  CheckBigint("-0x9876543210987654321098765432109876543210");
}

TEST_CASE(SerializeSingletons) {
  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &malloc_allocator, &malloc_deallocator, true);
  writer.WriteObject(Object::class_class());
  writer.WriteObject(Object::type_arguments_class());
  writer.WriteObject(Object::function_class());
  writer.WriteObject(Object::field_class());
  writer.WriteObject(Object::token_stream_class());
  writer.WriteObject(Object::script_class());
  writer.WriteObject(Object::library_class());
  writer.WriteObject(Object::code_class());
  writer.WriteObject(Object::instructions_class());
  writer.WriteObject(Object::pc_descriptors_class());
  writer.WriteObject(Object::exception_handlers_class());
  writer.WriteObject(Object::context_class());
  writer.WriteObject(Object::context_scope_class());
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  EXPECT(Object::class_class() == reader.ReadObject());
  EXPECT(Object::type_arguments_class() == reader.ReadObject());
  EXPECT(Object::function_class() == reader.ReadObject());
  EXPECT(Object::field_class() == reader.ReadObject());
  EXPECT(Object::token_stream_class() == reader.ReadObject());
  EXPECT(Object::script_class() == reader.ReadObject());
  EXPECT(Object::library_class() == reader.ReadObject());
  EXPECT(Object::code_class() == reader.ReadObject());
  EXPECT(Object::instructions_class() == reader.ReadObject());
  EXPECT(Object::pc_descriptors_class() == reader.ReadObject());
  EXPECT(Object::exception_handlers_class() == reader.ReadObject());
  EXPECT(Object::context_class() == reader.ReadObject());
  EXPECT(Object::context_scope_class() == reader.ReadObject());

  free(buffer);
}

static void TestString(const char* cstr) {
  Thread* thread = Thread::Current();
  EXPECT(Utf8::IsValid(reinterpret_cast<const uint8_t*>(cstr), strlen(cstr)));
  // Write snapshot with object content.
  String& str = String::Handle(String::New(cstr));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(str);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  String& serialized_str = String::Handle();
  serialized_str ^= reader.ReadObject();
  EXPECT(str.Equals(serialized_str));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kString, root->type);
  EXPECT_STREQ(cstr, root->value.as_string);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeString) {
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

TEST_CASE(SerializeArray) {
  // Write snapshot with object content.
  const int kArrayLength = 10;
  Array& array = Array::Handle(Array::New(kArrayLength));
  Smi& smi = Smi::Handle();
  for (int i = 0; i < kArrayLength; i++) {
    smi ^= Smi::New(i);
    array.SetAt(i, smi);
  }
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.CanonicalizeEquals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
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

TEST_CASE(SerializeEmptyArray) {
  // Write snapshot with object content.
  const int kArrayLength = 0;
  Array& array = Array::Handle(Array::New(kArrayLength));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.CanonicalizeEquals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  EXPECT(root->value.as_array.values == NULL);
  CheckEncodeDecodeMessage(root);
}

TEST_CASE(SerializeByteArray) {
  // Write snapshot with object content.
  const int kTypedDataLength = 256;
  TypedData& typed_data = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, kTypedDataLength));
  for (int i = 0; i < kTypedDataLength; i++) {
    typed_data.SetUint8(i, i);
  }
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(typed_data);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  TypedData& serialized_typed_data = TypedData::Handle();
  serialized_typed_data ^= reader.ReadObject();
  EXPECT(serialized_typed_data.IsTypedData());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
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
    uint8_t* buffer;                                                           \
    MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);   \
    writer.WriteMessage(array);                                                \
    intptr_t buffer_len = writer.BytesWritten();                               \
    MessageSnapshotReader reader(buffer, buffer_len, thread);                  \
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
    uint8_t* buffer;                                                           \
    MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);   \
    writer.WriteMessage(array);                                                \
    intptr_t buffer_len = writer.BytesWritten();                               \
    MessageSnapshotReader reader(buffer, buffer_len, thread);                  \
    TypedData& serialized_array = TypedData::Handle();                         \
    serialized_array ^= reader.ReadObject();                                   \
    for (int i = 0; i < length; i++) {                                         \
      EXPECT_EQ(static_cast<ctype>(data[i]),                                   \
                serialized_array.Get##darttype(i* scale));                     \
    }                                                                          \
  }

TEST_CASE(SerializeTypedArray) {
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

TEST_CASE(SerializeExternalTypedArray) {
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

TEST_CASE(SerializeEmptyByteArray) {
  // Write snapshot with object content.
  const int kTypedDataLength = 0;
  TypedData& typed_data = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, kTypedDataLength));
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteMessage(typed_data);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  MessageSnapshotReader reader(buffer, buffer_len, thread);
  TypedData& serialized_typed_data = TypedData::Handle();
  serialized_typed_data ^= reader.ReadObject();
  EXPECT(serialized_typed_data.IsTypedData());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kTypedData, root->type);
  EXPECT_EQ(Dart_TypedData_kUint8, root->value.as_typed_data.type);
  EXPECT_EQ(kTypedDataLength, root->value.as_typed_data.length);
  EXPECT(root->value.as_typed_data.values == NULL);
  CheckEncodeDecodeMessage(root);
}

class TestSnapshotWriter : public SnapshotWriter {
 public:
  static const intptr_t kInitialSize = 64 * KB;
  TestSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Thread::Current(),
                       Snapshot::kScript,
                       buffer,
                       alloc,
                       NULL,
                       kInitialSize,
                       &forward_list_,
                       true /* can_send_any_object */),
        forward_list_(thread(), kMaxPredefinedObjectIds) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~TestSnapshotWriter() {}

  // Writes just a script object
  void WriteScript(const Script& script) { WriteObject(script.raw()); }

 private:
  ForwardList forward_list_;

  DISALLOW_COPY_AND_ASSIGN(TestSnapshotWriter);
};

static void GenerateSourceAndCheck(const Script& script) {
  // Check if we are able to generate the source from the token stream.
  // Rescan this source and compare the token stream to see if they are
  // the same.
  Zone* zone = Thread::Current()->zone();
  const TokenStream& expected_tokens =
      TokenStream::Handle(zone, script.tokens());
  TokenStream::Iterator expected_iterator(zone, expected_tokens,
                                          TokenPosition::kMinSource,
                                          TokenStream::Iterator::kAllTokens);
  const String& str = String::Handle(zone, expected_tokens.GenerateSource());
  const String& private_key =
      String::Handle(zone, expected_tokens.PrivateKey());
  const TokenStream& reconstructed_tokens =
      TokenStream::Handle(zone, TokenStream::New(str, private_key, false));
  expected_iterator.SetCurrentPosition(TokenPosition::kMinSource);
  TokenStream::Iterator reconstructed_iterator(
      zone, reconstructed_tokens, TokenPosition::kMinSource,
      TokenStream::Iterator::kAllTokens);
  Token::Kind expected_kind = expected_iterator.CurrentTokenKind();
  Token::Kind reconstructed_kind = reconstructed_iterator.CurrentTokenKind();
  String& expected_literal = String::Handle(zone);
  String& actual_literal = String::Handle(zone);
  while (expected_kind != Token::kEOS && reconstructed_kind != Token::kEOS) {
    EXPECT_EQ(expected_kind, reconstructed_kind);
    expected_literal ^= expected_iterator.CurrentLiteral();
    actual_literal ^= reconstructed_iterator.CurrentLiteral();
    EXPECT_STREQ(expected_literal.ToCString(), actual_literal.ToCString());
    expected_iterator.Advance();
    reconstructed_iterator.Advance();
    expected_kind = expected_iterator.CurrentTokenKind();
    reconstructed_kind = reconstructed_iterator.CurrentTokenKind();
  }
}

TEST_CASE(SerializeScript) {
  const char* kScriptChars =
      "class A {\n"
      "  static bar() { return 42; }\n"
      "  static fly() { return 5; }\n"
      "  static s1() { return 'this is a string in the source'; }\n"
      "  static s2() { return 'this is a \"string\" in the source'; }\n"
      "  static s3() { return 'this is a \\\'string\\\' in \"the\" source'; }\n"
      "  static s4() { return 'this \"is\" a \"string\" in \"the\" source'; }\n"
      "  static ms1() {\n"
      "    return '''\n"
      "abc\n"
      "def\n"
      "ghi''';\n"
      "  }\n"
      "  static ms2() {\n"
      "    return '''\n"
      "abc\n"
      "$def\n"
      "ghi''';\n"
      "  }\n"
      "  static ms3() {\n"
      "    return '''\n"
      "a b c\n"
      "d $d e\n"
      "g h i''';\n"
      "  }\n"
      "  static ms4() {\n"
      "    return '''\n"
      "abc\n"
      "${def}\n"
      "ghi''';\n"
      "  }\n"
      "  static ms5() {\n"
      "    return '''\n"
      "a b c\n"
      "d ${d} e\n"
      "g h i''';\n"
      "  }\n"
      "  static ms6() {\n"
      "    return '\\t \\n \\x00 \\xFF';\n"
      "  }\n"
      "}\n";

  Zone* zone = thread->zone();
  String& url = String::Handle(zone, String::New("dart-test:SerializeScript"));
  String& source = String::Handle(zone, String::New(kScriptChars));
  Script& script =
      Script::Handle(zone, Script::New(url, source, RawScript::kScriptTag));
  const String& lib_url = String::Handle(zone, Symbols::New(thread, "TestLib"));
  Library& lib = Library::Handle(zone, Library::New(lib_url));
  lib.Register(thread);
  EXPECT(CompilerTest::TestCompileScript(lib, script));

  // Write snapshot with script content.
  uint8_t* buffer;
  TestSnapshotWriter writer(&buffer, &malloc_allocator);
  writer.WriteScript(script);

  // Read object back from the snapshot.
  ScriptSnapshotReader reader(buffer, writer.BytesWritten(), thread);
  Script& serialized_script = Script::Handle(zone);
  serialized_script ^= reader.ReadObject();

  // Check if the serialized script object matches the original script.
  String& expected_literal = String::Handle(zone);
  String& actual_literal = String::Handle(zone);
  String& str = String::Handle(zone);
  str ^= serialized_script.url();
  EXPECT(url.Equals(str));

  const TokenStream& expected_tokens =
      TokenStream::Handle(zone, script.tokens());
  const TokenStream& serialized_tokens =
      TokenStream::Handle(zone, serialized_script.tokens());
  const ExternalTypedData& expected_data =
      ExternalTypedData::Handle(zone, expected_tokens.GetStream());
  const ExternalTypedData& serialized_data =
      ExternalTypedData::Handle(zone, serialized_tokens.GetStream());
  EXPECT_EQ(expected_data.Length(), serialized_data.Length());
  TokenStream::Iterator expected_iterator(zone, expected_tokens,
                                          TokenPosition::kMinSource);
  TokenStream::Iterator serialized_iterator(zone, serialized_tokens,
                                            TokenPosition::kMinSource);
  Token::Kind expected_kind = expected_iterator.CurrentTokenKind();
  Token::Kind serialized_kind = serialized_iterator.CurrentTokenKind();
  while (expected_kind != Token::kEOS && serialized_kind != Token::kEOS) {
    EXPECT_EQ(expected_kind, serialized_kind);
    expected_literal ^= expected_iterator.CurrentLiteral();
    actual_literal ^= serialized_iterator.CurrentLiteral();
    EXPECT(expected_literal.Equals(actual_literal));
    expected_iterator.Advance();
    serialized_iterator.Advance();
    expected_kind = expected_iterator.CurrentTokenKind();
    serialized_kind = serialized_iterator.CurrentTokenKind();
  }

  // Check if we are able to generate the source from the token stream.
  // Rescan this source and compare the token stream to see if they are
  // the same.
  GenerateSourceAndCheck(serialized_script);

  free(buffer);
}

#if !defined(PRODUCT)  // Uses mirrors.
VM_UNIT_TEST_CASE(CanonicalizationInScriptSnapshots) {
  const char* kScriptChars =
      "\n"
      "import 'dart:mirrors';"
      "import 'dart:isolate';"
      "void main() {"
      "  if (reflectClass(MyException).superclass.reflectedType != "
      "      IsolateSpawnException) {"
      "    throw new Exception('Canonicalization failure');"
      "  }"
      "  if (reflectClass(IsolateSpawnException).reflectedType != "
      "      IsolateSpawnException) {"
      "    throw new Exception('Canonicalization failure');"
      "  }"
      "}\n"
      "class MyException extends IsolateSpawnException {}"
      "\n";

  Dart_Handle result;

  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;

  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }
  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;

  {
    // Now Create an Isolate using the full snapshot and load the
    // script  and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(lib);

    // Invoke a function which returns an object.
    result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(Thread::Current()));

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Now Create an Isolate using the full snapshot and load the
    // script snapshot created above and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the test library from the snapshot.
    EXPECT(script_snapshot != NULL);
    result = Dart_LoadScriptFromSnapshot(script_snapshot, size);
    EXPECT_VALID(result);

    // Invoke a function which returns an object.
    result = Dart_Invoke(result, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }
  free(script_snapshot);
  free(full_snapshot);
}
#endif

VM_UNIT_TEST_CASE(ScriptSnapshotsUpdateSubclasses) {
  const char* kScriptChars =
      "class _DebugDuration extends Duration {\n"
      "  const _DebugDuration() : super(milliseconds: 42);\n"
      "}\n"
      "foo(x, y) {\n"
      "  for (var i = 0; i < 1000000; i++) {\n"
      "    if (x != y) {\n"
      "      throw 'Boom!';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  final v = const Duration(milliseconds: 42);\n"
      "  foo(v, new _DebugDuration());\n"
      "}\n"
      "\n";

  Dart_Handle result;

  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;

#if !defined(PRODUCT)
  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
#endif
  intptr_t saved_max_polymorphic_checks = FLAG_max_polymorphic_checks;
  FLAG_max_polymorphic_checks = 0;

  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }

  {
    // Now Create an Isolate using the full snapshot and load the
    // script  and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(lib);

    // Invoke a function which returns an object.
    result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(Thread::Current()));

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Now Create an Isolate using the full snapshot and load the
    // script snapshot created above and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the test library from the snapshot.
    EXPECT(script_snapshot != NULL);
    result = Dart_LoadScriptFromSnapshot(script_snapshot, size);
    EXPECT_VALID(result);

    // Invoke a function which returns an object.
    result = Dart_Invoke(result, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }
  free(script_snapshot);
  free(full_snapshot);

  FLAG_max_polymorphic_checks = saved_max_polymorphic_checks;
#if !defined(PRODUCT)
  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;
#endif
}

static void IterateScripts(const Library& lib) {
  const Array& lib_scripts = Array::Handle(lib.LoadedScripts());
  Script& script = Script::Handle();
  String& uri = String::Handle();
  for (intptr_t i = 0; i < lib_scripts.Length(); i++) {
    script ^= lib_scripts.At(i);
    EXPECT(!script.IsNull());
    uri = script.url();
    OS::Print("Generating source for part: %s\n", uri.ToCString());
    GenerateSourceAndCheck(script);
  }
}

ISOLATE_UNIT_TEST_CASE(GenerateSource) {
  // Disable stack trace collection for this test as it results in a timeout.
  bool stack_trace_collection_enabled =
      MallocHooks::stack_trace_collection_enabled();
  MallocHooks::set_stack_trace_collection_enabled(false);

  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle();
  String& uri = String::Handle();
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    EXPECT(!lib.IsNull());
    uri = lib.url();
    OS::Print("Generating source for library: %s\n", uri.ToCString());
    IterateScripts(lib);
  }

  MallocHooks::set_stack_trace_collection_enabled(
      stack_trace_collection_enabled);
}

VM_UNIT_TEST_CASE(FullSnapshot) {
  const char* kScriptChars =
      "class Fields  {\n"
      "  Fields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  final int bigint_fld = 0xfffffffffff;\n"
      "  static int fld3;\n"
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
      "}\n";
  Dart_Handle result;

  uint8_t* isolate_snapshot_data_buffer;

  // Start an Isolate, load a script and create a full snapshot.
  Timer timer1(true, "Snapshot_test");
  timer1.Start();
  {
    TestIsolateScope __test_isolate__;

    Thread* thread = Thread::Current();
    StackZone zone(thread);
    HandleScope scope(thread);

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);
    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(thread));
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %" Pd64 "us\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    {
      FullSnapshotWriter writer(
          Snapshot::kFull, NULL, &isolate_snapshot_data_buffer,
          &malloc_allocator, NULL, NULL /* image_writer */);
      writer.WriteFullSnapshot();
    }
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

VM_UNIT_TEST_CASE(FullSnapshot1) {
  // This buffer has to be static for this to compile with Visual Studio.
  // If it is not static compilation of this file with Visual Studio takes
  // more than 30 minutes!
  static const char kFullSnapshotScriptChars[] = {
#include "snapshot_test.dat"
  };
  const char* kScriptChars = kFullSnapshotScriptChars;

  uint8_t* isolate_snapshot_data_buffer;

  // Start an Isolate, load a script and create a full snapshot.
  Timer timer1(true, "Snapshot_test");
  timer1.Start();
  {
    TestIsolateScope __test_isolate__;

    Thread* thread = Thread::Current();
    StackZone zone(thread);
    HandleScope scope(thread);

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(thread));
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %" Pd64 "us\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    {
      FullSnapshotWriter writer(
          Snapshot::kFull, NULL, &isolate_snapshot_data_buffer,
          &malloc_allocator, NULL, NULL /* image_writer */);
      writer.WriteFullSnapshot();
    }

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(lib, NewString("FieldsTest"));
    Dart_Handle result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
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
    Dart_Handle result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
    if (Dart_IsError(result)) {
      // Print the error.  It is probably an unhandled exception.
      fprintf(stderr, "%s\n", Dart_GetError(result));
    }
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(isolate_snapshot_data_buffer);
}

#ifndef PRODUCT

VM_UNIT_TEST_CASE(ScriptSnapshot) {
  const char* kLibScriptChars =
      "library dart_import_lib;"
      "class LibFields  {"
      "  LibFields(int i, int j) : fld1 = i, fld2 = j {}"
      "  int fld1;"
      "  final int fld2;"
      "}";
  const char* kScriptChars =
      "class TestTrace implements StackTrace {"
      "  TestTrace();"
      "  String toString() { return 'my trace'; }"
      "}"
      "class Fields  {"
      "  Fields(int i, int j) : fld1 = i, fld2 = j {}"
      "  int fld1;"
      "  final int fld2;"
      "  static int fld3;"
      "  static const int fld4 = 10;"
      "}"
      "class FieldsTest {"
      "  static Fields testMain() {"
      "    Fields obj = new Fields(10, 20);"
      "    Fields.fld3 = 100;"
      "    if (obj == null) {"
      "      throw new Exception('Allocation failure');"
      "    }"
      "    if (obj.fld1 != 10) {"
      "      throw new Exception('fld1 needs to be 10');"
      "    }"
      "    if (obj.fld2 != 20) {"
      "      throw new Exception('fld2 needs to be 20');"
      "    }"
      "    if (Fields.fld3 != 100) {"
      "      throw new Exception('Fields.fld3 needs to be 100');"
      "    }"
      "    if (Fields.fld4 != 10) {"
      "      throw new Exception('Fields.fld4 needs to be 10');"
      "    }"
      "    return obj;"
      "  }"
      "}";
  Dart_Handle result;

  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;
  intptr_t expected_num_libs;
  intptr_t actual_num_libs;

  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }
  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;

  // Test for Dart_CreateScriptSnapshot.
  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the library.
    Dart_Handle import_lib =
        Dart_LoadLibrary(NewString("dart_import_lib"), Dart_Null(),
                         NewString(kLibScriptChars), 0, 0);
    EXPECT_VALID(import_lib);

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(
        Dart_LibraryImportLibrary(TestCase::lib(), import_lib, Dart_Null()));
    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(Thread::Current()));

    // Get list of library URLs loaded and save the count.
    Dart_Handle libs = Dart_GetLibraryIds();
    EXPECT(Dart_IsList(libs));
    Dart_ListLength(libs, &expected_num_libs);

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Now Create an Isolate using the full snapshot and load the
    // script snapshot created above and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the test library from the snapshot.
    EXPECT(script_snapshot != NULL);
    result = Dart_LoadScriptFromSnapshot(script_snapshot, size);
    EXPECT_VALID(result);

    // Get list of library URLs loaded and compare with expected count.
    Dart_Handle libs = Dart_GetLibraryIds();
    EXPECT(Dart_IsList(libs));
    Dart_ListLength(libs, &actual_num_libs);

    EXPECT_EQ(expected_num_libs, actual_num_libs);

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(result, NewString("FieldsTest"));
    result = Dart_Invoke(cls, NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }
  free(full_snapshot);
  free(script_snapshot);
}

VM_UNIT_TEST_CASE(ScriptSnapshot1) {
  const char* kScriptChars =
      "class _SimpleNumEnumerable<T extends num> {"
      "final Iterable<T> _source;"
      "const _SimpleNumEnumerable(this._source) : super();"
      "}";

  Dart_Handle result;
  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;

  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
  bool saved_concurrent_sweep_mode = FLAG_concurrent_sweep;
  FLAG_concurrent_sweep = false;
  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }
  FLAG_concurrent_sweep = saved_concurrent_sweep_mode;

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Now Create an Isolate using the full snapshot and load the
    // script snapshot created above and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the test library from the snapshot.
    EXPECT(script_snapshot != NULL);
    result = Dart_LoadScriptFromSnapshot(script_snapshot, size);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }

  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;
  Dart_ShutdownIsolate();
  free(full_snapshot);
  free(script_snapshot);
}

VM_UNIT_TEST_CASE(ScriptSnapshot2) {
  // The snapshot of this library is always created in production mode, but
  // loaded and executed in both production and checked modes.
  // This test verifies that type information is still contained in the snapshot
  // although it was created in production mode and that type errors and
  // compilation errors (for const fields) are correctly reported according to
  // the execution mode.
  const char* kLibScriptChars =
      "library dart_import_lib;"
      "const String s = 1.0;"
      "final int i = true;"
      "bool b;";
  const char* kScriptChars =
      "test_s() {"
      "  s;"
      "}"
      "test_i() {"
      "  i;"
      "}"
      "test_b() {"
      "  b = 0;"
      "}";
  Dart_Handle result;

  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;

  // Force creation of snapshot in production mode.
  bool saved_enable_type_checks_mode = FLAG_enable_type_checks;
  NOT_IN_PRODUCT(FLAG_enable_type_checks = false);
  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
  bool saved_concurrent_sweep_mode = FLAG_concurrent_sweep;
  FLAG_concurrent_sweep = false;
  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }
  FLAG_concurrent_sweep = saved_concurrent_sweep_mode;

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the library.
    Dart_Handle import_lib =
        Dart_LoadLibrary(NewString("dart_import_lib"), Dart_Null(),
                         NewString(kLibScriptChars), 0, 0);
    EXPECT_VALID(import_lib);

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(
        Dart_LibraryImportLibrary(TestCase::lib(), import_lib, Dart_Null()));
    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(Thread::Current()));

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  // Continue in originally saved mode.
  NOT_IN_PRODUCT(FLAG_enable_type_checks = saved_enable_type_checks_mode);
  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;

  {
    // Now Create an Isolate using the full snapshot and load the
    // script snapshot created above and execute it.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the test library from the snapshot.
    EXPECT(script_snapshot != NULL);
    Dart_Handle lib = Dart_LoadScriptFromSnapshot(script_snapshot, size);
    EXPECT_VALID(lib);

    // Invoke the test_s function.
    result = Dart_Invoke(lib, NewString("test_s"), 0, NULL);
    EXPECT(Dart_IsError(result) == saved_enable_type_checks_mode);

    // Invoke the test_i function.
    result = Dart_Invoke(lib, NewString("test_i"), 0, NULL);
    EXPECT(Dart_IsError(result) == saved_enable_type_checks_mode);

    // Invoke the test_b function.
    result = Dart_Invoke(lib, NewString("test_b"), 0, NULL);
    EXPECT(Dart_IsError(result) == saved_enable_type_checks_mode);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(full_snapshot);
  free(script_snapshot);
}

VM_UNIT_TEST_CASE(MismatchedSnapshotKinds) {
  const char* kScriptChars = "main() { print('Hello, world!'); }";
  Dart_Handle result;

  uint8_t* buffer;
  intptr_t size;
  intptr_t vm_isolate_snapshot_size;
  uint8_t* isolate_snapshot = NULL;
  intptr_t isolate_snapshot_size;
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;

  bool saved_load_deferred_eagerly_mode = FLAG_load_deferred_eagerly;
  FLAG_load_deferred_eagerly = true;
  bool saved_concurrent_sweep_mode = FLAG_concurrent_sweep;
  FLAG_concurrent_sweep = false;
  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(NULL, &vm_isolate_snapshot_size,
                                 &isolate_snapshot, &isolate_snapshot_size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(isolate_snapshot_size));
    memmove(full_snapshot, isolate_snapshot, isolate_snapshot_size);
    Dart_ExitScope();
  }
  FLAG_concurrent_sweep = saved_concurrent_sweep_mode;
  FLAG_load_deferred_eagerly = saved_load_deferred_eagerly_mode;

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(Api::CheckAndFinalizePendingClasses(Thread::Current()));

    // Write out the script snapshot.
    result = Dart_CreateScriptSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    script_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(script_snapshot, buffer, size);
    Dart_ExitScope();
    Dart_ShutdownIsolate();
  }

  {
    // Use a script snapshot where a full snapshot is expected.
    char* error = NULL;
    Dart_Isolate isolate = Dart_CreateIsolate(
        "script-uri", "main", script_snapshot, NULL, NULL, NULL, &error);
    EXPECT(isolate == NULL);
    EXPECT(error != NULL);
    EXPECT_SUBSTRING(
        "Incompatible snapshot kinds:"
        " vm 'full', isolate 'script'",
        error);
    free(error);
  }

  {
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Use a full snapshot where a script snapshot is expected.
    Dart_Handle result = Dart_LoadScriptFromSnapshot(full_snapshot, size);
    EXPECT_ERROR(result,
                 "Dart_LoadScriptFromSnapshot expects parameter"
                 " 'buffer' to be a script type snapshot.");

    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(full_snapshot);
  free(script_snapshot);
}

#endif  // !PRODUCT

TEST_CASE(IntArrayMessage) {
  StackZone zone(Thread::Current());
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, &zone_allocator);

  static const int kArrayLength = 2;
  intptr_t data[kArrayLength] = {1, 2};
  int len = kArrayLength;
  writer.WriteMessage(len, data);

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, writer.BytesWritten());
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject_kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = root->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject_kInt32, element->type);
    EXPECT_EQ(i + 1, element->value.as_int32);
  }
  CheckEncodeDecodeMessage(root);
}

// Helper function to call a top level Dart function and serialize the result.
static uint8_t* GetSerialized(Dart_Handle lib,
                              const char* dart_function,
                              intptr_t* buffer_len) {
  Dart_Handle result;
  result = Dart_Invoke(lib, NewString(dart_function), 0, NULL);
  EXPECT_VALID(result);
  Object& obj = Object::Handle(Api::UnwrapHandle(result));

  // Serialize the object into a message.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, false);
  writer.WriteMessage(obj);
  *buffer_len = writer.BytesWritten();
  return buffer;
}

// Helper function to deserialize the result into a Dart_CObject structure.
static Dart_CObject* GetDeserialized(uint8_t* buffer, intptr_t buffer_len) {
  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(buffer, buffer_len);
  return api_reader.ReadMessage();
}

static void CheckString(Dart_Handle dart_string, const char* expected) {
  StackZone zone(Thread::Current());
  String& str = String::Handle();
  str ^= Api::UnwrapHandle(dart_string);
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, false);
  writer.WriteMessage(str);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
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
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, false);
  writer.WriteMessage(str);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject_kUnsupported, root->type);
}

VM_UNIT_TEST_CASE(DartGeneratedMessages) {
  static const char* kCustomIsolateScriptCommonChars =
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
      "  return new String.fromCharCodes([0xd800]);\n"
      "}\n"
      "getTrailSurrogateString() {\n"
      "  return \"\\u{10000}\".substring(1);\n"
      "}\n"
      "getSurrogatesString() {\n"
      "  return new String.fromCharCodes([0xdc00, 0xdc00, 0xd800, 0xd800]);\n"
      "}\n"
      "getCrappyString() {\n"
      "  return new String.fromCharCodes([0xd800, 32, 0xdc00, 32]);\n"
      "}\n"
      "getList() {\n"
      "  return new List(kArrayLength);\n"
      "}\n";
  static const char* kCustomIsolateScriptBigintChars =
      "getBigint() {\n"
      "  return -0x424242424242424242424242424242424242;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  const char* scriptChars = kCustomIsolateScriptCommonChars;
  if (!Bigint::IsDisabled()) {
    scriptChars = OS::SCreate(Thread::Current()->zone(), "%s%s", scriptChars,
                              kCustomIsolateScriptBigintChars);
  }

  Dart_Handle lib = TestCase::LoadTestScript(scriptChars, NULL);
  EXPECT_VALID(lib);
  Dart_Handle smi_result;
  smi_result = Dart_Invoke(lib, NewString("getSmi"), 0, NULL);
  EXPECT_VALID(smi_result);

  Dart_Handle bigint_result = NULL;
  if (!Bigint::IsDisabled()) {
    bigint_result = Dart_Invoke(lib, NewString("getBigint"), 0, NULL);
    EXPECT_VALID(bigint_result);
  }

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
    HANDLESCOPE(thread);

    {
      StackZone zone(thread);
      Smi& smi = Smi::Handle();
      smi ^= Api::UnwrapHandle(smi_result);
      uint8_t* buffer;
      MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, false);
      writer.WriteMessage(smi);
      intptr_t buffer_len = writer.BytesWritten();

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(buffer, buffer_len);
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kInt32, root->type);
      EXPECT_EQ(42, root->value.as_int32);
      CheckEncodeDecodeMessage(root);
    }
    if (!Bigint::IsDisabled()) {
      StackZone zone(thread);
      Bigint& bigint = Bigint::Handle();
      bigint ^= Api::UnwrapHandle(bigint_result);
      uint8_t* buffer;
      MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, false);
      writer.WriteMessage(bigint);
      intptr_t buffer_len = writer.BytesWritten();

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(buffer, buffer_len);
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kBigint, root->type);
      char* hex_value = TestCase::BigintToHexValue(root);
      EXPECT_STREQ("-0x424242424242424242424242424242424242", hex_value);
      free(hex_value);
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
      "  return new List(kArrayLength);\n"
      "}\n"
      "getIntList() {\n"
      "  var list = new List<int>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = i;\n"
      "  return list;\n"
      "}\n"
      "getStringList() {\n"
      "  var list = new List<String>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = i.toString();\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = new List(kArrayLength);\n"
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
    HANDLESCOPE(thread);
    StackZone zone(thread);
    intptr_t buf_len = 0;
    {
      // Generate a list of nulls from Dart code.
      uint8_t* buf = GetSerialized(lib, "getList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getIntList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getStringList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMixedList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      "  return [[],"
      "          [0],"
      "          [0, 1],"
      "          [0, 1, 2],"
      "          [0, 1, 2, 3],"
      "          [0, 1, 2, 3, 4],"
      "          [0, 1, 2, 3, 4, 5],"
      "          [0, 1, 2, 3, 4, 5, 6],"
      "          [0, 1, 2, 3, 4, 5, 6, 7],"
      "          [0, 1, 2, 3, 4, 5, 6, 7, 8]];\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = [];\n"
      "  list.add(0);\n"
      "  list.add('1');\n"
      "  list.add(2.2);\n"
      "  list.add(true);\n"
      "  list.add([]);\n"
      "  list.add([[]]);\n"
      "  list.add([[[]]]);\n"
      "  list.add([1, [2, [3]]]);\n"
      "  list.add([1, [1, 2, [1, 2, 3]]]);\n"
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
    HANDLESCOPE(thread);
    StackZone zone(thread);
    intptr_t buf_len = 0;
    {
      // Generate a list of nulls from Dart code.
      uint8_t* buf = GetSerialized(lib, "getList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getIntList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getStringList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getListList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMixedList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
  static const char* kScriptCommonChars =
      "import 'dart:typed_data';\n"
      "final int kArrayLength = 10;\n"
      "getStringList() {\n"
      "  var s = 'Hello, world!';\n"
      "  var list = new List<String>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = s;\n"
      "  return list;\n"
      "}\n"
      "getMintList() {\n"
      "  var mint = 0x7FFFFFFFFFFFFFFF;\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = mint;\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = new List<double>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = d;\n"
      "  return list;\n"
      "}\n"
      "getTypedDataList() {\n"
      "  var byte_array = new Uint8List(256);\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = byte_array;\n"
      "  return list;\n"
      "}\n"
      "getTypedDataViewList() {\n"
      "  var uint8_list = new Uint8List(256);\n"
      "  uint8_list[64] = 1;\n"
      "  var uint8_list_view =\n"
      "      new Uint8List.view(uint8_list.buffer, 64, 128);\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = uint8_list_view;\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list[i] = ((i % 2) == 0) ? 'A' : 2.72;\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getSelfRefList() {\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list[i] = list;\n"
      "  }\n"
      "  return list;\n"
      "}\n";
  static const char* kScriptBigintChars =
      "getBigintList() {\n"
      "  var bigint = 0x1234567890123456789012345678901234567890;\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = bigint;\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  const char* scriptChars = kScriptCommonChars;
  if (!Bigint::IsDisabled()) {
    scriptChars =
        OS::SCreate(thread->zone(), "%s%s", scriptChars, kScriptBigintChars);
  }

  Dart_Handle lib = TestCase::LoadTestScript(scriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    intptr_t buf_len = 0;
    {
      // Generate a list of strings from Dart code.
      uint8_t* buf = GetSerialized(lib, "getStringList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMintList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
    if (!Bigint::IsDisabled()) {
      // Generate a list of bigints from Dart code.
      uint8_t* buf = GetSerialized(lib, "getBigintList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kBigint, element->type);
        char* hex_value = TestCase::BigintToHexValue(element);
        EXPECT_STREQ("0x1234567890123456789012345678901234567890", hex_value);
        free(hex_value);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      uint8_t* buf = GetSerialized(lib, "getDoubleList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getTypedDataList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getTypedDataViewList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMixedList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kString, element->type);
      EXPECT_STREQ("A", element->value.as_string);
      element = root->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_STREQ(2.72, element->value.as_double);
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
          EXPECT_STREQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      uint8_t* buf = GetSerialized(lib, "getSelfRefList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
  static const char* kScriptCommonChars =
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
  static const char* kScriptBigintChars =
      "getBigintList() {\n"
      "  var bigint = 0x1234567890123456789012345678901234567890;\n"
      "  var list = [bigint, bigint, bigint, bigint, bigint,\n"
      "              bigint, bigint, bigint, bigint, bigint];\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread->isolate() != NULL);
  Dart_EnterScope();

  const char* scriptChars = kScriptCommonChars;
  if (!Bigint::IsDisabled()) {
    scriptChars =
        OS::SCreate(thread->zone(), "%s%s", scriptChars, kScriptBigintChars);
  }
  Dart_Handle lib = TestCase::LoadTestScript(scriptChars, NULL);
  EXPECT_VALID(lib);

  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    StackZone zone(thread);
    intptr_t buf_len = 0;
    {
      // Generate a list of strings from Dart code.
      uint8_t* buf = GetSerialized(lib, "getStringList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMintList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
    if (!Bigint::IsDisabled()) {
      // Generate a list of bigints from Dart code.
      uint8_t* buf = GetSerialized(lib, "getBigintList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject_kBigint, element->type);
        char* hex_value = TestCase::BigintToHexValue(element);
        EXPECT_STREQ("0x1234567890123456789012345678901234567890", hex_value);
        free(hex_value);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      uint8_t* buf = GetSerialized(lib, "getDoubleList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getTypedDataList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getTypedDataViewList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      uint8_t* buf = GetSerialized(lib, "getMixedList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      Dart_CObject* element = root->value.as_array.values[0];
      EXPECT_EQ(Dart_CObject_kString, element->type);
      EXPECT_STREQ(".", element->value.as_string);
      element = root->value.as_array.values[1];
      EXPECT_EQ(Dart_CObject_kDouble, element->type);
      EXPECT_STREQ(2.72, element->value.as_double);
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
          EXPECT_STREQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      uint8_t* buf = GetSerialized(lib, "getSelfRefList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
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
      "  var list = new List(10);\n"
      "  var index = 0;\n"
      "  list[index++] = new Int8List(256);\n"
      "  list[index++] = new Uint8List(256);\n"
      "  list[index++] = new Int16List(256);\n"
      "  list[index++] = new Uint16List(256);\n"
      "  list[index++] = new Int32List(256);\n"
      "  list[index++] = new Uint32List(256);\n"
      "  list[index++] = new Int64List(256);\n"
      "  list[index++] = new Uint64List(256);\n"
      "  list[index++] = new Float32List(256);\n"
      "  list[index++] = new Float64List(256);\n"
      "  return list;\n"
      "}\n"
      "getTypedDataViewList() {\n"
      "  var list = new List(30);\n"
      "  var index = 0;\n"
      "  list[index++] = new Int8List.view(new Int8List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Uint8List(256).buffer);\n"
      "  list[index++] = new Int16List.view(new Int16List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Uint16List(256).buffer);\n"
      "  list[index++] = new Int32List.view(new Int32List(256).buffer);\n"
      "  list[index++] = new Uint32List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = new Int64List.view(new Int64List(256).buffer);\n"
      "  list[index++] = new Uint64List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = new Float32List.view(new Float32List(256).buffer);\n"
      "  list[index++] = new Float64List.view(new Float64List(256).buffer);\n"

      "  list[index++] = new Int8List.view(new Int16List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Uint16List(256).buffer);\n"
      "  list[index++] = new Int8List.view(new Int32List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = new Int8List.view(new Int64List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = new Int8List.view(new Float32List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Float32List(256).buffer);\n"
      "  list[index++] = new Int8List.view(new Float64List(256).buffer);\n"
      "  list[index++] = new Uint8List.view(new Float64List(256).buffer);\n"

      "  list[index++] = new Int16List.view(new Int8List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Uint8List(256).buffer);\n"
      "  list[index++] = new Int16List.view(new Int32List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Uint32List(256).buffer);\n"
      "  list[index++] = new Int16List.view(new Int64List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Uint64List(256).buffer);\n"
      "  list[index++] = new Int16List.view(new Float32List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Float32List(256).buffer);\n"
      "  list[index++] = new Int16List.view(new Float64List(256).buffer);\n"
      "  list[index++] = new Uint16List.view(new Float64List(256).buffer);\n"
      "  return list;\n"
      "}\n"
      "getMultipleTypedDataViewList() {\n"
      "  var list = new List(10);\n"
      "  var index = 0;\n"
      "  var data = new Uint8List(256).buffer;\n"
      "  list[index++] = new Int8List.view(data);\n"
      "  list[index++] = new Uint8List.view(data);\n"
      "  list[index++] = new Int16List.view(data);\n"
      "  list[index++] = new Uint16List.view(data);\n"
      "  list[index++] = new Int32List.view(data);\n"
      "  list[index++] = new Uint32List.view(data);\n"
      "  list[index++] = new Int64List.view(data);\n"
      "  list[index++] = new Uint64List.view(data);\n"
      "  list[index++] = new Float32List.view(data);\n"
      "  list[index++] = new Float64List.view(data);\n"
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
    HANDLESCOPE(thread);
    StackZone zone(thread);
    intptr_t buf_len = 0;
    {
      // Generate a list of Uint8Lists from Dart code.
      uint8_t* buf = GetSerialized(lib, "getTypedDataList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},     {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 512},    {Dart_TypedData_kUint16, 512},
          {Dart_TypedData_kInt32, 1024},   {Dart_TypedData_kUint32, 1024},
          {Dart_TypedData_kInt64, 2048},   {Dart_TypedData_kUint64, 2048},
          {Dart_TypedData_kFloat32, 1024}, {Dart_TypedData_kFloat64, 2048},
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
      // Generate a list of Uint8List views from Dart code.
      uint8_t* buf = GetSerialized(lib, "getTypedDataViewList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},     {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 512},    {Dart_TypedData_kUint16, 512},
          {Dart_TypedData_kInt32, 1024},   {Dart_TypedData_kUint32, 1024},
          {Dart_TypedData_kInt64, 2048},   {Dart_TypedData_kUint64, 2048},
          {Dart_TypedData_kFloat32, 1024}, {Dart_TypedData_kFloat64, 2048},

          {Dart_TypedData_kInt8, 512},     {Dart_TypedData_kUint8, 512},
          {Dart_TypedData_kInt8, 1024},    {Dart_TypedData_kUint8, 1024},
          {Dart_TypedData_kInt8, 2048},    {Dart_TypedData_kUint8, 2048},
          {Dart_TypedData_kInt8, 1024},    {Dart_TypedData_kUint8, 1024},
          {Dart_TypedData_kInt8, 2048},    {Dart_TypedData_kUint8, 2048},

          {Dart_TypedData_kInt16, 256},    {Dart_TypedData_kUint16, 256},
          {Dart_TypedData_kInt16, 1024},   {Dart_TypedData_kUint16, 1024},
          {Dart_TypedData_kInt16, 2048},   {Dart_TypedData_kUint16, 2048},
          {Dart_TypedData_kInt16, 1024},   {Dart_TypedData_kUint16, 1024},
          {Dart_TypedData_kInt16, 2048},   {Dart_TypedData_kUint16, 2048},

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
      uint8_t* buf =
          GetSerialized(lib, "getMultipleTypedDataViewList", &buf_len);
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserialized(buf, buf_len);
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject_kArray, root->type);
      struct {
        Dart_TypedData_Type type;
        int size;
      } expected[] = {
          {Dart_TypedData_kInt8, 256},    {Dart_TypedData_kUint8, 256},
          {Dart_TypedData_kInt16, 256},   {Dart_TypedData_kUint16, 256},
          {Dart_TypedData_kInt32, 256},   {Dart_TypedData_kUint32, 256},
          {Dart_TypedData_kInt64, 256},   {Dart_TypedData_kUint64, 256},
          {Dart_TypedData_kFloat32, 256}, {Dart_TypedData_kFloat64, 256},
          {Dart_TypedData_kInvalid, -1}};

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

TEST_CASE(OmittedObjectEncodingLength) {
  StackZone zone(Thread::Current());
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator, &zone_deallocator, true);
  writer.WriteInlinedObjectHeader(kOmittedObjectId);
  // For performance, we'd like single-byte headers when ids are omitted.
  // If this starts failing, consider renumbering the snapshot ids.
  EXPECT_EQ(1, writer.BytesWritten());
}

}  // namespace dart
