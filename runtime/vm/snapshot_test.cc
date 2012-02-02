// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"
#include "platform/assert.h"
#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/snapshot.h"
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
  return false;
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  return reinterpret_cast<uint8_t*>(realloc(ptr, new_size));
}


TEST_CASE(SerializeNull) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Object& null_object = Object::Handle();
  writer.WriteObject(null_object.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(null_object, serialized_object));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                        writer.BytesWritten(),
                        &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_NOTNULL(cobject);
  EXPECT_EQ(Dart_CObject::kNull, cobject->type);
  free(cobject);
}


TEST_CASE(SerializeSmi1) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Smi& smi = Smi::Handle(Smi::New(124));
  writer.WriteObject(smi.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_NOTNULL(cobject);
  EXPECT_EQ(Dart_CObject::kInt32, cobject->type);
  EXPECT_EQ(smi.Value(), cobject->value.as_int32);
  free(cobject);
}


TEST_CASE(SerializeSmi2) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Smi& smi = Smi::Handle(Smi::New(-1));
  writer.WriteObject(smi.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_NOTNULL(cobject);
  EXPECT_EQ(Dart_CObject::kInt32, cobject->type);
  EXPECT_EQ(smi.Value(), cobject->value.as_int32);
  free(cobject);
}


TEST_CASE(SerializeDouble) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Double& dbl = Double::Handle(Double::New(101.29));
  writer.WriteObject(dbl.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(dbl, serialized_object));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_NOTNULL(cobject);
  EXPECT_EQ(Dart_CObject::kDouble, cobject->type);
  EXPECT_EQ(dbl.value(), cobject->value.as_double);
  free(cobject);
}


TEST_CASE(SerializeBool) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Bool& bool1 = Bool::Handle(Bool::True());
  const Bool& bool2 = Bool::Handle(Bool::False());
  writer.WriteObject(bool1.raw());
  writer.WriteObject(bool2.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  EXPECT(Bool::True() == reader.ReadObject());
  EXPECT(Bool::False() == reader.ReadObject());

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject1 = mreader.ReadObject();
  EXPECT_NOTNULL(cobject1);
  EXPECT_EQ(Dart_CObject::kBool, cobject1->type);
  EXPECT_EQ(true, cobject1->value.as_bool);
  Dart_CObject* cobject2 = mreader.ReadObject();
  EXPECT_NOTNULL(cobject2);
  EXPECT_EQ(Dart_CObject::kBool, cobject2->type);
  EXPECT_EQ(false, cobject2->value.as_bool);
  free(cobject1);
  free(cobject2);
}


TEST_CASE(SerializeBigint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Bigint& bigint = Bigint::Handle(Bigint::New(0xfffffffffLL));
  writer.WriteObject(bigint.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  Bigint& obj = Bigint::Handle();
  obj ^= reader.ReadObject();
  OS::Print("%lld", BigintOperations::ToInt64(obj));
  EXPECT_EQ(BigintOperations::ToInt64(bigint), BigintOperations::ToInt64(obj));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  // Bigint not supported.
  EXPECT(cobject == NULL);
}


TEST_CASE(SerializeSingletons) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  writer.WriteObject(Object::class_class());
  writer.WriteObject(Object::null_class());
  writer.WriteObject(Object::type_class());
  writer.WriteObject(Object::type_parameter_class());
  writer.WriteObject(Object::instantiated_type_class());
  writer.WriteObject(Object::abstract_type_arguments_class());
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
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  EXPECT(Object::class_class() == reader.ReadObject());
  EXPECT(Object::null_class() == reader.ReadObject());
  EXPECT(Object::type_class() == reader.ReadObject());
  EXPECT(Object::type_parameter_class() == reader.ReadObject());
  EXPECT(Object::instantiated_type_class() == reader.ReadObject());
  EXPECT(Object::abstract_type_arguments_class() == reader.ReadObject());
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
}


TEST_CASE(SerializeString) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  static const char* cstr = "This string shall be serialized";
  String& str = String::Handle(String::New(cstr));
  writer.WriteObject(str.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  String& serialized_str = String::Handle();
  serialized_str ^= reader.ReadObject();
  EXPECT(str.Equals(serialized_str));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_EQ(Dart_CObject::kString, cobject->type);
  EXPECT_STREQ(cstr, cobject->value.as_string);
  free(cobject);
}


TEST_CASE(SerializeArray) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const int kArrayLength = 10;
  Array& array = Array::Handle(Array::New(kArrayLength));
  Smi& smi = Smi::Handle();
  for (int i = 0; i < kArrayLength; i++) {
    smi ^= Smi::New(i);
    array.SetAt(i, smi);
  }
  writer.WriteObject(array.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.Equals(serialized_array));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_EQ(Dart_CObject::kArray, cobject->type);
  EXPECT_EQ(kArrayLength, cobject->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = cobject->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject::kInt32, element->type);
    EXPECT_EQ(i, element->value.as_int32);
    free(element);
  }
  free(cobject);
}


TEST_CASE(SerializeEmptyArray) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const int kArrayLength = 0;
  Array& array = Array::Handle(Array::New(kArrayLength));
  writer.WriteObject(array.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.Equals(serialized_array));

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* cobject = mreader.ReadObject();
  EXPECT_EQ(Dart_CObject::kArray, cobject->type);
  EXPECT_EQ(kArrayLength, cobject->value.as_array.length);
  EXPECT(cobject->value.as_array.values == NULL);
  free(cobject);
}


TEST_CASE(SerializeScript) {
  const char* kScriptChars =
      "class A {\n"
      "  static bar() { return 42; }\n"
      "  static fly() { return 5; }\n"
      "}\n";

  String& url = String::Handle(String::New("dart-test:SerializeScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kSource));
  const String& lib_url = String::Handle(String::NewSymbol("TestLib"));
  Library& lib = Library::Handle(Library::New(lib_url));
  lib.Register();
  EXPECT(CompilerTest::TestCompileScript(lib, script));

  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kScript, &buffer, &allocator);
  writer.WriteObject(script.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  Script& serialized_script = Script::Handle();
  serialized_script ^= reader.ReadObject();

  // Check if the serialized script object matches the original script.
  String& str = String::Handle();
  str ^= serialized_script.source();
  EXPECT(source.Equals(str));
  str ^= serialized_script.url();
  EXPECT(url.Equals(str));
  const TokenStream& expected_tokens = TokenStream::Handle(script.tokens());
  const TokenStream& serialized_tokens =
      TokenStream::Handle(serialized_script.tokens());
  EXPECT_EQ(expected_tokens.Length(), serialized_tokens.Length());
  String& expected_literal = String::Handle();
  String& actual_literal = String::Handle();
  for (intptr_t i = 0; i < expected_tokens.Length(); i++) {
    EXPECT_EQ(expected_tokens.KindAt(i), serialized_tokens.KindAt(i));
    expected_literal ^= expected_tokens.LiteralAt(i);
    actual_literal ^= serialized_tokens.LiteralAt(i);
    EXPECT(expected_literal.Equals(actual_literal));
  }
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
UNIT_TEST_CASE(FullSnapshot) {
  const char* kScriptChars =
      "class Fields  {\n"
      "  Fields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class FieldsTest {\n"
      "  static Fields testMain() {\n"
      "    Fields obj = new Fields(10, 20);\n"
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
    OS::PrintErr("Without Snapshot: %dus\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    Isolate* isolate = Isolate::Current();
    Zone zone(isolate);
    HandleScope scope(isolate);
    SnapshotWriter writer(Snapshot::kFull, &buffer, &allocator);
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
    OS::PrintErr("From Snapshot: %dus\n", timer2.TotalElapsedTime());

    // Invoke a function which returns an object.
    result = Dart_InvokeStatic(TestCase::lib(),
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
    OS::PrintErr("Without Snapshot: %dus\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    SnapshotWriter writer(Snapshot::kFull, &buffer, &allocator);
    writer.WriteFullSnapshot();

    // Invoke a function which returns an object.
    Dart_Handle result = Dart_InvokeStatic(lib,
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
    OS::PrintErr("From Snapshot: %dus\n", timer2.TotalElapsedTime());

    // Invoke a function which returns an object.
    Dart_Handle result = Dart_InvokeStatic(TestCase::lib(),
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
      "  static final int fld4 = 10;"
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

    EXPECT_VALID(Dart_LibraryImportLibrary(TestCase::lib(), import_lib));

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
    result = Dart_InvokeStatic(result,
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }
  Dart_ShutdownIsolate();
  free(full_snapshot);
  free(script_snapshot);
}


TEST_CASE(IntArrayMessage) {
  uint8_t* buffer = NULL;
  MessageWriter writer(&buffer, &allocator);

  static const int kArrayLength = 2;
  intptr_t data[kArrayLength] = {1, 2};
  int len = kArrayLength;
  writer.WriteMessage(len, data);

  // Read object back from the snapshot into a C structure.
  CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                         writer.BytesWritten(),
                         &allocator);
  Dart_CObject* value = mreader.ReadObject();
  EXPECT_EQ(Dart_CObject::kArray, value->type);
  EXPECT_EQ(kArrayLength, value->value.as_array.length);
  for (int i = 0; i < kArrayLength; i++) {
    Dart_CObject* element = value->value.as_array.values[i];
    EXPECT_EQ(Dart_CObject::kInt32, element->type);
    EXPECT_EQ(i + 1, element->value.as_int32);
    free(element);
  }
  free(value);
}


// Helper function to call a top level Dart function, serialize the
// result and deserialize the result into a Dart_CObject structure.
static Dart_CObject* GetDeserializedDartObject(Dart_Handle lib,
                                               const char* dart_function) {
  Dart_Handle result;
  result = Dart_InvokeStatic(lib,
                             Dart_NewString(""),
                             Dart_NewString(dart_function),
                             0,
                             NULL);
  EXPECT_VALID(result);

  // Serialize the list into a message.
  uint8_t* buffer;
  SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
  const Object& list = Object::Handle(Api::UnwrapHandle(result));
  writer.WriteObject(list.raw());
  writer.FinalizeBuffer();

  // Read object back from the snapshot into a C structure.
  CMessageReader reader(buffer + Snapshot::kHeaderSize,
                        writer.BytesWritten(),
                        &allocator);
  Dart_CObject* value = reader.ReadObject();
  free(buffer);
  return value;
}


UNIT_TEST_CASE(DartGeneratedMessages) {
  static const char* kCustomIsolateScriptChars =
      "getSmi() {\n"
      "  return 42;\n"
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
  smi_result = Dart_InvokeStatic(lib,
                                 Dart_NewString(""),
                                 Dart_NewString("getSmi"),
                                 0,
                                 NULL);
  EXPECT_VALID(smi_result);
  Dart_Handle string_result;
  string_result = Dart_InvokeStatic(lib,
                                    Dart_NewString(""),
                                    Dart_NewString("getString"),
                                    0,
                                    NULL);
  EXPECT_VALID(string_result);
  EXPECT(Dart_IsString(string_result));

  {
    DARTSCOPE_NOCHECKS(isolate);

    {
      uint8_t* buffer;
      SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
      Smi& smi = Smi::Handle();
      smi ^= Api::UnwrapHandle(smi_result);
      writer.WriteObject(smi.raw());
      writer.FinalizeBuffer();

      // Read object back from the snapshot into a C structure.
      CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                             writer.BytesWritten(),
                             &allocator);
      Dart_CObject* value = mreader.ReadObject();
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kInt32, value->type);
      EXPECT_EQ(42, value->value.as_int32);
      free(value);
      free(buffer);
    }
    {
      uint8_t* buffer;
      SnapshotWriter writer(Snapshot::kMessage, &buffer, &allocator);
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(string_result);
      writer.WriteObject(str.raw());
      writer.FinalizeBuffer();

      // Read object back from the snapshot into a C structure.
      CMessageReader mreader(buffer + Snapshot::kHeaderSize,
                             writer.BytesWritten(),
                             &allocator);
      Dart_CObject* value = mreader.ReadObject();
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kString, value->type);
      EXPECT_STREQ("Hello, world!", value->value.as_string);
      free(value);
      free(buffer);
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
      Dart_CObject* value = GetDeserializedDartObject(lib, "getList");
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kArray, value->type);
      EXPECT_EQ(kArrayLength, value->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kNull, value->value.as_array.values[i]->type);
        free(value->value.as_array.values[i]);
      }
      free(value);
    }
    {
      // Generate a list of ints from Dart code.
      Dart_CObject* value = GetDeserializedDartObject(lib, "getIntList");
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kArray, value->type);
      EXPECT_EQ(kArrayLength, value->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kInt32, value->value.as_array.values[i]->type);
        EXPECT_EQ(i, value->value.as_array.values[i]->value.as_int32);
        free(value->value.as_array.values[i]);
      }
      free(value);
    }
    {
      // Generate a list of strings from Dart code.
      Dart_CObject* value = GetDeserializedDartObject(lib, "getStringList");
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kArray, value->type);
      EXPECT_EQ(kArrayLength, value->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        EXPECT_EQ(Dart_CObject::kString, value->value.as_array.values[i]->type);
        char buffer[3];
        snprintf(buffer, sizeof(buffer), "%d", i);
        EXPECT_STREQ(buffer, value->value.as_array.values[i]->value.as_string);
        free(value->value.as_array.values[i]);
      }
      free(value);
    }
    {
      // Generate a list of objects of different types from Dart code.
      Dart_CObject* value = GetDeserializedDartObject(lib, "getMixedList");
      EXPECT_NOTNULL(value);
      EXPECT_EQ(Dart_CObject::kArray, value->type);
      EXPECT_EQ(kArrayLength, value->value.as_array.length);

      EXPECT_EQ(Dart_CObject::kInt32, value->value.as_array.values[0]->type);
      EXPECT_EQ(0, value->value.as_array.values[0]->value.as_int32);
      EXPECT_EQ(Dart_CObject::kString, value->value.as_array.values[1]->type);
      EXPECT_STREQ("1", value->value.as_array.values[1]->value.as_string);
      EXPECT_EQ(Dart_CObject::kDouble, value->value.as_array.values[2]->type);
      EXPECT_EQ(2.2, value->value.as_array.values[2]->value.as_double);
      EXPECT_EQ(Dart_CObject::kBool, value->value.as_array.values[3]->type);
      EXPECT_EQ(true, value->value.as_array.values[3]->value.as_bool);

      for (int i = 0; i < kArrayLength; i++) {
        if (i > 3) {
          EXPECT_EQ(Dart_CObject::kNull, value->value.as_array.values[i]->type);
        }
        free(value->value.as_array.values[i]);
      }
      free(value);
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DartGeneratedListMessagesWithBackref) {
  const int kArrayLength = 10;
  static const char* kScriptChars =
      "final int kArrayLength = 10;\n"
      "getStringList() {\n"
      "  var s = 'Hello, world!';\n"
      "  var list = new List<String>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = s;\n"
      "  return list;\n"
      "}\n"
      "getDoubleList() {\n"
      "  var d = 3.14;\n"
      "  var list = new List<double>(kArrayLength);\n"
      "  for (var i = 0; i < kArrayLength; i++) list[i] = d;\n"
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
      Dart_CObject* object = GetDeserializedDartObject(lib, "getStringList");
      EXPECT_NOTNULL(object);
      EXPECT_EQ(Dart_CObject::kArray, object->type);
      EXPECT_EQ(kArrayLength, object->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = object->value.as_array.values[i];
        EXPECT_EQ(object->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kString, element->type);
        EXPECT_STREQ("Hello, world!", element->value.as_string);
      }
      free(object->value.as_array.values[0]);
      free(object);
    }
    {
      // Generate a list of doubles from Dart code.
      Dart_CObject* object = GetDeserializedDartObject(lib, "getDoubleList");
      EXPECT_NOTNULL(object);
      EXPECT_EQ(Dart_CObject::kArray, object->type);
      EXPECT_EQ(kArrayLength, object->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = object->value.as_array.values[i];
        EXPECT_EQ(object->value.as_array.values[0], element);
        EXPECT_EQ(Dart_CObject::kDouble, element->type);
        EXPECT_EQ(3.14, element->value.as_double);
      }
      free(object->value.as_array.values[0]);
      free(object);
    }
    {
      // Generate a list of objects of different types from Dart code.
      Dart_CObject* object = GetDeserializedDartObject(lib, "getMixedList");
      EXPECT_NOTNULL(object);
      EXPECT_EQ(Dart_CObject::kArray, object->type);
      EXPECT_EQ(kArrayLength, object->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = object->value.as_array.values[i];
        if ((i % 2) == 0) {
          EXPECT_EQ(object->value.as_array.values[0], element);
          EXPECT_EQ(Dart_CObject::kString, element->type);
          EXPECT_STREQ("A", element->value.as_string);
        } else {
          EXPECT_EQ(object->value.as_array.values[1], element);
          EXPECT_EQ(Dart_CObject::kDouble, element->type);
          EXPECT_STREQ(2.72, element->value.as_double);
        }
      }
      free(object->value.as_array.values[0]);
      free(object->value.as_array.values[1]);
      free(object);
    }
    {
      // Generate a list of objects of different types from Dart code.
      Dart_CObject* object = GetDeserializedDartObject(lib, "getSelfRefList");
      EXPECT_NOTNULL(object);
      EXPECT_EQ(Dart_CObject::kArray, object->type);
      EXPECT_EQ(kArrayLength, object->value.as_array.length);
      for (int i = 0; i < kArrayLength; i++) {
        Dart_CObject* element = object->value.as_array.values[i];
        EXPECT_EQ(Dart_CObject::kArray, element->type);
        EXPECT_EQ(object, element);
      }
      free(object);
    }
  }
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
