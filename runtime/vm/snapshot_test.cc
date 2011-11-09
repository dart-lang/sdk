// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "vm/assert.h"
#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
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
  SnapshotWriter writer(false, &buffer, &allocator);
  const Object& null_object = Object::Handle();
  writer.WriteObject(null_object.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(null_object, serialized_object));
}


TEST_CASE(SerializeSmi1) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  const Smi& smi = Smi::Handle(Smi::New(124));
  writer.WriteObject(smi.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));
}


TEST_CASE(SerializeSmi2) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  const Smi& smi = Smi::Handle(Smi::New(-1));
  writer.WriteObject(smi.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(smi, serialized_object));
}


TEST_CASE(SerializeDouble) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  const Double& dbl = Double::Handle(Double::New(101.29));
  writer.WriteObject(dbl.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  const Object& serialized_object = Object::Handle(reader.ReadObject());
  EXPECT(Equals(dbl, serialized_object));
}


TEST_CASE(SerializeBool) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  const Bool& bool1 = Bool::Handle(Bool::True());
  const Bool& bool2 = Bool::Handle(Bool::False());
  writer.WriteObject(bool1.raw());
  writer.WriteObject(bool2.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  EXPECT(Bool::True() == reader.ReadObject());
  EXPECT(Bool::False() == reader.ReadObject());
}


TEST_CASE(SerializeBigint) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  const Bigint& bigint = Bigint::Handle(Bigint::New(0xfffffffffLL));
  writer.WriteObject(bigint.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  Bigint& obj = Bigint::Handle();
  obj ^= reader.ReadObject();
  OS::Print("%lld", BigintOperations::ToInt64(obj));
  EXPECT_EQ(BigintOperations::ToInt64(bigint), BigintOperations::ToInt64(obj));
}


TEST_CASE(SerializeSingletons) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
  writer.WriteObject(Object::class_class());
  writer.WriteObject(Object::null_class());
  writer.WriteObject(Object::parameterized_type_class());
  writer.WriteObject(Object::type_parameter_class());
  writer.WriteObject(Object::instantiated_type_class());
  writer.WriteObject(Object::type_arguments_class());
  writer.WriteObject(Object::type_array_class());
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
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  EXPECT(Object::class_class() == reader.ReadObject());
  EXPECT(Object::null_class() == reader.ReadObject());
  EXPECT(Object::parameterized_type_class() == reader.ReadObject());
  EXPECT(Object::type_parameter_class() == reader.ReadObject());
  EXPECT(Object::instantiated_type_class() == reader.ReadObject());
  EXPECT(Object::type_arguments_class() == reader.ReadObject());
  EXPECT(Object::type_array_class() == reader.ReadObject());
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
  SnapshotWriter writer(false, &buffer, &allocator);
  String& str = String::Handle(String::New("This string shall be serialized"));
  writer.WriteObject(str.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  String& serialized_str = String::Handle();
  serialized_str ^= reader.ReadObject();
  EXPECT(str.Equals(serialized_str));
}


TEST_CASE(SerializeArray) {
  // Write snapshot with object content.
  uint8_t* buffer;
  SnapshotWriter writer(false, &buffer, &allocator);
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
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  Array& serialized_array = Array::Handle();
  serialized_array ^= reader.ReadObject();
  EXPECT(array.Equals(serialized_array));
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
  SnapshotWriter writer(false, &buffer, &allocator);
  writer.WriteObject(script.raw());
  writer.FinalizeBuffer();

  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);

  // Read object back from the snapshot.
  Isolate* isolate= Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
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


#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.
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
  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    TestCase::LoadTestScript(kScriptChars, NULL);
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %dus\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    Zone zone;
    HandleScope hs;
    SnapshotWriter writer(true, &buffer, &allocator);
    writer.WriteFullSnapshot();

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();

  // Now Create another isolate using the snapshot and execute a method
  // from the script.
  Timer timer2(true, "Snapshot_test");
  timer2.Start();
  Dart_CreateIsolate(buffer, NULL);
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
    EXPECT(!Dart_ExceptionOccurred(result));

    Dart_ExitScope();  // Exit the Dart API scope.
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
  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    Zone zone;
    HandleScope hs;

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
    ClassFinalizer::FinalizeAllClasses();
    timer1.Stop();
    OS::PrintErr("Without Snapshot: %dus\n", timer1.TotalElapsedTime());

    // Write snapshot with object content.
    SnapshotWriter writer(true, &buffer, &allocator);
    writer.WriteFullSnapshot();

    // Invoke a function which returns an object.
    Dart_Handle result = Dart_InvokeStatic(lib,
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    EXPECT(!Dart_ExceptionOccurred(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();

  // Now Create another isolate using the snapshot and execute a method
  // from the script.
  Timer timer2(true, "Snapshot_test");
  timer2.Start();
  Dart_CreateIsolate(buffer, NULL);
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
    EXPECT_VALID(result);
    if (Dart_ExceptionOccurred(result)) {
      // Print the exception object.
      fprintf(stderr, "An unhandled exception has been thrown\n");
      Dart_Handle exception_result = Dart_GetException(result);
      assert(Dart_IsValid(exception_result));
      const char* obj_cstring = NULL;
      Dart_Handle retstr = Dart_StringToCString(exception_result, &obj_cstring);
      if (!Dart_IsValid(retstr)) {
        obj_cstring = Dart_GetError(retstr);
      }
      fprintf(stderr, "%s", obj_cstring);
    }
    EXPECT(!Dart_ExceptionOccurred(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();

  free(buffer);
}
#endif  // TARGET_ARCH_IA32.

}  // namespace dart
