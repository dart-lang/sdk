// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"
#include "platform/assert.h"
#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
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
      Bool& bl1 = Bool::Handle();
      Bool& bl2 = Bool::Handle();
      bl1 ^= expected.raw();
      bl2 ^= actual.raw();
      return bl1.value() == bl2.value();
    }
    return false;
  }
  return false;
}


static uint8_t* malloc_allocator(
    uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  return reinterpret_cast<uint8_t*>(realloc(ptr, new_size));
}


static uint8_t* zone_allocator(
    uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  Zone* zone = Isolate::Current()->current_zone();
  return zone->Realloc<uint8_t>(ptr, old_size, new_size);
}


// Compare two Dart_CObject object graphs rooted in first and
// second. The second graph will be destroyed by this operation no matter
// whether the graphs are equal or not.
static void CompareDartCObjects(Dart_CObject* first, Dart_CObject* second) {
  // Return immediately if entering a cycle.
  if (second->type == Dart_CObject::kNumberOfTypes) return;

  EXPECT_NE(first, second);
  EXPECT_EQ(first->type, second->type);
  switch (first->type) {
    case Dart_CObject::kNull:
      // Nothing more to compare.
      break;
    case Dart_CObject::kBool:
      EXPECT_EQ(first->value.as_bool, second->value.as_bool);
      break;
    case Dart_CObject::kInt32:
      EXPECT_EQ(first->value.as_int32, second->value.as_int32);
      break;
    case Dart_CObject::kInt64:
      EXPECT_EQ(first->value.as_int64, second->value.as_int64);
      break;
    case Dart_CObject::kBigint:
      EXPECT_STREQ(first->value.as_bigint, second->value.as_bigint);
      break;
    case Dart_CObject::kDouble:
      EXPECT_EQ(first->value.as_double, second->value.as_double);
      break;
    case Dart_CObject::kString:
      EXPECT_STREQ(first->value.as_string, second->value.as_string);
      break;
    case Dart_CObject::kUint8Array:
      EXPECT_EQ(first->value.as_byte_array.length,
                second->value.as_byte_array.length);
      for (int i = 0; i < first->value.as_byte_array.length; i++) {
        EXPECT_EQ(first->value.as_byte_array.values[i],
                  second->value.as_byte_array.values[i]);
      }
      break;
    case Dart_CObject::kArray:
      // Use invalid type as a visited marker to avoid infinite
      // recursion on graphs with cycles.
      second->type = Dart_CObject::kNumberOfTypes;
      EXPECT_EQ(first->value.as_array.length, second->value.as_array.length);
      for (int i = 0; i < first->value.as_array.length; i++) {
        CompareDartCObjects(first->value.as_array.values[i],
                            second->value.as_array.values[i]);
      }
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

  ApiMessageReader api_reader(buffer, writer.BytesWritten(), &zone_allocator);
  Dart_CObject* new_root = api_reader.ReadMessage();

  // Check that the two messages are the same.
  CompareDartCObjects(root, new_root);
}

TEST_CASE(SerializeNull) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Object& null_object = Object::Handle();
  writer.WriteMessage(null_object);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(null_object, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kNull, root->type);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeSmi1) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Smi& smi = Smi::Handle(Smi::New(124));
  writer.WriteMessage(smi);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeSmi2) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Smi& smi = Smi::Handle(Smi::New(-1));
  writer.WriteMessage(smi);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kInt32, root->type);
  EXPECT_EQ(smi.Value(), root->value.as_int32);
  CheckEncodeDecodeMessage(root);
}


Dart_CObject* SerializeAndDeserializeMint(const Mint& mint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  writer.WriteMessage(mint);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(serialized_object.IsMint());

  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  CheckEncodeDecodeMessage(root);
  return root;
}


void CheckMint(int64_t value) {
  Zone zone(Isolate::Current());

  const Mint& mint = Mint::Handle(Mint::New(value));
  ApiNativeScope scope;
  Dart_CObject* mint_cobject = SerializeAndDeserializeMint(mint);
  // On 64-bit platforms mints always require 64-bits as the smi range
  // here covers most of the 64-bit range. On 32-bit platforms the smi
  // range covers most of the 32-bit range and values outside that
  // range are also represented as mints.
#if defined(ARCH_IS_64_BIT)
  EXPECT_EQ(Dart_CObject::kInt64, mint_cobject->type);
  EXPECT_EQ(value, mint_cobject->value.as_int64);
#else
  if (kMinInt32 < value && value < kMaxInt32) {
    EXPECT_EQ(Dart_CObject::kInt32, mint_cobject->type);
    EXPECT_EQ(value, mint_cobject->value.as_int32);
  } else {
    EXPECT_EQ(Dart_CObject::kInt64, mint_cobject->type);
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
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Double& dbl = Double::Handle(Double::New(101.29));
  writer.WriteMessage(dbl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(dbl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kDouble, root->type);
  EXPECT_EQ(dbl.value(), root->value.as_double);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeTrue) {
  Zone zone(Isolate::Current());

  // Write snapshot with true object.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Bool& bl = Bool::Handle(Bool::True());
  writer.WriteMessage(bl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  fprintf(stderr, "%s / %s\n", bl.ToCString(), serialized_object.ToCString());

  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kBool, root->type);
  EXPECT_EQ(true, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeFalse) {
  Zone zone(Isolate::Current());

  // Write snapshot with false object.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Bool& bl = Bool::Handle(Bool::False());
  writer.WriteMessage(bl);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(bl, serialized_object));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kBool, root->type);
  EXPECT_EQ(false, root->value.as_bool);
  CheckEncodeDecodeMessage(root);
}


static uword allocator(intptr_t size) {
  return reinterpret_cast<uword>(malloc(size));
}


TEST_CASE(SerializeBigint) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Bigint& bigint = Bigint::Handle(Bigint::New(DART_INT64_C(0xfffffffff)));
  writer.WriteMessage(bigint);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  Bigint& obj = Bigint::Handle();
  obj ^= reader.ReadObject();

  EXPECT_EQ(BigintOperations::ToMint(bigint), BigintOperations::ToMint(obj));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  // Bigint not supported.
  EXPECT_NOTNULL(root);
  EXPECT_EQ(Dart_CObject::kBigint, root->type);
  EXPECT_STREQ("FFFFFFFFF", root->value.as_bigint);
  CheckEncodeDecodeMessage(root);
}


Dart_CObject* SerializeAndDeserializeBigint(const Bigint& bigint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  writer.WriteMessage(bigint);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  Bigint& serialized_bigint = Bigint::Handle();
  serialized_bigint ^= reader.ReadObject();
  const char* str1 = BigintOperations::ToHexCString(bigint, allocator);
  const char* str2 =
      BigintOperations::ToHexCString(serialized_bigint, allocator);
  EXPECT_STREQ(str1, str2);
  free(const_cast<char*>(str1));
  free(const_cast<char*>(str2));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  // Bigint not supported.
  EXPECT_NOTNULL(root);
  CheckEncodeDecodeMessage(root);
  return root;
}


void CheckBigint(const char* bigint_value) {
  Zone zone(Isolate::Current());

  Bigint& bigint = Bigint::Handle();
  bigint ^= BigintOperations::NewFromCString(bigint_value);
  Dart_CObject* bigint_cobject = SerializeAndDeserializeBigint(bigint);
  EXPECT_EQ(Dart_CObject::kBigint, bigint_cobject->type);
  if (bigint_value[0] == '0') {
    EXPECT_STREQ(bigint_value + 2, bigint_cobject->value.as_bigint);
  } else {
    EXPECT_EQ('-', bigint_value[0]);
    EXPECT_EQ('-', bigint_cobject->value.as_bigint[0]);
    EXPECT_STREQ(bigint_value + 3, bigint_cobject->value.as_bigint + 1);
  }
}


TEST_CASE(SerializeBigint2) {
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
  MessageWriter writer(&buffer, &malloc_allocator);
  writer.WriteObject(Object::class_class());
  writer.WriteObject(Object::null_class());
  writer.WriteObject(Object::type_arguments_class());
  writer.WriteObject(Object::instantiated_type_arguments_class());
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
  SnapshotReader reader(buffer, buffer_len, Snapshot::kMessage,
                        Isolate::Current());
  EXPECT(Object::class_class() == reader.ReadObject());
  EXPECT(Object::null_class() == reader.ReadObject());
  EXPECT(Object::type_arguments_class() == reader.ReadObject());
  EXPECT(Object::instantiated_type_arguments_class() == reader.ReadObject());
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


TEST_CASE(SerializeString) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  static const char* cstr = "This string shall be serialized";
  String& str = String::Handle(String::New(cstr));
  writer.WriteMessage(str);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  String& serialized_str = String::Handle();
  serialized_str ^= reader.ReadObject();
  EXPECT(str.Equals(serialized_str));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kString, root->type);
  EXPECT_STREQ(cstr, root->value.as_string);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeArray) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const int kArrayLength = 10;
  Array& array = Array::Handle(Array::New(kArrayLength));
  Smi& smi = Smi::Handle();
  for (int i = 0; i < kArrayLength; i++) {
    smi ^= Smi::New(i);
    array.SetAt(i, smi);
  }
  writer.WriteMessage(array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.Equals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = root->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject::kInt32, element->type);
    EXPECT_EQ(i, element->value.as_int32);
  }
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeEmptyArray) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const int kArrayLength = 0;
  Array& array = Array::Handle(Array::New(kArrayLength));
  writer.WriteMessage(array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.Equals(serialized_array));

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  EXPECT(root->value.as_array.values == NULL);
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeByteArray) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const int kByteArrayLength = 256;
  Uint8Array& byte_array =
      Uint8Array::Handle(Uint8Array::New(kByteArrayLength));
  for (int i = 0; i < kByteArrayLength; i++) {
    byte_array.SetAt(i, i);
  }
  writer.WriteMessage(byte_array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  ByteArray& serialized_byte_array = ByteArray::Handle();
  serialized_byte_array ^= reader.ReadObject();
  EXPECT(serialized_byte_array.IsByteArray());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kUint8Array, root->type);
  EXPECT_EQ(kByteArrayLength, root->value.as_byte_array.length);
  for (int i = 0; i < kByteArrayLength; i++) {
    EXPECT(root->value.as_byte_array.values[i] == i);
  }
  CheckEncodeDecodeMessage(root);
}


TEST_CASE(SerializeEmptyByteArray) {
  Zone zone(Isolate::Current());

  // Write snapshot with object content.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const int kByteArrayLength = 0;
  Uint8Array& byte_array =
      Uint8Array::Handle(Uint8Array::New(kByteArrayLength));
  writer.WriteMessage(byte_array);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, buffer_len,
                        Snapshot::kMessage, Isolate::Current());
  ByteArray& serialized_byte_array = ByteArray::Handle();
  serialized_byte_array ^= reader.ReadObject();
  EXPECT(serialized_byte_array.IsByteArray());

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kUint8Array, root->type);
  EXPECT_EQ(kByteArrayLength, root->value.as_byte_array.length);
  EXPECT(root->value.as_byte_array.values == NULL);
  CheckEncodeDecodeMessage(root);
}


class TestSnapshotWriter : public SnapshotWriter {
 public:
  static const intptr_t kIncrementSize = 64 * KB;
  TestSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kScript, buffer, alloc, kIncrementSize) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~TestSnapshotWriter() { }

  // Writes just a script object
  void WriteScript(const Script& script) {
    WriteObject(script.raw());
    UnmarkAll();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TestSnapshotWriter);
};


static void GenerateSourceAndCheck(const Script& script) {
  // Check if we are able to generate the source from the token stream.
  // Rescan this source and compare the token stream to see if they are
  // the same.
  const TokenStream& expected_tokens = TokenStream::Handle(script.tokens());
  TokenStream::Iterator expected_iterator(expected_tokens, 0);
  const String& str = String::Handle(expected_tokens.GenerateSource());
  const String& private_key = String::Handle(expected_tokens.PrivateKey());
  Scanner scanner(str, private_key);
  const TokenStream& reconstructed_tokens =
      TokenStream::Handle(TokenStream::New(scanner.GetStream(), private_key));
  expected_iterator.SetCurrentPosition(0);
  TokenStream::Iterator reconstructed_iterator(reconstructed_tokens, 0);
  Token::Kind expected_kind = expected_iterator.CurrentTokenKind();
  Token::Kind reconstructed_kind = reconstructed_iterator.CurrentTokenKind();
  String& expected_literal = String::Handle();
  String& actual_literal = String::Handle();
  while (expected_kind != Token::kEOS && reconstructed_kind != Token::kEOS) {
    EXPECT_EQ(expected_kind, reconstructed_kind);
    expected_literal ^= expected_iterator.CurrentLiteral();
    actual_literal ^= reconstructed_iterator.CurrentLiteral();
    EXPECT(expected_literal.Equals(actual_literal));
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
      "}\n";

  String& url = String::Handle(String::New("dart-test:SerializeScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kSourceTag));
  const String& lib_url = String::Handle(Symbols::New("TestLib"));
  Library& lib = Library::Handle(Library::New(lib_url));
  lib.Register();
  EXPECT(CompilerTest::TestCompileScript(lib, script));

  // Write snapshot with script content.
  uint8_t* buffer;
  TestSnapshotWriter writer(&buffer, &malloc_allocator);
  writer.WriteScript(script);

  // Read object back from the snapshot.
  SnapshotReader reader(buffer, writer.BytesWritten(),
                        Snapshot::kScript, Isolate::Current());
  Script& serialized_script = Script::Handle();
  serialized_script ^= reader.ReadObject();

  // Check if the serialized script object matches the original script.
  String& expected_literal = String::Handle();
  String& actual_literal = String::Handle();
  String& str = String::Handle();
  str ^= serialized_script.url();
  EXPECT(url.Equals(str));

  const TokenStream& expected_tokens = TokenStream::Handle(script.tokens());
  const TokenStream& serialized_tokens =
      TokenStream::Handle(serialized_script.tokens());
  const ExternalUint8Array& expected_data =
      ExternalUint8Array::Handle(expected_tokens.GetStream());
  const ExternalUint8Array& serialized_data =
      ExternalUint8Array::Handle(serialized_tokens.GetStream());
  EXPECT_EQ(expected_data.Length(), serialized_data.Length());
  TokenStream::Iterator expected_iterator(expected_tokens, 0);
  TokenStream::Iterator serialized_iterator(serialized_tokens, 0);
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


static void IterateScripts(const Library& lib) {
  const Array& lib_scripts = Array::Handle(lib.LoadedScripts());
  Script& script = Script::Handle();
  for (intptr_t i = 0; i < lib_scripts.Length(); i++) {
    script ^= lib_scripts.At(i);
    EXPECT(!script.IsNull());
    GenerateSourceAndCheck(script);
  }
}

TEST_CASE(GenerateSource) {
  Library& lib = Library::Handle();
  // Check core lib.
  lib = Library::CoreLibrary();
  EXPECT(!lib.IsNull());
  IterateScripts(lib);

  // Check core impl lib.
  lib = Library::CoreImplLibrary();
  EXPECT(!lib.IsNull());
  IterateScripts(lib);

  // Check isolate lib.
  lib = Library::IsolateLibrary();
  EXPECT(!lib.IsNull());
  IterateScripts(lib);

  // Check math lib.
  lib = Library::MathLibrary();
  EXPECT(!lib.IsNull());
  IterateScripts(lib);

  // Check mirrors lib.
  lib = Library::MirrorsLibrary();
  EXPECT(!lib.IsNull());
  IterateScripts(lib);
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
UNIT_TEST_CASE(FullSnapshot) {
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
      "class FieldsTest {\n"
      "  static Fields testMain() {\n"
      "    Expect.equals(true, Fields.bigint_sfld == 0xfffffffffff);\n"
      "    Fields obj = new Fields(10, 20);\n"
      "    Expect.equals(true, obj.bigint_fld == 0xfffffffffff);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Handle result;

  uint8_t* buffer;

  // Start an Isolate, load a script and create a full snapshot.
  Timer timer1(true, "Snapshot_test");
  timer1.Start();
  {
    TestIsolateScope __test_isolate__;

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %"Pd64"us\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    Isolate* isolate = Isolate::Current();
    Zone zone(isolate);
    HandleScope scope(isolate);
    FullSnapshotWriter writer(&buffer, &malloc_allocator);
    writer.WriteFullSnapshot();
  }

  // Now Create another isolate using the snapshot and execute a method
  // from the script.
  Timer timer2(true, "Snapshot_test");
  timer2.Start();
  TestCase::CreateTestIsolateFromSnapshot(buffer);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    timer2.Stop();
    OS::PrintErr("From Snapshot: %"Pd64"us\n", timer2.TotalElapsedTime());

    // Invoke a function which returns an object.
    Dart_Handle cls =
        Dart_GetClass(TestCase::lib(), Dart_NewString("FieldsTest"));
    result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(buffer);
}


UNIT_TEST_CASE(FullSnapshot1) {
  // This buffer has to be static for this to compile with Visual Studio.
  // If it is not static compilation of this file with Visual Studio takes
  // more than 30 minutes!
  static const char kFullSnapshotScriptChars[] = {
#include "snapshot_test.dat"
  };
  const char* kScriptChars = kFullSnapshotScriptChars;

  uint8_t* buffer;

  // Start an Isolate, load a script and create a full snapshot.
  Timer timer1(true, "Snapshot_test");
  timer1.Start();
  {
    TestIsolateScope __test_isolate__;

    Isolate* isolate = Isolate::Current();
    Zone zone(isolate);
    HandleScope scope(isolate);

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
    ClassFinalizer::FinalizePendingClasses();
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %"Pd64"us\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    FullSnapshotWriter writer(&buffer, &malloc_allocator);
    writer.WriteFullSnapshot();

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("FieldsTest"));
    Dart_Handle result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
  }

  // Now Create another isolate using the snapshot and execute a method
  // from the script.
  Timer timer2(true, "Snapshot_test");
  timer2.Start();
  TestCase::CreateTestIsolateFromSnapshot(buffer);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    timer2.Stop();
    OS::PrintErr("From Snapshot: %"Pd64"us\n", timer2.TotalElapsedTime());

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(TestCase::lib(),
                                    Dart_NewString("FieldsTest"));
    Dart_Handle result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
    if (Dart_IsError(result)) {
      // Print the error.  It is probably an unhandled exception.
      fprintf(stderr, "%s\n", Dart_GetError(result));
    }
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(buffer);
}


UNIT_TEST_CASE(ScriptSnapshot) {
  const char* kLibScriptChars =
      "#library('dart:import-lib');"
      "class LibFields  {"
      "  LibFields(int i, int j) : fld1 = i, fld2 = j {}"
      "  int fld1;"
      "  final int fld2;"
      "}";
  const char* kScriptChars =
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
      "    if (obj === null) {"
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
  uint8_t* full_snapshot = NULL;
  uint8_t* script_snapshot = NULL;
  intptr_t expected_num_libs;
  intptr_t actual_num_libs;

  {
    // Start an Isolate, and create a full snapshot of it.
    TestIsolateScope __test_isolate__;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Write out the script snapshot.
    result = Dart_CreateSnapshot(&buffer, &size);
    EXPECT_VALID(result);
    full_snapshot = reinterpret_cast<uint8_t*>(malloc(size));
    memmove(full_snapshot, buffer, size);
    Dart_ExitScope();
  }

  {
    // Create an Isolate using the full snapshot, load a script and create
    // a script snapshot of the script.
    TestCase::CreateTestIsolateFromSnapshot(full_snapshot);
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load the library.
    Dart_Handle import_lib = Dart_LoadLibrary(Dart_NewString("dart:import-lib"),
                                              Dart_NewString(kLibScriptChars));
    EXPECT_VALID(import_lib);

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);

    EXPECT_VALID(Dart_LibraryImportLibrary(TestCase::lib(),
                                           import_lib,
                                           Dart_Null()));

    // Get list of library URLs loaded and save the count.
    Dart_Handle libs = Dart_GetLibraryURLs();
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
    result = Dart_LoadScriptFromSnapshot(script_snapshot);
    EXPECT_VALID(result);

    // Get list of library URLs loaded and compare with expected count.
    Dart_Handle libs = Dart_GetLibraryURLs();
    EXPECT(Dart_IsList(libs));
    Dart_ListLength(libs, &actual_num_libs);

    EXPECT_EQ(expected_num_libs, actual_num_libs);

    // Invoke a function which returns an object.
    Dart_Handle cls = Dart_GetClass(result, Dart_NewString("FieldsTest"));
    result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(full_snapshot);
  free(script_snapshot);
}


TEST_CASE(IntArrayMessage) {
  Zone zone(Isolate::Current());
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, &zone_allocator);

  static const int kArrayLength = 2;
  intptr_t data[kArrayLength] = {1, 2};
  int len = kArrayLength;
  writer.WriteMessage(len, data);

  // Read object back from the snapshot into a C structure.
  ApiNativeScope scope;
  ApiMessageReader api_reader(buffer, writer.BytesWritten(), &zone_allocator);
  Dart_CObject* root = api_reader.ReadMessage();
  EXPECT_EQ(Dart_CObject::kArray, root->type);
  EXPECT_EQ(kArrayLength, root->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = root->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject::kInt32, element->type);
    EXPECT_EQ(i + 1, element->value.as_int32);
  }
  CheckEncodeDecodeMessage(root);
}


// Helper function to call a top level Dart function, serialize the
// result and deserialize the result into a Dart_CObject structure.
static Dart_CObject* GetDeserializedDartMessage(Dart_Handle lib,
                                                const char* dart_function) {
  Dart_Handle result;
  result = Dart_Invoke(lib, Dart_NewString(dart_function), 0, NULL);
  EXPECT_VALID(result);

  // Serialize the list into a message.
  uint8_t* buffer;
  MessageWriter writer(&buffer, &zone_allocator);
  const Object& list = Object::Handle(Api::UnwrapHandle(result));
  writer.WriteMessage(list);
  intptr_t buffer_len = writer.BytesWritten();

  // Read object back from the snapshot into a C structure.
  ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
  return api_reader.ReadMessage();
}


UNIT_TEST_CASE(DartGeneratedMessages) {
  static const char* kCustomIsolateScriptChars =
      "getSmi() {\n"
      "  return 42;\n"
      "}\n"
      "getBigint() {\n"
      "  return -0x424242424242424242424242424242424242;\n"
      "}\n"
      "getString() {\n"
      "  return \"Hello, world!\";\n"
      "}\n"
      "getList() {\n"
      "  return new List(kArrayLength);\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kCustomIsolateScriptChars,
                                             NULL);
  EXPECT_VALID(lib);
  Dart_Handle smi_result;
  smi_result = Dart_Invoke(lib, Dart_NewString("getSmi"), 0, NULL);
  EXPECT_VALID(smi_result);
  Dart_Handle bigint_result;
  bigint_result = Dart_Invoke(lib, Dart_NewString("getBigint"), 0, NULL);
  EXPECT_VALID(bigint_result);
  Dart_Handle string_result;
  string_result = Dart_Invoke(lib, Dart_NewString("getString"), 0, NULL);
  EXPECT_VALID(string_result);
  EXPECT(Dart_IsString(string_result));

  {
    DARTSCOPE_NOCHECKS(isolate);

    {
      Zone zone(Isolate::Current());
      uint8_t* buffer;
      MessageWriter writer(&buffer, &zone_allocator);
      Smi& smi = Smi::Handle();
      smi ^= Api::UnwrapHandle(smi_result);
      writer.WriteMessage(smi);
      intptr_t buffer_len = writer.BytesWritten();

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kInt32, root->type);
      EXPECT_EQ(42, root->value.as_int32);
      CheckEncodeDecodeMessage(root);
    }
    {
      Zone zone(Isolate::Current());
      uint8_t* buffer;
      MessageWriter writer(&buffer, &zone_allocator);
      Bigint& bigint = Bigint::Handle();
      bigint ^= Api::UnwrapHandle(bigint_result);
      writer.WriteMessage(bigint);
      intptr_t buffer_len = writer.BytesWritten();

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kBigint, root->type);
      EXPECT_STREQ("-424242424242424242424242424242424242",
                   root->value.as_bigint);
      CheckEncodeDecodeMessage(root);
    }
    {
      Zone zone(Isolate::Current());
      uint8_t* buffer;
      MessageWriter writer(&buffer, &zone_allocator);
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(string_result);
      writer.WriteMessage(str);
      intptr_t buffer_len = writer.BytesWritten();

      // Read object back from the snapshot into a C structure.
      ApiNativeScope scope;
      ApiMessageReader api_reader(buffer, buffer_len, &zone_allocator);
      Dart_CObject* root = api_reader.ReadMessage();
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kString, root->type);
      EXPECT_STREQ("Hello, world!", root->value.as_string);
      CheckEncodeDecodeMessage(root);
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DartGeneratedListMessages) {
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
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    DARTSCOPE_NOCHECKS(isolate);
    {
      // Generate a list of nulls from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kNull, root->value.as_array.values[i]->type);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of ints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getIntList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kInt32, root->value.as_array.values[i]->type);
        EXPECT_EQ(i, root->value.as_array.values[i]->value.as_int32);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of strings from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getStringList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kString, root->value.as_array.values[i]->type);
        char buffer[3];
        snprintf(buffer, sizeof(buffer), "%d", i);
        EXPECT_STREQ(buffer, root->value.as_array.values[i]->value.as_string);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMixedList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);

      EXPECT_EQ(Dart_CObject::kInt32, root->value.as_array.values[0]->type);
      EXPECT_EQ(0, root->value.as_array.values[0]->value.as_int32);
      EXPECT_EQ(Dart_CObject::kString, root->value.as_array.values[1]->type);
      EXPECT_STREQ("1", root->value.as_array.values[1]->value.as_string);
      EXPECT_EQ(Dart_CObject::kDouble, root->value.as_array.values[2]->type);
      EXPECT_EQ(2.2, root->value.as_array.values[2]->value.as_double);
      EXPECT_EQ(Dart_CObject::kBool, root->value.as_array.values[3]->type);
      EXPECT_EQ(true, root->value.as_array.values[3]->value.as_bool);

      for (int i = 0; i < kArrayLength; i++) {
        if (i > 3) {
          EXPECT_EQ(Dart_CObject::kNull, root->value.as_array.values[i]->type);
        }
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DartGeneratedArrayLiteralMessages) {
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
      "getMixedList() {\n"
      "  var list = [];\n"
      "  list.add(0);\n"
      "  list.add('1');\n"
      "  list.add(2.2);\n"
      "  list.add(true);\n"
      "  list.add(null);\n"
      "  list.add(null);\n"
      "  list.add(null);\n"
      "  list.add(null);\n"
      "  list.add(null);\n"
      "  list.add(null);\n"
      "  return list;\n"
      "}\n";

  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    DARTSCOPE_NOCHECKS(isolate);
    {
      // Generate a list of nulls from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kNull, root->value.as_array.values[i]->type);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of ints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getIntList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kInt32, root->value.as_array.values[i]->type);
        EXPECT_EQ(i, root->value.as_array.values[i]->value.as_int32);
      }
      CheckEncodeDecodeMessage(root);
    }
    {
      // Generate a list of strings from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getStringList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kString, root->value.as_array.values[i]->type);
        char buffer[3];
        snprintf(buffer, sizeof(buffer), "%d", i);
        EXPECT_STREQ(buffer, root->value.as_array.values[i]->value.as_string);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMixedList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);

      EXPECT_EQ(Dart_CObject::kInt32, root->value.as_array.values[0]->type);
      EXPECT_EQ(0, root->value.as_array.values[0]->value.as_int32);
      EXPECT_EQ(Dart_CObject::kString, root->value.as_array.values[1]->type);
      EXPECT_STREQ("1", root->value.as_array.values[1]->value.as_string);
      EXPECT_EQ(Dart_CObject::kDouble, root->value.as_array.values[2]->type);
      EXPECT_EQ(2.2, root->value.as_array.values[2]->value.as_double);
      EXPECT_EQ(Dart_CObject::kBool, root->value.as_array.values[3]->type);
      EXPECT_EQ(true, root->value.as_array.values[3]->value.as_bool);

      for (int i = 0; i < kArrayLength; i++) {
        if (i > 3) {
          EXPECT_EQ(Dart_CObject::kNull, root->value.as_array.values[i]->type);
        }
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DartGeneratedListMessagesWithBackref) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "#import('dart:scalarlist');\n"
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
      "getBigintList() {\n"
      "  var bigint = 0x1234567890123456789012345678901234567890;\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = bigint;\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = new List<double>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = d;\n"
      "  return list;\n"
      "}\n"
      "getByteArrayList() {\n"
      "  var byte_array = new Uint8List(256);\n"
      "  var list = new List(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = byte_array;\n"
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

  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    DARTSCOPE_NOCHECKS(isolate);

    {
      // Generate a list of strings from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getStringList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kString, element->type);
        EXPECT_STREQ("Hello, world!", element->value.as_string);
      }
    }
    {
      // Generate a list of medium ints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMintList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kInt64, element->type);
        EXPECT_EQ(DART_INT64_C(0x7FFFFFFFFFFFFFFF), element->value.as_int64);
      }
    }
    {
      // Generate a list of bigints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getBigintList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kBigint, element->type);
        EXPECT_STREQ("1234567890123456789012345678901234567890",
                     element->value.as_bigint);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getDoubleList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kDouble, element->type);
        EXPECT_EQ(3.14, element->value.as_double);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getByteArrayList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kUint8Array, element->type);
        EXPECT_EQ(256, element->value.as_byte_array.length);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMixedList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        if ((i % 2) == 0) {
          EXPECT_EQ(root->value.as_array.values[0], element);
          EXPECT_EQ(Dart_CObject::kString, element->type);
          EXPECT_STREQ("A", element->value.as_string);
        } else {
          EXPECT_EQ(root->value.as_array.values[1], element);
          EXPECT_EQ(Dart_CObject::kDouble, element->type);
          EXPECT_STREQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getSelfRefList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject::kArray, element->type);
        EXPECT_EQ(root, element);
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DartGeneratedArrayLiteralMessagesWithBackref) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "#import('dart:scalarlist');\n"
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
      "getBigintList() {\n"
      "  var bigint = 0x1234567890123456789012345678901234567890;\n"
      "  var list = [bigint, bigint, bigint, bigint, bigint,\n"
      "              bigint, bigint, bigint, bigint, bigint];\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = [3.14, 3.14, 3.14, 3.14, 3.14, 3.14];\n"
      "  list.add(3.14);;\n"
      "  list.add(3.14);;\n"
      "  list.add(3.14);;\n"
      "  list.add(3.14);;\n"
      "  return list;\n"
      "}\n"
      "getByteArrayList() {\n"
      "  var byte_array = new Uint8List(256);\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(byte_array);\n"
      "  }\n"
      "  return list;\n"
      "}\n"
      "getMixedList() {\n"
      "  var list = [];\n"
      "  for (var i = 0; i < kArrayLength; i++) {\n"
      "    list.add(((i % 2) == 0) ? 'A' : 2.72);\n"
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
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  Dart_EnterScope();

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  {
    DARTSCOPE_NOCHECKS(isolate);

    {
      // Generate a list of strings from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getStringList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kString, element->type);
        EXPECT_STREQ("Hello, world!", element->value.as_string);
      }
    }
    {
      // Generate a list of medium ints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMintList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kInt64, element->type);
        EXPECT_EQ(DART_INT64_C(0x7FFFFFFFFFFFFFFF), element->value.as_int64);
      }
    }
    {
      // Generate a list of bigints from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getBigintList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kBigint, element->type);
        EXPECT_STREQ("1234567890123456789012345678901234567890",
                     element->value.as_bigint);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getDoubleList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kDouble, element->type);
        EXPECT_EQ(3.14, element->value.as_double);
      }
    }
    {
      // Generate a list of doubles from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getByteArrayList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(root->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kUint8Array, element->type);
        EXPECT_EQ(256, element->value.as_byte_array.length);
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getMixedList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        if ((i % 2) == 0) {
          EXPECT_EQ(root->value.as_array.values[0], element);
          EXPECT_EQ(Dart_CObject::kString, element->type);
          EXPECT_STREQ("A", element->value.as_string);
        } else {
          EXPECT_EQ(root->value.as_array.values[1], element);
          EXPECT_EQ(Dart_CObject::kDouble, element->type);
          EXPECT_STREQ(2.72, element->value.as_double);
        }
      }
    }
    {
      // Generate a list of objects of different types from Dart code.
      ApiNativeScope scope;
      Dart_CObject* root = GetDeserializedDartMessage(lib, "getSelfRefList");
      EXPECT_NOTNULL(root);
      EXPECT_EQ(Dart_CObject::kArray, root->type);
      EXPECT_EQ(kArrayLength, root->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = root->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject::kArray, element->type);
        EXPECT_EQ(root, element);
      }
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(PostCObject) {
  // Create a native port for posting from C to Dart
  TestIsolateScope __test_isolate__;
  const char* kScriptChars =
      "#import('dart:isolate');\n"
      "main() {\n"
      "  var messageCount = 0;\n"
      "  var exception = '';\n"
      "  var port = new ReceivePort();\n"
      "  port.receive((message, replyTo) {\n"
      "    if (messageCount < 7) {\n"
      "      exception = '$exception${message}';\n"
      "    } else {\n"
      "      exception = '$exception${message.length}';\n"
      "      for (int i = 0; i < message.length; i++) {\n"
      "        exception = '$exception${message[i]}';\n"
      "      }\n"
      "    }\n"
      "    messageCount++;\n"
      "    if (messageCount == 8) throw new Exception(exception);\n"
      "  });\n"
      "  return port.toSendPort();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  // xxx
  Dart_Handle send_port = Dart_Invoke(lib, Dart_NewString("main"), 0, NULL);
  EXPECT_VALID(send_port);
  Dart_Handle result = Dart_GetField(send_port, Dart_NewString("_id"));
  ASSERT(!Dart_IsError(result));
  ASSERT(Dart_IsInteger(result));
  int64_t send_port_id;
  Dart_Handle result2 = Dart_IntegerToInt64(result, &send_port_id);
  ASSERT(!Dart_IsError(result2));

  // Setup single object message.
  Dart_CObject object;

  object.type = Dart_CObject::kNull;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kBool;
  object.value.as_bool = true;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kBool;
  object.value.as_bool = false;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kInt32;
  object.value.as_int32 = 123;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kString;
  object.value.as_string = const_cast<char*>("456");
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kDouble;
  object.value.as_double = 3.14;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  object.type = Dart_CObject::kArray;
  object.value.as_array.length = 0;
  EXPECT(Dart_PostCObject(send_port_id, &object));

  static const int kArrayLength = 10;
  Dart_CObject* array =
      reinterpret_cast<Dart_CObject*>(
          Dart_ScopeAllocate(
              sizeof(Dart_CObject) + sizeof(Dart_CObject*) * kArrayLength));  // NOLINT
  array->type = Dart_CObject::kArray;
  array->value.as_array.length = kArrayLength;
  array->value.as_array.values =
      reinterpret_cast<Dart_CObject**>(array + 1);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element =
        reinterpret_cast<Dart_CObject*>(
            Dart_ScopeAllocate(sizeof(Dart_CObject)));
    element->type = Dart_CObject::kInt32;
    element->value.as_int32 = i;
    array->value.as_array.values[i] = element;
  }
  EXPECT(Dart_PostCObject(send_port_id, array));

  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: nulltruefalse1234563.14[]100123456789\n",
                   Dart_GetError(result));

  Dart_ExitScope();
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
