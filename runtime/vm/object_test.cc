// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <limits>
#include <memory>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/vmservice_impl.h"

#include "platform/globals.h"

#include "vm/class_finalizer.h"
#include "vm/closure_functions_cache.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debugger_api_impl_test.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/simulator.h"
#include "vm/symbols.h"
#include "vm/tagged_pointer.h"
#include "vm/unit_test.h"

namespace dart {

#define Z (thread->zone())

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, write_protect_code);

static ClassPtr CreateDummyClass(const String& class_name,
                                 const Script& script) {
  const Class& cls = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  cls.set_is_synthesized_class_unsafe();  // Dummy class for testing.
  cls.set_is_declaration_loaded_unsafe();
  return cls.ptr();
}

ISOLATE_UNIT_TEST_CASE(Class) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));

  // Class has no fields and no functions yet.
  EXPECT_EQ(Array::Handle(cls.fields()).Length(), 0);
  EXPECT_EQ(Array::Handle(cls.current_functions()).Length(), 0);

  // Setup the interfaces in the class.
  // Normally the class finalizer is resolving super types and interfaces
  // before finalizing the types in a class. A side-effect of this is setting
  // the is_implemented() bit on a class. We do that manually here.
  const Array& interfaces = Array::Handle(Array::New(2));
  Class& interface = Class::Handle();
  String& interface_name = String::Handle();
  interface_name = Symbols::New(thread, "Harley");
  interface = CreateDummyClass(interface_name, script);
  interfaces.SetAt(0, Type::Handle(Type::NewNonParameterizedType(interface)));
  interface.set_is_implemented_unsafe();
  interface_name = Symbols::New(thread, "Norton");
  interface = CreateDummyClass(interface_name, script);
  interfaces.SetAt(1, Type::Handle(Type::NewNonParameterizedType(interface)));
  interface.set_is_implemented_unsafe();
  cls.set_interfaces(interfaces);

  // Finalization of types happens before the fields and functions have been
  // parsed.
  ClassFinalizer::FinalizeTypesInClass(cls);

  // Create and populate the function arrays.
  const Array& functions = Array::Handle(Array::New(6));
  FunctionType& signature = FunctionType::Handle();
  Function& function = Function::Handle();
  String& function_name = String::Handle();
  function_name = Symbols::New(thread, "foo");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, false, false,
                           false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, function);
  function_name = Symbols::New(thread, "bar");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, false, false,
                           false, false, false, cls, TokenPosition::kMinSource);

  const int kNumFixedParameters = 2;
  const int kNumOptionalParameters = 3;
  const bool kAreOptionalPositional = true;
  signature.set_num_fixed_parameters(kNumFixedParameters);
  signature.SetNumOptionalParameters(kNumOptionalParameters,
                                     kAreOptionalPositional);
  functions.SetAt(1, function);

  function_name = Symbols::New(thread, "baz");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, false, false,
                           false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(2, function);

  function_name = Symbols::New(thread, "Foo");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, true, false,
                           false, false, false, cls, TokenPosition::kMinSource);

  functions.SetAt(3, function);
  function_name = Symbols::New(thread, "Bar");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, true, false,
                           false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(4, function);
  function_name = Symbols::New(thread, "BaZ");
  signature = FunctionType::New();
  function = Function::New(signature, function_name,
                           UntaggedFunction::kRegularFunction, true, false,
                           false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(5, function);

  // Setup the functions in the class.
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
    // The class can now be finalized.
    cls.Finalize();
  }

  function_name = String::New("Foo");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(function.IsNull());
  function = cls.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.ptr(), function.Owner());
  EXPECT(function.is_static());
  function_name = String::New("baz");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.ptr(), function.Owner());
  EXPECT(!function.is_static());
  function = cls.LookupStaticFunction(function_name);
  EXPECT(function.IsNull());

  function_name = String::New("foo");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(!function.IsNull());
  EXPECT_EQ(0, function.num_fixed_parameters());
  EXPECT(!function.HasOptionalParameters());

  function_name = String::New("bar");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(!function.IsNull());
  EXPECT_EQ(kNumFixedParameters, function.num_fixed_parameters());
  EXPECT_EQ(kNumOptionalParameters, function.NumOptionalParameters());
}

ISOLATE_UNIT_TEST_CASE(SixtyThousandDartClasses) {
  auto zone = thread->zone();
  auto isolate_group = thread->isolate_group();
  auto class_table = isolate_group->class_table();

  const intptr_t start_cid = class_table->NumCids();
  const intptr_t num_classes = std::numeric_limits<uint16_t>::max() - start_cid;

  const Script& script = Script::Handle(zone);
  String& name = String::Handle(zone);
  Class& cls = Class::Handle(zone);
  Field& field = Field::Handle(zone);
  Array& fields = Array::Handle(zone);
  Instance& instance = Instance::Handle(zone);
  Instance& instance2 = Instance::Handle(zone);

  const auto& instances =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());

  // Create many top-level classes - they should not consume 16-bit range.
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    for (intptr_t i = 0; i < (1 << 16); ++i) {
      cls = CreateDummyClass(Symbols::TopLevel(), script);
      cls.Finalize();
      EXPECT(cls.id() > std::numeric_limits<uint16_t>::max());
    }
  }

  // Create many concrete classes - they should occupy the entire 16-bit space.
  for (intptr_t i = 0; i < num_classes; ++i) {
    name = Symbols::New(thread, OS::SCreate(zone, "MyClass%" Pd "", i));
    cls = CreateDummyClass(name, script);
    EXPECT_EQ(start_cid + i, cls.id());

    const intptr_t num_fields = (i % 10);
    fields = Array::New(num_fields);
    for (intptr_t f = 0; f < num_fields; ++f) {
      name =
          Symbols::New(thread, OS::SCreate(zone, "myField_%" Pd "_%" Pd, i, f));
      field = Field::New(name, false, false, false, true, false, cls,
                         Object::dynamic_type(), TokenPosition::kMinSource,
                         TokenPosition::kMinSource);
      fields.SetAt(f, field);
    }

    cls.set_interfaces(Array::empty_array());
    {
      SafepointWriteRwLocker ml(thread,
                                thread->isolate_group()->program_lock());
      cls.SetFunctions(Array::empty_array());
      cls.SetFields(fields);
      cls.Finalize();
    }

    instance = Instance::New(cls);
    for (intptr_t f = 0; f < num_fields; ++f) {
      field ^= fields.At(f);
      name = Symbols::New(thread,
                          OS::SCreate(zone, "myFieldValue_%" Pd "_%" Pd, i, f));
      instance.SetField(field, name);
    }
    instances.Add(instance);
  }
  EXPECT_EQ((1 << 16) - 1, class_table->NumCids());

  // Ensure GC runs and can recognize all those new instances.
  isolate_group->heap()->CollectAllGarbage();

  // Ensure the instances are what we expect.
  for (intptr_t i = 0; i < num_classes; ++i) {
    instance ^= instances.At(i);
    cls = instance.clazz();
    fields = cls.fields();

    name = cls.Name();
    EXPECT(strstr(name.ToCString(), OS::SCreate(zone, "MyClass%" Pd "", i)) !=
           0);
    EXPECT_EQ((i % 10), fields.Length());

    for (intptr_t f = 0; f < fields.Length(); ++f) {
      field ^= fields.At(f);
      instance2 ^= instance.GetField(field);
      EXPECT(strstr(instance2.ToCString(),
                    OS::SCreate(zone, "myFieldValue_%" Pd "_%" Pd, i, f)) != 0);
    }
  }
}

ISOLATE_UNIT_TEST_CASE(TypeArguments) {
  const Type& type1 = Type::Handle(Type::Double());
  const Type& type2 = Type::Handle(Type::StringType());
  const TypeArguments& type_arguments1 =
      TypeArguments::Handle(TypeArguments::New(2));
  type_arguments1.SetTypeAt(0, type1);
  type_arguments1.SetTypeAt(1, type2);
  const TypeArguments& type_arguments2 =
      TypeArguments::Handle(TypeArguments::New(2));
  type_arguments2.SetTypeAt(0, type1);
  type_arguments2.SetTypeAt(1, type2);
  EXPECT_NE(type_arguments1.ptr(), type_arguments2.ptr());
  OS::PrintErr("1: %s\n", type_arguments1.ToCString());
  OS::PrintErr("2: %s\n", type_arguments2.ToCString());
  EXPECT(type_arguments1.Equals(type_arguments2));
  TypeArguments& type_arguments3 = TypeArguments::Handle();
  type_arguments1.Canonicalize(thread);
  type_arguments3 ^= type_arguments2.Canonicalize(thread);
  EXPECT_EQ(type_arguments1.ptr(), type_arguments3.ptr());
}

TEST_CASE(Class_EndTokenPos) {
  const char* kScript =
      "\n"
      "class A {\n"
      "  /**\n"
      "   * Description of foo().\n"
      "   */\n"
      "  foo(a) { return '''\"}'''; }\n"
      "  // }\n"
      "  var bar = '\\'}';\n"
      "}\n";
  Dart_Handle lib_h = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(lib_h);
  TransitionNativeToVM transition(thread);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(lib_h);
  EXPECT(!lib.IsNull());
  const Class& cls =
      Class::Handle(lib.LookupClass(String::Handle(String::New("A"))));
  EXPECT(!cls.IsNull());
  const Error& error = Error::Handle(cls.EnsureIsFinalized(thread));
  EXPECT(error.IsNull());
  const TokenPosition end_token_pos = cls.end_token_pos();
  const Script& scr = Script::Handle(cls.script());
  intptr_t line;
  intptr_t col;
  EXPECT(scr.GetTokenLocation(end_token_pos, &line, &col));
  EXPECT_EQ(9, line);
  EXPECT_EQ(1, col);
}

ISOLATE_UNIT_TEST_CASE(InstanceClass) {
  // Allocate the class first.
  String& class_name = String::Handle(Symbols::New(thread, "EmptyClass"));
  Script& script = Script::Handle();
  const Class& empty_class =
      Class::Handle(CreateDummyClass(class_name, script));

  // EmptyClass has no fields and no functions.
  EXPECT_EQ(Array::Handle(empty_class.fields()).Length(), 0);
  EXPECT_EQ(Array::Handle(empty_class.current_functions()).Length(), 0);

  ClassFinalizer::FinalizeTypesInClass(empty_class);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    empty_class.Finalize();
  }

  EXPECT_EQ(kObjectAlignment, empty_class.host_instance_size());
  Instance& instance = Instance::Handle(Instance::New(empty_class));
  EXPECT_EQ(empty_class.ptr(), instance.clazz());

  class_name = Symbols::New(thread, "OneFieldClass");
  const Class& one_field_class =
      Class::Handle(CreateDummyClass(class_name, script));

  // No fields, functions, or super type for the OneFieldClass.
  EXPECT_EQ(Array::Handle(empty_class.fields()).Length(), 0);
  EXPECT_EQ(Array::Handle(empty_class.current_functions()).Length(), 0);
  EXPECT_EQ(empty_class.super_type(), AbstractType::null());
  ClassFinalizer::FinalizeTypesInClass(one_field_class);

  const Array& one_fields = Array::Handle(Array::New(1));
  const String& field_name = String::Handle(Symbols::New(thread, "the_field"));
  const Field& field = Field::Handle(
      Field::New(field_name, false, false, false, true, false, one_field_class,
                 Object::dynamic_type(), TokenPosition::kMinSource,
                 TokenPosition::kMinSource));
  one_fields.SetAt(0, field);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    one_field_class.SetFields(one_fields);
    one_field_class.Finalize();
  }
  intptr_t header_size = sizeof(UntaggedObject);
  EXPECT_EQ(Utils::RoundUp((header_size + (1 * kWordSize)), kObjectAlignment),
            one_field_class.host_instance_size());
  EXPECT_EQ(header_size, field.HostOffset());
  EXPECT(!one_field_class.is_implemented());
  one_field_class.set_is_implemented_unsafe();
  EXPECT(one_field_class.is_implemented());
}

ISOLATE_UNIT_TEST_CASE(Smi) {
  const Smi& smi = Smi::Handle(Smi::New(5));
  Object& smi_object = Object::Handle(smi.ptr());
  EXPECT(smi.IsSmi());
  EXPECT(smi_object.IsSmi());
  EXPECT_EQ(5, smi.Value());
  const Object& object = Object::Handle();
  EXPECT(!object.IsSmi());
  smi_object = Object::null();
  EXPECT(!smi_object.IsSmi());

  EXPECT(smi.Equals(Smi::Handle(Smi::New(5))));
  EXPECT(!smi.Equals(Smi::Handle(Smi::New(6))));
  EXPECT(smi.Equals(smi));
  EXPECT(!smi.Equals(Smi::Handle()));

  EXPECT(Smi::IsValid(0));
  EXPECT(Smi::IsValid(-15));
  EXPECT(Smi::IsValid(0xFFu));
// Upper two bits must be either 00 or 11.
#if defined(ARCH_IS_64_BIT) && !defined(DART_COMPRESSED_POINTERS)
  EXPECT(!Smi::IsValid(kMaxInt64));
  EXPECT(Smi::IsValid(0x3FFFFFFFFFFFFFFF));
  EXPECT(Smi::IsValid(-1));
#else
  EXPECT(!Smi::IsValid(kMaxInt32));
  EXPECT(Smi::IsValid(0x3FFFFFFF));
  EXPECT(Smi::IsValid(-1));
  EXPECT(!Smi::IsValid(0xFFFFFFFFu));
#endif

  EXPECT_EQ(5, smi.AsInt64Value());
  EXPECT_EQ(5.0, smi.AsDoubleValue());

  Smi& a = Smi::Handle(Smi::New(5));
  Smi& b = Smi::Handle(Smi::New(3));
  EXPECT_EQ(1, a.CompareWith(b));
  EXPECT_EQ(-1, b.CompareWith(a));
  EXPECT_EQ(0, a.CompareWith(a));

  Smi& c = Smi::Handle(Smi::New(-1));

  Mint& mint1 = Mint::Handle();
  mint1 ^= Integer::New(DART_2PART_UINT64_C(0x7FFFFFFF, 100));
  Mint& mint2 = Mint::Handle();
  mint2 ^= Integer::New(-DART_2PART_UINT64_C(0x7FFFFFFF, 100));
  EXPECT_EQ(-1, a.CompareWith(mint1));
  EXPECT_EQ(1, a.CompareWith(mint2));
  EXPECT_EQ(-1, c.CompareWith(mint1));
  EXPECT_EQ(1, c.CompareWith(mint2));
}

ISOLATE_UNIT_TEST_CASE(StringCompareTo) {
  const String& abcd = String::Handle(String::New("abcd"));
  const String& abce = String::Handle(String::New("abce"));
  EXPECT_EQ(0, abcd.CompareTo(abcd));
  EXPECT_EQ(0, abce.CompareTo(abce));
  EXPECT(abcd.CompareTo(abce) < 0);
  EXPECT(abce.CompareTo(abcd) > 0);

  const int kMonkeyLen = 4;
  const uint8_t monkey_utf8[kMonkeyLen] = {0xf0, 0x9f, 0x90, 0xb5};
  const String& monkey_face =
      String::Handle(String::FromUTF8(monkey_utf8, kMonkeyLen));
  const int kDogLen = 4;
  // 0x1f436 DOG FACE.
  const uint8_t dog_utf8[kDogLen] = {0xf0, 0x9f, 0x90, 0xb6};
  const String& dog_face = String::Handle(String::FromUTF8(dog_utf8, kDogLen));
  EXPECT_EQ(0, monkey_face.CompareTo(monkey_face));
  EXPECT_EQ(0, dog_face.CompareTo(dog_face));
  EXPECT(monkey_face.CompareTo(dog_face) < 0);
  EXPECT(dog_face.CompareTo(monkey_face) > 0);

  const int kDominoLen = 4;
  // 0x1f036 DOMINO TILE HORIZONTAL-00-05.
  const uint8_t domino_utf8[kDominoLen] = {0xf0, 0x9f, 0x80, 0xb6};
  const String& domino =
      String::Handle(String::FromUTF8(domino_utf8, kDominoLen));
  EXPECT_EQ(0, domino.CompareTo(domino));
  EXPECT(domino.CompareTo(dog_face) < 0);
  EXPECT(domino.CompareTo(monkey_face) < 0);
  EXPECT(dog_face.CompareTo(domino) > 0);
  EXPECT(monkey_face.CompareTo(domino) > 0);

  EXPECT(abcd.CompareTo(monkey_face) < 0);
  EXPECT(abce.CompareTo(monkey_face) < 0);
  EXPECT(abcd.CompareTo(domino) < 0);
  EXPECT(abce.CompareTo(domino) < 0);
  EXPECT(domino.CompareTo(abcd) > 0);
  EXPECT(domino.CompareTo(abcd) > 0);
  EXPECT(monkey_face.CompareTo(abce) > 0);
  EXPECT(monkey_face.CompareTo(abce) > 0);
}

ISOLATE_UNIT_TEST_CASE(StringEncodeIRI) {
  const char* kInput =
      "file:///usr/local/johnmccutchan/workspace/dart-repo/dart/test.dart";
  const char* kOutput =
      "file%3A%2F%2F%2Fusr%2Flocal%2Fjohnmccutchan%2Fworkspace%2F"
      "dart-repo%2Fdart%2Ftest.dart";
  const String& input = String::Handle(String::New(kInput));
  const char* encoded = String::EncodeIRI(input);
  EXPECT(strcmp(encoded, kOutput) == 0);
}

ISOLATE_UNIT_TEST_CASE(StringDecodeIRI) {
  const char* kOutput =
      "file:///usr/local/johnmccutchan/workspace/dart-repo/dart/test.dart";
  const char* kInput =
      "file%3A%2F%2F%2Fusr%2Flocal%2Fjohnmccutchan%2Fworkspace%2F"
      "dart-repo%2Fdart%2Ftest.dart";
  const String& input = String::Handle(String::New(kInput));
  const String& output = String::Handle(String::New(kOutput));
  const String& decoded = String::Handle(String::DecodeIRI(input));
  EXPECT(output.Equals(decoded));
}

ISOLATE_UNIT_TEST_CASE(StringDecodeIRIInvalid) {
  String& input = String::Handle();
  input = String::New("file%");
  String& decoded = String::Handle();
  decoded = String::DecodeIRI(input);
  EXPECT(decoded.IsNull());
  input = String::New("file%3");
  decoded = String::DecodeIRI(input);
  EXPECT(decoded.IsNull());
  input = String::New("file%3g");
  decoded = String::DecodeIRI(input);
  EXPECT(decoded.IsNull());
}

ISOLATE_UNIT_TEST_CASE(StringIRITwoByte) {
  const intptr_t kInputLen = 3;
  const uint16_t kInput[kInputLen] = {'x', '/', 256};
  const String& input = String::Handle(String::FromUTF16(kInput, kInputLen));
  const intptr_t kOutputLen = 10;
  const uint16_t kOutput[kOutputLen] = {'x', '%', '2', 'F', '%',
                                        'C', '4', '%', '8', '0'};
  const String& output = String::Handle(String::FromUTF16(kOutput, kOutputLen));
  const String& encoded = String::Handle(String::New(String::EncodeIRI(input)));
  EXPECT(output.Equals(encoded));
  const String& decoded = String::Handle(String::DecodeIRI(output));
  EXPECT(input.Equals(decoded));
}

ISOLATE_UNIT_TEST_CASE(Mint) {
// On 64-bit architectures a Smi is stored in a 64 bit word. A Midint cannot
// be allocated if it does fit into a Smi.
#if !defined(ARCH_IS_64_BIT) || defined(DART_COMPRESSED_POINTERS)
  {
    Mint& med = Mint::Handle();
    EXPECT(med.IsNull());
    int64_t v = DART_2PART_UINT64_C(1, 0);
    med ^= Integer::New(v);
    EXPECT_EQ(v, med.value());
    const String& smi_str = String::Handle(String::New("1"));
    const String& mint1_str = String::Handle(String::New("2147419168"));
    const String& mint2_str = String::Handle(String::New("-2147419168"));
    Integer& i = Integer::Handle(Integer::NewCanonical(smi_str));
    EXPECT(i.IsSmi());
    i = Integer::NewCanonical(mint1_str);
    EXPECT(i.IsMint());
    EXPECT(!i.IsZero());
    EXPECT(!i.IsNegative());
    i = Integer::NewCanonical(mint2_str);
    EXPECT(i.IsMint());
    EXPECT(!i.IsZero());
    EXPECT(i.IsNegative());
  }
  Integer& i = Integer::Handle(Integer::New(DART_2PART_UINT64_C(1, 0)));
  EXPECT(i.IsMint());
  EXPECT(!i.IsZero());
  EXPECT(!i.IsNegative());
  Integer& i1 = Integer::Handle(Integer::New(DART_2PART_UINT64_C(1010, 0)));
  Mint& i2 = Mint::Handle();
  i2 ^= Integer::New(DART_2PART_UINT64_C(1010, 0));
  EXPECT(i1.Equals(i2));
  EXPECT(!i.Equals(i1));
  int64_t test = DART_2PART_UINT64_C(1010, 0);
  EXPECT_EQ(test, i2.value());

  Mint& a = Mint::Handle();
  a ^= Integer::New(DART_2PART_UINT64_C(5, 0));
  Mint& b = Mint::Handle();
  b ^= Integer::New(DART_2PART_UINT64_C(3, 0));
  EXPECT_EQ(1, a.CompareWith(b));
  EXPECT_EQ(-1, b.CompareWith(a));
  EXPECT_EQ(0, a.CompareWith(a));

  Mint& c = Mint::Handle();
  c ^= Integer::New(-DART_2PART_UINT64_C(3, 0));
  Smi& smi1 = Smi::Handle(Smi::New(4));
  Smi& smi2 = Smi::Handle(Smi::New(-4));
  EXPECT_EQ(1, a.CompareWith(smi1));
  EXPECT_EQ(1, a.CompareWith(smi2));
  EXPECT_EQ(-1, c.CompareWith(smi1));
  EXPECT_EQ(-1, c.CompareWith(smi2));

  int64_t mint_value = DART_2PART_UINT64_C(0x7FFFFFFF, 64);
  const String& mint_string = String::Handle(String::New("0x7FFFFFFF00000064"));
  Mint& mint1 = Mint::Handle();
  mint1 ^= Integer::NewCanonical(mint_string);
  Mint& mint2 = Mint::Handle();
  mint2 ^= Integer::NewCanonical(mint_string);
  EXPECT_EQ(mint1.value(), mint_value);
  EXPECT_EQ(mint2.value(), mint_value);
  EXPECT_EQ(mint1.ptr(), mint2.ptr());
#endif
}

ISOLATE_UNIT_TEST_CASE(Double) {
  {
    const double dbl_const = 5.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.ptr());
    EXPECT(dbl.IsDouble());
    EXPECT(dbl_object.IsDouble());
    EXPECT_EQ(dbl_const, dbl.value());
  }

  {
    const double dbl_const = -5.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.ptr());
    EXPECT(dbl.IsDouble());
    EXPECT(dbl_object.IsDouble());
    EXPECT_EQ(dbl_const, dbl.value());
  }

  {
    const double dbl_const = 0.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.ptr());
    EXPECT(dbl.IsDouble());
    EXPECT(dbl_object.IsDouble());
    EXPECT_EQ(dbl_const, dbl.value());
  }

  {
    const double dbl_const = 5.0;
    const String& dbl_str = String::Handle(String::New("5.0"));
    const Double& dbl1 = Double::Handle(Double::NewCanonical(dbl_const));
    const Double& dbl2 = Double::Handle(Double::NewCanonical(dbl_const));
    const Double& dbl3 = Double::Handle(Double::NewCanonical(dbl_str));
    EXPECT_EQ(dbl_const, dbl1.value());
    EXPECT_EQ(dbl_const, dbl2.value());
    EXPECT_EQ(dbl_const, dbl3.value());
    EXPECT_EQ(dbl1.ptr(), dbl2.ptr());
    EXPECT_EQ(dbl1.ptr(), dbl3.ptr());
  }

  {
    const double dbl_const = 2.0;
    const Double& dbl1 = Double::Handle(Double::New(dbl_const));
    const Double& dbl2 = Double::Handle(Double::New(dbl_const));
    EXPECT(dbl1.OperatorEquals(dbl2));
    EXPECT(dbl1.IsIdenticalTo(dbl2));
    EXPECT(dbl1.CanonicalizeEquals(dbl2));
    const Double& dbl3 = Double::Handle(Double::New(3.3));
    EXPECT(!dbl1.OperatorEquals(dbl3));
    EXPECT(!dbl1.OperatorEquals(Smi::Handle(Smi::New(3))));
    EXPECT(!dbl1.OperatorEquals(Double::Handle()));
    const Double& nan0 = Double::Handle(Double::New(NAN));
    EXPECT(isnan(nan0.value()));
    EXPECT(nan0.IsIdenticalTo(nan0));
    EXPECT(nan0.CanonicalizeEquals(nan0));
    EXPECT(!nan0.OperatorEquals(nan0));
    const Double& nan1 =
        Double::Handle(Double::New(bit_cast<double>(kMaxUint64 - 0)));
    const Double& nan2 =
        Double::Handle(Double::New(bit_cast<double>(kMaxUint64 - 1)));
    EXPECT(isnan(nan1.value()));
    EXPECT(isnan(nan2.value()));
    EXPECT(!nan1.IsIdenticalTo(nan2));
    EXPECT(!nan1.CanonicalizeEquals(nan2));
    EXPECT(!nan1.OperatorEquals(nan2));
  }
  {
    const String& dbl_str0 = String::Handle(String::New("bla"));
    const Double& dbl0 = Double::Handle(Double::New(dbl_str0));
    EXPECT(dbl0.IsNull());

    const String& dbl_str1 = String::Handle(String::New("2.0"));
    const Double& dbl1 = Double::Handle(Double::New(dbl_str1));
    EXPECT_EQ(2.0, dbl1.value());

    // Disallow legacy form.
    const String& dbl_str2 = String::Handle(String::New("2.0d"));
    const Double& dbl2 = Double::Handle(Double::New(dbl_str2));
    EXPECT(dbl2.IsNull());
  }
}

ISOLATE_UNIT_TEST_CASE(Integer) {
  Integer& i = Integer::Handle();
  i = Integer::NewCanonical(String::Handle(String::New("12")));
  EXPECT(i.IsSmi());
  i = Integer::NewCanonical(String::Handle(String::New("-120")));
  EXPECT(i.IsSmi());
  i = Integer::NewCanonical(String::Handle(String::New("0")));
  EXPECT(i.IsSmi());
  i = Integer::NewCanonical(
      String::Handle(String::New("12345678901234567890")));
  EXPECT(i.IsNull());
  i = Integer::NewCanonical(
      String::Handle(String::New("-12345678901234567890111222")));
  EXPECT(i.IsNull());
}

ISOLATE_UNIT_TEST_CASE(String) {
  const char* kHello = "Hello World!";
  int32_t hello_len = strlen(kHello);
  const String& str = String::Handle(String::New(kHello));
  EXPECT(str.IsInstance());
  EXPECT(str.IsString());
  EXPECT(str.IsOneByteString());
  EXPECT(!str.IsTwoByteString());
  EXPECT(!str.IsNumber());
  EXPECT_EQ(hello_len, str.Length());
  EXPECT_EQ('H', str.CharAt(0));
  EXPECT_EQ('e', str.CharAt(1));
  EXPECT_EQ('l', str.CharAt(2));
  EXPECT_EQ('l', str.CharAt(3));
  EXPECT_EQ('o', str.CharAt(4));
  EXPECT_EQ(' ', str.CharAt(5));
  EXPECT_EQ('W', str.CharAt(6));
  EXPECT_EQ('o', str.CharAt(7));
  EXPECT_EQ('r', str.CharAt(8));
  EXPECT_EQ('l', str.CharAt(9));
  EXPECT_EQ('d', str.CharAt(10));
  EXPECT_EQ('!', str.CharAt(11));

  const uint8_t* motto =
      reinterpret_cast<const uint8_t*>("Dart's bescht wos je hets gits");
  const String& str2 = String::Handle(String::FromUTF8(motto + 7, 4));
  EXPECT_EQ(4, str2.Length());
  EXPECT_EQ('b', str2.CharAt(0));
  EXPECT_EQ('e', str2.CharAt(1));
  EXPECT_EQ('s', str2.CharAt(2));
  EXPECT_EQ('c', str2.CharAt(3));

  const String& str3 = String::Handle(String::New(kHello));
  EXPECT(str.Equals(str));
  EXPECT_EQ(str.Hash(), str.Hash());
  EXPECT(!str.Equals(str2));
  EXPECT(str.Equals(str3));
  EXPECT_EQ(str.Hash(), str3.Hash());
  EXPECT(str3.Equals(str));

  const String& str4 = String::Handle(String::New("foo"));
  const String& str5 = String::Handle(String::New("bar"));
  const String& str6 = String::Handle(String::Concat(str4, str5));
  const String& str7 = String::Handle(String::New("foobar"));
  EXPECT(str6.Equals(str7));
  EXPECT(!str6.Equals(Smi::Handle(Smi::New(4))));

  const String& empty1 = String::Handle(String::New(""));
  const String& empty2 = String::Handle(String::New(""));
  EXPECT(empty1.Equals(empty2, 0, 0));

  const intptr_t kCharsLen = 8;
  const uint8_t chars[kCharsLen] = {1, 2, 127, 64, 92, 0, 55, 55};
  const String& str8 = String::Handle(String::FromUTF8(chars, kCharsLen));
  EXPECT_EQ(kCharsLen, str8.Length());
  EXPECT_EQ(1, str8.CharAt(0));
  EXPECT_EQ(127, str8.CharAt(2));
  EXPECT_EQ(64, str8.CharAt(3));
  EXPECT_EQ(0, str8.CharAt(5));
  EXPECT_EQ(55, str8.CharAt(6));
  EXPECT_EQ(55, str8.CharAt(7));
  const intptr_t kCharsIndex = 3;
  const String& sub1 = String::Handle(String::SubString(str8, kCharsIndex));
  EXPECT_EQ((kCharsLen - kCharsIndex), sub1.Length());
  EXPECT_EQ(64, sub1.CharAt(0));
  EXPECT_EQ(92, sub1.CharAt(1));
  EXPECT_EQ(0, sub1.CharAt(2));
  EXPECT_EQ(55, sub1.CharAt(3));
  EXPECT_EQ(55, sub1.CharAt(4));

  const intptr_t kWideCharsLen = 7;
  uint16_t wide_chars[kWideCharsLen] = {'H', 'e', 'l', 'l', 'o', 256, '!'};
  const String& two_str =
      String::Handle(String::FromUTF16(wide_chars, kWideCharsLen));
  EXPECT(two_str.IsInstance());
  EXPECT(two_str.IsString());
  EXPECT(two_str.IsTwoByteString());
  EXPECT(!two_str.IsOneByteString());
  EXPECT_EQ(kWideCharsLen, two_str.Length());
  EXPECT_EQ('H', two_str.CharAt(0));
  EXPECT_EQ(256, two_str.CharAt(5));
  const intptr_t kWideCharsIndex = 3;
  const String& sub2 = String::Handle(String::SubString(two_str, kCharsIndex));
  EXPECT_EQ((kWideCharsLen - kWideCharsIndex), sub2.Length());
  EXPECT_EQ('l', sub2.CharAt(0));
  EXPECT_EQ('o', sub2.CharAt(1));
  EXPECT_EQ(256, sub2.CharAt(2));
  EXPECT_EQ('!', sub2.CharAt(3));

  {
    const String& str1 = String::Handle(String::New("My.create"));
    const String& str2 = String::Handle(String::New("My"));
    const String& str3 = String::Handle(String::New("create"));
    EXPECT_EQ(true, str1.StartsWith(str2));
    EXPECT_EQ(false, str1.StartsWith(str3));
  }

  const int32_t four_chars[] = {'C', 0xFF, 'h', 0xFFFF, 'a', 0x10FFFF, 'r'};
  const String& four_str = String::Handle(String::FromUTF32(four_chars, 7));
  EXPECT_EQ(four_str.Hash(), four_str.Hash());
  EXPECT(four_str.IsTwoByteString());
  EXPECT(!four_str.IsOneByteString());
  EXPECT_EQ(8, four_str.Length());
  EXPECT_EQ('C', four_str.CharAt(0));
  EXPECT_EQ(0xFF, four_str.CharAt(1));
  EXPECT_EQ('h', four_str.CharAt(2));
  EXPECT_EQ(0xFFFF, four_str.CharAt(3));
  EXPECT_EQ('a', four_str.CharAt(4));
  EXPECT_EQ(0xDBFF, four_str.CharAt(5));
  EXPECT_EQ(0xDFFF, four_str.CharAt(6));
  EXPECT_EQ('r', four_str.CharAt(7));

  // Create a 1-byte string from an array of 2-byte elements.
  {
    const uint16_t char16[] = {0x00, 0x7F, 0xFF};
    const String& str8 = String::Handle(String::FromUTF16(char16, 3));
    EXPECT(str8.IsOneByteString());
    EXPECT(!str8.IsTwoByteString());
    EXPECT_EQ(0x00, str8.CharAt(0));
    EXPECT_EQ(0x7F, str8.CharAt(1));
    EXPECT_EQ(0xFF, str8.CharAt(2));
  }

  // Create a 1-byte string from an array of 4-byte elements.
  {
    const int32_t char32[] = {0x00, 0x1F, 0x7F};
    const String& str8 = String::Handle(String::FromUTF32(char32, 3));
    EXPECT(str8.IsOneByteString());
    EXPECT(!str8.IsTwoByteString());
    EXPECT_EQ(0x00, str8.CharAt(0));
    EXPECT_EQ(0x1F, str8.CharAt(1));
    EXPECT_EQ(0x7F, str8.CharAt(2));
  }

  // Create a 2-byte string from an array of 4-byte elements.
  {
    const int32_t char32[] = {0, 0x7FFF, 0xFFFF};
    const String& str16 = String::Handle(String::FromUTF32(char32, 3));
    EXPECT(!str16.IsOneByteString());
    EXPECT(str16.IsTwoByteString());
    EXPECT_EQ(0x0000, str16.CharAt(0));
    EXPECT_EQ(0x7FFF, str16.CharAt(1));
    EXPECT_EQ(0xFFFF, str16.CharAt(2));
  }
}

ISOLATE_UNIT_TEST_CASE(StringFormat) {
  const char* hello_str = "Hello World!";
  const String& str =
      String::Handle(String::NewFormatted("Hello %s!", "World"));
  EXPECT(str.IsInstance());
  EXPECT(str.IsString());
  EXPECT(str.IsOneByteString());
  EXPECT(!str.IsTwoByteString());
  EXPECT(!str.IsNumber());
  EXPECT(str.Equals(hello_str));
}

ISOLATE_UNIT_TEST_CASE(StringConcat) {
  // Create strings from concatenated 1-byte empty strings.
  {
    const String& empty1 = String::Handle(String::New(""));
    EXPECT(empty1.IsOneByteString());
    EXPECT_EQ(0, empty1.Length());

    const String& empty2 = String::Handle(String::New(""));
    EXPECT(empty2.IsOneByteString());
    EXPECT_EQ(0, empty2.Length());

    // Concat

    const String& empty3 = String::Handle(String::Concat(empty1, empty2));
    EXPECT(empty3.IsOneByteString());
    EXPECT_EQ(0, empty3.Length());

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(0));
    EXPECT_EQ(0, array1.Length());
    const String& empty4 = String::Handle(String::ConcatAll(array1));
    EXPECT_EQ(0, empty4.Length());

    const Array& array2 = Array::Handle(Array::New(10));
    EXPECT_EQ(10, array2.Length());
    for (int i = 0; i < array2.Length(); ++i) {
      array2.SetAt(i, String::Handle(String::New("")));
    }
    const String& empty5 = String::Handle(String::ConcatAll(array2));
    EXPECT(empty5.IsOneByteString());
    EXPECT_EQ(0, empty5.Length());

    const Array& array3 = Array::Handle(Array::New(123));
    EXPECT_EQ(123, array3.Length());

    const String& empty6 = String::Handle(String::New(""));
    EXPECT(empty6.IsOneByteString());
    EXPECT_EQ(0, empty6.Length());
    for (int i = 0; i < array3.Length(); ++i) {
      array3.SetAt(i, empty6);
    }
    const String& empty7 = String::Handle(String::ConcatAll(array3));
    EXPECT(empty7.IsOneByteString());
    EXPECT_EQ(0, empty7.Length());
  }

  // Concatenated empty and non-empty 1-byte strings.
  {
    const String& str1 = String::Handle(String::New(""));
    EXPECT_EQ(0, str1.Length());
    EXPECT(str1.IsOneByteString());

    const String& str2 = String::Handle(String::New("one"));
    EXPECT(str2.IsOneByteString());
    EXPECT_EQ(3, str2.Length());

    // Concat

    const String& str3 = String::Handle(String::Concat(str1, str2));
    EXPECT(str3.IsOneByteString());
    EXPECT_EQ(3, str3.Length());
    EXPECT(str3.Equals(str2));

    const String& str4 = String::Handle(String::Concat(str2, str1));
    EXPECT(str4.IsOneByteString());
    EXPECT_EQ(3, str4.Length());
    EXPECT(str4.Equals(str2));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, str1);
    array1.SetAt(1, str2);
    const String& str5 = String::Handle(String::ConcatAll(array1));
    EXPECT(str5.IsOneByteString());
    EXPECT_EQ(3, str5.Length());
    EXPECT(str5.Equals(str2));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, str1);
    array2.SetAt(1, str2);
    const String& str6 = String::Handle(String::ConcatAll(array2));
    EXPECT(str6.IsOneByteString());
    EXPECT_EQ(3, str6.Length());
    EXPECT(str6.Equals(str2));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, str2);
    array3.SetAt(1, str1);
    array3.SetAt(2, str2);
    const String& str7 = String::Handle(String::ConcatAll(array3));
    EXPECT(str7.IsOneByteString());
    EXPECT_EQ(6, str7.Length());
    EXPECT(str7.Equals("oneone"));
    EXPECT(!str7.Equals("oneoneone"));
  }

  // Create a string by concatenating non-empty 1-byte strings.
  {
    const char* one = "one";
    intptr_t one_len = strlen(one);
    const String& onestr = String::Handle(String::New(one));
    EXPECT(onestr.IsOneByteString());
    EXPECT_EQ(one_len, onestr.Length());

    const char* three = "three";
    intptr_t three_len = strlen(three);
    const String& threestr = String::Handle(String::New(three));
    EXPECT(threestr.IsOneByteString());
    EXPECT_EQ(three_len, threestr.Length());

    // Concat

    const String& str3 = String::Handle(String::Concat(onestr, threestr));
    EXPECT(str3.IsOneByteString());
    const char* one_three = "onethree";
    EXPECT(str3.Equals(one_three));

    const String& str4 = String::Handle(String::Concat(threestr, onestr));
    EXPECT(str4.IsOneByteString());
    const char* three_one = "threeone";
    intptr_t three_one_len = strlen(three_one);
    EXPECT_EQ(three_one_len, str4.Length());
    EXPECT(str4.Equals(three_one));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, onestr);
    array1.SetAt(1, threestr);
    const String& str5 = String::Handle(String::ConcatAll(array1));
    EXPECT(str5.IsOneByteString());
    intptr_t one_three_len = strlen(one_three);
    EXPECT_EQ(one_three_len, str5.Length());
    EXPECT(str5.Equals(one_three));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, threestr);
    array2.SetAt(1, onestr);
    const String& str6 = String::Handle(String::ConcatAll(array2));
    EXPECT(str6.IsOneByteString());
    EXPECT_EQ(three_one_len, str6.Length());
    EXPECT(str6.Equals(three_one));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, onestr);
    array3.SetAt(1, threestr);
    array3.SetAt(2, onestr);
    const String& str7 = String::Handle(String::ConcatAll(array3));
    EXPECT(str7.IsOneByteString());
    const char* one_three_one = "onethreeone";
    intptr_t one_three_one_len = strlen(one_three_one);
    EXPECT_EQ(one_three_one_len, str7.Length());
    EXPECT(str7.Equals(one_three_one));

    const Array& array4 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array4.Length());
    array4.SetAt(0, threestr);
    array4.SetAt(1, onestr);
    array4.SetAt(2, threestr);
    const String& str8 = String::Handle(String::ConcatAll(array4));
    EXPECT(str8.IsOneByteString());
    const char* three_one_three = "threeonethree";
    intptr_t three_one_three_len = strlen(three_one_three);
    EXPECT_EQ(three_one_three_len, str8.Length());
    EXPECT(str8.Equals(three_one_three));
  }

  // Concatenate empty and non-empty 2-byte strings.
  {
    const String& str1 = String::Handle(String::New(""));
    EXPECT(str1.IsOneByteString());
    EXPECT_EQ(0, str1.Length());

    uint16_t two[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& str2 = String::Handle(String::FromUTF16(two, two_len));
    EXPECT(str2.IsTwoByteString());
    EXPECT_EQ(two_len, str2.Length());

    // Concat

    const String& str3 = String::Handle(String::Concat(str1, str2));
    EXPECT(str3.IsTwoByteString());
    EXPECT_EQ(two_len, str3.Length());
    EXPECT(str3.Equals(str2));

    const String& str4 = String::Handle(String::Concat(str2, str1));
    EXPECT(str4.IsTwoByteString());
    EXPECT_EQ(two_len, str4.Length());
    EXPECT(str4.Equals(str2));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, str1);
    array1.SetAt(1, str2);
    const String& str5 = String::Handle(String::ConcatAll(array1));
    EXPECT(str5.IsTwoByteString());
    EXPECT_EQ(two_len, str5.Length());
    EXPECT(str5.Equals(str2));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, str1);
    array2.SetAt(1, str2);
    const String& str6 = String::Handle(String::ConcatAll(array2));
    EXPECT(str6.IsTwoByteString());
    EXPECT_EQ(two_len, str6.Length());
    EXPECT(str6.Equals(str2));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, str2);
    array3.SetAt(1, str1);
    array3.SetAt(2, str2);
    const String& str7 = String::Handle(String::ConcatAll(array3));
    EXPECT(str7.IsTwoByteString());
    EXPECT_EQ(two_len * 2, str7.Length());
    uint16_t twotwo[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                         0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t twotwo_len = sizeof(twotwo) / sizeof(twotwo[0]);
    EXPECT(str7.IsTwoByteString());
    EXPECT(str7.Equals(twotwo, twotwo_len));
  }

  // Concatenating non-empty 2-byte strings.
  {
    const uint16_t one[] = {0x05D0, 0x05D9, 0x05D9, 0x05DF};
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& str1 = String::Handle(String::FromUTF16(one, one_len));
    EXPECT(str1.IsTwoByteString());
    EXPECT_EQ(one_len, str1.Length());

    const uint16_t two[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& str2 = String::Handle(String::FromUTF16(two, two_len));
    EXPECT(str2.IsTwoByteString());
    EXPECT_EQ(two_len, str2.Length());

    // Concat

    const String& one_two_str = String::Handle(String::Concat(str1, str2));
    EXPECT(one_two_str.IsTwoByteString());
    const uint16_t one_two[] = {0x05D0, 0x05D9, 0x05D9, 0x05DF, 0x05E6,
                                0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ(one_two_len, one_two_str.Length());
    EXPECT(one_two_str.Equals(one_two, one_two_len));

    const String& two_one_str = String::Handle(String::Concat(str2, str1));
    EXPECT(two_one_str.IsTwoByteString());
    const uint16_t two_one[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                                0x05D0, 0x05D9, 0x05D9, 0x05DF};
    intptr_t two_one_len = sizeof(two_one) / sizeof(two_one[0]);
    EXPECT_EQ(two_one_len, two_one_str.Length());
    EXPECT(two_one_str.Equals(two_one, two_one_len));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, str1);
    array1.SetAt(1, str2);
    const String& str3 = String::Handle(String::ConcatAll(array1));
    EXPECT(str3.IsTwoByteString());
    EXPECT_EQ(one_two_len, str3.Length());
    EXPECT(str3.Equals(one_two, one_two_len));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, str2);
    array2.SetAt(1, str1);
    const String& str4 = String::Handle(String::ConcatAll(array2));
    EXPECT(str4.IsTwoByteString());
    EXPECT_EQ(two_one_len, str4.Length());
    EXPECT(str4.Equals(two_one, two_one_len));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, str1);
    array3.SetAt(1, str2);
    array3.SetAt(2, str1);
    const String& str5 = String::Handle(String::ConcatAll(array3));
    EXPECT(str5.IsTwoByteString());
    const uint16_t one_two_one[] = {0x05D0, 0x05D9, 0x05D9, 0x05DF, 0x05E6,
                                    0x05D5, 0x05D5, 0x05D9, 0x05D9, 0x05D0,
                                    0x05D9, 0x05D9, 0x05DF};
    intptr_t one_two_one_len = sizeof(one_two_one) / sizeof(one_two_one[0]);
    EXPECT_EQ(one_two_one_len, str5.Length());
    EXPECT(str5.Equals(one_two_one, one_two_one_len));

    const Array& array4 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array4.Length());
    array4.SetAt(0, str2);
    array4.SetAt(1, str1);
    array4.SetAt(2, str2);
    const String& str6 = String::Handle(String::ConcatAll(array4));
    EXPECT(str6.IsTwoByteString());
    const uint16_t two_one_two[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                                    0x05D0, 0x05D9, 0x05D9, 0x05DF, 0x05E6,
                                    0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT_EQ(two_one_two_len, str6.Length());
    EXPECT(str6.Equals(two_one_two, two_one_two_len));
  }

  // Concatenated empty and non-empty strings built from 4-byte elements.
  {
    const String& str1 = String::Handle(String::New(""));
    EXPECT(str1.IsOneByteString());
    EXPECT_EQ(0, str1.Length());

    int32_t four[] = {0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1};
    intptr_t four_len = sizeof(four) / sizeof(four[0]);
    intptr_t expected_len = (four_len * 2);
    const String& str2 = String::Handle(String::FromUTF32(four, four_len));
    EXPECT(str2.IsTwoByteString());
    EXPECT_EQ(expected_len, str2.Length());

    // Concat

    const String& str3 = String::Handle(String::Concat(str1, str2));
    EXPECT_EQ(expected_len, str3.Length());
    EXPECT(str3.Equals(str2));

    const String& str4 = String::Handle(String::Concat(str2, str1));
    EXPECT(str4.IsTwoByteString());
    EXPECT_EQ(expected_len, str4.Length());
    EXPECT(str4.Equals(str2));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, str1);
    array1.SetAt(1, str2);
    const String& str5 = String::Handle(String::ConcatAll(array1));
    EXPECT(str5.IsTwoByteString());
    EXPECT_EQ(expected_len, str5.Length());
    EXPECT(str5.Equals(str2));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, str1);
    array2.SetAt(1, str2);
    const String& str6 = String::Handle(String::ConcatAll(array2));
    EXPECT(str6.IsTwoByteString());
    EXPECT_EQ(expected_len, str6.Length());
    EXPECT(str6.Equals(str2));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, str2);
    array3.SetAt(1, str1);
    array3.SetAt(2, str2);
    const String& str7 = String::Handle(String::ConcatAll(array3));
    EXPECT(str7.IsTwoByteString());
    int32_t fourfour[] = {0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1,
                          0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1};
    intptr_t fourfour_len = sizeof(fourfour) / sizeof(fourfour[0]);
    EXPECT_EQ((fourfour_len * 2), str7.Length());
    const String& fourfour_str =
        String::Handle(String::FromUTF32(fourfour, fourfour_len));
    EXPECT(str7.Equals(fourfour_str));
  }

  // Concatenate non-empty strings built from 4-byte elements.
  {
    const int32_t one[] = {0x105D0, 0x105D9, 0x105D9, 0x105DF};
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& onestr = String::Handle(String::FromUTF32(one, one_len));
    EXPECT(onestr.IsTwoByteString());
    EXPECT_EQ((one_len * 2), onestr.Length());

    const int32_t two[] = {0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9};
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& twostr = String::Handle(String::FromUTF32(two, two_len));
    EXPECT(twostr.IsTwoByteString());
    EXPECT_EQ((two_len * 2), twostr.Length());

    // Concat

    const String& str1 = String::Handle(String::Concat(onestr, twostr));
    EXPECT(str1.IsTwoByteString());
    const int32_t one_two[] = {0x105D0, 0x105D9, 0x105D9, 0x105DF, 0x105E6,
                               0x105D5, 0x105D5, 0x105D9, 0x105D9};
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ((one_two_len * 2), str1.Length());
    const String& one_two_str =
        String::Handle(String::FromUTF32(one_two, one_two_len));
    EXPECT(str1.Equals(one_two_str));

    const String& str2 = String::Handle(String::Concat(twostr, onestr));
    EXPECT(str2.IsTwoByteString());
    const int32_t two_one[] = {0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9,
                               0x105D0, 0x105D9, 0x105D9, 0x105DF};
    intptr_t two_one_len = sizeof(two_one) / sizeof(two_one[0]);
    EXPECT_EQ((two_one_len * 2), str2.Length());
    const String& two_one_str =
        String::Handle(String::FromUTF32(two_one, two_one_len));
    EXPECT(str2.Equals(two_one_str));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array1.Length());
    array1.SetAt(0, onestr);
    array1.SetAt(1, twostr);
    const String& str3 = String::Handle(String::ConcatAll(array1));
    EXPECT(str3.IsTwoByteString());
    EXPECT_EQ((one_two_len * 2), str3.Length());
    EXPECT(str3.Equals(one_two_str));

    const Array& array2 = Array::Handle(Array::New(2));
    EXPECT_EQ(2, array2.Length());
    array2.SetAt(0, twostr);
    array2.SetAt(1, onestr);
    const String& str4 = String::Handle(String::ConcatAll(array2));
    EXPECT(str4.IsTwoByteString());
    EXPECT_EQ((two_one_len * 2), str4.Length());
    EXPECT(str4.Equals(two_one_str));

    const Array& array3 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array3.Length());
    array3.SetAt(0, onestr);
    array3.SetAt(1, twostr);
    array3.SetAt(2, onestr);
    const String& str5 = String::Handle(String::ConcatAll(array3));
    EXPECT(str5.IsTwoByteString());
    const int32_t one_two_one[] = {0x105D0, 0x105D9, 0x105D9, 0x105DF, 0x105E6,
                                   0x105D5, 0x105D5, 0x105D9, 0x105D9, 0x105D0,
                                   0x105D9, 0x105D9, 0x105DF};
    intptr_t one_two_one_len = sizeof(one_two_one) / sizeof(one_two_one[0]);
    EXPECT_EQ((one_two_one_len * 2), str5.Length());
    const String& one_two_one_str =
        String::Handle(String::FromUTF32(one_two_one, one_two_one_len));
    EXPECT(str5.Equals(one_two_one_str));

    const Array& array4 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array4.Length());
    array4.SetAt(0, twostr);
    array4.SetAt(1, onestr);
    array4.SetAt(2, twostr);
    const String& str6 = String::Handle(String::ConcatAll(array4));
    EXPECT(str6.IsTwoByteString());
    const int32_t two_one_two[] = {0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9,
                                   0x105D0, 0x105D9, 0x105D9, 0x105DF, 0x105E6,
                                   0x105D5, 0x105D5, 0x105D9, 0x105D9};
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT_EQ((two_one_two_len * 2), str6.Length());
    const String& two_one_two_str =
        String::Handle(String::FromUTF32(two_one_two, two_one_two_len));
    EXPECT(str6.Equals(two_one_two_str));
  }

  // Concatenate 1-byte strings and 2-byte strings.
  {
    const uint8_t one[] = {'o', 'n', 'e', ' ', 'b', 'y', 't', 'e'};
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& onestr = String::Handle(String::FromLatin1(one, one_len));
    EXPECT(onestr.IsOneByteString());
    EXPECT_EQ(one_len, onestr.Length());
    EXPECT(onestr.EqualsLatin1(one, one_len));

    uint16_t two[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& twostr = String::Handle(String::FromUTF16(two, two_len));
    EXPECT(twostr.IsTwoByteString());
    EXPECT_EQ(two_len, twostr.Length());
    EXPECT(twostr.Equals(two, two_len));

    // Concat

    const String& one_two_str = String::Handle(String::Concat(onestr, twostr));
    EXPECT(one_two_str.IsTwoByteString());
    uint16_t one_two[] = {'o', 'n',    'e',    ' ',    'b',    'y',   't',
                          'e', 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ(one_two_len, one_two_str.Length());
    EXPECT(one_two_str.Equals(one_two, one_two_len));

    const String& two_one_str = String::Handle(String::Concat(twostr, onestr));
    EXPECT(two_one_str.IsTwoByteString());
    uint16_t two_one[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9, 'o', 'n',
                          'e',    ' ',    'b',    'y',    't',    'e'};
    intptr_t two_one_len = sizeof(two_one) / sizeof(two_one[0]);
    EXPECT_EQ(two_one_len, two_one_str.Length());
    EXPECT(two_one_str.Equals(two_one, two_one_len));

    // ConcatAll

    const Array& array1 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array1.Length());
    array1.SetAt(0, onestr);
    array1.SetAt(1, twostr);
    array1.SetAt(2, onestr);
    const String& one_two_one_str = String::Handle(String::ConcatAll(array1));
    EXPECT(one_two_one_str.IsTwoByteString());
    EXPECT_EQ(onestr.Length() * 2 + twostr.Length(), one_two_one_str.Length());
    uint16_t one_two_one[] = {'o', 'n',    'e',    ' ',    'b',    'y',    't',
                              'e', 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9, 'o',
                              'n', 'e',    ' ',    'b',    'y',    't',    'e'};
    intptr_t one_two_one_len = sizeof(one_two_one) / sizeof(one_two_one[0]);
    EXPECT(one_two_one_str.Equals(one_two_one, one_two_one_len));

    const Array& array2 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array2.Length());
    array2.SetAt(0, twostr);
    array2.SetAt(1, onestr);
    array2.SetAt(2, twostr);
    const String& two_one_two_str = String::Handle(String::ConcatAll(array2));
    EXPECT(two_one_two_str.IsTwoByteString());
    EXPECT_EQ(twostr.Length() * 2 + onestr.Length(), two_one_two_str.Length());
    uint16_t two_one_two[] = {0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9, 'o',
                              'n',    'e',    ' ',    'b',    'y',    't',
                              'e',    0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9};
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT(two_one_two_str.Equals(two_one_two, two_one_two_len));
  }
}

ISOLATE_UNIT_TEST_CASE(StringHashConcat) {
  EXPECT_EQ(String::Handle(String::New("onebyte")).Hash(),
            String::HashConcat(String::Handle(String::New("one")),
                               String::Handle(String::New("byte"))));
  uint16_t clef_utf16[] = {0xD834, 0xDD1E};
  const String& clef = String::Handle(String::FromUTF16(clef_utf16, 2));
  int32_t clef_utf32[] = {0x1D11E};
  EXPECT(clef.Equals(clef_utf32, 1));
  uword hash32 = String::Hash(String::FromUTF32(clef_utf32, 1));
  EXPECT_EQ(hash32, clef.Hash());
  EXPECT_EQ(hash32, String::HashConcat(
                        String::Handle(String::FromUTF16(clef_utf16, 1)),
                        String::Handle(String::FromUTF16(clef_utf16 + 1, 1))));
}

ISOLATE_UNIT_TEST_CASE(StringSubStringDifferentWidth) {
  // Create 1-byte substring from a 1-byte source string.
  const char* onechars = "\xC3\xB6\xC3\xB1\xC3\xA9";

  const String& onestr = String::Handle(String::New(onechars));
  EXPECT(!onestr.IsNull());
  EXPECT(onestr.IsOneByteString());
  EXPECT(!onestr.IsTwoByteString());

  const String& onesub = String::Handle(String::SubString(onestr, 0));
  EXPECT(!onesub.IsNull());
  EXPECT(onestr.IsOneByteString());
  EXPECT(!onestr.IsTwoByteString());
  EXPECT_EQ(onesub.Length(), 3);

  // Create 1- and 2-byte substrings from a 2-byte source string.
  const char* twochars =
      "\x1f\x2f\x3f"
      "\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93";

  const String& twostr = String::Handle(String::New(twochars));
  EXPECT(!twostr.IsNull());
  EXPECT(twostr.IsTwoByteString());

  const String& twosub1 = String::Handle(String::SubString(twostr, 0, 3));
  EXPECT(!twosub1.IsNull());
  EXPECT(twosub1.IsOneByteString());
  EXPECT_EQ(twosub1.Length(), 3);

  const String& twosub2 = String::Handle(String::SubString(twostr, 3));
  EXPECT(!twosub2.IsNull());
  EXPECT(twosub2.IsTwoByteString());
  EXPECT_EQ(twosub2.Length(), 3);

  // Create substrings from a string built using 1-, 2- and 4-byte elements.
  const char* fourchars =
      "\x1f\x2f\x3f"
      "\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"
      "\xF0\x9D\x96\xBF\xF0\x9D\x97\x88\xF0\x9D\x97\x8E\xF0\x9D\x97\x8B";

  const String& fourstr = String::Handle(String::New(fourchars));
  EXPECT(!fourstr.IsNull());
  EXPECT(fourstr.IsTwoByteString());

  const String& foursub1 = String::Handle(String::SubString(fourstr, 0, 3));
  EXPECT(!foursub1.IsNull());
  EXPECT(foursub1.IsOneByteString());
  EXPECT_EQ(foursub1.Length(), 3);

  const String& foursub2 = String::Handle(String::SubString(fourstr, 3, 3));
  EXPECT(!foursub2.IsNull());
  EXPECT(foursub2.IsTwoByteString());
  EXPECT_EQ(foursub2.Length(), 3);

  const String& foursub4 = String::Handle(String::SubString(fourstr, 6));
  EXPECT_EQ(foursub4.Length(), 8);
  EXPECT(!foursub4.IsNull());
  EXPECT(foursub4.IsTwoByteString());
}

ISOLATE_UNIT_TEST_CASE(StringFromUtf8Literal) {
  // Create a 1-byte string from a UTF-8 encoded string literal.
  {
    const char* src =
        "\xC2\xA0\xC2\xA1\xC2\xA2\xC2\xA3"
        "\xC2\xA4\xC2\xA5\xC2\xA6\xC2\xA7"
        "\xC2\xA8\xC2\xA9\xC2\xAA\xC2\xAB"
        "\xC2\xAC\xC2\xAD\xC2\xAE\xC2\xAF"
        "\xC2\xB0\xC2\xB1\xC2\xB2\xC2\xB3"
        "\xC2\xB4\xC2\xB5\xC2\xB6\xC2\xB7"
        "\xC2\xB8\xC2\xB9\xC2\xBA\xC2\xBB"
        "\xC2\xBC\xC2\xBD\xC2\xBE\xC2\xBF"
        "\xC3\x80\xC3\x81\xC3\x82\xC3\x83"
        "\xC3\x84\xC3\x85\xC3\x86\xC3\x87"
        "\xC3\x88\xC3\x89\xC3\x8A\xC3\x8B"
        "\xC3\x8C\xC3\x8D\xC3\x8E\xC3\x8F"
        "\xC3\x90\xC3\x91\xC3\x92\xC3\x93"
        "\xC3\x94\xC3\x95\xC3\x96\xC3\x97"
        "\xC3\x98\xC3\x99\xC3\x9A\xC3\x9B"
        "\xC3\x9C\xC3\x9D\xC3\x9E\xC3\x9F"
        "\xC3\xA0\xC3\xA1\xC3\xA2\xC3\xA3"
        "\xC3\xA4\xC3\xA5\xC3\xA6\xC3\xA7"
        "\xC3\xA8\xC3\xA9\xC3\xAA\xC3\xAB"
        "\xC3\xAC\xC3\xAD\xC3\xAE\xC3\xAF"
        "\xC3\xB0\xC3\xB1\xC3\xB2\xC3\xB3"
        "\xC3\xB4\xC3\xB5\xC3\xB6\xC3\xB7"
        "\xC3\xB8\xC3\xB9\xC3\xBA\xC3\xBB"
        "\xC3\xBC\xC3\xBD\xC3\xBE\xC3\xBF";
    const uint8_t expected[] = {
        0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB,
        0xAC, 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7,
        0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC1, 0xC2, 0xC3,
        0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF,
        0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB,
        0xDC, 0xDD, 0xDE, 0xDF, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7,
        0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3,
        0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF,
    };
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsOneByteString());
    intptr_t expected_length = sizeof(expected);
    EXPECT_EQ(expected_length, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }

  // Create a 2-byte string from a UTF-8 encoded string literal.
  {
    const char* src =
        "\xD7\x92\xD7\x9C\xD7\xA2\xD7\x93"
        "\xD7\x91\xD7\xA8\xD7\x9B\xD7\x94";
    const uint16_t expected[] = {0x5D2, 0x5DC, 0x5E2, 0x5D3,
                                 0x5D1, 0x5E8, 0x5DB, 0x5D4};
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
    intptr_t expected_size = sizeof(expected) / sizeof(expected[0]);
    EXPECT_EQ(expected_size, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }

  // Create a BMP 2-byte string from UTF-8 encoded 1- and 2-byte
  // characters.
  {
    const char* src =
        "\x0A\x0B\x0D\x0C\x0E\x0F\xC2\xA0"
        "\xC2\xB0\xC3\x80\xC3\x90\xC3\xA0"
        "\xC3\xB0\xE0\xA8\x80\xE0\xAC\x80"
        "\xE0\xB0\x80\xE0\xB4\x80\xE0\xB8"
        "\x80\xE0\xBC\x80\xEA\x80\x80\xEB"
        "\x80\x80\xEC\x80\x80\xED\x80\x80"
        "\xEE\x80\x80\xEF\x80\x80";
    const intptr_t expected[] = {
        0x000A, 0x000B, 0x000D, 0x000C, 0x000E, 0x000F, 0x00A0, 0x00B0,
        0x00C0, 0x00D0, 0x00E0, 0x00F0, 0x0A00, 0x0B00, 0x0C00, 0x0D00,
        0x0E00, 0x0F00, 0xA000, 0xB000, 0xC000, 0xD000, 0xE000, 0xF000};
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
    intptr_t expected_size = sizeof(expected) / sizeof(expected[0]);
    EXPECT_EQ(expected_size, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }

  // Create a 2-byte string with supplementary characters from a UTF-8
  // string literal.
  {
    const char* src =
        "\xF0\x9D\x91\xA0\xF0\x9D\x91\xA1"
        "\xF0\x9D\x91\xA2\xF0\x9D\x91\xA3";
    const intptr_t expected[] = {0xd835, 0xdc60, 0xd835, 0xdc61,
                                 0xd835, 0xdc62, 0xd835, 0xdc63};
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
    intptr_t expected_size = (sizeof(expected) / sizeof(expected[0]));
    EXPECT_EQ(expected_size, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }

  // Create a 2-byte string from UTF-8 encoded 2- and 4-byte
  // characters.
  {
    const char* src =
        "\xE0\xA8\x80\xE0\xAC\x80\xE0\xB0"
        "\x80\xE0\xB4\x80\xE0\xB8\x80\xE0"
        "\xBC\x80\xEA\x80\x80\xEB\x80\x80"
        "\xEC\x80\x80\xED\x80\x80\xEE\x80"
        "\x80\xEF\x80\x80\xF0\x9A\x80\x80"
        "\xF0\x9B\x80\x80\xF0\x9D\x80\x80"
        "\xF0\x9E\x80\x80\xF0\x9F\x80\x80";
    const intptr_t expected[] = {
        0x0A00, 0x0B00, 0x0C00, 0x0D00, 0x0E00, 0x0F00, 0xA000, 0xB000,
        0xC000, 0xD000, 0xE000, 0xF000, 0xD828, 0xDC00, 0xD82c, 0xDC00,
        0xD834, 0xDC00, 0xD838, 0xDC00, 0xD83c, 0xDC00,
    };
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
    intptr_t expected_size = sizeof(expected) / sizeof(expected[0]);
    EXPECT_EQ(expected_size, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }

  // Create a 2-byte string from UTF-8 encoded 1-, 2- and 4-byte
  // characters.
  {
    const char* src =
        "\x0A\x0B\x0D\x0C\x0E\x0F\xC2\xA0"
        "\xC2\xB0\xC3\x80\xC3\x90\xC3\xA0"
        "\xC3\xB0\xE0\xA8\x80\xE0\xAC\x80"
        "\xE0\xB0\x80\xE0\xB4\x80\xE0\xB8"
        "\x80\xE0\xBC\x80\xEA\x80\x80\xEB"
        "\x80\x80\xEC\x80\x80\xED\x80\x80"
        "\xEE\x80\x80\xEF\x80\x80\xF0\x9A"
        "\x80\x80\xF0\x9B\x80\x80\xF0\x9D"
        "\x80\x80\xF0\x9E\x80\x80\xF0\x9F"
        "\x80\x80";
    const intptr_t expected[] = {
        0x000A, 0x000B, 0x000D, 0x000C, 0x000E, 0x000F, 0x00A0, 0x00B0, 0x00C0,
        0x00D0, 0x00E0, 0x00F0, 0x0A00, 0x0B00, 0x0C00, 0x0D00, 0x0E00, 0x0F00,
        0xA000, 0xB000, 0xC000, 0xD000, 0xE000, 0xF000, 0xD828, 0xDC00, 0xD82c,
        0xDC00, 0xD834, 0xDC00, 0xD838, 0xDC00, 0xD83c, 0xDC00,
    };
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
    intptr_t expected_size = sizeof(expected) / sizeof(expected[0]);
    EXPECT_EQ(expected_size, str.Length());
    for (int i = 0; i < str.Length(); ++i) {
      EXPECT_EQ(expected[i], str.CharAt(i));
    }
  }
}

ISOLATE_UNIT_TEST_CASE(StringEqualsUtf8) {
  const char* onesrc = "abc";
  const String& onestr = String::Handle(String::New(onesrc));
  EXPECT(onestr.IsOneByteString());
  EXPECT(!onestr.Equals(""));
  EXPECT(!onestr.Equals("a"));
  EXPECT(!onestr.Equals("ab"));
  EXPECT(onestr.Equals("abc"));
  EXPECT(!onestr.Equals("abcd"));

  const char* twosrc = "\xD7\x90\xD7\x91\xD7\x92";
  const String& twostr = String::Handle(String::New(twosrc));
  EXPECT(twostr.IsTwoByteString());
  EXPECT(!twostr.Equals(""));
  EXPECT(!twostr.Equals("\xD7\x90"));
  EXPECT(!twostr.Equals("\xD7\x90\xD7\x91"));
  EXPECT(twostr.Equals("\xD7\x90\xD7\x91\xD7\x92"));
  EXPECT(!twostr.Equals("\xD7\x90\xD7\x91\xD7\x92\xD7\x93"));

  const char* foursrc = "\xF0\x90\x8E\xA0\xF0\x90\x8E\xA1\xF0\x90\x8E\xA2";
  const String& fourstr = String::Handle(String::New(foursrc));
  EXPECT(fourstr.IsTwoByteString());
  EXPECT(!fourstr.Equals(""));
  EXPECT(!fourstr.Equals("\xF0\x90\x8E\xA0"));
  EXPECT(!fourstr.Equals("\xF0\x90\x8E\xA0\xF0\x90\x8E\xA1"));
  EXPECT(fourstr.Equals("\xF0\x90\x8E\xA0\xF0\x90\x8E\xA1\xF0\x90\x8E\xA2"));
  EXPECT(
      !fourstr.Equals("\xF0\x90\x8E\xA0\xF0\x90\x8E\xA1"
                      "\xF0\x90\x8E\xA2\xF0\x90\x8E\xA3"));
}

ISOLATE_UNIT_TEST_CASE(StringEqualsUTF32) {
  const String& empty = String::Handle(String::New(""));
  const String& t_str = String::Handle(String::New("t"));
  const String& th_str = String::Handle(String::New("th"));
  const int32_t chars[] = {'t', 'h', 'i', 's'};
  EXPECT(!empty.Equals(chars, -1));
  EXPECT(empty.Equals(chars, 0));
  EXPECT(!empty.Equals(chars, 1));
  EXPECT(!t_str.Equals(chars, 0));
  EXPECT(t_str.Equals(chars, 1));
  EXPECT(!t_str.Equals(chars, 2));
  EXPECT(!th_str.Equals(chars, 1));
  EXPECT(th_str.Equals(chars, 2));
  EXPECT(!th_str.Equals(chars, 3));
}

static void NoopFinalizer(void* isolate_callback_data, void* peer) {}

ISOLATE_UNIT_TEST_CASE(ExternalOneByteString) {
  uint8_t characters[] = {0xF6, 0xF1, 0xE9};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str = String::Handle(ExternalOneByteString::New(
      characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
  EXPECT(!str.IsOneByteString());
  EXPECT(str.IsExternalOneByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("\xC3\xB6\xC3\xB1\xC3\xA9"));

  const String& copy = String::Handle(String::SubString(str, 0, len));
  EXPECT(!copy.IsExternalOneByteString());
  EXPECT(copy.IsOneByteString());
  EXPECT_EQ(len, copy.Length());
  EXPECT(copy.Equals(str));

  const String& concat = String::Handle(String::Concat(str, str));
  EXPECT(!concat.IsExternalOneByteString());
  EXPECT(concat.IsOneByteString());
  EXPECT_EQ(len * 2, concat.Length());
  EXPECT(concat.Equals("\xC3\xB6\xC3\xB1\xC3\xA9\xC3\xB6\xC3\xB1\xC3\xA9"));

  const String& substr = String::Handle(String::SubString(str, 1, 1));
  EXPECT(!substr.IsExternalOneByteString());
  EXPECT(substr.IsOneByteString());
  EXPECT_EQ(1, substr.Length());
  EXPECT(substr.Equals("\xC3\xB1"));
}

ISOLATE_UNIT_TEST_CASE(EscapeSpecialCharactersOneByteString) {
  uint8_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                          '\v', '\r', '\\', '$',  'z'};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str =
      String::Handle(OneByteString::New(characters, len, Heap::kNew));
  EXPECT(str.IsOneByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& escaped_empty_str =
      String::Handle(String::EscapeSpecialCharacters(Symbols::Empty()));
  EXPECT_EQ(escaped_empty_str.Length(), 0);
}

ISOLATE_UNIT_TEST_CASE(EscapeSpecialCharactersExternalOneByteString) {
  uint8_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                          '\v', '\r', '\\', '$',  'z'};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str = String::Handle(ExternalOneByteString::New(
      characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
  EXPECT(!str.IsOneByteString());
  EXPECT(str.IsExternalOneByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& empty_str = String::Handle(ExternalOneByteString::New(
      characters, 0, nullptr, 0, NoopFinalizer, Heap::kNew));
  const String& escaped_empty_str =
      String::Handle(String::EscapeSpecialCharacters(empty_str));
  EXPECT_EQ(empty_str.Length(), 0);
  EXPECT_EQ(escaped_empty_str.Length(), 0);
}

ISOLATE_UNIT_TEST_CASE(EscapeSpecialCharactersTwoByteString) {
  uint16_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                           '\v', '\r', '\\', '$',  'z'};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str =
      String::Handle(TwoByteString::New(characters, len, Heap::kNew));
  EXPECT(str.IsTwoByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& empty_str =
      String::Handle(TwoByteString::New(static_cast<intptr_t>(0), Heap::kNew));
  const String& escaped_empty_str =
      String::Handle(String::EscapeSpecialCharacters(empty_str));
  EXPECT_EQ(empty_str.Length(), 0);
  EXPECT_EQ(escaped_empty_str.Length(), 0);
}

ISOLATE_UNIT_TEST_CASE(EscapeSpecialCharactersExternalTwoByteString) {
  uint16_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                           '\v', '\r', '\\', '$',  'z'};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str = String::Handle(ExternalTwoByteString::New(
      characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
  EXPECT(str.IsExternalTwoByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& empty_str = String::Handle(ExternalTwoByteString::New(
      characters, 0, nullptr, 0, NoopFinalizer, Heap::kNew));
  const String& escaped_empty_str =
      String::Handle(String::EscapeSpecialCharacters(empty_str));
  EXPECT_EQ(empty_str.Length(), 0);
  EXPECT_EQ(escaped_empty_str.Length(), 0);
}

ISOLATE_UNIT_TEST_CASE(ExternalTwoByteString) {
  uint16_t characters[] = {0x1E6B, 0x1E85, 0x1E53};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str = String::Handle(ExternalTwoByteString::New(
      characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
  EXPECT(!str.IsTwoByteString());
  EXPECT(str.IsExternalTwoByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"));

  const String& copy = String::Handle(String::SubString(str, 0, len));
  EXPECT(!copy.IsExternalTwoByteString());
  EXPECT(copy.IsTwoByteString());
  EXPECT_EQ(len, copy.Length());
  EXPECT(copy.Equals(str));

  const String& concat = String::Handle(String::Concat(str, str));
  EXPECT(!concat.IsExternalTwoByteString());
  EXPECT(concat.IsTwoByteString());
  EXPECT_EQ(len * 2, concat.Length());
  EXPECT(
      concat.Equals("\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"
                    "\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"));

  const String& substr = String::Handle(String::SubString(str, 1, 1));
  EXPECT(!substr.IsExternalTwoByteString());
  EXPECT(substr.IsTwoByteString());
  EXPECT_EQ(1, substr.Length());
  EXPECT(substr.Equals("\xE1\xBA\x85"));
}

ISOLATE_UNIT_TEST_CASE(Symbol) {
  const String& one = String::Handle(Symbols::New(thread, "Eins"));
  EXPECT(one.IsSymbol());
  const String& two = String::Handle(Symbols::New(thread, "Zwei"));
  const String& three = String::Handle(Symbols::New(thread, "Drei"));
  const String& four = String::Handle(Symbols::New(thread, "Vier"));
  const String& five = String::Handle(Symbols::New(thread, "Fuenf"));
  const String& six = String::Handle(Symbols::New(thread, "Sechs"));
  const String& seven = String::Handle(Symbols::New(thread, "Sieben"));
  const String& eight = String::Handle(Symbols::New(thread, "Acht"));
  const String& nine = String::Handle(Symbols::New(thread, "Neun"));
  const String& ten = String::Handle(Symbols::New(thread, "Zehn"));
  String& eins = String::Handle(Symbols::New(thread, "Eins"));
  EXPECT_EQ(one.ptr(), eins.ptr());
  EXPECT(one.ptr() != two.ptr());
  EXPECT(two.Equals(String::Handle(String::New("Zwei"))));
  EXPECT_EQ(two.ptr(), Symbols::New(thread, "Zwei"));
  EXPECT_EQ(three.ptr(), Symbols::New(thread, "Drei"));
  EXPECT_EQ(four.ptr(), Symbols::New(thread, "Vier"));
  EXPECT_EQ(five.ptr(), Symbols::New(thread, "Fuenf"));
  EXPECT_EQ(six.ptr(), Symbols::New(thread, "Sechs"));
  EXPECT_EQ(seven.ptr(), Symbols::New(thread, "Sieben"));
  EXPECT_EQ(eight.ptr(), Symbols::New(thread, "Acht"));
  EXPECT_EQ(nine.ptr(), Symbols::New(thread, "Neun"));
  EXPECT_EQ(ten.ptr(), Symbols::New(thread, "Zehn"));

  // Make sure to cause symbol table overflow.
  for (int i = 0; i < 1024; i++) {
    char buf[256];
    Utils::SNPrint(buf, sizeof(buf), "%d", i);
    Symbols::New(thread, buf);
  }
  eins = Symbols::New(thread, "Eins");
  EXPECT_EQ(one.ptr(), eins.ptr());
  EXPECT_EQ(two.ptr(), Symbols::New(thread, "Zwei"));
  EXPECT_EQ(three.ptr(), Symbols::New(thread, "Drei"));
  EXPECT_EQ(four.ptr(), Symbols::New(thread, "Vier"));
  EXPECT_EQ(five.ptr(), Symbols::New(thread, "Fuenf"));
  EXPECT_EQ(six.ptr(), Symbols::New(thread, "Sechs"));
  EXPECT_EQ(seven.ptr(), Symbols::New(thread, "Sieben"));
  EXPECT_EQ(eight.ptr(), Symbols::New(thread, "Acht"));
  EXPECT_EQ(nine.ptr(), Symbols::New(thread, "Neun"));
  EXPECT_EQ(ten.ptr(), Symbols::New(thread, "Zehn"));

  // Symbols from Strings.
  eins = String::New("Eins");
  EXPECT(!eins.IsSymbol());
  String& ein_symbol = String::Handle(Symbols::New(thread, eins));
  EXPECT_EQ(one.ptr(), ein_symbol.ptr());
  EXPECT(one.ptr() != eins.ptr());

  uint16_t char16[] = {'E', 'l', 'f'};
  String& elf1 = String::Handle(Symbols::FromUTF16(thread, char16, 3));
  int32_t char32[] = {'E', 'l', 'f'};
  String& elf2 = String::Handle(
      Symbols::New(thread, String::Handle(String::FromUTF32(char32, 3))));
  EXPECT(elf1.IsSymbol());
  EXPECT(elf2.IsSymbol());
  EXPECT_EQ(elf1.ptr(), Symbols::New(thread, "Elf"));
  EXPECT_EQ(elf2.ptr(), Symbols::New(thread, "Elf"));
}

ISOLATE_UNIT_TEST_CASE(SymbolUnicode) {
  uint16_t monkey_utf16[] = {0xd83d, 0xdc35};  // Unicode Monkey Face.
  String& monkey = String::Handle(Symbols::FromUTF16(thread, monkey_utf16, 2));
  EXPECT(monkey.IsSymbol());
  const char monkey_utf8[] = {'\xf0', '\x9f', '\x90', '\xb5', 0};
  EXPECT_EQ(monkey.ptr(), Symbols::New(thread, monkey_utf8));

  int32_t kMonkeyFace = 0x1f435;
  String& monkey2 = String::Handle(
      Symbols::New(thread, String::Handle(String::FromUTF32(&kMonkeyFace, 1))));
  EXPECT_EQ(monkey.ptr(), monkey2.ptr());

  // Unicode cat face with tears of joy.
  int32_t kCatFaceWithTearsOfJoy = 0x1f639;
  String& cat = String::Handle(Symbols::New(
      thread, String::Handle(String::FromUTF32(&kCatFaceWithTearsOfJoy, 1))));

  uint16_t cat_utf16[] = {0xd83d, 0xde39};
  String& cat2 = String::Handle(Symbols::FromUTF16(thread, cat_utf16, 2));
  EXPECT(cat2.IsSymbol());
  EXPECT_EQ(cat2.ptr(), cat.ptr());
}

ISOLATE_UNIT_TEST_CASE(Bool) {
  EXPECT(Bool::True().value());
  EXPECT(!Bool::False().value());
}

ISOLATE_UNIT_TEST_CASE(Array) {
  const int kArrayLen = 5;
  const Array& array = Array::Handle(Array::New(kArrayLen));
  EXPECT_EQ(kArrayLen, array.Length());
  Object& element = Object::Handle(array.At(0));
  EXPECT(element.IsNull());
  element = array.At(kArrayLen - 1);
  EXPECT(element.IsNull());
  array.SetAt(0, array);
  array.SetAt(2, array);
  element = array.At(0);
  EXPECT_EQ(array.ptr(), element.ptr());
  element = array.At(1);
  EXPECT(element.IsNull());
  element = array.At(2);
  EXPECT_EQ(array.ptr(), element.ptr());

  Array& other_array = Array::Handle(Array::New(kArrayLen));
  other_array.SetAt(0, array);
  other_array.SetAt(2, array);

  EXPECT(array.CanonicalizeEquals(array));
  EXPECT(array.CanonicalizeEquals(other_array));

  other_array.SetAt(1, other_array);
  EXPECT(!array.CanonicalizeEquals(other_array));

  other_array = Array::New(kArrayLen - 1);
  other_array.SetAt(0, array);
  other_array.SetAt(2, array);
  EXPECT(!array.CanonicalizeEquals(other_array));

  EXPECT_EQ(0, Object::empty_array().Length());

  array.MakeImmutable();
  Object& obj = Object::Handle(array.ptr());
  EXPECT(obj.IsArray());
}

ISOLATE_UNIT_TEST_CASE(Array_Grow) {
  const intptr_t kSmallSize = 100;
  EXPECT(!Array::UseCardMarkingForAllocation(kSmallSize));
  const intptr_t kMediumSize = 1000;
  EXPECT(!Array::UseCardMarkingForAllocation(kMediumSize));
  const intptr_t kLargeSize = 100000;
  EXPECT(Array::UseCardMarkingForAllocation(kLargeSize));

  const Array& small = Array::Handle(Array::New(kSmallSize));
  for (intptr_t i = 0; i < kSmallSize; i++) {
    small.SetAt(i, Smi::Handle(Smi::New(i)));
  }

  const Array& medium = Array::Handle(Array::Grow(small, kMediumSize));
  EXPECT_EQ(kMediumSize, medium.Length());
  for (intptr_t i = 0; i < kSmallSize; i++) {
    EXPECT_EQ(Smi::New(i), medium.At(i));
  }
  for (intptr_t i = kSmallSize; i < kMediumSize; i++) {
    EXPECT_EQ(Object::null(), medium.At(i));
  }

  const Array& large = Array::Handle(Array::Grow(small, kLargeSize));
  EXPECT_EQ(kLargeSize, large.Length());
  for (intptr_t i = 0; i < kSmallSize; i++) {
    EXPECT_EQ(large.At(i), Smi::New(i));
  }
  for (intptr_t i = kSmallSize; i < kLargeSize; i++) {
    EXPECT_EQ(large.At(i), Object::null());
  }
}

ISOLATE_UNIT_TEST_CASE(EmptyInstantiationsCacheArray) {
  SafepointMutexLocker ml(
      thread->isolate_group()->type_arguments_canonicalization_mutex());
  const Array& empty_cache = Object::empty_instantiations_cache_array();
  DEBUG_ONLY(EXPECT(TypeArguments::Cache::IsValidStorageLocked(empty_cache));)
  const TypeArguments::Cache cache(thread->zone(), empty_cache);
  EXPECT(cache.IsLinear());
  EXPECT(!cache.IsHash());
  EXPECT_EQ(0, cache.NumOccupied());
  const InstantiationsCacheTable table(empty_cache);
  EXPECT_EQ(1, table.Length());
  for (const auto& tuple : table) {
    EXPECT(tuple.Get<TypeArguments::Cache::kSentinelIndex>() ==
           TypeArguments::Cache::Sentinel());
  }
}

static void TestIllegalArrayLength(intptr_t length) {
  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "main() {\n"
                 "  List.filled(%" Pd
                 ", null);\n"
                 "}\n",
                 length);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  Utils::SNPrint(buffer, sizeof(buffer),
                 "Unhandled exception:\n"
                 "RangeError (length): Invalid value: "
                 "Not in inclusive range 0..%" Pd ": %" Pd,
                 Array::kMaxElements, length);
  EXPECT_ERROR(result, buffer);
}

TEST_CASE(ArrayLengthNegativeOne) {
  TestIllegalArrayLength(-1);
}
TEST_CASE(ArrayLengthSmiMin) {
  TestIllegalArrayLength(kSmiMin);
}

TEST_CASE(ArrayLengthOneTooMany) {
  const intptr_t kOneTooMany = Array::kMaxElements + 1;
  ASSERT(kOneTooMany >= 0);

  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "main() {\n"
                 "  return List.filled(%" Pd
                 ", null);\n"
                 "}\n",
                 kOneTooMany);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  EXPECT_ERROR(result, "Out of Memory");
}

TEST_CASE(ArrayLengthMaxElements) {
  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "main() {\n"
                 "  return List.filled(%" Pd
                 ", null);\n"
                 "}\n",
                 Array::kMaxElements);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  if (Dart_IsError(result)) {
    EXPECT_ERROR(result, "Out of Memory");
  } else {
    const intptr_t kExpected = Array::kMaxElements;
    intptr_t actual = 0;
    EXPECT_VALID(Dart_ListLength(result, &actual));
    EXPECT_EQ(kExpected, actual);
  }
}

static void TestIllegalTypedDataLength(const char* class_name,
                                       intptr_t length) {
  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "import 'dart:typed_data';\n"
                 "main() {\n"
                 "  new %s(%" Pd
                 ");\n"
                 "}\n",
                 class_name, length);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  Utils::SNPrint(buffer, sizeof(buffer), "%" Pd, length);
  EXPECT_ERROR(result, "RangeError (length): Invalid value");
  EXPECT_ERROR(result, buffer);
}

TEST_CASE(Int8ListLengthNegativeOne) {
  TestIllegalTypedDataLength("Int8List", -1);
}
TEST_CASE(Int8ListLengthSmiMin) {
  TestIllegalTypedDataLength("Int8List", kSmiMin);
}
TEST_CASE(Int8ListLengthOneTooMany) {
  const intptr_t kOneTooMany =
      TypedData::MaxElements(kTypedDataInt8ArrayCid) + 1;
  ASSERT(kOneTooMany >= 0);

  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "import 'dart:typed_data';\n"
                 "main() {\n"
                 "  return new Int8List(%" Pd
                 ");\n"
                 "}\n",
                 kOneTooMany);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  EXPECT_ERROR(result, "Out of Memory");
}

TEST_CASE(Int8ListLengthMaxElements) {
  const intptr_t max_elements = TypedData::MaxElements(kTypedDataInt8ArrayCid);
  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "import 'dart:typed_data';\n"
                 "main() {\n"
                 "  return new Int8List(%" Pd
                 ");\n"
                 "}\n",
                 max_elements);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
  if (Dart_IsError(result)) {
    EXPECT_ERROR(result, "Out of Memory");
  } else {
    intptr_t actual = 0;
    EXPECT_VALID(Dart_ListLength(result, &actual));
    EXPECT_EQ(max_elements, actual);
  }
}

ISOLATE_UNIT_TEST_CASE(StringCodePointIterator) {
  const String& str0 = String::Handle(String::New(""));
  String::CodePointIterator it0(str0);
  EXPECT(!it0.Next());

  const String& str1 = String::Handle(String::New(" \xc3\xa7 "));
  String::CodePointIterator it1(str1);
  EXPECT(it1.Next());
  EXPECT_EQ(' ', it1.Current());
  EXPECT(it1.Next());
  EXPECT_EQ(0xE7, it1.Current());
  EXPECT(it1.Next());
  EXPECT_EQ(' ', it1.Current());
  EXPECT(!it1.Next());

  const String& str2 =
      String::Handle(String::New("\xD7\x92\xD7\x9C"
                                 "\xD7\xA2\xD7\x93"
                                 "\xD7\x91\xD7\xA8"
                                 "\xD7\x9B\xD7\x94"));
  String::CodePointIterator it2(str2);
  EXPECT(it2.Next());
  EXPECT_EQ(0x5D2, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5DC, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5E2, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5D3, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5D1, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5E8, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5DB, it2.Current());
  EXPECT(it2.Next());
  EXPECT_EQ(0x5D4, it2.Current());
  EXPECT(!it2.Next());

  const String& str3 =
      String::Handle(String::New("\xF0\x9D\x91\xA0"
                                 "\xF0\x9D\x91\xA1"
                                 "\xF0\x9D\x91\xA2"
                                 "\xF0\x9D\x91\xA3"));
  String::CodePointIterator it3(str3);
  EXPECT(it3.Next());
  EXPECT_EQ(0x1D460, it3.Current());
  EXPECT(it3.Next());
  EXPECT_EQ(0x1D461, it3.Current());
  EXPECT(it3.Next());
  EXPECT_EQ(0x1D462, it3.Current());
  EXPECT(it3.Next());
  EXPECT_EQ(0x1D463, it3.Current());
  EXPECT(!it3.Next());
}

ISOLATE_UNIT_TEST_CASE(StringCodePointIteratorRange) {
  const String& str = String::Handle(String::New("foo bar baz"));

  String::CodePointIterator it0(str, 3, 0);
  EXPECT(!it0.Next());

  String::CodePointIterator it1(str, 4, 3);
  EXPECT(it1.Next());
  EXPECT_EQ('b', it1.Current());
  EXPECT(it1.Next());
  EXPECT_EQ('a', it1.Current());
  EXPECT(it1.Next());
  EXPECT_EQ('r', it1.Current());
  EXPECT(!it1.Next());
}

ISOLATE_UNIT_TEST_CASE(GrowableObjectArray) {
  const int kArrayLen = 5;
  Smi& value = Smi::Handle();
  Smi& expected_value = Smi::Handle();
  GrowableObjectArray& array = GrowableObjectArray::Handle();

  // Test basic growing functionality.
  array = GrowableObjectArray::New(kArrayLen);
  EXPECT_EQ(kArrayLen, array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 10; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  EXPECT_EQ(10, array.Length());
  for (intptr_t i = 0; i < 10; i++) {
    expected_value = Smi::New(i);
    value ^= array.At(i);
    EXPECT(value.Equals(expected_value));
  }
  for (intptr_t i = 0; i < 10; i++) {
    value = Smi::New(i * 10);
    array.SetAt(i, value);
  }
  EXPECT_EQ(10, array.Length());
  for (intptr_t i = 0; i < 10; i++) {
    expected_value = Smi::New(i * 10);
    value ^= array.At(i);
    EXPECT(value.Equals(expected_value));
  }

  // Test the MakeFixedLength functionality to make sure the resulting array
  // object is properly setup.
  // 1. Should produce an array of length 2 and a left over int8 array.
  Array& new_array = Array::Handle();
  TypedData& left_over_array = TypedData::Handle();
  Object& obj = Object::Handle();
  uword addr = 0;
  intptr_t used_size = 0;

  array = GrowableObjectArray::New(kArrayLen + 1);
  EXPECT_EQ(kArrayLen + 1, array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 2; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  used_size = Array::InstanceSize(array.Length());
  new_array = Array::MakeFixedLength(array);
  addr = UntaggedObject::ToAddr(new_array.ptr());
  obj = UntaggedObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.ptr();
  EXPECT_EQ(2, new_array.Length());
  addr += used_size;
  obj = UntaggedObject::FromAddr(addr);
#if defined(DART_COMPRESSED_POINTERS)
  // In compressed pointer mode, the TypedData doesn't fit.
  EXPECT(obj.IsInstance());
#else
  EXPECT(obj.IsTypedData());
  left_over_array ^= obj.ptr();
  EXPECT_EQ(4 * kWordSize - TypedData::InstanceSize(0),
            left_over_array.Length());
#endif

  // 2. Should produce an array of length 3 and a left over int8 array or
  // instance.
  array = GrowableObjectArray::New(kArrayLen);
  EXPECT_EQ(kArrayLen, array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 3; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  used_size = Array::InstanceSize(array.Length());
  new_array = Array::MakeFixedLength(array);
  addr = UntaggedObject::ToAddr(new_array.ptr());
  obj = UntaggedObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.ptr();
  EXPECT_EQ(3, new_array.Length());
  addr += used_size;
  obj = UntaggedObject::FromAddr(addr);
  if (TypedData::InstanceSize(0) <= 2 * kCompressedWordSize) {
    EXPECT(obj.IsTypedData());
    left_over_array ^= obj.ptr();
    EXPECT_EQ(2 * kCompressedWordSize - TypedData::InstanceSize(0),
              left_over_array.Length());
  } else {
    EXPECT(obj.IsInstance());
  }

  // 3. Should produce an array of length 1 and a left over int8 array.
  array = GrowableObjectArray::New(kArrayLen + 3);
  EXPECT_EQ((kArrayLen + 3), array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 1; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  used_size = Array::InstanceSize(array.Length());
  new_array = Array::MakeFixedLength(array);
  addr = UntaggedObject::ToAddr(new_array.ptr());
  obj = UntaggedObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.ptr();
  EXPECT_EQ(1, new_array.Length());
  addr += used_size;
  obj = UntaggedObject::FromAddr(addr);
#if defined(DART_COMPRESSED_POINTERS)
  // In compressed pointer mode, the TypedData doesn't fit.
  EXPECT(obj.IsInstance());
#else
  EXPECT(obj.IsTypedData());
  left_over_array ^= obj.ptr();
  EXPECT_EQ(8 * kWordSize - TypedData::InstanceSize(0),
            left_over_array.Length());
#endif

  // 4. Verify that GC can handle the filler object for a large array.
  array = GrowableObjectArray::New((1 * MB) >> kWordSizeLog2);
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 1; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  Heap* heap = IsolateGroup::Current()->heap();
  GCTestHelper::CollectAllGarbage();
  intptr_t capacity_before = heap->CapacityInWords(Heap::kOld);
  new_array = Array::MakeFixedLength(array);
  EXPECT_EQ(1, new_array.Length());
  GCTestHelper::CollectAllGarbage();
  intptr_t capacity_after = heap->CapacityInWords(Heap::kOld);
  // Page should shrink.
  EXPECT_LT(capacity_after, capacity_before);
  EXPECT_EQ(1, new_array.Length());
}

ISOLATE_UNIT_TEST_CASE(TypedData_Grow) {
  const intptr_t kSmallSize = 42;
  const intptr_t kLargeSize = 1000;

  Random random(42);

  for (classid_t cid = kTypedDataInt8ArrayCid; cid < kByteDataViewCid;
       cid += 4) {
    ASSERT(IsTypedDataClassId(cid));

    const auto& small = TypedData::Handle(TypedData::New(cid, kSmallSize));
    EXPECT_EQ(small.LengthInBytes(), kSmallSize * small.ElementSizeInBytes());

    for (intptr_t i = 0; i < TypedData::ElementSizeFor(cid) * kSmallSize; i++) {
      small.SetUint8(i, static_cast<uint8_t>(random.NextUInt64() & 0xff));
    }

    const auto& big = TypedData::Handle(TypedData::Grow(small, kLargeSize));
    EXPECT_EQ(small.GetClassId(), big.GetClassId());
    EXPECT_EQ(big.LengthInBytes(), kLargeSize * big.ElementSizeInBytes());

    for (intptr_t i = 0; i < TypedData::ElementSizeFor(cid) * kSmallSize; i++) {
      EXPECT_EQ(small.GetUint8(i), big.GetUint8(i));
    }
    for (intptr_t i = TypedData::ElementSizeFor(cid) * kSmallSize;
         i < TypedData::ElementSizeFor(cid) * kLargeSize; i++) {
      EXPECT_EQ(0, big.GetUint8(i));
    }
  }
}

ISOLATE_UNIT_TEST_CASE(InternalTypedData) {
  uint8_t data[] = {253, 254, 255, 0, 1, 2, 3, 4};
  intptr_t data_length = ARRAY_SIZE(data);

  const TypedData& int8_array =
      TypedData::Handle(TypedData::New(kTypedDataInt8ArrayCid, data_length));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());
  for (intptr_t i = 0; i < data_length; ++i) {
    int8_array.SetInt8(i, data[i]);
  }

  EXPECT_EQ(-3, int8_array.GetInt8(0));
  EXPECT_EQ(253, int8_array.GetUint8(0));

  EXPECT_EQ(-2, int8_array.GetInt8(1));
  EXPECT_EQ(254, int8_array.GetUint8(1));

  EXPECT_EQ(-1, int8_array.GetInt8(2));
  EXPECT_EQ(255, int8_array.GetUint8(2));

  EXPECT_EQ(0, int8_array.GetInt8(3));
  EXPECT_EQ(0, int8_array.GetUint8(3));

  EXPECT_EQ(1, int8_array.GetInt8(4));
  EXPECT_EQ(1, int8_array.GetUint8(4));

  EXPECT_EQ(2, int8_array.GetInt8(5));
  EXPECT_EQ(2, int8_array.GetUint8(5));

  EXPECT_EQ(3, int8_array.GetInt8(6));
  EXPECT_EQ(3, int8_array.GetUint8(6));

  EXPECT_EQ(4, int8_array.GetInt8(7));
  EXPECT_EQ(4, int8_array.GetUint8(7));

  const TypedData& int8_array2 =
      TypedData::Handle(TypedData::New(kTypedDataInt8ArrayCid, data_length));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());
  for (intptr_t i = 0; i < data_length; ++i) {
    int8_array2.SetInt8(i, data[i]);
  }

  for (intptr_t i = 0; i < data_length; ++i) {
    EXPECT_EQ(int8_array.GetInt8(i), int8_array2.GetInt8(i));
  }
  for (intptr_t i = 0; i < data_length; ++i) {
    int8_array.SetInt8(i, 123 + i);
  }
  for (intptr_t i = 0; i < data_length; ++i) {
    EXPECT(int8_array.GetInt8(i) != int8_array2.GetInt8(i));
  }
}

ISOLATE_UNIT_TEST_CASE(ExternalTypedData) {
  uint8_t data[] = {253, 254, 255, 0, 1, 2, 3, 4};
  intptr_t data_length = ARRAY_SIZE(data);

  const ExternalTypedData& int8_array =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataInt8ArrayCid, data, data_length));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());

  const ExternalTypedData& uint8_array =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ArrayCid, data, data_length));
  EXPECT(!uint8_array.IsNull());
  EXPECT_EQ(data_length, uint8_array.Length());

  const ExternalTypedData& uint8_clamped_array =
      ExternalTypedData::Handle(ExternalTypedData::New(
          kExternalTypedDataUint8ClampedArrayCid, data, data_length));
  EXPECT(!uint8_clamped_array.IsNull());
  EXPECT_EQ(data_length, uint8_clamped_array.Length());

  EXPECT_EQ(-3, int8_array.GetInt8(0));
  EXPECT_EQ(253, uint8_array.GetUint8(0));
  EXPECT_EQ(253, uint8_clamped_array.GetUint8(0));

  EXPECT_EQ(-2, int8_array.GetInt8(1));
  EXPECT_EQ(254, uint8_array.GetUint8(1));
  EXPECT_EQ(254, uint8_clamped_array.GetUint8(1));

  EXPECT_EQ(-1, int8_array.GetInt8(2));
  EXPECT_EQ(255, uint8_array.GetUint8(2));
  EXPECT_EQ(255, uint8_clamped_array.GetUint8(2));

  EXPECT_EQ(0, int8_array.GetInt8(3));
  EXPECT_EQ(0, uint8_array.GetUint8(3));
  EXPECT_EQ(0, uint8_clamped_array.GetUint8(3));

  EXPECT_EQ(1, int8_array.GetInt8(4));
  EXPECT_EQ(1, uint8_array.GetUint8(4));
  EXPECT_EQ(1, uint8_clamped_array.GetUint8(4));

  EXPECT_EQ(2, int8_array.GetInt8(5));
  EXPECT_EQ(2, uint8_array.GetUint8(5));
  EXPECT_EQ(2, uint8_clamped_array.GetUint8(5));

  for (intptr_t i = 0; i < int8_array.Length(); ++i) {
    EXPECT_EQ(int8_array.GetUint8(i), uint8_array.GetUint8(i));
  }

  int8_array.SetInt8(2, -123);
  uint8_array.SetUint8(0, 123);
  for (intptr_t i = 0; i < int8_array.Length(); ++i) {
    EXPECT_EQ(int8_array.GetInt8(i), uint8_array.GetInt8(i));
  }

  uint8_clamped_array.SetUint8(0, 123);
  for (intptr_t i = 0; i < int8_array.Length(); ++i) {
    EXPECT_EQ(int8_array.GetUint8(i), uint8_clamped_array.GetUint8(i));
  }
}

ISOLATE_UNIT_TEST_CASE(Script) {
  {
    const char* url_chars = "builtin:test-case";
    const char* source_chars = "This will not compile.";
    const String& url = String::Handle(String::New(url_chars));
    const String& source = String::Handle(String::New(source_chars));
    const Script& script = Script::Handle(Script::New(url, source));
    EXPECT(!script.IsNull());
    EXPECT(script.IsScript());
    String& str = String::Handle(script.url());
    EXPECT_EQ(17, str.Length());
    EXPECT_EQ('b', str.CharAt(0));
    EXPECT_EQ(':', str.CharAt(7));
    EXPECT_EQ('e', str.CharAt(16));
    str = script.Source();
    EXPECT_EQ(22, str.Length());
    EXPECT_EQ('T', str.CharAt(0));
    EXPECT_EQ('n', str.CharAt(10));
    EXPECT_EQ('.', str.CharAt(21));
  }

  {
    const char* url_chars = "";
    // Single line, no terminators.
    const char* source_chars = "abc";
    const String& url = String::Handle(String::New(url_chars));
    const String& source = String::Handle(String::New(source_chars));
    const Script& script = Script::Handle(Script::New(url, source));
    EXPECT(!script.IsNull());
    EXPECT(script.IsScript());
    auto& str = String::Handle(Z);
    str = script.GetLine(1);
    EXPECT_STREQ("abc", str.ToCString());
    str = script.GetSnippet(1, 1, 1, 2);
    EXPECT_STREQ("a", str.ToCString());
    str = script.GetSnippet(1, 2, 1, 4);
    EXPECT_STREQ("bc", str.ToCString());
    // Lines not in the source should return the empty string.
    str = script.GetLine(-500);
    EXPECT_STREQ("", str.ToCString());
    str = script.GetLine(0);
    EXPECT_STREQ("", str.ToCString());
    str = script.GetLine(2);
    EXPECT_STREQ("", str.ToCString());
    str = script.GetLine(10000);
    EXPECT_STREQ("", str.ToCString());
    // Snippets not contained within the source should be the null string.
    str = script.GetSnippet(-1, 1, 1, 2);
    EXPECT(str.IsNull());
    str = script.GetSnippet(2, 1, 2, 2);
    EXPECT(str.IsNull());
    str = script.GetSnippet(1, 1, 1, 5);
    EXPECT(str.IsNull());
  }

  TransitionVMToNative transition(thread);
  const char* kScript = "main() {}";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, nullptr);
  EXPECT_VALID(result);
}

ISOLATE_UNIT_TEST_CASE(Context) {
  const int kNumVariables = 5;
  const Context& parent_context = Context::Handle(Context::New(0));
  const Context& context = Context::Handle(Context::New(kNumVariables));
  context.set_parent(parent_context);
  EXPECT_EQ(kNumVariables, context.num_variables());
  EXPECT(Context::Handle(context.parent()).ptr() == parent_context.ptr());
  EXPECT_EQ(0, Context::Handle(context.parent()).num_variables());
  EXPECT(Context::Handle(Context::Handle(context.parent()).parent()).IsNull());
  Object& variable = Object::Handle(context.At(0));
  EXPECT(variable.IsNull());
  variable = context.At(kNumVariables - 1);
  EXPECT(variable.IsNull());
  context.SetAt(0, Smi::Handle(Smi::New(2)));
  context.SetAt(2, Smi::Handle(Smi::New(3)));
  Smi& smi = Smi::Handle();
  smi ^= context.At(0);
  EXPECT_EQ(2, smi.Value());
  smi ^= context.At(2);
  EXPECT_EQ(3, smi.Value());
}

ISOLATE_UNIT_TEST_CASE(ContextScope) {
  // We need an active compiler context to manipulate scopes, since local
  // variables and slots can be canonicalized in the compiler state.
  CompilerState compiler_state(Thread::Current(), /*is_aot=*/false,
                               /*is_optimizing=*/false);

  const intptr_t parent_scope_function_level = 0;
  LocalScope* parent_scope =
      new LocalScope(nullptr, parent_scope_function_level, 0);

  const intptr_t local_scope_function_level = 1;
  LocalScope* local_scope =
      new LocalScope(parent_scope, local_scope_function_level, 0);

  const Type& dynamic_type = Type::ZoneHandle(Type::DynamicType());
  const String& ta = Symbols::FunctionTypeArgumentsVar();
  LocalVariable* var_ta = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, ta, dynamic_type);
  parent_scope->AddVariable(var_ta);

  const String& a = String::ZoneHandle(Symbols::New(thread, "a"));
  LocalVariable* var_a = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, a, dynamic_type);
  parent_scope->AddVariable(var_a);

  const String& b = String::ZoneHandle(Symbols::New(thread, "b"));
  LocalVariable* var_b = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, b, dynamic_type);
  local_scope->AddVariable(var_b);

  const String& c = String::ZoneHandle(Symbols::New(thread, "c"));
  LocalVariable* var_c = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, c, dynamic_type);
  parent_scope->AddVariable(var_c);

  bool test_only = false;  // Please, insert alias.
  var_ta = local_scope->LookupVariable(ta, LocalVariable::kNoKernelOffset,
                                       test_only);
  EXPECT(var_ta->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_ta->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(ta, LocalVariable::kNoKernelOffset) ==
         var_ta);  // Alias.

  var_a =
      local_scope->LookupVariable(a, LocalVariable::kNoKernelOffset, test_only);
  EXPECT(var_a->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_a->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(a, LocalVariable::kNoKernelOffset) ==
         var_a);  // Alias.

  var_b =
      local_scope->LookupVariable(b, LocalVariable::kNoKernelOffset, test_only);
  EXPECT(!var_b->is_captured());
  EXPECT_EQ(local_scope_function_level, var_b->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(b, LocalVariable::kNoKernelOffset) ==
         var_b);

  test_only = true;  // Please, do not insert alias.
  var_c =
      local_scope->LookupVariable(c, LocalVariable::kNoKernelOffset, test_only);
  EXPECT(!var_c->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_c->owner()->function_level());
  // c is not in local_scope.
  EXPECT(local_scope->LocalLookupVariable(c, LocalVariable::kNoKernelOffset) ==
         nullptr);

  test_only = false;  // Please, insert alias.
  var_c =
      local_scope->LookupVariable(c, LocalVariable::kNoKernelOffset, test_only);
  EXPECT(var_c->is_captured());

  EXPECT_EQ(4, local_scope->num_variables());         // ta, a, b, c.
  EXPECT_EQ(3, local_scope->NumCapturedVariables());  // ta, a, c.

  const VariableIndex first_parameter_index(0);
  const int num_parameters = 0;
  const VariableIndex first_local_index(-1);
  bool found_captured_vars = false;
  VariableIndex next_index = parent_scope->AllocateVariables(
      Function::null_function(), first_parameter_index, num_parameters,
      first_local_index, nullptr, &found_captured_vars);
  // Variables a, c and var_ta are captured, therefore are not allocated in
  // frame.
  EXPECT_EQ(0, next_index.value() -
                   first_local_index.value());  // Indices in frame < 0.
  const intptr_t parent_scope_context_level = 1;
  EXPECT_EQ(parent_scope_context_level, parent_scope->context_level());
  EXPECT(found_captured_vars);

  const intptr_t local_scope_context_level = 5;
  const ContextScope& context_scope = ContextScope::Handle(
      local_scope->PreserveOuterScope(local_scope_context_level));
  LocalScope* outer_scope = LocalScope::RestoreOuterScope(context_scope);
  EXPECT_EQ(3, outer_scope->num_variables());

  var_ta = outer_scope->LocalLookupVariable(ta, LocalVariable::kNoKernelOffset);
  EXPECT(var_ta->is_captured());
  EXPECT_EQ(0, var_ta->index().value());  // First index.
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_ta->owner()->context_level());  // Adjusted context level.

  var_a = outer_scope->LocalLookupVariable(a, LocalVariable::kNoKernelOffset);
  EXPECT(var_a->is_captured());
  EXPECT_EQ(1, var_a->index().value());  // First index.
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_a->owner()->context_level());  // Adjusted context level.

  // var b was not captured.
  EXPECT(outer_scope->LocalLookupVariable(b, LocalVariable::kNoKernelOffset) ==
         nullptr);

  var_c = outer_scope->LocalLookupVariable(c, LocalVariable::kNoKernelOffset);
  EXPECT(var_c->is_captured());
  EXPECT_EQ(2, var_c->index().value());
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_c->owner()->context_level());  // Adjusted context level.
}

ISOLATE_UNIT_TEST_CASE(Closure) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));
  const Array& functions = Array::Handle(Array::New(1));

  const Context& context = Context::Handle(Context::New(0));
  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New(thread, "foo_papa"));
  FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  parent = Function::New(signature, parent_name,
                         UntaggedFunction::kRegularFunction, false, false,
                         false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, parent);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
    cls.Finalize();
  }

  Function& function = Function::Handle();
  const String& function_name = String::Handle(Symbols::New(thread, "foo"));
  function = Function::NewClosureFunction(function_name, parent,
                                          TokenPosition::kMinSource);
  signature = function.signature();
  signature.set_result_type(Object::dynamic_type());
  signature ^= ClassFinalizer::FinalizeType(signature);
  function.SetSignature(signature);
  const Closure& closure = Closure::Handle(
      Closure::New(Object::null_type_arguments(), Object::null_type_arguments(),
                   function, context));
  const Class& closure_class = Class::Handle(closure.clazz());
  EXPECT_EQ(closure_class.id(), kClosureCid);
  const Function& closure_function = Function::Handle(closure.function());
  EXPECT_EQ(closure_function.ptr(), function.ptr());
  const Context& closure_context = Context::Handle(closure.context());
  EXPECT_EQ(closure_context.ptr(), context.ptr());
}

ISOLATE_UNIT_TEST_CASE(ObjectPrinting) {
  // Simple Smis.
  EXPECT_STREQ("2", Smi::Handle(Smi::New(2)).ToCString());
  EXPECT_STREQ("-15", Smi::Handle(Smi::New(-15)).ToCString());

  // bool class and true/false values.
  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  const Class& bool_class = Class::Handle(object_store->bool_class());
  EXPECT_STREQ("Library:'dart:core' Class: bool", bool_class.ToCString());
  EXPECT_STREQ("true", Bool::True().ToCString());
  EXPECT_STREQ("false", Bool::False().ToCString());

  // Strings.
  EXPECT_STREQ("Sugarbowl",
               String::Handle(String::New("Sugarbowl")).ToCString());
}

ISOLATE_UNIT_TEST_CASE(CheckedHandle) {
  // Ensure that null handles have the correct C++ vtable setup.
  Zone* zone = Thread::Current()->zone();
  const String& str1 = String::Handle(zone);
  EXPECT(str1.IsString());
  EXPECT(str1.IsNull());
  const String& str2 = String::CheckedHandle(zone, Object::null());
  EXPECT(str2.IsString());
  EXPECT(str2.IsNull());
  String& str3 = String::Handle(zone);
  str3 ^= Object::null();
  EXPECT(str3.IsString());
  EXPECT(str3.IsNull());
  EXPECT(!str3.IsOneByteString());
  str3 = String::New("Steep and Deep!");
  EXPECT(str3.IsString());
  EXPECT(str3.IsOneByteString());
  str3 = OneByteString::null();
  EXPECT(str3.IsString());
  EXPECT(!str3.IsOneByteString());
}

static LibraryPtr CreateDummyLibrary(const String& library_name) {
  return Library::New(library_name);
}

static FunctionPtr CreateFunction(const char* name) {
  Thread* thread = Thread::Current();
  const String& class_name = String::Handle(Symbols::New(thread, "ownerClass"));
  const String& lib_name = String::Handle(Symbols::New(thread, "ownerLibrary"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(CreateDummyClass(class_name, script));
  const Library& owner_library = Library::Handle(CreateDummyLibrary(lib_name));
  owner_class.set_library(owner_library);
  const String& function_name = String::ZoneHandle(Symbols::New(thread, name));
  const FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  return Function::New(signature, function_name,
                       UntaggedFunction::kRegularFunction, true, false, false,
                       false, false, owner_class, TokenPosition::kMinSource);
}

// Test for Code and Instruction object creation.
ISOLATE_UNIT_TEST_CASE(Code) {
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.ptr(), Instructions::FromPayloadStart(payload_start));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT_EQ(1, Smi::Cast(result).Value());
}

// Test for immutability of generated instructions. The test crashes with a
// segmentation fault when writing into it.
ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(CodeImmutability, "Crash") {
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.ptr(), Instructions::FromPayloadStart(payload_start));
  // Try writing into the generated code, expected to crash.
  *(reinterpret_cast<char*>(payload_start) + 1) = 1;
  if (!FLAG_write_protect_code) {
    // Since this test is expected to crash, crash if write protection of code
    // is switched off.
    FATAL("Test requires --write-protect-code; skip by forcing expected crash");
  }
}

class CodeTestHelper {
 public:
  static void SetInstructions(const Code& code,
                              const Instructions& instructions,
                              uword unchecked_offset) {
    code.SetActiveInstructions(instructions, unchecked_offset);
    code.set_instructions(instructions);
  }
};

// Test for executability of generated instructions. The test crashes with a
// segmentation fault when executing the writeable view.
ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(CodeExecutability, "Crash") {
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = code.PayloadStart();
  const uword unchecked_offset = code.UncheckedEntryPoint() - code.EntryPoint();
  EXPECT_EQ(instructions.ptr(), Instructions::FromPayloadStart(payload_start));
  // Execute the executable view of the instructions (default).
  Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT_EQ(1, Smi::Cast(result).Value());
  // Switch to the writeable but non-executable view of the instructions.
  instructions ^= Page::ToWritable(instructions.ptr());
  payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.ptr(), Instructions::FromPayloadStart(payload_start));
  // Hook up Code and Instructions objects.
  CodeTestHelper::SetInstructions(code, instructions, unchecked_offset);
  function.AttachCode(code);
  // Try executing the generated code, expected to crash.
  result = DartEntry::InvokeFunction(function, Array::empty_array());
  EXPECT_EQ(1, Smi::Cast(result).Value());
  if (!FLAG_dual_map_code) {
    // Since this test is expected to crash, crash if dual mapping of code
    // is switched off.
    FATAL("Test requires --dual-map-code; skip by forcing expected crash");
  }
}

// Test for Embedded String object in the instructions.
ISOLATE_UNIT_TEST_CASE(EmbedStringInCode) {
  extern void GenerateEmbedStringInCode(compiler::Assembler * assembler,
                                        const char* str);
  const char* kHello = "Hello World!";
  word expected_length = static_cast<word>(strlen(kHello));
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateEmbedStringInCode(&_assembler_, kHello);
  const Function& function =
      Function::Handle(CreateFunction("Test_EmbedStringInCode"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(result.ptr()->IsHeapObject());
  String& string_object = String::Handle();
  string_object ^= result.ptr();
  EXPECT(string_object.Length() == expected_length);
  for (int i = 0; i < expected_length; i++) {
    EXPECT(string_object.CharAt(i) == kHello[i]);
  }
}

// Test for Embedded Smi object in the instructions.
ISOLATE_UNIT_TEST_CASE(EmbedSmiInCode) {
  extern void GenerateEmbedSmiInCode(compiler::Assembler * assembler,
                                     intptr_t value);
  const intptr_t kSmiTestValue = 5;
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateEmbedSmiInCode(&_assembler_, kSmiTestValue);
  const Function& function =
      Function::Handle(CreateFunction("Test_EmbedSmiInCode"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(Smi::Cast(result).Value() == kSmiTestValue);
}

#if defined(ARCH_IS_64_BIT) && !defined(DART_COMPRESSED_POINTERS)
// Test for Embedded Smi object in the instructions.
ISOLATE_UNIT_TEST_CASE(EmbedSmiIn64BitCode) {
  extern void GenerateEmbedSmiInCode(compiler::Assembler * assembler,
                                     intptr_t value);
  const intptr_t kSmiTestValue = DART_INT64_C(5) << 32;
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateEmbedSmiInCode(&_assembler_, kSmiTestValue);
  const Function& function =
      Function::Handle(CreateFunction("Test_EmbedSmiIn64BitCode"));
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(Smi::Cast(result).Value() == kSmiTestValue);
}
#endif  // ARCH_IS_64_BIT && !DART_COMPRESSED_POINTERS

ISOLATE_UNIT_TEST_CASE(ExceptionHandlers) {
  const int kNumEntries = 4;
  // Add an exception handler table to the code.
  ExceptionHandlers& exception_handlers = ExceptionHandlers::Handle();
  exception_handlers ^= ExceptionHandlers::New(kNumEntries);
  const bool kNeedsStackTrace = true;
  const bool kNoStackTrace = false;
  exception_handlers.SetHandlerInfo(0, -1, 20u, kNeedsStackTrace, false, true);
  exception_handlers.SetHandlerInfo(1, 0, 30u, kNeedsStackTrace, false, true);
  exception_handlers.SetHandlerInfo(2, -1, 40u, kNoStackTrace, true, true);
  exception_handlers.SetHandlerInfo(3, 1, 150u, kNoStackTrace, true, true);

  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      Function::Handle(CreateFunction("Test_Code")), nullptr, &_assembler_,
      Code::PoolAttachment::kAttachPool));
  code.set_exception_handlers(exception_handlers);

  // Verify the exception handler table entries by accessing them.
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(code.exception_handlers());
  EXPECT_EQ(kNumEntries, handlers.num_entries());
  ExceptionHandlerInfo info;
  handlers.GetHandlerInfo(0, &info);
  EXPECT_EQ(-1, handlers.OuterTryIndex(0));
  EXPECT_EQ(-1, info.outer_try_index);
  EXPECT_EQ(20u, handlers.HandlerPCOffset(0));
  EXPECT(handlers.NeedsStackTrace(0));
  EXPECT(!handlers.HasCatchAll(0));
  EXPECT_EQ(20u, info.handler_pc_offset);
  EXPECT_EQ(1, handlers.OuterTryIndex(3));
  EXPECT_EQ(150u, handlers.HandlerPCOffset(3));
  EXPECT(!handlers.NeedsStackTrace(3));
  EXPECT(handlers.HasCatchAll(3));
}

ISOLATE_UNIT_TEST_CASE(PcDescriptors) {
  DescriptorList* builder = new DescriptorList(thread->zone());

  // kind, pc_offset, deopt_id, token_pos, try_index, yield_index
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 10, 1,
                         TokenPosition::Deserialize(20), 1, 1);
  builder->AddDescriptor(UntaggedPcDescriptors::kDeopt, 20, 2,
                         TokenPosition::Deserialize(30), 0, -1);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 30, 3,
                         TokenPosition::Deserialize(40), 1, 10);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 10, 4,
                         TokenPosition::Deserialize(40), 2, 20);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 10, 5,
                         TokenPosition::Deserialize(80), 3, 30);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 80, 6,
                         TokenPosition::Deserialize(150), 3, 30);

  PcDescriptors& descriptors = PcDescriptors::Handle();
  descriptors ^= builder->FinalizePcDescriptors(0);

  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      Function::Handle(CreateFunction("Test_Code")), nullptr, &_assembler_,
      Code::PoolAttachment::kAttachPool));
  code.set_pc_descriptors(descriptors);

  // Verify the PcDescriptor entries by accessing them.
  const PcDescriptors& pc_descs = PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(pc_descs, UntaggedPcDescriptors::kAnyKind);

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(1, iter.YieldIndex());
  EXPECT_EQ(20, iter.TokenPos().Pos());
  EXPECT_EQ(1, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(10), iter.PcOffset());
  EXPECT_EQ(1, iter.DeoptId());
  EXPECT_EQ(UntaggedPcDescriptors::kOther, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(-1, iter.YieldIndex());
  EXPECT_EQ(30, iter.TokenPos().Pos());
  EXPECT_EQ(UntaggedPcDescriptors::kDeopt, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(10, iter.YieldIndex());
  EXPECT_EQ(40, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(20, iter.YieldIndex());
  EXPECT_EQ(40, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(30, iter.YieldIndex());
  EXPECT_EQ(80, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(30, iter.YieldIndex());
  EXPECT_EQ(150, iter.TokenPos().Pos());

  EXPECT_EQ(3, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(80), iter.PcOffset());
  EXPECT_EQ(150, iter.TokenPos().Pos());
  EXPECT_EQ(UntaggedPcDescriptors::kOther, iter.Kind());

  EXPECT_EQ(false, iter.MoveNext());
}

ISOLATE_UNIT_TEST_CASE(PcDescriptorsLargeDeltas) {
  DescriptorList* builder = new DescriptorList(thread->zone());

  // kind, pc_offset, deopt_id, token_pos, try_index
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 100, 1,
                         TokenPosition::Deserialize(200), 1, 10);
  builder->AddDescriptor(UntaggedPcDescriptors::kDeopt, 200, 2,
                         TokenPosition::Deserialize(300), 0, -1);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 300, 3,
                         TokenPosition::Deserialize(400), 1, 10);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 100, 4,
                         TokenPosition::Deserialize(0), 2, 20);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 100, 5,
                         TokenPosition::Deserialize(800), 3, 30);
  builder->AddDescriptor(UntaggedPcDescriptors::kOther, 800, 6,
                         TokenPosition::Deserialize(150), 3, 30);

  PcDescriptors& descriptors = PcDescriptors::Handle();
  descriptors ^= builder->FinalizePcDescriptors(0);

  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      Function::Handle(CreateFunction("Test_Code")), nullptr, &_assembler_,
      Code::PoolAttachment::kAttachPool));
  code.set_pc_descriptors(descriptors);

  // Verify the PcDescriptor entries by accessing them.
  const PcDescriptors& pc_descs = PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(pc_descs, UntaggedPcDescriptors::kAnyKind);

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(10, iter.YieldIndex());
  EXPECT_EQ(200, iter.TokenPos().Pos());
  EXPECT_EQ(1, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(100), iter.PcOffset());
  EXPECT_EQ(1, iter.DeoptId());
  EXPECT_EQ(UntaggedPcDescriptors::kOther, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(-1, iter.YieldIndex());
  EXPECT_EQ(300, iter.TokenPos().Pos());
  EXPECT_EQ(UntaggedPcDescriptors::kDeopt, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(10, iter.YieldIndex());
  EXPECT_EQ(400, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(20, iter.YieldIndex());
  EXPECT_EQ(0, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(30, iter.YieldIndex());
  EXPECT_EQ(800, iter.TokenPos().Pos());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(30, iter.YieldIndex());
  EXPECT_EQ(150, iter.TokenPos().Pos());

  EXPECT_EQ(3, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(800), iter.PcOffset());
  EXPECT_EQ(150, iter.TokenPos().Pos());
  EXPECT_EQ(UntaggedPcDescriptors::kOther, iter.Kind());

  EXPECT_EQ(false, iter.MoveNext());
}

static ClassPtr CreateTestClass(const char* name) {
  const String& class_name =
      String::Handle(Symbols::New(Thread::Current(), name));
  const Class& cls =
      Class::Handle(CreateDummyClass(class_name, Script::Handle()));
  return cls.ptr();
}

static FieldPtr CreateTestField(const char* name) {
  auto thread = Thread::Current();
  const Class& cls = Class::Handle(CreateTestClass("global:"));
  const String& field_name = String::Handle(Symbols::New(thread, name));
  const Field& field = Field::Handle(Field::New(
      field_name, true, false, false, true, false, cls, Object::dynamic_type(),
      TokenPosition::kMinSource, TokenPosition::kMinSource));
  {
    SafepointWriteRwLocker locker(thread,
                                  thread->isolate_group()->program_lock());
    thread->isolate_group()->RegisterStaticField(field, Object::sentinel());
  }
  return field.ptr();
}

ISOLATE_UNIT_TEST_CASE(ClassDictionaryIterator) {
  Class& ae66 = Class::ZoneHandle(CreateTestClass("Ae6/6"));
  Class& re44 = Class::ZoneHandle(CreateTestClass("Re4/4"));
  Field& ce68 = Field::ZoneHandle(CreateTestField("Ce6/8"));
  Field& tee = Field::ZoneHandle(CreateTestField("TEE"));
  String& url = String::ZoneHandle(String::New("SBB"));
  Library& lib = Library::Handle(Library::New(url));
  lib.AddClass(ae66);
  lib.AddObject(ce68, String::ZoneHandle(ce68.name()));
  lib.AddClass(re44);
  lib.AddObject(tee, String::ZoneHandle(tee.name()));
  ClassDictionaryIterator iterator(lib);
  int count = 0;
  Class& cls = Class::Handle();
  while (iterator.HasNext()) {
    cls = iterator.GetNextClass();
    EXPECT((cls.ptr() == ae66.ptr()) || (cls.ptr() == re44.ptr()));
    count++;
  }
  EXPECT(count == 2);
}

static FunctionPtr GetDummyTarget(const char* name) {
  const String& function_name =
      String::Handle(Symbols::New(Thread::Current(), name));
  const Class& cls =
      Class::Handle(CreateDummyClass(function_name, Script::Handle()));
  const bool is_static = false;
  const bool is_const = false;
  const bool is_abstract = false;
  const bool is_external = false;
  const bool is_native = false;
  const FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  return Function::New(signature, function_name,
                       UntaggedFunction::kRegularFunction, is_static, is_const,
                       is_abstract, is_external, is_native, cls,
                       TokenPosition::kMinSource);
}

ISOLATE_UNIT_TEST_CASE(ICData) {
  Function& function = Function::Handle(GetDummyTarget("Bern"));
  const intptr_t id = 12;
  const intptr_t num_args_tested = 1;
  const String& target_name = String::Handle(Symbols::New(thread, "Thun"));
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 1;
  const Array& args_descriptor = Array::Handle(ArgumentsDescriptor::NewBoxed(
      kTypeArgsLen, kNumArgs, Object::null_array()));
  ICData& o1 = ICData::Handle();
  o1 = ICData::New(function, target_name, args_descriptor, id, num_args_tested,
                   ICData::kInstance);
  EXPECT_EQ(1, o1.NumArgsTested());
  EXPECT_EQ(id, o1.deopt_id());
  EXPECT_EQ(function.ptr(), o1.Owner());
  EXPECT_EQ(0, o1.NumberOfChecks());
  EXPECT_EQ(target_name.ptr(), o1.target_name());
  EXPECT_EQ(args_descriptor.ptr(), o1.arguments_descriptor());

  const Function& target1 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kSmiCid, target1);
  EXPECT_EQ(1, o1.NumberOfChecks());
  EXPECT_EQ(1, o1.NumberOfUsedChecks());
  intptr_t test_class_id = -1;
  Function& test_target = Function::Handle();
  o1.GetOneClassCheckAt(0, &test_class_id, &test_target);
  EXPECT_EQ(kSmiCid, test_class_id);
  EXPECT_EQ(target1.ptr(), test_target.ptr());
  EXPECT_EQ(kSmiCid, o1.GetCidAt(0));
  GrowableArray<intptr_t> test_class_ids;
  o1.GetCheckAt(0, &test_class_ids, &test_target);
  EXPECT_EQ(1, test_class_ids.length());
  EXPECT_EQ(kSmiCid, test_class_ids[0]);
  EXPECT_EQ(target1.ptr(), test_target.ptr());

  const Function& target2 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kDoubleCid, target2);
  EXPECT_EQ(2, o1.NumberOfChecks());
  EXPECT_EQ(2, o1.NumberOfUsedChecks());
  o1.GetOneClassCheckAt(1, &test_class_id, &test_target);
  EXPECT_EQ(kDoubleCid, test_class_id);
  EXPECT_EQ(target2.ptr(), test_target.ptr());
  EXPECT_EQ(kDoubleCid, o1.GetCidAt(1));

  o1.AddReceiverCheck(kMintCid, target2);
  EXPECT_EQ(3, o1.NumberOfUsedChecks());
  o1.SetCountAt(o1.NumberOfChecks() - 1, 0);
  EXPECT_EQ(2, o1.NumberOfUsedChecks());

  ICData& o2 = ICData::Handle();
  o2 = ICData::New(function, target_name, args_descriptor, 57, 2,
                   ICData::kInstance);
  EXPECT_EQ(2, o2.NumArgsTested());
  EXPECT_EQ(57, o2.deopt_id());
  EXPECT_EQ(function.ptr(), o2.Owner());
  EXPECT_EQ(0, o2.NumberOfChecks());
  GrowableArray<intptr_t> classes;
  classes.Add(kSmiCid);
  classes.Add(kSmiCid);
  o2.AddCheck(classes, target1);
  EXPECT_EQ(1, o2.NumberOfChecks());
  o2.GetCheckAt(0, &test_class_ids, &test_target);
  EXPECT_EQ(2, test_class_ids.length());
  EXPECT_EQ(kSmiCid, test_class_ids[0]);
  EXPECT_EQ(kSmiCid, test_class_ids[1]);
  EXPECT_EQ(target1.ptr(), test_target.ptr());

  // Check ICData for unoptimized static calls.
  const intptr_t kNumArgsChecked = 0;
  const ICData& scall_icdata = ICData::Handle(
      ICData::NewForStaticCall(function, target1, args_descriptor, 57,
                               kNumArgsChecked, ICData::kInstance));
  EXPECT_EQ(target1.ptr(), scall_icdata.GetTargetAt(0));
}

ISOLATE_UNIT_TEST_CASE(SubtypeTestCache) {
  SafepointMutexLocker ml(thread->isolate_group()->subtype_test_cache_mutex());

  String& class1_name = String::Handle(Symbols::New(thread, "EmptyClass1"));
  Script& script = Script::Handle();
  const Class& empty_class1 =
      Class::Handle(CreateDummyClass(class1_name, script));
  String& class2_name = String::Handle(Symbols::New(thread, "EmptyClass2"));
  const Class& empty_class2 =
      Class::Handle(CreateDummyClass(class2_name, script));
  SubtypeTestCache& cache = SubtypeTestCache::Handle(SubtypeTestCache::New());
  EXPECT(!cache.IsNull());
  EXPECT_EQ(0, cache.NumberOfChecks());
  const Object& class_id_or_fun = Object::Handle(Smi::New(empty_class1.id()));
  const AbstractType& dest_type =
      AbstractType::Handle(Type::NewNonParameterizedType(empty_class2));
  const TypeArguments& targ_0 = TypeArguments::Handle(TypeArguments::New(2));
  const TypeArguments& targ_1 = TypeArguments::Handle(TypeArguments::New(3));
  const TypeArguments& targ_2 = TypeArguments::Handle(TypeArguments::New(4));
  const TypeArguments& targ_3 = TypeArguments::Handle(TypeArguments::New(5));
  const TypeArguments& targ_4 = TypeArguments::Handle(TypeArguments::New(6));
  cache.AddCheck(class_id_or_fun, dest_type, targ_0, targ_1, targ_2, targ_3,
                 targ_4, Bool::True());
  EXPECT_EQ(1, cache.NumberOfChecks());
  Object& test_class_id_or_fun = Object::Handle();
  AbstractType& test_dest_type = AbstractType::Handle();
  TypeArguments& test_targ_0 = TypeArguments::Handle();
  TypeArguments& test_targ_1 = TypeArguments::Handle();
  TypeArguments& test_targ_2 = TypeArguments::Handle();
  TypeArguments& test_targ_3 = TypeArguments::Handle();
  TypeArguments& test_targ_4 = TypeArguments::Handle();
  Bool& test_result = Bool::Handle();
  cache.GetCheck(0, &test_class_id_or_fun, &test_dest_type, &test_targ_0,
                 &test_targ_1, &test_targ_2, &test_targ_3, &test_targ_4,
                 &test_result);
  EXPECT_EQ(class_id_or_fun.ptr(), test_class_id_or_fun.ptr());
  EXPECT_EQ(dest_type.ptr(), test_dest_type.ptr());
  EXPECT_EQ(targ_0.ptr(), test_targ_0.ptr());
  EXPECT_EQ(targ_1.ptr(), test_targ_1.ptr());
  EXPECT_EQ(targ_2.ptr(), test_targ_2.ptr());
  EXPECT_EQ(targ_3.ptr(), test_targ_3.ptr());
  EXPECT_EQ(targ_4.ptr(), test_targ_4.ptr());
  EXPECT_EQ(Bool::True().ptr(), test_result.ptr());
}

ISOLATE_UNIT_TEST_CASE(MegamorphicCache) {
  const auto& name = String::Handle(Symbols::New(thread, "name"));
  const auto& args_descriptor =
      Array::Handle(ArgumentsDescriptor::NewBoxed(1, 1, Object::null_array()));

  const auto& cidA = Smi::Handle(Smi::New(1));
  const auto& cidB = Smi::Handle(Smi::New(2));

  const auto& valueA = Smi::Handle(Smi::New(42));
  const auto& valueB = Smi::Handle(Smi::New(43));

  // Test normal insert/lookup methods.
  {
    const auto& cache =
        MegamorphicCache::Handle(MegamorphicCache::New(name, args_descriptor));

    EXPECT(cache.Lookup(cidA) == Object::null());
    cache.EnsureContains(cidA, valueA);
    EXPECT(cache.Lookup(cidA) == valueA.ptr());

    EXPECT(cache.Lookup(cidB) == Object::null());
    cache.EnsureContains(cidB, valueB);
    EXPECT(cache.Lookup(cidB) == valueB.ptr());
  }

  // Try to insert many keys to hit collisions & growth.
  {
    const auto& cache =
        MegamorphicCache::Handle(MegamorphicCache::New(name, args_descriptor));

    auto& cid = Smi::Handle();
    auto& value = Object::Handle();
    for (intptr_t i = 0; i < 100; ++i) {
      cid = Smi::New(100 * i);
      if (cid.Value() == kIllegalCid) continue;

      value = Smi::New(i);
      cache.EnsureContains(cid, value);
    }
    auto& expected = Object::Handle();
    for (intptr_t i = 0; i < 100; ++i) {
      cid = Smi::New(100 * i);
      if (cid.Value() == kIllegalCid) continue;

      expected = Smi::New(i);
      value = cache.Lookup(cid);
      EXPECT(Smi::Cast(value).Equals(Smi::Cast(expected)));
    }
  }
}

ISOLATE_UNIT_TEST_CASE(FieldTests) {
  const String& f = String::Handle(String::New("oneField"));
  const String& getter_f = String::Handle(Field::GetterName(f));
  const String& setter_f = String::Handle(Field::SetterName(f));
  EXPECT(!Field::IsGetterName(f));
  EXPECT(!Field::IsSetterName(f));
  EXPECT(Field::IsGetterName(getter_f));
  EXPECT(!Field::IsSetterName(getter_f));
  EXPECT(!Field::IsGetterName(setter_f));
  EXPECT(Field::IsSetterName(setter_f));
  EXPECT_STREQ(f.ToCString(),
               String::Handle(Field::NameFromGetter(getter_f)).ToCString());
  EXPECT_STREQ(f.ToCString(),
               String::Handle(Field::NameFromSetter(setter_f)).ToCString());
}

// Expose helper function from object.cc for testing.
bool EqualsIgnoringPrivate(const String& name, const String& private_name);

ISOLATE_UNIT_TEST_CASE(EqualsIgnoringPrivate) {
  String& mangled_name = String::Handle();
  String& bare_name = String::Handle();

  // Simple matches.
  mangled_name = OneByteString::New("foo");
  bare_name = OneByteString::New("foo");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.");
  bare_name = OneByteString::New("foo.");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.named");
  bare_name = OneByteString::New("foo.named");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Simple mismatches.
  mangled_name = OneByteString::New("bar");
  bare_name = OneByteString::New("foo");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.");
  bare_name = OneByteString::New("foo");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo");
  bare_name = OneByteString::New("foo.");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.name");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.named");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private match.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("foo");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mismatch.
  mangled_name = OneByteString::New("food@12345");
  bare_name = OneByteString::New("foo");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mismatch 2.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("food");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mixin application match.
  mangled_name = OneByteString::New("_M1@12345&_M2@12345&_M3@12345");
  bare_name = OneByteString::New("_M1&_M2&_M3");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mixin application mismatch.
  mangled_name = OneByteString::New("_M1@12345&_M2@12345&_M3@12345");
  bare_name = OneByteString::New("_M1&_M2&_M4");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor match.
  mangled_name = OneByteString::New("foo@12345.");
  bare_name = OneByteString::New("foo.");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.");
  bare_name = OneByteString::New("foo");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor mismatch 2.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("foo.");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor match.
  mangled_name = OneByteString::New("foo@12345.named");
  bare_name = OneByteString::New("foo.named");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.name");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor mismatch 2.
  mangled_name = OneByteString::New("foo@12345.named");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor match.  Yes, this happens.
  mangled_name = OneByteString::New("foo@12345.named@12345");
  bare_name = OneByteString::New("foo.named");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor match where the caller knows the private
  // key.  Yes, this also happens.
  mangled_name = OneByteString::New("foo@12345.named@12345");
  bare_name = OneByteString::New("foo@12345.named");
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.name@12345");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.named@12345");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  const char* ext_mangled_str = "foo@12345.name@12345";
  const char* ext_bare_str = "foo.name";
  const char* ext_bad_bare_str = "foo.named";
  String& ext_mangled_name = String::Handle();
  String& ext_bare_name = String::Handle();
  String& ext_bad_bare_name = String::Handle();

  mangled_name = OneByteString::New("foo@12345.name@12345");
  ext_mangled_name = ExternalOneByteString::New(
      reinterpret_cast<const uint8_t*>(ext_mangled_str),
      strlen(ext_mangled_str), nullptr, 0, NoopFinalizer, Heap::kNew);
  EXPECT(ext_mangled_name.IsExternalOneByteString());
  ext_bare_name = ExternalOneByteString::New(
      reinterpret_cast<const uint8_t*>(ext_bare_str), strlen(ext_bare_str),
      nullptr, 0, NoopFinalizer, Heap::kNew);
  EXPECT(ext_bare_name.IsExternalOneByteString());
  ext_bad_bare_name = ExternalOneByteString::New(
      reinterpret_cast<const uint8_t*>(ext_bad_bare_str),
      strlen(ext_bad_bare_str), nullptr, 0, NoopFinalizer, Heap::kNew);
  EXPECT(ext_bad_bare_name.IsExternalOneByteString());

  // str1 - OneByteString, str2 - ExternalOneByteString.
  EXPECT(String::EqualsIgnoringPrivateKey(mangled_name, ext_bare_name));
  EXPECT(!String::EqualsIgnoringPrivateKey(mangled_name, ext_bad_bare_name));

  // str1 - ExternalOneByteString, str2 - OneByteString.
  EXPECT(String::EqualsIgnoringPrivateKey(ext_mangled_name, bare_name));

  // str1 - ExternalOneByteString, str2 - ExternalOneByteString.
  EXPECT(String::EqualsIgnoringPrivateKey(ext_mangled_name, ext_bare_name));
  EXPECT(
      !String::EqualsIgnoringPrivateKey(ext_mangled_name, ext_bad_bare_name));
}

ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(ArrayNew_Overflow_Crash, "Crash") {
  Array::Handle(Array::New(Array::kMaxElements + 1));
}

TEST_CASE(StackTraceFormat) {
  const char* kScriptChars =
      "void baz() {\n"
      "  throw 'MyException';\n"
      "}\n"
      "\n"
      "class _OtherClass {\n"
      "  _OtherClass._named() {\n"
      "    baz();\n"
      "  }\n"
      "}\n"
      "\n"
      "set globalVar(var value) {\n"
      "  new _OtherClass._named();\n"
      "}\n"
      "\n"
      "void _bar() {\n"
      "  globalVar = null;\n"
      "}\n"
      "\n"
      "class MyClass {\n"
      "  MyClass() {\n"
      "    (() => foo())();\n"
      "  }\n"
      "\n"
      "  static get field {\n"
      "    _bar();\n"
      "  }\n"
      "\n"
      "  static foo() {\n"
      "    fooHelper() {\n"
      "      field;\n"
      "    }\n"
      "    fooHelper();\n"
      "  }\n"
      "}\n"
      "\n"
      "main() {\n"
      "  (() => new MyClass())();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);

  const char* lib_url = "file:///test-lib";
  const size_t kBufferSize = 1024;
  char expected[kBufferSize];
  snprintf(expected, kBufferSize,
           "Unhandled exception:\n"
           "MyException\n"
           "#0      baz (%1$s:2:3)\n"
           "#1      new _OtherClass._named (%1$s:7:5)\n"
           "#2      globalVar= (%1$s:12:7)\n"
           "#3      _bar (%1$s:16:3)\n"
           "#4      MyClass.field (%1$s:25:5)\n"
           "#5      MyClass.foo.fooHelper (%1$s:30:7)\n"
           "#6      MyClass.foo (%1$s:32:5)\n"
           "#7      new MyClass.<anonymous closure> (%1$s:21:12)\n"
           "#8      new MyClass (%1$s:21:18)\n"
           "#9      main.<anonymous closure> (%1$s:37:14)\n"
           "#10     main (%1$s:37:24)",
           lib_url);

  EXPECT_ERROR(result, expected);
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveCrossGen) {
  WeakProperty& weak = WeakProperty::Handle();
  {
    // Weak property and value in new. Key in old.
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key", Heap::kOld);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kNew);
    weak ^= WeakProperty::New(Heap::kNew);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectNewSpace();
  GCTestHelper::CollectOldSpace();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key in new.
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key", Heap::kNew);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectNewSpace();
  GCTestHelper::CollectOldSpace();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in new. Key is a Smi.
    HANDLESCOPE(thread);
    Integer& key = Integer::Handle();
    key ^= Integer::New(31);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kNew);
    weak ^= WeakProperty::New(Heap::kNew);
    weak.set_key(key);
    weak.set_value(value);
    key ^= Integer::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectAllGarbage();
  // Weak property key and value should survive due implicit liveness of
  // non-heap objects.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key is a Smi.
    HANDLESCOPE(thread);
    Integer& key = Integer::Handle();
    key ^= Integer::New(32);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectAllGarbage();
  // Weak property key and value should survive due implicit liveness of
  // non-heap objects.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in new. Key in VM isolate.
    HANDLESCOPE(thread);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kNew);
    weak ^= WeakProperty::New(Heap::kNew);
    weak.set_key(Symbols::Dot());
    weak.set_value(value);
    String& key = String::Handle();
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectNewSpace();
  GCTestHelper::CollectOldSpace();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key in VM isolate.
    HANDLESCOPE(thread);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(Symbols::Dot());
    weak.set_value(value);
    String& key = String::Handle();
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectNewSpace();
  GCTestHelper::CollectOldSpace();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveRecurse) {
  // This used to end in an infinite recursion. Caused by scavenging the weak
  // property before scavenging the key.
  WeakProperty& weak = WeakProperty::Handle();
  Array& arr = Array::Handle(Array::New(1));
  {
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key");
    arr.SetAt(0, key);
    String& value = String::Handle();
    value ^= OneByteString::New("value");
    weak ^= WeakProperty::New();
    weak.set_key(key);
    weak.set_value(value);
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveOne_NewSpace) {
  WeakProperty& weak = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key");
  {
    HANDLESCOPE(thread);
    String& value = String::Handle();
    value ^= OneByteString::New("value");
    weak ^= WeakProperty::New();
    weak.set_key(key);
    weak.set_value(value);
  }
  GCTestHelper::CollectNewSpace();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveTwo_NewSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  String& key1 = String::Handle();
  key1 ^= OneByteString::New("key1");
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key2 = String::Handle();
  key2 ^= OneByteString::New("key2");
  {
    HANDLESCOPE(thread);
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1");
    weak1 ^= WeakProperty::New();
    weak1.set_key(key1);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2");
    weak2 ^= WeakProperty::New();
    weak2.set_key(key2);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectNewSpace();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveTwoShared_NewSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key");
  {
    HANDLESCOPE(thread);
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1");
    weak1 ^= WeakProperty::New();
    weak1.set_key(key);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2");
    weak2 ^= WeakProperty::New();
    weak2.set_key(key);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectNewSpace();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveOne_OldSpace) {
  WeakProperty& weak = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key", Heap::kOld);
  {
    HANDLESCOPE(thread);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveTwo_OldSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  String& key1 = String::Handle();
  key1 ^= OneByteString::New("key1", Heap::kOld);
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key2 = String::Handle();
  key2 ^= OneByteString::New("key2", Heap::kOld);
  {
    HANDLESCOPE(thread);
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1", Heap::kOld);
    weak1 ^= WeakProperty::New(Heap::kOld);
    weak1.set_key(key1);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2", Heap::kOld);
    weak2 ^= WeakProperty::New(Heap::kOld);
    weak2.set_key(key2);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_PreserveTwoShared_OldSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key", Heap::kOld);
  {
    HANDLESCOPE(thread);
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1", Heap::kOld);
    weak1 ^= WeakProperty::New(Heap::kOld);
    weak1.set_key(key);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2", Heap::kOld);
    weak2 ^= WeakProperty::New(Heap::kOld);
    weak2.set_key(key);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_ClearOne_NewSpace) {
  WeakProperty& weak = WeakProperty::Handle();
  {
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key");
    String& value = String::Handle();
    value ^= OneByteString::New("value");
    weak ^= WeakProperty::New();
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectNewSpace();
  EXPECT(weak.key() == Object::null());
  EXPECT(weak.value() == Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_ClearTwoShared_NewSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  {
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key");
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1");
    weak1 ^= WeakProperty::New();
    weak1.set_key(key);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2");
    weak2 ^= WeakProperty::New();
    weak2.set_key(key);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectNewSpace();
  EXPECT(weak1.key() == Object::null());
  EXPECT(weak1.value() == Object::null());
  EXPECT(weak2.key() == Object::null());
  EXPECT(weak2.value() == Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_ClearOne_OldSpace) {
  WeakProperty& weak = WeakProperty::Handle();
  {
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key", Heap::kOld);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak.key() == Object::null());
  EXPECT(weak.value() == Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakProperty_ClearTwoShared_OldSpace) {
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  {
    HANDLESCOPE(thread);
    String& key = String::Handle();
    key ^= OneByteString::New("key", Heap::kOld);
    String& value1 = String::Handle();
    value1 ^= OneByteString::New("value1");
    weak1 ^= WeakProperty::New(Heap::kOld);
    weak1.set_key(key);
    weak1.set_value(value1);
    String& value2 = String::Handle();
    value2 ^= OneByteString::New("value2", Heap::kOld);
    weak2 ^= WeakProperty::New(Heap::kOld);
    weak2.set_key(key);
    weak2.set_value(value2);
  }
  GCTestHelper::CollectAllGarbage();
  EXPECT(weak1.key() == Object::null());
  EXPECT(weak1.value() == Object::null());
  EXPECT(weak2.key() == Object::null());
  EXPECT(weak2.value() == Object::null());
}

static void WeakReference_PreserveOne(Thread* thread, Heap::Space space) {
  auto& weak = WeakReference::Handle();
  const auto& target = String::Handle(OneByteString::New("target", space));
  {
    HANDLESCOPE(thread);
    ObjectStore* object_store = thread->isolate_group()->object_store();
    const auto& type_arguments =
        TypeArguments::Handle(object_store->type_argument_double());
    weak ^= WeakReference::New(space);
    weak.set_target(target);
    weak.SetTypeArguments(type_arguments);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  EXPECT(weak.target() != Object::null());
  EXPECT(weak.GetTypeArguments() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakReference_PreserveOne_NewSpace) {
  WeakReference_PreserveOne(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(WeakReference_PreserveOne_OldSpace) {
  WeakReference_PreserveOne(thread, Heap::kOld);
}

static void WeakReference_ClearOne(Thread* thread, Heap::Space space) {
  auto& weak = WeakReference::Handle();
  {
    HANDLESCOPE(thread);
    const auto& target = String::Handle(OneByteString::New("target", space));
    ObjectStore* object_store = thread->isolate_group()->object_store();
    const auto& type_arguments =
        TypeArguments::Handle(object_store->type_argument_double());
    weak ^= WeakReference::New(space);
    weak.set_target(target);
    weak.SetTypeArguments(type_arguments);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  EXPECT(weak.target() == Object::null());
  EXPECT(weak.GetTypeArguments() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(WeakReference_ClearOne_NewSpace) {
  WeakReference_ClearOne(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(WeakReference_ClearOne_OldSpace) {
  WeakReference_ClearOne(thread, Heap::kOld);
}

static void WeakReference_Clear_ReachableThroughWeakProperty(
    Thread* thread,
    Heap::Space space) {
  auto& weak_property = WeakProperty::Handle();
  const auto& key = String::Handle(OneByteString::New("key", space));
  {
    HANDLESCOPE(thread);
    ObjectStore* object_store = thread->isolate_group()->object_store();
    const auto& type_arguments =
        TypeArguments::Handle(object_store->type_argument_double());
    const auto& weak_reference =
        WeakReference::Handle(WeakReference::New(space));
    const auto& target = String::Handle(OneByteString::New("target", space));
    weak_reference.set_target(target);
    weak_reference.SetTypeArguments(type_arguments);

    weak_property ^= WeakProperty::New(space);
    weak_property.set_key(key);
    weak_property.set_value(weak_reference);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  const auto& weak_reference =
      WeakReference::CheckedHandle(Z, weak_property.value());
  EXPECT(weak_reference.target() == Object::null());
  EXPECT(weak_reference.GetTypeArguments() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(
    WeakReference_Clear_ReachableThroughWeakProperty_NewSpace) {
  WeakReference_Clear_ReachableThroughWeakProperty(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(
    WeakReference_Clear_ReachableThroughWeakProperty_OldSpace) {
  WeakReference_Clear_ReachableThroughWeakProperty(thread, Heap::kOld);
}

static void WeakReference_Preserve_ReachableThroughWeakProperty(
    Thread* thread,
    Heap::Space space) {
  auto& weak_property = WeakProperty::Handle();
  const auto& key = String::Handle(OneByteString::New("key", space));
  const auto& target = String::Handle(OneByteString::New("target", space));
  {
    HANDLESCOPE(thread);
    ObjectStore* object_store = thread->isolate_group()->object_store();
    const auto& type_arguments =
        TypeArguments::Handle(object_store->type_argument_double());
    const auto& weak_reference =
        WeakReference::Handle(WeakReference::New(space));
    weak_reference.set_target(target);
    weak_reference.SetTypeArguments(type_arguments);

    weak_property ^= WeakProperty::New(space);
    weak_property.set_key(key);
    weak_property.set_value(weak_reference);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  const auto& weak_reference =
      WeakReference::CheckedHandle(Z, weak_property.value());
  EXPECT(weak_reference.target() != Object::null());
  EXPECT(weak_reference.GetTypeArguments() != Object::null());
}

ISOLATE_UNIT_TEST_CASE(
    WeakReference_Preserve_ReachableThroughWeakProperty_NewSpace) {
  WeakReference_Preserve_ReachableThroughWeakProperty(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(
    WeakReference_Preserve_ReachableThroughWeakProperty_OldSpace) {
  WeakReference_Preserve_ReachableThroughWeakProperty(thread, Heap::kOld);
}

ISOLATE_UNIT_TEST_CASE(WeakArray_New) {
  WeakArray& array = WeakArray::Handle(WeakArray::New(2, Heap::kNew));
  Object& target0 = Object::Handle();
  {
    HANDLESCOPE(thread);
    target0 = String::New("0", Heap::kNew);
    Object& target1 = Object::Handle(String::New("1", Heap::kNew));
    array.SetAt(0, target0);
    array.SetAt(1, target1);
  }

  EXPECT(array.Length() == 2);
  EXPECT(array.At(0) != Object::null());
  EXPECT(array.At(1) != Object::null());

  GCTestHelper::CollectNewSpace();

  EXPECT(array.Length() == 2);
  EXPECT(array.At(0) != Object::null());  // Survives
  EXPECT(array.At(1) == Object::null());  // Cleared
}

ISOLATE_UNIT_TEST_CASE(WeakArray_Old) {
  WeakArray& array = WeakArray::Handle(WeakArray::New(2, Heap::kOld));
  Object& target0 = Object::Handle();
  {
    HANDLESCOPE(thread);
    target0 = String::New("0", Heap::kOld);
    Object& target1 = Object::Handle(String::New("1", Heap::kOld));
    array.SetAt(0, target0);
    array.SetAt(1, target1);
  }

  EXPECT(array.Length() == 2);
  EXPECT(array.At(0) != Object::null());
  EXPECT(array.At(1) != Object::null());

  GCTestHelper::CollectAllGarbage();

  EXPECT(array.Length() == 2);
  EXPECT(array.At(0) != Object::null());  // Survives
  EXPECT(array.At(1) == Object::null());  // Cleared
}

static int NumEntries(const FinalizerEntry& entry, intptr_t acc = 0) {
  if (entry.IsNull()) {
    return acc;
  }
  return NumEntries(FinalizerEntry::Handle(entry.next()), acc + 1);
}

static void Finalizer_PreserveOne(Thread* thread,
                                  Heap::Space space,
                                  bool with_detach) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  {
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }

  const auto& finalizer = Finalizer::Handle(Finalizer::New(space));
  finalizer.set_isolate(thread->isolate());
  const auto& entry =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, space));
  const auto& value = String::Handle(OneByteString::New("value", space));
  entry.set_value(value);
  auto& detach = Object::Handle();
  if (with_detach) {
    detach = OneByteString::New("detach", space);
  } else {
    detach = Object::null();
  }
  entry.set_detach(detach);
  const auto& token = String::Handle(OneByteString::New("token", space));
  entry.set_token(token);

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  // Nothing in the entry should have been collected.
  EXPECT_NE(Object::null(), entry.value());
  EXPECT((entry.detach() == Object::null()) ^ with_detach);
  EXPECT_NE(Object::null(), entry.token());

  // The entry should not have moved to the collected list.
  EXPECT_EQ(0,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  // We should have no messages.
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveNoDetachOne_NewSpace) {
  Finalizer_PreserveOne(thread, Heap::kNew, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveNoDetachOne_OldSpace) {
  Finalizer_PreserveOne(thread, Heap::kOld, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveWithDetachOne_NewSpace) {
  Finalizer_PreserveOne(thread, Heap::kNew, true);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveWithDetachOne_OldSpace) {
  Finalizer_PreserveOne(thread, Heap::kOld, true);
}

static void Finalizer_ClearDetachOne(Thread* thread, Heap::Space space) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  {
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }

  const auto& finalizer = Finalizer::Handle(Finalizer::New(space));
  finalizer.set_isolate(thread->isolate());
  const auto& entry =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, space));
  const auto& value = String::Handle(OneByteString::New("value", space));
  entry.set_value(value);
  const auto& token = String::Handle(OneByteString::New("token", space));
  entry.set_token(token);

  {
    HANDLESCOPE(thread);
    const auto& detach = String::Handle(OneByteString::New("detach", space));
    entry.set_detach(detach);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  // Detach should have been collected.
  EXPECT_NE(Object::null(), entry.value());
  EXPECT_EQ(Object::null(), entry.detach());
  EXPECT_NE(Object::null(), entry.token());

  // The entry should not have moved to the collected list.
  EXPECT_EQ(0,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  // We should have no messages.
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearDetachOne_NewSpace) {
  Finalizer_ClearDetachOne(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearDetachOne_OldSpace) {
  Finalizer_ClearDetachOne(thread, Heap::kOld);
}

static void Finalizer_ClearValueOne(Thread* thread,
                                    Heap::Space space,
                                    bool null_token) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  {
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }

  const auto& finalizer = Finalizer::Handle(Finalizer::New(space));
  finalizer.set_isolate(thread->isolate());
  const auto& entry =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, space));
  const auto& detach = String::Handle(OneByteString::New("detach", space));
  auto& token = Object::Handle();
  if (null_token) {
    // Null is a valid token in Dart finalizers.
    token = Object::null();
  } else {
    token = OneByteString::New("token", space);
  }
  entry.set_token(token);
  entry.set_detach(detach);

  {
    HANDLESCOPE(thread);
    const auto& value = String::Handle(OneByteString::New("value", space));
    entry.set_value(value);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  // Value should have been collected.
  EXPECT_EQ(Object::null(), entry.value());
  EXPECT_NE(Object::null(), entry.detach());

  // The entry should have moved to the collected list.
  EXPECT_EQ(1,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  // We should have 1 message.
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(1, aq.queue()->Length());
  }
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueOne_NewSpace) {
  Finalizer_ClearValueOne(thread, Heap::kNew, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueOne_OldSpace) {
  Finalizer_ClearValueOne(thread, Heap::kOld, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueNullTokenOne_NewSpace) {
  Finalizer_ClearValueOne(thread, Heap::kNew, true);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueNullTokenOne_OldSpace) {
  Finalizer_ClearValueOne(thread, Heap::kOld, true);
}

static void Finalizer_DetachOne(Thread* thread,
                                Heap::Space space,
                                bool clear_value) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  {
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }

  const auto& finalizer = Finalizer::Handle(Finalizer::New(space));
  finalizer.set_isolate(thread->isolate());
  const auto& entry =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, space));
  const auto& detach = String::Handle(OneByteString::New("detach", space));
  entry.set_detach(detach);

  // Simulate calling detach, setting the token of the entry to the entry.
  entry.set_token(entry);

  auto& value = String::Handle();
  {
    HANDLESCOPE(thread);

    const auto& object = String::Handle(OneByteString::New("value", space));
    entry.set_value(object);
    if (!clear_value) {
      value = object.ptr();
    }
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  EXPECT((entry.value() == Object::null()) ^ !clear_value);
  EXPECT_NE(Object::null(), entry.detach());
  EXPECT_EQ(entry.ptr(), entry.token());

  // The entry should have been removed entirely
  EXPECT_EQ(0,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  // We should have no message.
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }
}

ISOLATE_UNIT_TEST_CASE(Finalizer_DetachOne_NewSpace) {
  Finalizer_DetachOne(thread, Heap::kNew, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_DetachOne_OldSpace) {
  Finalizer_DetachOne(thread, Heap::kOld, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_DetachAndClearValueOne_NewSpace) {
  Finalizer_DetachOne(thread, Heap::kNew, true);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_DetachAndClearValueOne_OldSpace) {
  Finalizer_DetachOne(thread, Heap::kOld, true);
}

static void Finalizer_GcFinalizer(Thread* thread, Heap::Space space) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  {
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }

  const auto& detach = String::Handle(OneByteString::New("detach", space));
  const auto& token = String::Handle(OneByteString::New("token", space));

  {
    HANDLESCOPE(thread);
    const auto& finalizer = Finalizer::Handle(Finalizer::New(space));
    finalizer.set_isolate(thread->isolate());
    const auto& entry =
        FinalizerEntry::Handle(FinalizerEntry::New(finalizer, space));
    entry.set_detach(detach);
    entry.set_token(token);
    const auto& value = String::Handle(OneByteString::New("value", space));
    entry.set_value(value);
  }

  if (space == Heap::kNew) {
    GCTestHelper::CollectNewSpace();
  } else {
    GCTestHelper::CollectAllGarbage();
  }

  // We should have no message, the Finalizer itself has been GCed.
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(0, aq.queue()->Length());
  }
}

ISOLATE_UNIT_TEST_CASE(Finalizer_GcFinalizer_NewSpace) {
  Finalizer_GcFinalizer(thread, Heap::kNew);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_GcFinalizer_OldSpace) {
  Finalizer_GcFinalizer(thread, Heap::kOld);
}

static void Finalizer_TwoEntriesCrossGen(
    Thread* thread,
    Heap::Space* spaces,
    bool collect_old_space,
    bool collect_new_space,
    bool evacuate_new_space_and_collect_old_space,
    bool clear_value_1,
    bool clear_value_2,
    bool clear_detach_1,
    bool clear_detach_2) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  MessageHandler* handler = thread->isolate()->message_handler();
  // We're reusing the isolate in a loop, so there are messages from previous
  // runs of this test.
  intptr_t queue_length_start = 0;
  {
    MessageHandler::AcquiredQueues aq(handler);
    queue_length_start = aq.queue()->Length();
  }

  const auto& finalizer = Finalizer::Handle(Finalizer::New(spaces[0]));
  finalizer.set_isolate(thread->isolate());
  const auto& entry1 =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, spaces[1]));
  const auto& entry2 =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, spaces[2]));

  auto& value1 = String::Handle();
  auto& detach1 = String::Handle();
  const auto& token1 = String::Handle(OneByteString::New("token1", spaces[3]));
  entry1.set_token(token1);

  auto& value2 = String::Handle();
  auto& detach2 = String::Handle();
  const auto& token2 = String::Handle(OneByteString::New("token2", spaces[4]));
  entry2.set_token(token2);
  entry2.set_detach(detach2);

  {
    HANDLESCOPE(thread);
    auto& object = String::Handle();

    object ^= OneByteString::New("value1", spaces[5]);
    entry1.set_value(object);
    if (!clear_value_1) {
      value1 = object.ptr();
    }

    object ^= OneByteString::New("detach", spaces[6]);
    entry1.set_detach(object);
    if (!clear_detach_1) {
      detach1 = object.ptr();
    }

    object ^= OneByteString::New("value2", spaces[7]);
    entry2.set_value(object);
    if (!clear_value_2) {
      value2 = object.ptr();
    }

    object ^= OneByteString::New("detach", spaces[8]);
    entry2.set_detach(object);
    if (!clear_detach_2) {
      detach2 = object.ptr();
    }
  }

  if (collect_old_space) {
    GCTestHelper::CollectOldSpace();
  }
  if (collect_new_space) {
    GCTestHelper::CollectNewSpace();
  }
  if (evacuate_new_space_and_collect_old_space) {
    GCTestHelper::CollectAllGarbage();
  }

  EXPECT((entry1.value() == Object::null()) ^ !clear_value_1);
  EXPECT((entry2.value() == Object::null()) ^ !clear_value_2);
  EXPECT((entry1.detach() == Object::null()) ^ !clear_detach_1);
  EXPECT((entry2.detach() == Object::null()) ^ !clear_detach_2);
  EXPECT_NE(Object::null(), entry1.token());
  EXPECT_NE(Object::null(), entry2.token());

  const intptr_t expect_num_cleared =
      (clear_value_1 ? 1 : 0) + (clear_value_2 ? 1 : 0);
  EXPECT_EQ(expect_num_cleared,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  const intptr_t expect_num_messages = expect_num_cleared == 0 ? 0 : 1;
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(expect_num_messages + queue_length_start, aq.queue()->Length());
  }
}

const intptr_t kFinalizerTwoEntriesNumObjects = 9;

static void Finalizer_TwoEntries(Thread* thread,
                                 Heap::Space space,
                                 bool clear_value_1,
                                 bool clear_value_2,
                                 bool clear_detach_1,
                                 bool clear_detach_2) {
  const bool collect_old_space = true;
  const bool collect_new_space = space == Heap::kNew;
  const bool evacuate_new_space_and_collect_old_space = !collect_new_space;

  Heap::Space spaces[kFinalizerTwoEntriesNumObjects];
  for (intptr_t i = 0; i < kFinalizerTwoEntriesNumObjects; i++) {
    spaces[i] = space;
  }
  Finalizer_TwoEntriesCrossGen(
      thread, spaces, collect_old_space, collect_new_space,
      evacuate_new_space_and_collect_old_space, clear_value_1, clear_value_2,
      clear_detach_1, clear_detach_2);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueTwo_NewSpace) {
  Finalizer_TwoEntries(thread, Heap::kNew, true, true, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearValueTwo_OldSpace) {
  Finalizer_TwoEntries(thread, Heap::kOld, true, true, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearFirstValue_NewSpace) {
  Finalizer_TwoEntries(thread, Heap::kNew, true, false, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearFirstValue_OldSpace) {
  Finalizer_TwoEntries(thread, Heap::kOld, true, false, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearSecondValue_NewSpace) {
  Finalizer_TwoEntries(thread, Heap::kNew, false, true, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearSecondValue_OldSpace) {
  Finalizer_TwoEntries(thread, Heap::kOld, false, true, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveTwo_NewSpace) {
  Finalizer_TwoEntries(thread, Heap::kNew, false, false, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_PreserveTwo_OldSpace) {
  Finalizer_TwoEntries(thread, Heap::kOld, false, false, false, false);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearDetachTwo_NewSpace) {
  Finalizer_TwoEntries(thread, Heap::kNew, false, false, true, true);
}

ISOLATE_UNIT_TEST_CASE(Finalizer_ClearDetachTwo_OldSpace) {
  Finalizer_TwoEntries(thread, Heap::kOld, false, false, true, true);
}

static void Finalizer_TwoEntriesCrossGen(Thread* thread, intptr_t test_i) {
  ASSERT(test_i < (1 << kFinalizerTwoEntriesNumObjects));
  Heap::Space spaces[kFinalizerTwoEntriesNumObjects];
  for (intptr_t i = 0; i < kFinalizerTwoEntriesNumObjects; i++) {
    spaces[i] = ((test_i >> i) & 0x1) == 0x1 ? Heap::kOld : Heap::kNew;
  }
  // Either collect or evacuate new space.
  for (const bool collect_new_space : {false, true}) {
    // Always run old space collection first.
    const bool collect_old_space = true;
    // Always run old space collection after new space.
    const bool evacuate_new_space_and_collect_old_space = true;
    for (intptr_t test_j = 0; test_j < 16; test_j++) {
      const bool clear_value_1 = (test_j >> 0 & 0x1) == 0x1;
      const bool clear_value_2 = (test_j >> 1 & 0x1) == 0x1;
      const bool clear_detach_1 = (test_j >> 2 & 0x1) == 0x1;
      const bool clear_detach_2 = (test_j >> 3 & 0x1) == 0x1;
      Finalizer_TwoEntriesCrossGen(
          thread, spaces, collect_old_space, collect_new_space,
          evacuate_new_space_and_collect_old_space, clear_value_1,
          clear_value_2, clear_detach_1, clear_detach_2);
    }
  }
}
#define FINALIZER_CROSS_GEN_TEST_CASE(n)                                       \
  ISOLATE_UNIT_TEST_CASE(Finalizer_CrossGen_##n) {                             \
    Finalizer_TwoEntriesCrossGen(thread, n);                                   \
  }

#define REPEAT_512(V)                                                          \
  V(0)                                                                         \
  V(1)                                                                         \
  V(2)                                                                         \
  V(3)                                                                         \
  V(4)                                                                         \
  V(5)                                                                         \
  V(6)                                                                         \
  V(7)                                                                         \
  V(8)                                                                         \
  V(9)                                                                         \
  V(10)                                                                        \
  V(11)                                                                        \
  V(12)                                                                        \
  V(13)                                                                        \
  V(14)                                                                        \
  V(15)                                                                        \
  V(16)                                                                        \
  V(17)                                                                        \
  V(18)                                                                        \
  V(19)                                                                        \
  V(20)                                                                        \
  V(21)                                                                        \
  V(22)                                                                        \
  V(23)                                                                        \
  V(24)                                                                        \
  V(25)                                                                        \
  V(26)                                                                        \
  V(27)                                                                        \
  V(28)                                                                        \
  V(29)                                                                        \
  V(30)                                                                        \
  V(31)                                                                        \
  V(32)                                                                        \
  V(33)                                                                        \
  V(34)                                                                        \
  V(35)                                                                        \
  V(36)                                                                        \
  V(37)                                                                        \
  V(38)                                                                        \
  V(39)                                                                        \
  V(40)                                                                        \
  V(41)                                                                        \
  V(42)                                                                        \
  V(43)                                                                        \
  V(44)                                                                        \
  V(45)                                                                        \
  V(46)                                                                        \
  V(47)                                                                        \
  V(48)                                                                        \
  V(49)                                                                        \
  V(50)                                                                        \
  V(51)                                                                        \
  V(52)                                                                        \
  V(53)                                                                        \
  V(54)                                                                        \
  V(55)                                                                        \
  V(56)                                                                        \
  V(57)                                                                        \
  V(58)                                                                        \
  V(59)                                                                        \
  V(60)                                                                        \
  V(61)                                                                        \
  V(62)                                                                        \
  V(63)                                                                        \
  V(64)                                                                        \
  V(65)                                                                        \
  V(66)                                                                        \
  V(67)                                                                        \
  V(68)                                                                        \
  V(69)                                                                        \
  V(70)                                                                        \
  V(71)                                                                        \
  V(72)                                                                        \
  V(73)                                                                        \
  V(74)                                                                        \
  V(75)                                                                        \
  V(76)                                                                        \
  V(77)                                                                        \
  V(78)                                                                        \
  V(79)                                                                        \
  V(80)                                                                        \
  V(81)                                                                        \
  V(82)                                                                        \
  V(83)                                                                        \
  V(84)                                                                        \
  V(85)                                                                        \
  V(86)                                                                        \
  V(87)                                                                        \
  V(88)                                                                        \
  V(89)                                                                        \
  V(90)                                                                        \
  V(91)                                                                        \
  V(92)                                                                        \
  V(93)                                                                        \
  V(94)                                                                        \
  V(95)                                                                        \
  V(96)                                                                        \
  V(97)                                                                        \
  V(98)                                                                        \
  V(99)                                                                        \
  V(100)                                                                       \
  V(101)                                                                       \
  V(102)                                                                       \
  V(103)                                                                       \
  V(104)                                                                       \
  V(105)                                                                       \
  V(106)                                                                       \
  V(107)                                                                       \
  V(108)                                                                       \
  V(109)                                                                       \
  V(110)                                                                       \
  V(111)                                                                       \
  V(112)                                                                       \
  V(113)                                                                       \
  V(114)                                                                       \
  V(115)                                                                       \
  V(116)                                                                       \
  V(117)                                                                       \
  V(118)                                                                       \
  V(119)                                                                       \
  V(120)                                                                       \
  V(121)                                                                       \
  V(122)                                                                       \
  V(123)                                                                       \
  V(124)                                                                       \
  V(125)                                                                       \
  V(126)                                                                       \
  V(127)                                                                       \
  V(128)                                                                       \
  V(129)                                                                       \
  V(130)                                                                       \
  V(131)                                                                       \
  V(132)                                                                       \
  V(133)                                                                       \
  V(134)                                                                       \
  V(135)                                                                       \
  V(136)                                                                       \
  V(137)                                                                       \
  V(138)                                                                       \
  V(139)                                                                       \
  V(140)                                                                       \
  V(141)                                                                       \
  V(142)                                                                       \
  V(143)                                                                       \
  V(144)                                                                       \
  V(145)                                                                       \
  V(146)                                                                       \
  V(147)                                                                       \
  V(148)                                                                       \
  V(149)                                                                       \
  V(150)                                                                       \
  V(151)                                                                       \
  V(152)                                                                       \
  V(153)                                                                       \
  V(154)                                                                       \
  V(155)                                                                       \
  V(156)                                                                       \
  V(157)                                                                       \
  V(158)                                                                       \
  V(159)                                                                       \
  V(160)                                                                       \
  V(161)                                                                       \
  V(162)                                                                       \
  V(163)                                                                       \
  V(164)                                                                       \
  V(165)                                                                       \
  V(166)                                                                       \
  V(167)                                                                       \
  V(168)                                                                       \
  V(169)                                                                       \
  V(170)                                                                       \
  V(171)                                                                       \
  V(172)                                                                       \
  V(173)                                                                       \
  V(174)                                                                       \
  V(175)                                                                       \
  V(176)                                                                       \
  V(177)                                                                       \
  V(178)                                                                       \
  V(179)                                                                       \
  V(180)                                                                       \
  V(181)                                                                       \
  V(182)                                                                       \
  V(183)                                                                       \
  V(184)                                                                       \
  V(185)                                                                       \
  V(186)                                                                       \
  V(187)                                                                       \
  V(188)                                                                       \
  V(189)                                                                       \
  V(190)                                                                       \
  V(191)                                                                       \
  V(192)                                                                       \
  V(193)                                                                       \
  V(194)                                                                       \
  V(195)                                                                       \
  V(196)                                                                       \
  V(197)                                                                       \
  V(198)                                                                       \
  V(199)                                                                       \
  V(200)                                                                       \
  V(201)                                                                       \
  V(202)                                                                       \
  V(203)                                                                       \
  V(204)                                                                       \
  V(205)                                                                       \
  V(206)                                                                       \
  V(207)                                                                       \
  V(208)                                                                       \
  V(209)                                                                       \
  V(210)                                                                       \
  V(211)                                                                       \
  V(212)                                                                       \
  V(213)                                                                       \
  V(214)                                                                       \
  V(215)                                                                       \
  V(216)                                                                       \
  V(217)                                                                       \
  V(218)                                                                       \
  V(219)                                                                       \
  V(220)                                                                       \
  V(221)                                                                       \
  V(222)                                                                       \
  V(223)                                                                       \
  V(224)                                                                       \
  V(225)                                                                       \
  V(226)                                                                       \
  V(227)                                                                       \
  V(228)                                                                       \
  V(229)                                                                       \
  V(230)                                                                       \
  V(231)                                                                       \
  V(232)                                                                       \
  V(233)                                                                       \
  V(234)                                                                       \
  V(235)                                                                       \
  V(236)                                                                       \
  V(237)                                                                       \
  V(238)                                                                       \
  V(239)                                                                       \
  V(240)                                                                       \
  V(241)                                                                       \
  V(242)                                                                       \
  V(243)                                                                       \
  V(244)                                                                       \
  V(245)                                                                       \
  V(246)                                                                       \
  V(247)                                                                       \
  V(248)                                                                       \
  V(249)                                                                       \
  V(250)                                                                       \
  V(251)                                                                       \
  V(252)                                                                       \
  V(253)                                                                       \
  V(254)                                                                       \
  V(255)                                                                       \
  V(256)                                                                       \
  V(257)                                                                       \
  V(258)                                                                       \
  V(259)                                                                       \
  V(260)                                                                       \
  V(261)                                                                       \
  V(262)                                                                       \
  V(263)                                                                       \
  V(264)                                                                       \
  V(265)                                                                       \
  V(266)                                                                       \
  V(267)                                                                       \
  V(268)                                                                       \
  V(269)                                                                       \
  V(270)                                                                       \
  V(271)                                                                       \
  V(272)                                                                       \
  V(273)                                                                       \
  V(274)                                                                       \
  V(275)                                                                       \
  V(276)                                                                       \
  V(277)                                                                       \
  V(278)                                                                       \
  V(279)                                                                       \
  V(280)                                                                       \
  V(281)                                                                       \
  V(282)                                                                       \
  V(283)                                                                       \
  V(284)                                                                       \
  V(285)                                                                       \
  V(286)                                                                       \
  V(287)                                                                       \
  V(288)                                                                       \
  V(289)                                                                       \
  V(290)                                                                       \
  V(291)                                                                       \
  V(292)                                                                       \
  V(293)                                                                       \
  V(294)                                                                       \
  V(295)                                                                       \
  V(296)                                                                       \
  V(297)                                                                       \
  V(298)                                                                       \
  V(299)                                                                       \
  V(300)                                                                       \
  V(301)                                                                       \
  V(302)                                                                       \
  V(303)                                                                       \
  V(304)                                                                       \
  V(305)                                                                       \
  V(306)                                                                       \
  V(307)                                                                       \
  V(308)                                                                       \
  V(309)                                                                       \
  V(310)                                                                       \
  V(311)                                                                       \
  V(312)                                                                       \
  V(313)                                                                       \
  V(314)                                                                       \
  V(315)                                                                       \
  V(316)                                                                       \
  V(317)                                                                       \
  V(318)                                                                       \
  V(319)                                                                       \
  V(320)                                                                       \
  V(321)                                                                       \
  V(322)                                                                       \
  V(323)                                                                       \
  V(324)                                                                       \
  V(325)                                                                       \
  V(326)                                                                       \
  V(327)                                                                       \
  V(328)                                                                       \
  V(329)                                                                       \
  V(330)                                                                       \
  V(331)                                                                       \
  V(332)                                                                       \
  V(333)                                                                       \
  V(334)                                                                       \
  V(335)                                                                       \
  V(336)                                                                       \
  V(337)                                                                       \
  V(338)                                                                       \
  V(339)                                                                       \
  V(340)                                                                       \
  V(341)                                                                       \
  V(342)                                                                       \
  V(343)                                                                       \
  V(344)                                                                       \
  V(345)                                                                       \
  V(346)                                                                       \
  V(347)                                                                       \
  V(348)                                                                       \
  V(349)                                                                       \
  V(350)                                                                       \
  V(351)                                                                       \
  V(352)                                                                       \
  V(353)                                                                       \
  V(354)                                                                       \
  V(355)                                                                       \
  V(356)                                                                       \
  V(357)                                                                       \
  V(358)                                                                       \
  V(359)                                                                       \
  V(360)                                                                       \
  V(361)                                                                       \
  V(362)                                                                       \
  V(363)                                                                       \
  V(364)                                                                       \
  V(365)                                                                       \
  V(366)                                                                       \
  V(367)                                                                       \
  V(368)                                                                       \
  V(369)                                                                       \
  V(370)                                                                       \
  V(371)                                                                       \
  V(372)                                                                       \
  V(373)                                                                       \
  V(374)                                                                       \
  V(375)                                                                       \
  V(376)                                                                       \
  V(377)                                                                       \
  V(378)                                                                       \
  V(379)                                                                       \
  V(380)                                                                       \
  V(381)                                                                       \
  V(382)                                                                       \
  V(383)                                                                       \
  V(384)                                                                       \
  V(385)                                                                       \
  V(386)                                                                       \
  V(387)                                                                       \
  V(388)                                                                       \
  V(389)                                                                       \
  V(390)                                                                       \
  V(391)                                                                       \
  V(392)                                                                       \
  V(393)                                                                       \
  V(394)                                                                       \
  V(395)                                                                       \
  V(396)                                                                       \
  V(397)                                                                       \
  V(398)                                                                       \
  V(399)                                                                       \
  V(400)                                                                       \
  V(401)                                                                       \
  V(402)                                                                       \
  V(403)                                                                       \
  V(404)                                                                       \
  V(405)                                                                       \
  V(406)                                                                       \
  V(407)                                                                       \
  V(408)                                                                       \
  V(409)                                                                       \
  V(410)                                                                       \
  V(411)                                                                       \
  V(412)                                                                       \
  V(413)                                                                       \
  V(414)                                                                       \
  V(415)                                                                       \
  V(416)                                                                       \
  V(417)                                                                       \
  V(418)                                                                       \
  V(419)                                                                       \
  V(420)                                                                       \
  V(421)                                                                       \
  V(422)                                                                       \
  V(423)                                                                       \
  V(424)                                                                       \
  V(425)                                                                       \
  V(426)                                                                       \
  V(427)                                                                       \
  V(428)                                                                       \
  V(429)                                                                       \
  V(430)                                                                       \
  V(431)                                                                       \
  V(432)                                                                       \
  V(433)                                                                       \
  V(434)                                                                       \
  V(435)                                                                       \
  V(436)                                                                       \
  V(437)                                                                       \
  V(438)                                                                       \
  V(439)                                                                       \
  V(440)                                                                       \
  V(441)                                                                       \
  V(442)                                                                       \
  V(443)                                                                       \
  V(444)                                                                       \
  V(445)                                                                       \
  V(446)                                                                       \
  V(447)                                                                       \
  V(448)                                                                       \
  V(449)                                                                       \
  V(450)                                                                       \
  V(451)                                                                       \
  V(452)                                                                       \
  V(453)                                                                       \
  V(454)                                                                       \
  V(455)                                                                       \
  V(456)                                                                       \
  V(457)                                                                       \
  V(458)                                                                       \
  V(459)                                                                       \
  V(460)                                                                       \
  V(461)                                                                       \
  V(462)                                                                       \
  V(463)                                                                       \
  V(464)                                                                       \
  V(465)                                                                       \
  V(466)                                                                       \
  V(467)                                                                       \
  V(468)                                                                       \
  V(469)                                                                       \
  V(470)                                                                       \
  V(471)                                                                       \
  V(472)                                                                       \
  V(473)                                                                       \
  V(474)                                                                       \
  V(475)                                                                       \
  V(476)                                                                       \
  V(477)                                                                       \
  V(478)                                                                       \
  V(479)                                                                       \
  V(480)                                                                       \
  V(481)                                                                       \
  V(482)                                                                       \
  V(483)                                                                       \
  V(484)                                                                       \
  V(485)                                                                       \
  V(486)                                                                       \
  V(487)                                                                       \
  V(488)                                                                       \
  V(489)                                                                       \
  V(490)                                                                       \
  V(491)                                                                       \
  V(492)                                                                       \
  V(493)                                                                       \
  V(494)                                                                       \
  V(495)                                                                       \
  V(496)                                                                       \
  V(497)                                                                       \
  V(498)                                                                       \
  V(499)                                                                       \
  V(500)                                                                       \
  V(501)                                                                       \
  V(502)                                                                       \
  V(503)                                                                       \
  V(504)                                                                       \
  V(505)                                                                       \
  V(506)                                                                       \
  V(507)                                                                       \
  V(508)                                                                       \
  V(509)                                                                       \
  V(510)                                                                       \
  V(511)

REPEAT_512(FINALIZER_CROSS_GEN_TEST_CASE)

#undef FINALIZER_CROSS_GEN_TEST_CASE

// Force the marker to add a FinalizerEntry to the store buffer during marking.
//
// This test requires two entries, one in new space, one in old space.
// The scavenger should run first, adding the entry to collected_entries.
// The marker runs right after, swapping the collected_entries with the entry
// in old space, _and_ setting the next field to the entry in new space.
// This forces the entry to be added to the store-buffer _during_ marking.
//
// Then, the compacter needs to be used. Which will move the entry in old
// space.
//
// If the thread's store buffer block is not released after that, the compactor
// will not update it, causing an outdated address to be released to the store
// buffer later.
//
// This causes two types of errors to trigger with --verify-store-buffer:
// 1. We see the address in the store buffer but the object is no entry there.
//    Also can cause segfaults on reading garbage or unallocated memory.
// 2. We see the entry has a marked bit, but can't find it in the store buffer.
ISOLATE_UNIT_TEST_CASE(Finalizer_Regress_48843) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
  SetFlagScope<bool> sfs2(&FLAG_verify_store_buffer, true);
#endif
  SetFlagScope<bool> sfs3(&FLAG_use_compactor, true);

  const auto& finalizer = Finalizer::Handle(Finalizer::New(Heap::kOld));
  finalizer.set_isolate(thread->isolate());

  const auto& detach1 =
      String::Handle(OneByteString::New("detach1", Heap::kNew));
  const auto& token1 = String::Handle(OneByteString::New("token1", Heap::kNew));
  const auto& detach2 =
      String::Handle(OneByteString::New("detach2", Heap::kOld));
  const auto& token2 = String::Handle(OneByteString::New("token2", Heap::kOld));

  {
    HANDLESCOPE(thread);
    const auto& entry1 =
        FinalizerEntry::Handle(FinalizerEntry::New(finalizer, Heap::kNew));
    entry1.set_detach(detach1);
    entry1.set_token(token1);

    const auto& entry2 =
        FinalizerEntry::Handle(FinalizerEntry::New(finalizer, Heap::kOld));
    entry2.set_detach(detach2);
    entry2.set_token(token2);

    {
      HANDLESCOPE(thread);
      const auto& value1 =
          String::Handle(OneByteString::New("value1", Heap::kNew));
      entry1.set_value(value1);
      const auto& value2 =
          String::Handle(OneByteString::New("value2", Heap::kOld));
      entry2.set_value(value2);
      // Lose both values.
    }

    // First collect new space.
    GCTestHelper::CollectNewSpace();
    // Then old space, this will make the old space entry point to the new
    // space entry.
    // Also, this must be a mark compact, not a mark sweep, to move the entry.
    GCTestHelper::CollectOldSpace();
  }

  // Imagine callbacks running.
  // Entries themselves become unreachable.
  finalizer.set_entries_collected(
      FinalizerEntry::Handle(FinalizerEntry::null()));

  // There should be a single entry in the store buffer.
  // And it should crash when seeing the address in the buffer.
  GCTestHelper::CollectNewSpace();

  // We should no longer be processing the entries.
  GCTestHelper::CollectOldSpace();
  GCTestHelper::CollectNewSpace();
}

void NativeFinalizer_TwoEntriesCrossGen_Finalizer(void* peer) {
  intptr_t* token = reinterpret_cast<intptr_t*>(peer);
  (*token)++;
}

static void NativeFinalizer_TwoEntriesCrossGen(
    Thread* thread,
    Heap::Space* spaces,
    bool collect_new_space,
    bool evacuate_new_space_and_collect_old_space,
    bool clear_value_1,
    bool clear_value_2,
    bool clear_detach_1,
    bool clear_detach_2) {
#ifdef DEBUG
  SetFlagScope<bool> sfs(&FLAG_trace_finalizers, true);
#endif

  intptr_t token1_memory = 0;
  intptr_t token2_memory = 0;

  MessageHandler* handler = thread->isolate()->message_handler();
  // We're reusing the isolate in a loop, so there are messages from previous
  // runs of this test.
  intptr_t queue_length_start = 0;
  {
    MessageHandler::AcquiredQueues aq(handler);
    queue_length_start = aq.queue()->Length();
  }

  const auto& callback = Pointer::Handle(Pointer::New(
      reinterpret_cast<uword>(&NativeFinalizer_TwoEntriesCrossGen_Finalizer),
      spaces[3]));

  const auto& finalizer =
      NativeFinalizer::Handle(NativeFinalizer::New(spaces[0]));
  finalizer.set_callback(callback);
  finalizer.set_isolate(thread->isolate());

  const auto& isolate_finalizers =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const auto& weak1 = WeakReference::Handle(WeakReference::New());
  weak1.set_target(finalizer);
  isolate_finalizers.Add(weak1);
  thread->isolate()->set_finalizers(isolate_finalizers);

  const auto& all_entries = Set::Handle(Set::NewDefault());
  finalizer.set_all_entries(all_entries);
  const auto& all_entries_data = Array::Handle(all_entries.data());
  THR_Print("entry1 space: %s\n", spaces[1] == Heap::kNew ? "new" : "old");
  const auto& entry1 =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, spaces[1]));
  all_entries_data.SetAt(0, entry1);
  THR_Print("entry2 space: %s\n", spaces[2] == Heap::kNew ? "new" : "old");
  const auto& entry2 =
      FinalizerEntry::Handle(FinalizerEntry::New(finalizer, spaces[2]));
  all_entries_data.SetAt(1, entry2);
  all_entries.set_used_data(2);  // Don't bother setting the index.

  const intptr_t external_size1 = 1024;
  const intptr_t external_size2 = 2048;
  entry1.set_external_size(external_size1);
  entry2.set_external_size(external_size2);
  IsolateGroup::Current()->heap()->AllocatedExternal(external_size1, spaces[5]);
  IsolateGroup::Current()->heap()->AllocatedExternal(external_size2, spaces[7]);

  auto& value1 = String::Handle();
  auto& detach1 = String::Handle();
  const auto& token1 = Pointer::Handle(
      Pointer::New(reinterpret_cast<uword>(&token1_memory), spaces[3]));
  entry1.set_token(token1);

  auto& value2 = String::Handle();
  auto& detach2 = String::Handle();
  const auto& token2 = Pointer::Handle(
      Pointer::New(reinterpret_cast<uword>(&token2_memory), spaces[4]));
  entry2.set_token(token2);
  entry2.set_detach(detach2);

  {
    HANDLESCOPE(thread);
    auto& object = String::Handle();

    THR_Print("value1 space: %s\n", spaces[5] == Heap::kNew ? "new" : "old");
    object ^= OneByteString::New("value1", spaces[5]);
    entry1.set_value(object);
    if (!clear_value_1) {
      value1 = object.ptr();
    }

    object ^= OneByteString::New("detach", spaces[6]);
    entry1.set_detach(object);
    if (!clear_detach_1) {
      detach1 = object.ptr();
    }

    THR_Print("value2 space: %s\n", spaces[7] == Heap::kNew ? "new" : "old");
    object ^= OneByteString::New("value2", spaces[7]);
    entry2.set_value(object);
    if (!clear_value_2) {
      value2 = object.ptr();
    }

    object ^= OneByteString::New("detach", spaces[8]);
    entry2.set_detach(object);
    if (!clear_detach_2) {
      detach2 = object.ptr();
    }
  }

  THR_Print("CollectOldSpace\n");
  GCTestHelper::CollectOldSpace();
  if (collect_new_space) {
    THR_Print("CollectNewSpace\n");
    GCTestHelper::CollectNewSpace();
  }
  if (evacuate_new_space_and_collect_old_space) {
    THR_Print("CollectAllGarbage\n");
    GCTestHelper::CollectAllGarbage();
  }

  EXPECT((entry1.value() == Object::null()) ^ !clear_value_1);
  EXPECT((entry2.value() == Object::null()) ^ !clear_value_2);
  EXPECT((entry1.detach() == Object::null()) ^ !clear_detach_1);
  EXPECT((entry2.detach() == Object::null()) ^ !clear_detach_2);
  EXPECT_NE(Object::null(), entry1.token());
  EXPECT_NE(Object::null(), entry2.token());

  const intptr_t expect_num_cleared =
      (clear_value_1 ? 1 : 0) + (clear_value_2 ? 1 : 0);
  EXPECT_EQ(expect_num_cleared,
            NumEntries(FinalizerEntry::Handle(finalizer.entries_collected())));

  EXPECT_EQ(clear_value_1 ? 1 : 0, token1_memory);
  EXPECT_EQ(clear_value_2 ? 1 : 0, token2_memory);

  const intptr_t expect_num_messages = expect_num_cleared == 0 ? 0 : 1;
  {
    // Acquire ownership of message handler queues.
    MessageHandler::AcquiredQueues aq(handler);
    EXPECT_EQ(expect_num_messages + queue_length_start, aq.queue()->Length());
  }

  // Simulate detachments.
  entry1.set_token(entry1);
  entry2.set_token(entry2);
  all_entries_data.SetAt(0, Object::Handle(Object::null()));
  all_entries_data.SetAt(1, Object::Handle(Object::null()));
  all_entries.set_used_data(0);
}

static void NativeFinalizer_TwoEntriesCrossGen(Thread* thread,
                                               intptr_t test_i) {
  ASSERT(test_i < (1 << kFinalizerTwoEntriesNumObjects));
  Heap::Space spaces[kFinalizerTwoEntriesNumObjects];
  for (intptr_t i = 0; i < kFinalizerTwoEntriesNumObjects; i++) {
    spaces[i] = ((test_i >> i) & 0x1) == 0x1 ? Heap::kOld : Heap::kNew;
  }
  // Either collect or evacuate new space.
  for (const bool collect_new_space : {true, false}) {
    // Always run old space collection after new space.
    const bool evacuate_new_space_and_collect_old_space = true;
    const bool clear_value_1 = true;
    const bool clear_value_2 = true;
    const bool clear_detach_1 = false;
    const bool clear_detach_2 = false;
    THR_Print(
        "collect_new_space: %s evacuate_new_space_and_collect_old_space: %s\n",
        collect_new_space ? "true" : "false",
        evacuate_new_space_and_collect_old_space ? "true" : "false");
    NativeFinalizer_TwoEntriesCrossGen(thread, spaces, collect_new_space,
                                       evacuate_new_space_and_collect_old_space,
                                       clear_value_1, clear_value_2,
                                       clear_detach_1, clear_detach_2);
  }
}

#define FINALIZER_NATIVE_CROSS_GEN_TEST_CASE(n)                                \
  ISOLATE_UNIT_TEST_CASE(NativeFinalizer_CrossGen_##n) {                       \
    NativeFinalizer_TwoEntriesCrossGen(thread, n);                             \
  }

REPEAT_512(FINALIZER_NATIVE_CROSS_GEN_TEST_CASE)

#undef FINALIZER_NATIVE_CROSS_GEN_TEST_CASE

#undef REPEAT_512

static ClassPtr GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.ptr();
}

TEST_CASE(IsIsolateUnsendable) {
  Zone* const zone = Thread::Current()->zone();

  const char* kScript = R"(
import 'dart:ffi';

class AImpl implements A {}
class ASub extends A {}
// Wonky class order and non-alphabetic naming on purpose.
class C extends Z {}
class E extends D {}
class A implements Finalizable {}
class Z implements A {}
class D implements C {}
class X extends E {}
)";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);

  TransitionNativeToVM transition(thread);
  const Library& lib = Library::CheckedHandle(zone, Api::UnwrapHandle(h_lib));
  EXPECT(!lib.IsNull());

  const auto& class_x = Class::Handle(zone, GetClass(lib, "X"));
  class_x.EnsureIsFinalized(thread);
  EXPECT(class_x.is_isolate_unsendable());

  const auto& class_a_impl = Class::Handle(zone, GetClass(lib, "AImpl"));
  class_a_impl.EnsureIsFinalized(thread);
  EXPECT(class_a_impl.is_isolate_unsendable());

  const auto& class_a_sub = Class::Handle(zone, GetClass(lib, "ASub"));
  class_a_sub.EnsureIsFinalized(thread);
  EXPECT(class_a_sub.is_isolate_unsendable());
}

TEST_CASE(ImplementorCid) {
  const char* kScriptChars = R"(
abstract class AInterface {}

abstract class BInterface {}
class BImplementation implements BInterface {}

abstract class CInterface {}
class CImplementation1 implements CInterface {}
class CImplementation2 implements CInterface {}

abstract class DInterface {}
abstract class DSubinterface implements DInterface {}

abstract class EInterface {}
abstract class ESubinterface implements EInterface {}
class EImplementation implements ESubinterface {}

abstract class FInterface {}
abstract class FSubinterface implements FInterface {}
class FImplementation1 implements FSubinterface {}
class FImplementation2 implements FSubinterface {}

main() {
  new BImplementation();
  new CImplementation1();
  new CImplementation2();
  new EImplementation();
  new FImplementation1();
  new FImplementation2();
}
)";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, nullptr);
  EXPECT_VALID(result);

  TransitionNativeToVM transition(thread);
  const Library& lib =
      Library::CheckedHandle(thread->zone(), Api::UnwrapHandle(h_lib));
  EXPECT(!lib.IsNull());

  const Class& AInterface = Class::Handle(GetClass(lib, "AInterface"));
  EXPECT_EQ(AInterface.implementor_cid(), kIllegalCid);

  const Class& BInterface = Class::Handle(GetClass(lib, "BInterface"));
  const Class& BImplementation =
      Class::Handle(GetClass(lib, "BImplementation"));
  EXPECT_EQ(BInterface.implementor_cid(), BImplementation.id());
  EXPECT_EQ(BImplementation.implementor_cid(), BImplementation.id());

  const Class& CInterface = Class::Handle(GetClass(lib, "CInterface"));
  const Class& CImplementation1 =
      Class::Handle(GetClass(lib, "CImplementation1"));
  const Class& CImplementation2 =
      Class::Handle(GetClass(lib, "CImplementation2"));
  EXPECT_EQ(CInterface.implementor_cid(), kDynamicCid);
  EXPECT_EQ(CImplementation1.implementor_cid(), CImplementation1.id());
  EXPECT_EQ(CImplementation2.implementor_cid(), CImplementation2.id());

  const Class& DInterface = Class::Handle(GetClass(lib, "DInterface"));
  const Class& DSubinterface = Class::Handle(GetClass(lib, "DSubinterface"));
  EXPECT_EQ(DInterface.implementor_cid(), kIllegalCid);
  EXPECT_EQ(DSubinterface.implementor_cid(), kIllegalCid);

  const Class& EInterface = Class::Handle(GetClass(lib, "EInterface"));
  const Class& ESubinterface = Class::Handle(GetClass(lib, "ESubinterface"));
  const Class& EImplementation =
      Class::Handle(GetClass(lib, "EImplementation"));
  EXPECT_EQ(EInterface.implementor_cid(), EImplementation.id());
  EXPECT_EQ(ESubinterface.implementor_cid(), EImplementation.id());
  EXPECT_EQ(EImplementation.implementor_cid(), EImplementation.id());

  const Class& FInterface = Class::Handle(GetClass(lib, "FInterface"));
  const Class& FSubinterface = Class::Handle(GetClass(lib, "FSubinterface"));
  const Class& FImplementation1 =
      Class::Handle(GetClass(lib, "FImplementation1"));
  const Class& FImplementation2 =
      Class::Handle(GetClass(lib, "FImplementation2"));
  EXPECT_EQ(FInterface.implementor_cid(), kDynamicCid);
  EXPECT_EQ(FSubinterface.implementor_cid(), kDynamicCid);
  EXPECT_EQ(FImplementation1.implementor_cid(), FImplementation1.id());
  EXPECT_EQ(FImplementation2.implementor_cid(), FImplementation2.id());
}

ISOLATE_UNIT_TEST_CASE(MirrorReference) {
  const MirrorReference& reference =
      MirrorReference::Handle(MirrorReference::New(Object::Handle()));
  Object& initial_referent = Object::Handle(reference.referent());
  EXPECT(initial_referent.IsNull());

  Library& library = Library::Handle(Library::CoreLibrary());
  EXPECT(!library.IsNull());
  EXPECT(library.IsLibrary());
  reference.set_referent(library);
  const Object& returned_referent = Object::Handle(reference.referent());
  EXPECT(returned_referent.IsLibrary());
  EXPECT_EQ(returned_referent.ptr(), library.ptr());

  const MirrorReference& other_reference =
      MirrorReference::Handle(MirrorReference::New(Object::Handle()));
  EXPECT_NE(reference.ptr(), other_reference.ptr());
  other_reference.set_referent(library);
  EXPECT_NE(reference.ptr(), other_reference.ptr());
  EXPECT_EQ(reference.referent(), other_reference.referent());

  Object& obj = Object::Handle(reference.ptr());
  EXPECT(obj.IsMirrorReference());
}

static FunctionPtr GetFunction(const Class& cls, const char* name) {
  Thread* thread = Thread::Current();
  const auto& error = cls.EnsureIsFinalized(thread);
  EXPECT(error == Error::null());
  const Function& result = Function::Handle(Resolver::ResolveDynamicFunction(
      Z, cls, String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.ptr();
}

static FunctionPtr GetFunction(const Library& lib, const char* name) {
  const Function& result = Function::Handle(
      lib.LookupLocalFunction(String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.ptr();
}

static FunctionPtr GetStaticFunction(const Class& cls, const char* name) {
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  EXPECT(error == Error::null());
  const Function& result = Function::Handle(
      cls.LookupStaticFunction(String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.ptr();
}

static FieldPtr GetField(const Class& cls, const char* name) {
  const Field& field =
      Field::Handle(cls.LookupField(String::Handle(String::New(name))));
  EXPECT(!field.IsNull());
  return field.ptr();
}

ISOLATE_UNIT_TEST_CASE(FindClosureIndex) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));
  const Array& functions = Array::Handle(Array::New(1));

  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New(thread, "foo_papa"));
  const FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  parent = Function::New(signature, parent_name,
                         UntaggedFunction::kRegularFunction, false, false,
                         false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, parent);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
  }

  Function& function = Function::Handle();
  const String& function_name = String::Handle(Symbols::New(thread, "foo"));
  function = Function::NewClosureFunction(function_name, parent,
                                          TokenPosition::kMinSource);
  // Add closure function to class.
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    ClosureFunctionsCache::AddClosureFunctionLocked(function);
  }

  // The closure should return a valid index.
  intptr_t good_closure_index =
      ClosureFunctionsCache::FindClosureIndex(function);
  EXPECT_GE(good_closure_index, 0);
  // The parent function should return an invalid index.
  intptr_t bad_closure_index = ClosureFunctionsCache::FindClosureIndex(parent);
  EXPECT_EQ(bad_closure_index, -1);

  // Retrieve closure function via index.
  Function& func_from_index = Function::Handle();
  func_from_index ^=
      ClosureFunctionsCache::ClosureFunctionFromIndex(good_closure_index);
  // Same closure function.
  EXPECT_EQ(func_from_index.ptr(), function.ptr());
}

ISOLATE_UNIT_TEST_CASE(FindInvocationDispatcherFunctionIndex) {
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));
  ClassFinalizer::FinalizeTypesInClass(cls);

  const Array& functions = Array::Handle(Array::New(1));
  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New(thread, "foo_papa"));
  const FunctionType& signature = FunctionType::ZoneHandle(FunctionType::New());
  parent = Function::New(signature, parent_name,
                         UntaggedFunction::kRegularFunction, false, false,
                         false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, parent);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
    cls.Finalize();
  }

  // Add invocation dispatcher.
  const String& invocation_dispatcher_name =
      String::Handle(Symbols::New(thread, "myMethod"));
  const Array& args_desc = Array::Handle(ArgumentsDescriptor::NewBoxed(0, 1));
  Function& invocation_dispatcher = Function::Handle();
  invocation_dispatcher ^= cls.GetInvocationDispatcher(
      invocation_dispatcher_name, args_desc,
      UntaggedFunction::kNoSuchMethodDispatcher, true /* create_if_absent */);
  EXPECT(!invocation_dispatcher.IsNull());
  // Get index to function.
  intptr_t invocation_dispatcher_index =
      cls.FindInvocationDispatcherFunctionIndex(invocation_dispatcher);
  // Expect a valid index.
  EXPECT_GE(invocation_dispatcher_index, 0);
  // Retrieve function through index.
  Function& invocation_dispatcher_from_index = Function::Handle();
  invocation_dispatcher_from_index ^=
      cls.InvocationDispatcherFunctionFromIndex(invocation_dispatcher_index);
  // Same function.
  EXPECT_EQ(invocation_dispatcher.ptr(),
            invocation_dispatcher_from_index.ptr());
  // Test function not found case.
  const Function& bad_function = Function::Handle(Function::null());
  intptr_t bad_invocation_dispatcher_index =
      cls.FindInvocationDispatcherFunctionIndex(bad_function);
  EXPECT_EQ(bad_invocation_dispatcher_index, -1);
}

static void PrintMetadata(const char* name, const Object& data) {
  if (data.IsError()) {
    OS::PrintErr("Error in metadata evaluation for %s: '%s'\n", name,
                 Error::Cast(data).ToErrorCString());
  }
  EXPECT(data.IsArray());
  const Array& metadata = Array::Cast(data);
  OS::PrintErr("Metadata for %s has %" Pd " values:\n", name,
               metadata.Length());
  Object& elem = Object::Handle();
  for (int i = 0; i < metadata.Length(); i++) {
    elem = metadata.At(i);
    OS::PrintErr("  %d: %s\n", i, elem.ToCString());
  }
}

TEST_CASE(Metadata) {
  // clang-format off
  auto kScriptChars =
      Utils::CStringUniquePtr(OS::SCreate(nullptr,
        "@metafoo                       \n"
        "class Meta {                   \n"
        "  final m;                     \n"
        "  const Meta(this.m);          \n"
        "}                              \n"
        "                               \n"
        "const metafoo = 'metafoo';     \n"
        "const metabar = 'meta' 'bar';  \n"
        "                               \n"
        "@metafoo                       \n"
        "@Meta(0) String%s gVar;        \n"
        "                               \n"
        "@metafoo                       \n"
        "get tlGetter => gVar;          \n"
        "                               \n"
        "@metabar                       \n"
        "class A {                      \n"
        "  @metafoo                     \n"
        "  @metabar                     \n"
        "  @Meta('baz')                 \n"
        "  var aField;                  \n"
        "                               \n"
        "  @metabar @Meta('baa')        \n"
        "  int aFunc(a,b) => a + b;     \n"
        "}                              \n"
        "                               \n"
        "@Meta('main')                  \n"
        "A main() {                     \n"
        "  return A();                  \n"
        "}                              \n",
        TestCase::NullableTag()), std::free);
  // clang-format on

  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars.get(), nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, nullptr);
  EXPECT_VALID(result);
  TransitionNativeToVM transition(thread);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  const Class& class_a = Class::Handle(GetClass(lib, "A"));
  Object& res = Object::Handle(lib.GetMetadata(class_a));
  PrintMetadata("A", res);

  const Class& class_meta = Class::Handle(GetClass(lib, "Meta"));
  res = lib.GetMetadata(class_meta);
  PrintMetadata("Meta", res);

  Field& field = Field::Handle(GetField(class_a, "aField"));
  res = lib.GetMetadata(field);
  PrintMetadata("A.aField", res);

  Function& func = Function::Handle(GetFunction(class_a, "aFunc"));
  res = lib.GetMetadata(func);
  PrintMetadata("A.aFunc", res);

  func = lib.LookupLocalFunction(String::Handle(Symbols::New(thread, "main")));
  EXPECT(!func.IsNull());
  res = lib.GetMetadata(func);
  PrintMetadata("main", res);

  func = lib.LookupLocalFunction(
      String::Handle(Symbols::New(thread, "get:tlGetter")));
  EXPECT(!func.IsNull());
  res = lib.GetMetadata(func);
  PrintMetadata("tlGetter", res);

  field = lib.LookupLocalField(String::Handle(Symbols::New(thread, "gVar")));
  EXPECT(!field.IsNull());
  res = lib.GetMetadata(field);
  PrintMetadata("gVar", res);
}

TEST_CASE(FunctionSourceFingerprint) {
  const char* kScriptChars =
      "class A {\n"
      "  static test1(int a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "  static test2(a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "  static test3(b) {\n"
      "    return b > 1 ? b + 1 : b;\n"
      "  }\n"
      "  static test4(b) {\n"
      "    return b > 1 ? b - 1 : b;\n"
      "  }\n"
      "  static test5(b) {\n"
      "    return b > 1 ? b - 2 : b;\n"
      "  }\n"
      "  test6(int a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "}\n"
      "class B {\n"
      "  static /* Different declaration style. */\n"
      "  test1(int a) {\n"
      "    /* Returns a + 1 for a > 1, a otherwise. */\n"
      "    return a > 1 ?\n"
      "        a + 1 :\n"
      "        a;\n"
      "  }\n"
      "  static test5(b) {\n"
      "    return b > 1 ?\n"
      "        b - 2 : b;\n"
      "  }\n"
      "  test6(int a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "}";
  TestCase::LoadTestScript(kScriptChars, nullptr);
  TransitionNativeToVM transition(thread);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(thread, name));
  EXPECT(!lib.IsNull());

  const Class& class_a =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  const Class& class_b =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "B"))));
  const Function& a_test1 =
      Function::Handle(GetStaticFunction(class_a, "test1"));
  const Function& b_test1 =
      Function::Handle(GetStaticFunction(class_b, "test1"));
  const Function& a_test2 =
      Function::Handle(GetStaticFunction(class_a, "test2"));
  const Function& a_test3 =
      Function::Handle(GetStaticFunction(class_a, "test3"));
  const Function& a_test4 =
      Function::Handle(GetStaticFunction(class_a, "test4"));
  const Function& a_test5 =
      Function::Handle(GetStaticFunction(class_a, "test5"));
  const Function& b_test5 =
      Function::Handle(GetStaticFunction(class_b, "test5"));
  const Function& a_test6 = Function::Handle(GetFunction(class_a, "test6"));
  const Function& b_test6 = Function::Handle(GetFunction(class_b, "test6"));

  EXPECT_EQ(a_test1.SourceFingerprint(), b_test1.SourceFingerprint());
  EXPECT_NE(a_test1.SourceFingerprint(), a_test2.SourceFingerprint());
  EXPECT_NE(a_test2.SourceFingerprint(), a_test3.SourceFingerprint());
  EXPECT_NE(a_test3.SourceFingerprint(), a_test4.SourceFingerprint());
  EXPECT_NE(a_test4.SourceFingerprint(), a_test5.SourceFingerprint());
  EXPECT_EQ(a_test5.SourceFingerprint(), b_test5.SourceFingerprint());
  // Although a_test6's receiver type is different than b_test6's receiver type,
  // the fingerprints are identical. The token stream does not reflect the
  // receiver's type. This is not a problem, since we recognize functions
  // of a given class and of a given name.
  EXPECT_EQ(a_test6.SourceFingerprint(), b_test6.SourceFingerprint());
}

#ifndef PRODUCT

TEST_CASE(FunctionWithBreakpointNotInlined) {
  const char* kScriptChars =
      "class A {\n"
      "  a() {\n"
      "  }\n"
      "  b() {\n"
      "    a();\n"  // This is line 5.
      "  }\n"
      "}\n"
      "test() {\n"
      "  new A().b();\n"
      "}";
  const int kBreakpointLine = 5;
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
  EXPECT_VALID(lib);

  // Run function A.b one time.
  Dart_Handle result = Dart_Invoke(lib, NewString("test"), 0, nullptr);
  EXPECT_VALID(result);

  // With no breakpoint, function A.b is inlineable.
  {
    TransitionNativeToVM transition(thread);
    const String& name = String::Handle(String::New(TestCase::url()));
    const Library& vmlib =
        Library::Handle(Library::LookupLibrary(thread, name));
    EXPECT(!vmlib.IsNull());
    const Class& class_a = Class::Handle(
        vmlib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
    Function& func_b = Function::Handle(GetFunction(class_a, "b"));
    EXPECT(func_b.CanBeInlined());
  }

  result = Dart_SetBreakpoint(NewString(TestCase::url()), kBreakpointLine);
  EXPECT_VALID(result);

  // After setting a breakpoint in a function A.b, it is no longer inlineable.
  {
    TransitionNativeToVM transition(thread);
    const String& name = String::Handle(String::New(TestCase::url()));
    const Library& vmlib =
        Library::Handle(Library::LookupLibrary(thread, name));
    EXPECT(!vmlib.IsNull());
    const Class& class_a = Class::Handle(
        vmlib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
    Function& func_b = Function::Handle(GetFunction(class_a, "b"));
    EXPECT(!func_b.CanBeInlined());
  }
}

ISOLATE_UNIT_TEST_CASE(SpecialClassesHaveEmptyArrays) {
  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  Class& cls = Class::Handle();
  Object& array = Object::Handle();

  cls = object_store->null_class();
  array = cls.fields();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());
  array = cls.current_functions();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());

  cls = Object::void_class();
  array = cls.fields();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());
  array = cls.current_functions();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());

  cls = Object::dynamic_class();
  array = cls.fields();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());
  array = cls.current_functions();
  EXPECT(!array.IsNull());
  EXPECT(array.IsArray());
}

class ObjectAccumulator : public ObjectVisitor {
 public:
  explicit ObjectAccumulator(GrowableArray<Object*>* objects)
      : objects_(objects) {}
  virtual ~ObjectAccumulator() {}
  virtual void VisitObject(ObjectPtr obj) {
    if (obj->IsPseudoObject()) {
      return;  // Cannot be wrapped in handles.
    }
    Object& handle = Object::Handle(obj);
    // Skip some common simple objects to run in reasonable time.
    if (handle.IsString() || handle.IsArray()) {
      return;
    }
    objects_->Add(&handle);
  }

 private:
  GrowableArray<Object*>* objects_;
};

ISOLATE_UNIT_TEST_CASE(ToCString) {
  // Set native resolvers in case we need to read native methods.
  {
    TransitionVMToNative transition(thread);
    bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
    bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
    bin::Builtin::SetNativeResolver(bin::Builtin::kCLILibrary);
    bin::VmService::SetNativeResolver();
  }

  GCTestHelper::CollectAllGarbage();
  GrowableArray<Object*> objects;
  {
    HeapIterationScope iteration(Thread::Current());
    ObjectAccumulator acc(&objects);
    iteration.IterateObjects(&acc);
  }
  for (intptr_t i = 0; i < objects.length(); ++i) {
    StackZone zone(thread);
    HANDLESCOPE(thread);

    // All ToCString implementations should not allocate on the Dart heap so
    // they remain useful in all parts of the VM.
    NoSafepointScope no_safepoint;
    objects[i]->ToCString();
  }
}

ISOLATE_UNIT_TEST_CASE(PrintJSON) {
  // Set native resolvers in case we need to read native methods.
  {
    TransitionVMToNative transition(thread);
    bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
    bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);
    bin::Builtin::SetNativeResolver(bin::Builtin::kCLILibrary);
    bin::VmService::SetNativeResolver();
  }

  GCTestHelper::CollectAllGarbage();
  GrowableArray<Object*> objects;
  {
    HeapIterationScope iteration(Thread::Current());
    ObjectAccumulator acc(&objects);
    iteration.IterateObjects(&acc);
  }
  for (intptr_t i = 0; i < objects.length(); ++i) {
    JSONStream js;
    objects[i]->PrintJSON(&js, false);
    EXPECT_SUBSTRING("\"type\":", js.ToCString());
  }
}

ISOLATE_UNIT_TEST_CASE(PrintJSONPrimitives) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 4096;
  char buffer[kBufferSize];
  Isolate* isolate = Isolate::Current();

  // Class reference
  {
    JSONStream js;
    Class& cls = Class::Handle(isolate->group()->object_store()->bool_class());
    cls.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    StripTokenPositions(buffer);

    EXPECT_STREQ(
        "{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"bool\","
        "\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":\"@"
        "Script\","
        "\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core\\/bool.dart\","
        "\"_kind\":\"kernel\"}},"
        "\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}}",
        buffer);
  }
  // Function reference
  {
    Thread* thread = Thread::Current();
    JSONStream js;
    Class& cls = Class::Handle(isolate->group()->object_store()->bool_class());
    const String& func_name = String::Handle(String::New("toString"));
    Function& func =
        Function::Handle(Resolver::ResolveFunction(Z, cls, func_name));
    ASSERT(!func.IsNull());
    func.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"toString\",\"owner\":{\"type\":\"@Class\","
        "\"fixedId\":true,\"id\":\"\",\"name\":\"bool\","
        "\"location\":{\"type\":\"SourceLocation\","
        "\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core\\/bool.dart\","
        "\"_kind\":\"kernel\"}},"
        "\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"_kind\":\"RegularFunction\",\"static\":false,\"const\":false,"
        "\"implicit\":false,\"abstract\":false,"
        "\"_intrinsic\":false,\"_native\":false,"
        "\"location\":{\"type\":\"SourceLocation\","
        "\"script\":{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
        "\"uri\":\"dart:core\\/bool.dart\",\"_kind\":\"kernel\"}}}",
        buffer);
  }
  // Library reference
  {
    JSONStream js;
    Library& lib =
        Library::Handle(isolate->group()->object_store()->core_library());
    lib.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("libraries", json_str, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}",
        buffer);
  }
  // Bool reference
  {
    JSONStream js;
    Bool::True().PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"Bool\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"bool\",\"location\":{"
        "\"type\":\"SourceLocation\",\"script\":{\"type\":\"@Script\","
        "\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core\\/bool.dart\",\"_"
        "kind\":\"kernel\"}},\"library\":"
        "{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\",\"name\":\"dart."
        "core\",\"uri\":\"dart:core\"}},\"identityHashCode\":0,\"kind\":"
        "\"Bool\",\"fixedId\":true,\"id\":\"objects\\/bool-true\","
        "\"valueAsString\":\"true\"}",
        buffer);
  }
  // Smi reference
  {
    JSONStream js;
    const Integer& smi = Integer::Handle(Integer::New(7));
    smi.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("_Smi@", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"Smi\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_Smi\",\"_vmName\":"
        "\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":"
        "\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/integers.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":0,\"kind\":\"Int\",\"fixedId\":true,\"id\":"
        "\"objects\\/int-7\",\"valueAsString\":\"7\"}",
        buffer);
  }
  // Mint reference
  {
    JSONStream js;
    const Integer& smi = Integer::Handle(Integer::New(Mint::kMinValue));
    smi.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_Mint@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"Mint\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_Mint\",\"_vmName\":"
        "\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":"
        "\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/integers.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"Int\",\"valueAsString\":"
        "\"-9223372036854775808\"}",
        buffer);
  }
  // Double reference
  {
    JSONStream js;
    const Double& dub = Double::Handle(Double::New(0.1234));
    dub.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_Double@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"Double\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_Double\",\"_vmName\":"
        "\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":"
        "\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/double.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"Double\","
        "\"valueAsString\":\"0.1234\"}",
        buffer);
  }
  // String reference
  {
    JSONStream js;
    const String& str = String::Handle(String::New("dw"));
    str.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_OneByteString@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"String\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_OneByteString\",\"_"
        "vmName\":\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{"
        "\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/string_patch.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"String\",\"length\":2,"
        "\"valueAsString\":\"dw\"}",
        buffer);
  }
  // Array reference
  {
    JSONStream js;
    const Array& array = Array::Handle(Array::New(0));
    array.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_List@", buffer, buffer);
    ElideJSONSubstring("_TypeParameter@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_SUBSTRING(
        "{\"type\":\"@Instance\",\"_vmType\":\"Array\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_List\",\"_vmName\":"
        "\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":"
        "\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-patch\\/"
        "array.dart\",\"_kind\":\"kernel\"}},"
        "\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"},\"typeParameters\":[{"
        "\"type\":\"@"
        "Instance\",\"_vmType\":\"TypeParameter\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_TypeParameter\",\"_"
        "vmName\":\"\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core-patch\\/"
        "type_patch.dart\",\"_kind\":\"kernel\"}},"
        "\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":",
        buffer);

    EXPECT_SUBSTRING(
        "\"id\":\"\",\"kind\":\"TypeParameter\",\"name\":\"X0\","
        "\"parameterizedClass\":{\"type\":\"@Instance\",\"_vmType\":\"Class\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\",\"name\":"
        "\"Null\",\"location\":{\"type\":\"SourceLocation\",\"script\":{"
        "\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:"
        "core\\/"
        "null.dart\",\"_kind\":\"kernel\"}},"
        "\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}},\"kind\":\"Null\","
        "\"fixedId\":true,\"id\":\"\",\"valueAsString\":\"null\"}}]},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"List\",\"length\":0}",
        buffer);
  }
  OS::PrintErr("\n\n\n");
  // GrowableObjectArray reference
  {
    JSONStream js;
    const GrowableObjectArray& array =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    array.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_GrowableList@", buffer, buffer);
    StripTokenPositions(buffer);
    ElideJSONSubstring("_TypeParameter@", buffer, buffer);
    EXPECT_SUBSTRING(
        "{\"type\":\"@Instance\",\"_vmType\":\"GrowableObjectArray\",\"class\":"
        "{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_"
        "GrowableList\",\"_vmName\":\"\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core-patch\\/"
        "growable_array.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"},"
        "\"typeParameters\":[{\"type\":\"@Instance\",\"_vmType\":"
        "\"TypeParameter\",\"class\":{\"type\":\"@Class\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"_TypeParameter\",\"_vmName\":\""
        "\",\"location\":{\"type\":\"SourceLocation\",\"script\":{"
        "\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/"
        "type_patch.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":",
        buffer);

    EXPECT_SUBSTRING(
        "\"id\":\"\",\"kind\":\"TypeParameter\",\"name\":\"X0\","
        "\"parameterizedClass\":{\"type\":\"@Instance\","
        "\"_vmType\":\"Class\",\"class\":{\"type\":\"@Class\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"Null\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core\\/"
        "null.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}},\"kind\":\"Null\","
        "\"fixedId\":true,\"id\":\"\",\"valueAsString\":\"null\"}}]},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"List\",\"length\":0}",
        buffer);
  }
  // Map reference
  {
    JSONStream js;
    const Map& array = Map::Handle(Map::NewDefault());
    array.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_Map@", buffer, buffer);
    StripTokenPositions(buffer);
    ElideJSONSubstring("_TypeParameter@", buffer, buffer);
    EXPECT_SUBSTRING(
        "{\"type\":\"@Instance\",\"_vmType\":\"Map\",\"class\":{"
        "\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_"
        "Map\",\"_vmName\":\"\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:collection-patch\\/"
        "compact_hash.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.collection\",\"uri\":\"dart:"
        "collection\"},\"typeParameters\":[{\"type\":\"@Instance\",\"_vmType\":"
        "\"TypeParameter\",\"class\":{\"type\":\"@Class\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"_TypeParameter\",\"_vmName\":\""
        "\",\"location\":{\"type\":\"SourceLocation\",\"script\":{"
        "\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/"
        "type_patch.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":",
        buffer);

    EXPECT_SUBSTRING(
        "\"id\":\"\",\"kind\":\"TypeParameter\",\"name\":\"X0\","
        "\"parameterizedClass\":{\"type\":\"@Instance\","
        "\"_vmType\":\"Class\",\"class\":{\"type\":\"@Class\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"Null\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core\\/"
        "null.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}},\"kind\":\"Null\","
        "\"fixedId\":true,\"id\":\"\",\"valueAsString\":\"null\"}},{\"type\":"
        "\"@Instance\",\"_vmType\":\"TypeParameter\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_TypeParameter\",\"_"
        "vmName\":\"\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core-patch\\/"
        "type_patch.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"identityHashCode\":",
        buffer);

    EXPECT_SUBSTRING(
        "\"id\":\"\",\"kind\":\"TypeParameter\",\"name\":\"X1\","
        "\"parameterizedClass\":{\"type\":\"@Instance\","
        "\"_vmType\":\"Class\",\"class\":{\"type\":\"@Class\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"Null\",\"location\":{\"type\":"
        "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
        "\"id\":\"\",\"uri\":\"dart:core\\/"
        "null.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}},\"kind\":\"Null\","
        "\"fixedId\":true,\"id\":\"\",\"valueAsString\":\"null\"}}]},"
        "\"identityHashCode\":0,\"id\":\"\",\"kind\":\"Map\",\"length\":0}",
        buffer);
  }
  // UserTag reference
  {
    JSONStream js;
    Instance& tag = Instance::Handle(isolate->default_tag());
    tag.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_UserTag@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_SUBSTRING(
        "\"type\":\"@Instance\",\"_vmType\":\"UserTag\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_UserTag\",\"_"
        "vmName\":\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{"
        "\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:"
        "developer-patch\\/"
        "profiler.dart\",\"_kind\":\"kernel\"}},\"library\":{\"type\":\"@"
        "Library\","
        "\"fixedId\":true,\"id\":\"\",\"name\":\"dart.developer\",\"uri\":"
        "\"dart:developer\"}},"
        // Handle non-zero identity hash.
        "\"identityHashCode\":",
        buffer);
    EXPECT_SUBSTRING(
        "\"id\":\"\","
        "\"kind\":\"UserTag\",\"label\":\"Default\"}",
        buffer);
  }
  // Type reference
  // TODO(turnidge): Add in all of the other Type siblings.
  {
    JSONStream js;
    Instance& type =
        Instance::Handle(isolate->group()->object_store()->bool_type());
    type.PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    ElideJSONSubstring("_Type@", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_SUBSTRING(
        "{\"type\":\"@Instance\",\"_vmType\":\"Type\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"_Type\",\"_vmName\":"
        "\"\",\"location\":{\"type\":\"SourceLocation\",\"script\":{\"type\":"
        "\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core-"
        "patch\\/type_patch.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        // Handle non-zero identity hash.
        "\"identityHashCode\":",
        buffer);
    EXPECT_SUBSTRING(
        "\"kind\":\"Type\","
        "\"fixedId\":true,\"id\":\"\","
        "\"typeClass\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"bool\",\"location\":{\"type\":\"SourceLocation\","
        "\"script\":{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\",\"uri\":"
        "\"dart:core\\/bool.dart\",\"_kind\":\"kernel\"}"
        "},\"library\":{\"type\":\"@Library\",\"fixedId\":"
        "true,\"id\":\"\",\"name\":\"dart.core\",\"uri\":\"dart:core\"}},"
        "\"name\":\"bool\"}",
        buffer);
  }
  // Null reference
  {
    JSONStream js;
    Object::null_object().PrintJSON(&js, true);
    const char* json_str = js.ToCString();
    ASSERT(strlen(json_str) < kBufferSize);
    ElideJSONSubstring("classes", json_str, buffer);
    ElideJSONSubstring("libraries", buffer, buffer);
    StripTokenPositions(buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\",\"_vmType\":\"null\",\"class\":{\"type\":\"@"
        "Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"Null\",\"location\":{"
        "\"type\":\"SourceLocation\",\"script\":{\"type\":\"@Script\","
        "\"fixedId\":true,\"id\":\"\",\"uri\":\"dart:core\\/null.dart\",\"_"
        "kind\":\"kernel\"}},\"library\":"
        "{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\",\"name\":\"dart."
        "core\",\"uri\":\"dart:core\"}},\"kind\":\"Null\",\"fixedId\":true,"
        "\"id\":\"objects\\/null\",\"valueAsString\":\"null\"}",
        buffer);
  }
  // Sentinel reference
  {
    JSONStream js;
    Object::sentinel().PrintJSON(&js, true);
    EXPECT_STREQ(
        "{\"type\":\"Sentinel\","
        "\"kind\":\"NotInitialized\","
        "\"valueAsString\":\"<not initialized>\"}",
        js.ToCString());
  }
  // Transition sentinel reference
  {
    JSONStream js;
    Object::transition_sentinel().PrintJSON(&js, true);
    EXPECT_STREQ(
        "{\"type\":\"Sentinel\","
        "\"kind\":\"BeingInitialized\","
        "\"valueAsString\":\"<being initialized>\"}",
        js.ToCString());
  }
}

#endif  // !PRODUCT

TEST_CASE(InstanceEquality) {
  // Test that Instance::OperatorEquals can call a user-defined operator==.
  const char* kScript =
      "class A {\n"
      "  bool operator==(covariant A other) { return true; }\n"
      "}\n"
      "main() {\n"
      "  A a = new A();\n"
      "}";

  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, nullptr);
  EXPECT_VALID(result);

  TransitionNativeToVM transition(thread);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  const Class& clazz = Class::Handle(GetClass(lib, "A"));
  EXPECT(!clazz.IsNull());
  const Instance& a0 = Instance::Handle(Instance::New(clazz));
  const Instance& a1 = Instance::Handle(Instance::New(clazz));
  EXPECT(a0.ptr() != a1.ptr());
  EXPECT(a0.OperatorEquals(a0));
  EXPECT(a0.OperatorEquals(a1));
  EXPECT(a0.IsIdenticalTo(a0));
  EXPECT(!a0.IsIdenticalTo(a1));
}

TEST_CASE(HashCode) {
  // Ensure C++ overrides of Instance::HashCode match the Dart implementations.
  const char* kScript =
      "foo() {\n"
      "  return \"foo\".hashCode;\n"
      "}";

  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("foo"), 0, nullptr);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);
  Integer& result = Integer::Handle();
  result ^= Api::UnwrapHandle(h_result);
  String& foo = String::Handle(String::New("foo"));
  Integer& expected = Integer::Handle();
  expected ^= foo.HashCode();
  EXPECT(result.IsIdenticalTo(expected));
}

const uint32_t kCalculateCanonicalizeHash = 0;

// Checks that the .hashCode equals the VM CanonicalizeHash() for keys in
// constant maps.
//
// Expects a script with a method named `value`.
//
// If `hashcode_canonicalize_vm` is non-zero, the VM CanonicalizeHash()
// is not executed but the provided value is used.
static bool HashCodeEqualsCanonicalizeHash(
    const char* value_script,
    uint32_t hashcode_canonicalize_vm = kCalculateCanonicalizeHash,
    bool check_identity = true,
    bool check_hashcode = true) {
  auto kScriptChars = Utils::CStringUniquePtr(
      OS::SCreate(nullptr,
                  "%s"
                  "\n"
                  "valueHashCode() {\n"
                  "  return value().hashCode;\n"
                  "}\n"
                  "\n"
                  "valueIdentityHashCode() {\n"
                  "  return identityHashCode(value());\n"
                  "}\n",
                  value_script),
      std::free);

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars.get(), nullptr);
  EXPECT_VALID(lib);
  Dart_Handle value_result = Dart_Invoke(lib, NewString("value"), 0, nullptr);
  EXPECT_VALID(value_result);
  Dart_Handle hashcode_result;
  if (check_hashcode) {
    hashcode_result = Dart_Invoke(lib, NewString("valueHashCode"), 0, nullptr);
    EXPECT_VALID(hashcode_result);
  }
  Dart_Handle identity_hashcode_result =
      Dart_Invoke(lib, NewString("valueIdentityHashCode"), 0, nullptr);
  EXPECT_VALID(identity_hashcode_result);

  TransitionNativeToVM transition(Thread::Current());

  const auto& value_dart = Instance::CheckedHandle(
      Thread::Current()->zone(), Api::UnwrapHandle(value_result));
  int64_t hashcode_dart;
  if (check_hashcode) {
    hashcode_dart =
        Integer::Cast(Object::Handle(Api::UnwrapHandle(hashcode_result)))
            .AsInt64Value();
  }
  const int64_t identity_hashcode_dart =
      Integer::Cast(Object::Handle(Api::UnwrapHandle(identity_hashcode_result)))
          .AsInt64Value();
  if (hashcode_canonicalize_vm == 0) {
    hashcode_canonicalize_vm = Instance::Cast(value_dart).CanonicalizeHash();
  }

  bool success = true;

  if (check_hashcode) {
    success &= hashcode_dart == hashcode_canonicalize_vm;
  }
  if (check_identity) {
    success &= identity_hashcode_dart == hashcode_canonicalize_vm;
  }

  if (!success) {
    LogBlock lb;
    THR_Print(
        "Dart hashCode or Dart identityHashCode does not equal VM "
        "CanonicalizeHash for %s\n",
        value_dart.ToCString());
    THR_Print("Dart hashCode %" Px64 " %" Pd64 "\n", hashcode_dart,
              hashcode_dart);
    THR_Print("Dart identityHashCode %" Px64 " %" Pd64 "\n",
              identity_hashcode_dart, identity_hashcode_dart);
    THR_Print("VM CanonicalizeHash %" Px32 " %" Pd32 "\n",
              hashcode_canonicalize_vm, hashcode_canonicalize_vm);
  }

  return success;
}

TEST_CASE(HashCode_Double) {
  const char* kScript =
      "value() {\n"
      "  return 1.0;\n"
      "}\n";
  // Double VM CanonicalizeHash is not equal to hashCode, because doubles
  // cannot be used as keys in constant sets and maps. However, doubles
  // _can_ be used for lookups in which case they are equal to their integer
  // value.
  uint32_t kInt1HashCode = 0;
  {
    TransitionNativeToVM transition(thread);
    kInt1HashCode = Integer::Handle(Integer::New(1)).CanonicalizeHash();
  }
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript, kInt1HashCode));
}

TEST_CASE(HashCode_Mint) {
  const char* kScript =
      "value() {\n"
      "  return 0x8000000;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript));
}

TEST_CASE(HashCode_Null) {
  const char* kScript =
      "value() {\n"
      "  return null;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript));
}

TEST_CASE(HashCode_Smi) {
  const char* kScript =
      "value() {\n"
      "  return 123;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript));
}

TEST_CASE(HashCode_String) {
  const char* kScript =
      "value() {\n"
      "  return 'asdf';\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript));
}

TEST_CASE(HashCode_Symbol) {
  const char* kScript =
      "value() {\n"
      "  return #A;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript, kCalculateCanonicalizeHash,
                                        /*check_identity=*/false));
}

TEST_CASE(HashCode_True) {
  const char* kScript =
      "value() {\n"
      "  return true;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript));
}

TEST_CASE(HashCode_Type_Dynamic) {
  const char* kScript =
      "const type = dynamic;\n"
      "\n"
      "value() {\n"
      "  return type;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript, kCalculateCanonicalizeHash,
                                        /*check_identity=*/false));
}

TEST_CASE(HashCode_Type_Int) {
  const char* kScript =
      "const type = int;\n"
      "\n"
      "value() {\n"
      "  return type;\n"
      "}\n";
  EXPECT(HashCodeEqualsCanonicalizeHash(kScript, kCalculateCanonicalizeHash,
                                        /*check_identity=*/false));
}

TEST_CASE(Map_iteration) {
  const char* kScript =
      "makeMap() {\n"
      "  var map = {'x': 3, 'y': 4, 'z': 5, 'w': 6};\n"
      "  map.remove('y');\n"
      "  map.remove('w');\n"
      "  return map;\n"
      "}";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("makeMap"), 0, nullptr);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);
  Instance& dart_map = Instance::Handle();
  dart_map ^= Api::UnwrapHandle(h_result);
  ASSERT(dart_map.IsMap());
  const Map& cc_map = Map::Cast(dart_map);

  EXPECT_EQ(2, cc_map.Length());

  Map::Iterator iterator(cc_map);
  Object& object = Object::Handle();

  EXPECT(iterator.MoveNext());
  object = iterator.CurrentKey();
  EXPECT_STREQ("x", object.ToCString());
  object = iterator.CurrentValue();
  EXPECT_STREQ("3", object.ToCString());

  EXPECT(iterator.MoveNext());
  object = iterator.CurrentKey();
  EXPECT_STREQ("z", object.ToCString());
  object = iterator.CurrentValue();
  EXPECT_STREQ("5", object.ToCString());

  EXPECT(!iterator.MoveNext());
}

template <class LinkedHashBase>
static bool LinkedHashBaseEqual(const LinkedHashBase& map1,
                                const LinkedHashBase& map2,
                                bool print_diff,
                                bool check_data = true) {
  if (check_data) {
    // Check data, only for non-nested.
    const auto& data1 = Array::Handle(map1.data());
    const auto& data2 = Array::Handle(map2.data());
    const intptr_t data1_length = Smi::Value(map1.used_data());
    const intptr_t data2_length = Smi::Value(map2.used_data());
    const bool data_length_equal = data1_length == data2_length;
    bool data_equal = data_length_equal;
    if (data_length_equal) {
      auto& object1 = Instance::Handle();
      auto& object2 = Instance::Handle();
      for (intptr_t i = 0; i < data1_length; i++) {
        object1 ^= data1.At(i);
        object2 ^= data2.At(i);
        data_equal &= object1.CanonicalizeEquals(object2);
      }
    }
    if (!data_equal) {
      if (print_diff) {
        THR_Print("LinkedHashBaseEqual Data not equal.\n");
        THR_Print("LinkedHashBaseEqual data1.length %" Pd " data1.length %" Pd
                  " \n",
                  data1_length, data2_length);
        auto& object1 = Instance::Handle();
        for (intptr_t i = 0; i < data1_length; i++) {
          object1 ^= data1.At(i);
          THR_Print("LinkedHashBaseEqual data1[%" Pd "] %s\n", i,
                    object1.ToCString());
        }
        for (intptr_t i = 0; i < data2_length; i++) {
          object1 ^= data2.At(i);
          THR_Print("LinkedHashBaseEqual data2[%" Pd "] %s\n", i,
                    object1.ToCString());
        }
      }
      return false;
    }
  }

  // Check hashing.
  intptr_t hash_mask1 = Smi::Value(map1.hash_mask());
  EXPECT(!Integer::Handle(map2.hash_mask()).IsNull());
  intptr_t hash_mask2 = Smi::Value(map2.hash_mask());
  const bool hash_masks_equal = hash_mask1 == hash_mask2;
  if (!hash_masks_equal) {
    if (print_diff) {
      THR_Print("LinkedHashBaseEqual Hash masks not equal.\n");
      THR_Print("LinkedHashBaseEqual hash_mask1 %" Px " hash_mask2 %" Px " \n",
                hash_mask1, hash_mask2);
    }
  }

  // Check indices.
  const auto& index1 = TypedData::Handle(map1.index());
  const auto& index2 = TypedData::Handle(map2.index());
  EXPECT(!index2.IsNull());
  ASSERT(index1.ElementType() == kUint32ArrayElement);
  ASSERT(index2.ElementType() == kUint32ArrayElement);
  const intptr_t kElementSize = 4;
  ASSERT(kElementSize == index1.ElementSizeInBytes());
  const bool index_length_equal = index1.Length() == index2.Length();
  bool index_equal = index_length_equal;
  if (index_length_equal) {
    for (intptr_t i = 0; i < index1.Length(); i++) {
      const uint32_t index1_val = index1.GetUint32(i * kElementSize);
      const uint32_t index2_val = index2.GetUint32(i * kElementSize);
      index_equal &= index1_val == index2_val;
    }
  }
  if (!index_equal && print_diff) {
    THR_Print("LinkedHashBaseEqual Indices not equal.\n");
    THR_Print("LinkedHashBaseEqual index1.length %" Pd " index2.length %" Pd
              " \n",
              index1.Length(), index2.Length());
    for (intptr_t i = 0; i < index1.Length(); i++) {
      const uint32_t index_val = index1.GetUint32(i * kElementSize);
      THR_Print("LinkedHashBaseEqual index1[%" Pd "] %" Px32 "\n", i,
                index_val);
    }
    for (intptr_t i = 0; i < index2.Length(); i++) {
      const uint32_t index_val = index2.GetUint32(i * kElementSize);
      THR_Print("LinkedHashBaseEqual index2[%" Pd "] %" Px32 "\n", i,
                index_val);
    }
  }
  return index_equal;
}

// Copies elements from data.
static MapPtr ConstructImmutableMap(const Array& input_data,
                                    intptr_t used_data,
                                    const TypeArguments& type_arguments) {
  auto& map = Map::Handle(ConstMap::NewUninitialized());

  const auto& data = Array::Handle(Array::New(used_data));
  for (intptr_t i = 0; i < used_data; i++) {
    data.SetAt(i, Object::Handle(input_data.At(i)));
  }
  map.set_data(data);
  map.set_used_data(used_data);
  map.SetTypeArguments(type_arguments);
  map.set_deleted_keys(0);
  map.ComputeAndSetHashMask();
  map ^= map.Canonicalize(Thread::Current());

  return map.ptr();
}

// Constructs an immutable hashmap from a mutable one in this test.
TEST_CASE(ConstMap_vm) {
  const char* kScript = R"(
enum ExperimentalFlag {
  alternativeInvalidationStrategy,
  constFunctions,
  constantUpdate2018,
  constructorTearoffs,
  controlFlowCollections,
  extensionMethods,
  extensionTypes,
  genericMetadata,
  nonNullable,
  nonfunctionTypeAliases,
  setLiterals,
  spreadCollections,
  testExperiment,
  tripleShift,
  valueClass,
  variance,
}

final Map<ExperimentalFlag?, bool> expiredExperimentalFlagsNonConst = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constFunctions: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.constructorTearoffs: false,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.extensionTypes: false,
  ExperimentalFlag.genericMetadata: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.testExperiment: false,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

makeNonConstMap() {
  return expiredExperimentalFlagsNonConst;
}

firstKey() {
  return ExperimentalFlag.alternativeInvalidationStrategy;
}

firstKeyHashCode() {
  return firstKey().hashCode;
}

firstKeyIdentityHashCode() {
  return identityHashCode(firstKey());
}

bool lookupSpreadCollections(Map map) =>
    map[ExperimentalFlag.spreadCollections];

bool? lookupNull(Map map) => map[null];
)";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle non_const_result =
      Dart_Invoke(lib, NewString("makeNonConstMap"), 0, nullptr);
  EXPECT_VALID(non_const_result);
  Dart_Handle first_key_result =
      Dart_Invoke(lib, NewString("firstKey"), 0, nullptr);
  EXPECT_VALID(first_key_result);
  Dart_Handle first_key_hashcode_result =
      Dart_Invoke(lib, NewString("firstKeyHashCode"), 0, nullptr);
  EXPECT_VALID(first_key_hashcode_result);
  Dart_Handle first_key_identity_hashcode_result =
      Dart_Invoke(lib, NewString("firstKeyIdentityHashCode"), 0, nullptr);
  EXPECT_VALID(first_key_identity_hashcode_result);

  Dart_Handle const_argument;

  {
    TransitionNativeToVM transition(thread);
    const auto& non_const_map =
        Map::Cast(Object::Handle(Api::UnwrapHandle(non_const_result)));
    const auto& non_const_type_args =
        TypeArguments::Handle(non_const_map.GetTypeArguments());
    const auto& non_const_data = Array::Handle(non_const_map.data());
    const auto& const_map = Map::Handle(ConstructImmutableMap(
        non_const_data, Smi::Value(non_const_map.used_data()),
        non_const_type_args));
    ASSERT(non_const_map.GetClassId() == kMapCid);
    ASSERT(const_map.GetClassId() == kConstMapCid);
    ASSERT(!non_const_map.IsCanonical());
    ASSERT(const_map.IsCanonical());

    const_argument = Api::NewHandle(thread, const_map.ptr());
  }

  Dart_Handle lookup_result = Dart_Invoke(
      lib, NewString("lookupSpreadCollections"), 1, &const_argument);
  EXPECT_VALID(lookup_result);
  EXPECT_TRUE(lookup_result);

  Dart_Handle lookup_null_result =
      Dart_Invoke(lib, NewString("lookupNull"), 1, &const_argument);
  EXPECT_VALID(lookup_null_result);
  EXPECT_NULL(lookup_null_result);

  {
    TransitionNativeToVM transition(thread);
    const auto& non_const_object =
        Object::Handle(Api::UnwrapHandle(non_const_result));
    const auto& non_const_map = Map::Cast(non_const_object);
    const auto& const_object =
        Object::Handle(Api::UnwrapHandle(const_argument));
    const auto& const_map = Map::Cast(const_object);

    EXPECT(non_const_map.GetClassId() != const_map.GetClassId());

    // Check that the index is identical.
    EXPECT(LinkedHashBaseEqual(non_const_map, const_map,
                               /*print_diff=*/true));
  }
}

static bool IsLinkedHashBase(const Object& object) {
  return object.IsMap() || object.IsSet();
}

// Checks that the non-constant and constant HashMap and HashSets are equal.
//
// Expects a script with a methods named `nonConstValue`, `constValue`, and
// `init`.
template <class LinkedHashBase, int kMutableCid, int kImmutableCid>
static void HashBaseNonConstEqualsConst(const char* script,
                                        bool check_data = true) {
  Dart_Handle lib = TestCase::LoadTestScript(script, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle init_result = Dart_Invoke(lib, NewString("init"), 0, nullptr);
  EXPECT_VALID(init_result);
  Dart_Handle non_const_result =
      Dart_Invoke(lib, NewString("nonConstValue"), 0, nullptr);
  EXPECT_VALID(non_const_result);
  Dart_Handle const_result =
      Dart_Invoke(lib, NewString("constValue"), 0, nullptr);
  EXPECT_VALID(const_result);

  TransitionNativeToVM transition(Thread::Current());
  const auto& non_const_object =
      Object::Handle(Api::UnwrapHandle(non_const_result));
  const auto& const_object = Object::Handle(Api::UnwrapHandle(const_result));
  non_const_object.IsMap();
  EXPECT(IsLinkedHashBase(non_const_object));
  if (!IsLinkedHashBase(non_const_object)) return;
  const auto& non_const_value = LinkedHashBase::Cast(non_const_object);
  EXPECT(IsLinkedHashBase(const_object));
  if (!IsLinkedHashBase(const_object)) return;
  const auto& const_value = LinkedHashBase::Cast(const_object);
  EXPECT_EQ(non_const_value.GetClassId(), kMutableCid);
  EXPECT_EQ(const_value.GetClassId(), kImmutableCid);
  EXPECT(!non_const_value.IsCanonical());
  EXPECT(const_value.IsCanonical());
  EXPECT(LinkedHashBaseEqual(non_const_value, const_value,
                             /*print_diff=*/true, check_data));
}

static void HashMapNonConstEqualsConst(const char* script,
                                       bool check_data = true) {
  HashBaseNonConstEqualsConst<Map, kMapCid, kConstMapCid>(script, check_data);
}

static void HashSetNonConstEqualsConst(const char* script,
                                       bool check_data = true) {
  HashBaseNonConstEqualsConst<Set, kSetCid, kConstSetCid>(script, check_data);
}

TEST_CASE(ConstMap_small) {
  const char* kScript = R"(
constValue() => const {1: 42, 'foo': 499, 2: 'bar'};

nonConstValue() => {1: 42, 'foo': 499, 2: 'bar'};

void init() {
  constValue()[null];
}
)";
  HashMapNonConstEqualsConst(kScript);
}

TEST_CASE(ConstMap_null) {
  const char* kScript = R"(
constValue() => const {1: 42, 'foo': 499, null: 'bar'};

nonConstValue() => {1: 42, 'foo': 499, null: 'bar'};

void init() {
  constValue()[null];
}
)";
  HashMapNonConstEqualsConst(kScript);
}

TEST_CASE(ConstMap_larger) {
  const char* kScript = R"(
enum ExperimentalFlag {
  alternativeInvalidationStrategy,
  constFunctions,
  constantUpdate2018,
  constructorTearoffs,
  controlFlowCollections,
  extensionMethods,
  extensionTypes,
  genericMetadata,
  nonNullable,
  nonfunctionTypeAliases,
  setLiterals,
  spreadCollections,
  testExperiment,
  tripleShift,
  valueClass,
  variance,
}

const Map<ExperimentalFlag, bool> expiredExperimentalFlags = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constFunctions: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.constructorTearoffs: false,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.extensionTypes: false,
  ExperimentalFlag.genericMetadata: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.testExperiment: false,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

final Map<ExperimentalFlag, bool> expiredExperimentalFlagsNonConst = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constFunctions: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.constructorTearoffs: false,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.extensionTypes: false,
  ExperimentalFlag.genericMetadata: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.testExperiment: false,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

constValue() => expiredExperimentalFlags;

nonConstValue() => expiredExperimentalFlagsNonConst;

void init() {
  constValue()[null];
}
)";
  HashMapNonConstEqualsConst(kScript);
}

TEST_CASE(ConstMap_nested) {
  const char* kScript = R"(
enum Abi {
  wordSize64,
  wordSize32Align32,
  wordSize32Align64,
}

enum NativeType {
  kNativeType,
  kNativeInteger,
  kNativeDouble,
  kPointer,
  kNativeFunction,
  kInt8,
  kInt16,
  kInt32,
  kInt64,
  kUint8,
  kUint16,
  kUint32,
  kUint64,
  kIntptr,
  kFloat,
  kDouble,
  kVoid,
  kOpaque,
  kStruct,
  kHandle,
}

const nonSizeAlignment = <Abi, Map<NativeType, int>>{
  Abi.wordSize64: {},
  Abi.wordSize32Align32: {
    NativeType.kDouble: 4,
    NativeType.kInt64: 4,
    NativeType.kUint64: 4
  },
  Abi.wordSize32Align64: {},
};

final nonSizeAlignmentNonConst = <Abi, Map<NativeType, int>>{
  Abi.wordSize64: {},
  Abi.wordSize32Align32: {
    NativeType.kDouble: 4,
    NativeType.kInt64: 4,
    NativeType.kUint64: 4
  },
  Abi.wordSize32Align64: {},
};

constValue() => nonSizeAlignment;

nonConstValue() => nonSizeAlignmentNonConst;

void init() {
  constValue()[null];
}
)";
  HashMapNonConstEqualsConst(kScript, false);
}

TEST_CASE(Set_iteration) {
  const char* kScript = R"(
makeSet() {
  var set = {'x', 'y', 'z', 'w'};
  set.remove('y');
  set.remove('w');
  return set;
}
)";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("makeSet"), 0, nullptr);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);
  Instance& dart_set = Instance::Handle();
  dart_set ^= Api::UnwrapHandle(h_result);
  ASSERT(dart_set.IsSet());
  const Set& cc_set = Set::Cast(dart_set);

  EXPECT_EQ(2, cc_set.Length());

  Set::Iterator iterator(cc_set);
  Object& object = Object::Handle();

  EXPECT(iterator.MoveNext());
  object = iterator.CurrentKey();
  EXPECT_STREQ("x", object.ToCString());

  EXPECT(iterator.MoveNext());
  object = iterator.CurrentKey();
  EXPECT_STREQ("z", object.ToCString());

  EXPECT(!iterator.MoveNext());
}

// Copies elements from data.
static SetPtr ConstructImmutableSet(const Array& input_data,
                                    intptr_t used_data,
                                    const TypeArguments& type_arguments) {
  auto& set = Set::Handle(ConstSet::NewUninitialized());

  const auto& data = Array::Handle(Array::New(used_data));
  for (intptr_t i = 0; i < used_data; i++) {
    data.SetAt(i, Object::Handle(input_data.At(i)));
  }
  set.set_data(data);
  set.set_used_data(used_data);
  set.SetTypeArguments(type_arguments);
  set.set_deleted_keys(0);
  set.ComputeAndSetHashMask();
  set ^= set.Canonicalize(Thread::Current());

  return set.ptr();
}

TEST_CASE(ConstSet_vm) {
  const char* kScript = R"(
makeNonConstSet() {
  return {1, 2, 3, 5, 8, 13};
}

bool containsFive(Set set) => set.contains(5);
)";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle non_const_result =
      Dart_Invoke(lib, NewString("makeNonConstSet"), 0, nullptr);
  EXPECT_VALID(non_const_result);

  Dart_Handle const_argument;

  {
    TransitionNativeToVM transition(thread);
    const auto& non_const_object =
        Object::Handle(Api::UnwrapHandle(non_const_result));
    const auto& non_const_set = Set::Cast(non_const_object);
    ASSERT(non_const_set.GetClassId() == kSetCid);
    ASSERT(!non_const_set.IsCanonical());

    const auto& non_const_data = Array::Handle(non_const_set.data());
    const auto& non_const_type_args =
        TypeArguments::Handle(non_const_set.GetTypeArguments());
    const auto& const_set = Set::Handle(ConstructImmutableSet(
        non_const_data, Smi::Value(non_const_set.used_data()),
        non_const_type_args));
    ASSERT(const_set.GetClassId() == kConstSetCid);
    ASSERT(const_set.IsCanonical());

    const_argument = Api::NewHandle(thread, const_set.ptr());
  }

  Dart_Handle contains_5_result =
      Dart_Invoke(lib, NewString("containsFive"), 1, &const_argument);
  EXPECT_VALID(contains_5_result);
  EXPECT_TRUE(contains_5_result);

  {
    TransitionNativeToVM transition(thread);
    const auto& non_const_object =
        Object::Handle(Api::UnwrapHandle(non_const_result));
    const auto& non_const_set = Set::Cast(non_const_object);
    const auto& const_object =
        Object::Handle(Api::UnwrapHandle(const_argument));
    const auto& const_set = Set::Cast(const_object);

    EXPECT(non_const_set.GetClassId() != const_set.GetClassId());

    // Check that the index is identical.
    EXPECT(LinkedHashBaseEqual(non_const_set, const_set,
                               /*print_diff=*/true));
  }
}

TEST_CASE(ConstSet_small) {
  const char* kScript = R"(
constValue() => const {1, 2, 3, 5, 8, 13};

nonConstValue() => {1, 2, 3, 5, 8, 13};

void init() {
  constValue().contains(null);
}
)";
  HashSetNonConstEqualsConst(kScript);
}

TEST_CASE(ConstSet_larger) {
  const char* kScript = R"(
const Set<String> tokensThatMayFollowTypeArg = {
  '(',
  ')',
  ']',
  '}',
  ':',
  ';',
  ',',
  '.',
  '?',
  '==',
  '!=',
  '..',
  '?.',
  '\?\?',
  '?..',
  '&',
  '|',
  '^',
  '+',
  '*',
  '%',
  '/',
  '~/'
};

final Set<String> tokensThatMayFollowTypeArgNonConst = {
  '(',
  ')',
  ']',
  '}',
  ':',
  ';',
  ',',
  '.',
  '?',
  '==',
  '!=',
  '..',
  '?.',
  '\?\?',
  '?..',
  '&',
  '|',
  '^',
  '+',
  '*',
  '%',
  '/',
  '~/'
};

constValue() => tokensThatMayFollowTypeArg;

nonConstValue() => tokensThatMayFollowTypeArgNonConst;

void init() {
  constValue().contains(null);
}
)";
  HashSetNonConstEqualsConst(kScript);
}

TEST_CASE(OneByteStringExternalEqualsInternal) {
  const char* kScript = R"(
makeInternalString() {
  return String.fromCharCodes(<int>[1, 1, 2, 3, 5, 8, 13]);
}

bool equalsAB(String a, String b) => !identical(a, b) && (a == b);
bool equalsBA(String a, String b) => !identical(b, a) && (b == a);
)";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(lib);
  Dart_Handle internal_string =
      Dart_Invoke(lib, NewString("makeInternalString"), 0, nullptr);
  EXPECT_VALID(internal_string);

  Dart_Handle external_string;
  uint8_t characters[] = {1, 1, 2, 3, 5, 8, 13};
  intptr_t len = ARRAY_SIZE(characters);

  {
    TransitionNativeToVM transition(thread);

    const String& str = String::Handle(ExternalOneByteString::New(
        characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
    EXPECT(!str.IsOneByteString());
    EXPECT(str.IsExternalOneByteString());

    external_string = Api::NewHandle(thread, str.ptr());
  }

  Dart_Handle args[2] = {internal_string, external_string};
  Dart_Handle equalsAB_result =
      Dart_Invoke(lib, NewString("equalsAB"), 2, args);
  EXPECT_VALID(equalsAB_result);
  EXPECT_TRUE(equalsAB_result);

  Dart_Handle equalsBA_result =
      Dart_Invoke(lib, NewString("equalsBA"), 2, args);
  EXPECT_VALID(equalsBA_result);
  EXPECT_TRUE(equalsBA_result);
}

static void CheckConcatAll(const String* data[], intptr_t n) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, n);
  const Array& array = Array::Handle(zone, Array::New(n));
  for (int i = 0; i < n; i++) {
    pieces.Add(*data[i]);
    array.SetAt(i, *data[i]);
  }
  const String& res1 =
      String::Handle(zone, Symbols::FromConcatAll(thread, pieces));
  const String& res2 = String::Handle(zone, String::ConcatAll(array));
  EXPECT(res1.Equals(res2));
}

ISOLATE_UNIT_TEST_CASE(Symbols_FromConcatAll) {
  {
    const String* data[3] = {&Symbols::TypeError(), &Symbols::Dot(),
                             &Symbols::isPaused()};
    CheckConcatAll(data, 3);
  }

  {
    const intptr_t kWideCharsLen = 7;
    uint16_t wide_chars[kWideCharsLen] = {'H', 'e', 'l', 'l', 'o', 256, '!'};
    const String& two_str =
        String::Handle(String::FromUTF16(wide_chars, kWideCharsLen));

    const String* data[3] = {&two_str, &Symbols::Dot(), &two_str};
    CheckConcatAll(data, 3);
  }

  {
    uint8_t characters[] = {0xF6, 0xF1, 0xE9};
    intptr_t len = ARRAY_SIZE(characters);

    const String& str = String::Handle(ExternalOneByteString::New(
        characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str, &Symbols::Dot(), &str};
    CheckConcatAll(data, 3);
  }

  {
    uint16_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                             '\v', '\r', '\\', '$',  'z'};
    intptr_t len = ARRAY_SIZE(characters);

    const String& str = String::Handle(ExternalTwoByteString::New(
        characters, len, nullptr, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str, &Symbols::Dot(), &str};
    CheckConcatAll(data, 3);
  }

  {
    uint8_t characters1[] = {0xF6, 0xF1, 0xE9};
    intptr_t len1 = ARRAY_SIZE(characters1);

    const String& str1 = String::Handle(ExternalOneByteString::New(
        characters1, len1, nullptr, 0, NoopFinalizer, Heap::kNew));

    uint16_t characters2[] = {'a',  '\n', '\f', '\b', '\t',
                              '\v', '\r', '\\', '$',  'z'};
    intptr_t len2 = ARRAY_SIZE(characters2);

    const String& str2 = String::Handle(ExternalTwoByteString::New(
        characters2, len2, nullptr, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str1, &Symbols::Dot(), &str2};
    CheckConcatAll(data, 3);
  }

  {
    const String& empty = String::Handle(String::New(""));
    const String* data[3] = {&Symbols::TypeError(), &empty,
                             &Symbols::isPaused()};
    CheckConcatAll(data, 3);
  }
}

struct TestResult {
  const char* in;
  const char* out;
};

ISOLATE_UNIT_TEST_CASE(String_ScrubName) {
  TestResult tests[] = {
      {"(dynamic, dynamic) => void", "(dynamic, dynamic) => void"},
      {"_List@915557746", "_List"},
      {"_HashMap@600006304<K, V>(dynamic) => V",
       "_HashMap<K, V>(dynamic) => V"},
      {"set:foo", "foo="},
      {"get:foo", "foo"},
      {"_ReceivePortImpl@709387912", "_ReceivePortImpl"},
      {"_ReceivePortImpl@709387912._internal@709387912",
       "_ReceivePortImpl._internal"},
      {"_C@6328321&_E@6328321&_F@6328321", "_C&_E&_F"},
      {"List.", "List"},
      {"get:foo@6328321", "foo"},
      {"_MyClass@6328321.", "_MyClass"},
      {"_MyClass@6328321.named", "_MyClass.named"},
  };
  String& test = String::Handle();
  const char* result;
  for (size_t i = 0; i < ARRAY_SIZE(tests); i++) {
    test = String::New(tests[i].in);
    result = String::ScrubName(test);
    EXPECT_STREQ(tests[i].out, result);
  }
}

ISOLATE_UNIT_TEST_CASE(String_EqualsUTF32) {
  // Regression test for Issue 27433. Checks that comparisons between Strings
  // and utf32 arrays happens after conversion to utf16 instead of utf32, as
  // required for proper canonicalization of string literals with a lossy
  // utf32->utf16 conversion.
  int32_t char_codes[] = {0,      0x0a,   0x0d,   0x7f,   0xff,
                          0xffff, 0xd800, 0xdc00, 0xdbff, 0xdfff};

  const String& str =
      String::Handle(String::FromUTF32(char_codes, ARRAY_SIZE(char_codes)));
  EXPECT(str.Equals(char_codes, ARRAY_SIZE(char_codes)));
}

TEST_CASE(TypeParameterTypeRef) {
  // Regression test for issue 82890.
  const char* kScriptChars =
      "void foo<T extends C<T>>(T x) {}\n"
      "void bar<M extends U<M>>(M x) {}\n"
      "abstract class C<T> {}\n"
      "abstract class U<T> extends C<T> {}\n";
  TestCase::LoadTestScript(kScriptChars, nullptr);
  TransitionNativeToVM transition(thread);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(thread, name));
  EXPECT(!lib.IsNull());

  const Function& foo = Function::Handle(GetFunction(lib, "foo"));
  const Function& bar = Function::Handle(GetFunction(lib, "bar"));
  const TypeParameter& t = TypeParameter::Handle(foo.TypeParameterAt(0));
  const TypeParameter& m = TypeParameter::Handle(bar.TypeParameterAt(0));
  EXPECT(!m.IsSubtypeOf(t, Heap::kNew));
}

static void FinalizeAndCanonicalize(AbstractType* type) {
  *type ^= ClassFinalizer::FinalizeType(*type);
  ASSERT(type->IsCanonical());
}

static void CheckSubtypeRelation(const Expect& expect,
                                 const AbstractType& sub,
                                 const AbstractType& super,
                                 bool is_subtype) {
  if (sub.IsSubtypeOf(super, Heap::kNew) != is_subtype) {
    TextBuffer buffer(128);
    buffer.AddString("Expected ");
    sub.PrintName(Object::kScrubbedName, &buffer);
    buffer.Printf(" to %s a subtype of ", is_subtype ? "be" : "not be");
    super.PrintName(Object::kScrubbedName, &buffer);
    expect.Fail("%s", buffer.buffer());
  }
}

#define EXPECT_SUBTYPE(sub, super)                                             \
  CheckSubtypeRelation(Expect(__FILE__, __LINE__), sub, super, true);
#define EXPECT_NOT_SUBTYPE(sub, super)                                         \
  CheckSubtypeRelation(Expect(__FILE__, __LINE__), sub, super, false);

ISOLATE_UNIT_TEST_CASE(ClosureType_SubtypeOfFunctionType) {
  const auto& closure_class =
      Class::Handle(IsolateGroup::Current()->object_store()->closure_class());
  const auto& closure_type = Type::Handle(closure_class.DeclarationType());
  auto& closure_type_nullable = Type::Handle(
      closure_type.ToNullability(Nullability::kNullable, Heap::kNew));
  FinalizeAndCanonicalize(&closure_type_nullable);
  auto& closure_type_legacy = Type::Handle(
      closure_type.ToNullability(Nullability::kLegacy, Heap::kNew));
  FinalizeAndCanonicalize(&closure_type_legacy);
  auto& closure_type_nonnullable = Type::Handle(
      closure_type.ToNullability(Nullability::kNonNullable, Heap::kNew));
  FinalizeAndCanonicalize(&closure_type_nonnullable);

  const auto& function_type =
      Type::Handle(IsolateGroup::Current()->object_store()->function_type());
  auto& function_type_nullable = Type::Handle(
      function_type.ToNullability(Nullability::kNullable, Heap::kNew));
  FinalizeAndCanonicalize(&function_type_nullable);
  auto& function_type_legacy = Type::Handle(
      function_type.ToNullability(Nullability::kLegacy, Heap::kNew));
  FinalizeAndCanonicalize(&function_type_legacy);
  auto& function_type_nonnullable = Type::Handle(
      function_type.ToNullability(Nullability::kNonNullable, Heap::kNew));
  FinalizeAndCanonicalize(&function_type_nonnullable);

  EXPECT_SUBTYPE(closure_type_nonnullable, function_type_nullable);
  EXPECT_SUBTYPE(closure_type_nonnullable, function_type_legacy);
  EXPECT_SUBTYPE(closure_type_nonnullable, function_type_nonnullable);
  EXPECT_SUBTYPE(closure_type_legacy, function_type_nullable);
  EXPECT_SUBTYPE(closure_type_legacy, function_type_legacy);
  EXPECT_SUBTYPE(closure_type_legacy, function_type_nonnullable);
  EXPECT_SUBTYPE(closure_type_nullable, function_type_nullable);
  EXPECT_SUBTYPE(closure_type_nullable, function_type_legacy);
  // Nullable types are not a subtype of non-nullable types in strict mode.
  if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
    EXPECT_NOT_SUBTYPE(closure_type_nullable, function_type_nonnullable);
  } else {
    EXPECT_SUBTYPE(closure_type_nullable, function_type_nonnullable);
  }

  const auto& async_lib = Library::Handle(Library::AsyncLibrary());
  const auto& future_or_class =
      Class::Handle(async_lib.LookupClass(Symbols::FutureOr()));
  auto& tav_function_nullable = TypeArguments::Handle(TypeArguments::New(1));
  tav_function_nullable.SetTypeAt(0, function_type_nullable);
  tav_function_nullable = tav_function_nullable.Canonicalize(thread);
  auto& tav_function_legacy = TypeArguments::Handle(TypeArguments::New(1));
  tav_function_legacy.SetTypeAt(0, function_type_legacy);
  tav_function_legacy = tav_function_legacy.Canonicalize(thread);
  auto& tav_function_nonnullable = TypeArguments::Handle(TypeArguments::New(1));
  tav_function_nonnullable.SetTypeAt(0, function_type_nonnullable);
  tav_function_nonnullable = tav_function_nonnullable.Canonicalize(thread);

  auto& future_or_function_type_nullable =
      Type::Handle(Type::New(future_or_class, tav_function_nullable));
  FinalizeAndCanonicalize(&future_or_function_type_nullable);
  auto& future_or_function_type_legacy =
      Type::Handle(Type::New(future_or_class, tav_function_legacy));
  FinalizeAndCanonicalize(&future_or_function_type_legacy);
  auto& future_or_function_type_nonnullable =
      Type::Handle(Type::New(future_or_class, tav_function_nonnullable));
  FinalizeAndCanonicalize(&future_or_function_type_nonnullable);

  EXPECT_SUBTYPE(closure_type_nonnullable, future_or_function_type_nullable);
  EXPECT_SUBTYPE(closure_type_nonnullable, future_or_function_type_legacy);
  EXPECT_SUBTYPE(closure_type_nonnullable, future_or_function_type_nonnullable);
  EXPECT_SUBTYPE(closure_type_legacy, future_or_function_type_nullable);
  EXPECT_SUBTYPE(closure_type_legacy, future_or_function_type_legacy);
  EXPECT_SUBTYPE(closure_type_legacy, future_or_function_type_nonnullable);
  EXPECT_SUBTYPE(closure_type_nullable, future_or_function_type_nullable);
  EXPECT_SUBTYPE(closure_type_nullable, future_or_function_type_legacy);
  // Nullable types are not a subtype of non-nullable types in strict mode.
  if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
    EXPECT_NOT_SUBTYPE(closure_type_nullable,
                       future_or_function_type_nonnullable);
  } else {
    EXPECT_SUBTYPE(closure_type_nullable, future_or_function_type_nonnullable);
  }
}

ISOLATE_UNIT_TEST_CASE(FunctionType_IsSubtypeOfNonNullableObject) {
  const auto& type_object = Type::Handle(
      IsolateGroup::Current()->object_store()->non_nullable_object_type());

  auto& type_function_int_nullary =
      FunctionType::Handle(FunctionType::New(0, Nullability::kNonNullable));
  type_function_int_nullary.set_result_type(Type::Handle(Type::IntType()));
  FinalizeAndCanonicalize(&type_function_int_nullary);

  auto& type_nullable_function_int_nullary =
      FunctionType::Handle(type_function_int_nullary.ToNullability(
          Nullability::kNullable, Heap::kOld));
  FinalizeAndCanonicalize(&type_nullable_function_int_nullary);

  EXPECT_SUBTYPE(type_function_int_nullary, type_object);
  if (IsolateGroup::Current()->use_strict_null_safety_checks()) {
    EXPECT_NOT_SUBTYPE(type_nullable_function_int_nullary, type_object);
  } else {
    EXPECT_SUBTYPE(type_nullable_function_int_nullary, type_object);
  }
}

#undef EXPECT_NOT_SUBTYPE
#undef EXPECT_SUBTYPE

static void ExpectTypesEquivalent(const Expect& expect,
                                  const AbstractType& expected,
                                  const AbstractType& got,
                                  TypeEquality kind) {
  if (got.IsEquivalent(expected, kind)) return;
  TextBuffer buffer(128);
  buffer.AddString("Expected type ");
  expected.PrintName(Object::kScrubbedName, &buffer);
  buffer.AddString(", got ");
  got.PrintName(Object::kScrubbedName, &buffer);
  expect.Fail("%s", buffer.buffer());
}

#define EXPECT_TYPES_EQUAL(expected, got)                                      \
  ExpectTypesEquivalent(Expect(__FILE__, __LINE__), expected, got,             \
                        TypeEquality::kCanonical);

TEST_CASE(Class_GetInstantiationOf) {
  const char* kScript = R"(
    class B<T> {}
    class A1<X, Y> implements B<List<Y>> {}
    class A2<X, Y> extends A1<Y, X> {}
  )";
  Dart_Handle api_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(api_lib);
  TransitionNativeToVM transition(thread);
  Zone* const zone = thread->zone();

  const auto& root_lib =
      Library::CheckedHandle(zone, Api::UnwrapHandle(api_lib));
  EXPECT(!root_lib.IsNull());
  const auto& class_b = Class::Handle(zone, GetClass(root_lib, "B"));
  const auto& class_a1 = Class::Handle(zone, GetClass(root_lib, "A1"));
  const auto& class_a2 = Class::Handle(zone, GetClass(root_lib, "A2"));

  const auto& core_lib = Library::Handle(zone, Library::CoreLibrary());
  const auto& class_list = Class::Handle(zone, GetClass(core_lib, "List"));

  const auto& decl_type_b = Type::Handle(zone, class_b.DeclarationType());
  const auto& decl_type_list = Type::Handle(zone, class_list.DeclarationType());
  const auto& null_tav = Object::null_type_arguments();

  // Test that A1.GetInstantiationOf(B) returns B<List<A1::Y>>.
  {
    const auto& decl_type_a1 = Type::Handle(zone, class_a1.DeclarationType());
    const auto& decl_type_args_a1 =
        TypeArguments::Handle(zone, decl_type_a1.arguments());
    const auto& type_arg_a1_y =
        TypeParameter::CheckedHandle(zone, decl_type_args_a1.TypeAt(1));
    auto& tav_a1_y = TypeArguments::Handle(TypeArguments::New(1));
    tav_a1_y.SetTypeAt(0, type_arg_a1_y);
    tav_a1_y = tav_a1_y.Canonicalize(thread);
    auto& type_list_a1_y = Type::CheckedHandle(
        zone, decl_type_list.InstantiateFrom(tav_a1_y, null_tav, kAllFree,
                                             Heap::kNew));
    type_list_a1_y ^= type_list_a1_y.Canonicalize(thread);
    auto& tav_list_a1_y = TypeArguments::Handle(TypeArguments::New(1));
    tav_list_a1_y.SetTypeAt(0, type_list_a1_y);
    tav_list_a1_y = tav_list_a1_y.Canonicalize(thread);
    auto& type_b_list_a1_y = Type::CheckedHandle(
        zone, decl_type_b.InstantiateFrom(tav_list_a1_y, null_tav, kAllFree,
                                          Heap::kNew));
    type_b_list_a1_y ^= type_b_list_a1_y.Canonicalize(thread);

    const auto& inst_b_a1 =
        Type::Handle(zone, class_a1.GetInstantiationOf(zone, class_b));
    EXPECT(!inst_b_a1.IsNull());
    EXPECT_TYPES_EQUAL(type_b_list_a1_y, inst_b_a1);
  }

  // Test that A2.GetInstantiationOf(B) returns B<List<A2::X>>.
  {
    const auto& decl_type_a2 = Type::Handle(zone, class_a2.DeclarationType());
    const auto& decl_type_args_a2 =
        TypeArguments::Handle(zone, decl_type_a2.arguments());
    const auto& type_arg_a2_x =
        TypeParameter::CheckedHandle(zone, decl_type_args_a2.TypeAt(0));
    auto& tav_a2_x = TypeArguments::Handle(TypeArguments::New(1));
    tav_a2_x.SetTypeAt(0, type_arg_a2_x);
    tav_a2_x = tav_a2_x.Canonicalize(thread);
    auto& type_list_a2_x = Type::CheckedHandle(
        zone, decl_type_list.InstantiateFrom(tav_a2_x, null_tav, kAllFree,
                                             Heap::kNew));
    type_list_a2_x ^= type_list_a2_x.Canonicalize(thread);
    auto& tav_list_a2_x = TypeArguments::Handle(TypeArguments::New(1));
    tav_list_a2_x.SetTypeAt(0, type_list_a2_x);
    tav_list_a2_x = tav_list_a2_x.Canonicalize(thread);
    auto& type_b_list_a2_x = Type::CheckedHandle(
        zone, decl_type_b.InstantiateFrom(tav_list_a2_x, null_tav, kAllFree,
                                          Heap::kNew));
    type_b_list_a2_x ^= type_b_list_a2_x.Canonicalize(thread);

    const auto& inst_b_a2 =
        Type::Handle(zone, class_a2.GetInstantiationOf(zone, class_b));
    EXPECT(!inst_b_a2.IsNull());
    EXPECT_TYPES_EQUAL(type_b_list_a2_x, inst_b_a2);
  }
}

#undef EXPECT_TYPES_EQUAL

#define EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got)                   \
  ExpectTypesEquivalent(Expect(__FILE__, __LINE__), expected, got,             \
                        TypeEquality::kSyntactical);

static TypePtr CreateFutureOrType(const AbstractType& param,
                                  Nullability nullability) {
  const auto& async_lib = Library::Handle(Library::AsyncLibrary());
  const auto& future_or_class =
      Class::Handle(async_lib.LookupClass(Symbols::FutureOr()));
  const auto& tav = TypeArguments::Handle(TypeArguments::New(1));
  tav.SetTypeAt(0, param);
  const auto& type =
      AbstractType::Handle(Type::New(future_or_class, tav, nullability));
  return Type::RawCast(
      ClassFinalizer::FinalizeType(type, ClassFinalizer::kFinalize));
}

static TypePtr CreateFutureType(const AbstractType& param,
                                Nullability nullability) {
  ObjectStore* const object_store = IsolateGroup::Current()->object_store();
  const auto& future_class = Class::Handle(object_store->future_class());
  const auto& tav = TypeArguments::Handle(TypeArguments::New(1));
  tav.SetTypeAt(0, param);
  const auto& type = Type::Handle(Type::New(future_class, tav, nullability));
  return Type::RawCast(
      ClassFinalizer::FinalizeType(type, ClassFinalizer::kFinalize));
}

ISOLATE_UNIT_TEST_CASE(AbstractType_NormalizeFutureOrType) {
  // This should be kept up to date with any changes in
  // https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md

  ObjectStore* const object_store = IsolateGroup::Current()->object_store();

  auto normalized_future_or = [&](const AbstractType& param,
                                  Nullability nullability) -> AbstractTypePtr {
    const auto& type = Type::Handle(CreateFutureOrType(param, nullability));
    return type.NormalizeFutureOrType(Heap::kNew);
  };

  // NORM(FutureOr<T>) =
  //   let S be NORM(T)
  //   if S is a top type then S
  {
    const auto& type = AbstractType::Handle(normalized_future_or(
        Object::dynamic_type(), Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::dynamic_type(), type);
  }

  {
    const auto& type = AbstractType::Handle(
        normalized_future_or(Object::void_type(), Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::void_type(), type);
  }

  {
    const auto& type_nullable_object =
        Type::Handle(object_store->nullable_object_type());
    const auto& type = AbstractType::Handle(
        normalized_future_or(type_nullable_object, Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, type);
  }

  //   if S is Object then S

  {
    const auto& type_non_nullable_object =
        Type::Handle(object_store->non_nullable_object_type());
    const auto& type = AbstractType::Handle(normalized_future_or(
        type_non_nullable_object, Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_non_nullable_object, type);
  }

  //   if S is Object* then S

  {
    const auto& type_legacy_object =
        Type::Handle(object_store->legacy_object_type());
    const auto& type = AbstractType::Handle(
        normalized_future_or(type_legacy_object, Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_legacy_object, type);
  }

  //   if S is Never then Future<Never>

  {
    const auto& type_never = Type::Handle(object_store->never_type());
    const auto& expected =
        Type::Handle(CreateFutureType(type_never, Nullability::kNonNullable));
    const auto& got = AbstractType::Handle(
        normalized_future_or(type_never, Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  //   if S is Null then Future<Null>?

  {
    const auto& type_null = Type::Handle(object_store->null_type());
    const auto& expected =
        Type::Handle(CreateFutureType(type_null, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        normalized_future_or(type_null, Nullability::kNonNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  //   else FutureOr<S>

  // NORM(T?) =
  //   let S be NORM(T)
  //   ...
  //   if S is FutureOr<R> and R is nullable then S

  {
    const auto& type_nullable_int =
        Type::Handle(object_store->nullable_int_type());
    const auto& expected = Type::Handle(
        CreateFutureOrType(type_nullable_int, Nullability::kNonNullable));
    const auto& got = AbstractType::Handle(
        normalized_future_or(type_nullable_int, Nullability::kNullable));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }
}

TEST_CASE(AbstractType_InstantiatedFutureOrIsNormalized) {
  const char* kScript = R"(
import 'dart:async';

FutureOr<T>? foo<T>() { return null; }
FutureOr<T?> bar<T>() { return null; }
)";

  Dart_Handle api_lib = TestCase::LoadTestScript(kScript, nullptr);
  EXPECT_VALID(api_lib);
  TransitionNativeToVM transition(thread);
  Zone* const zone = thread->zone();
  ObjectStore* const object_store = IsolateGroup::Current()->object_store();

  const auto& null_tav = Object::null_type_arguments();
  auto instantiate_future_or =
      [&](const AbstractType& generic,
          const AbstractType& param) -> AbstractTypePtr {
    const auto& tav = TypeArguments::Handle(TypeArguments::New(1));
    tav.SetTypeAt(0, param);
    return generic.InstantiateFrom(null_tav, tav, kCurrentAndEnclosingFree,
                                   Heap::kNew);
  };

  const auto& root_lib =
      Library::CheckedHandle(zone, Api::UnwrapHandle(api_lib));
  EXPECT(!root_lib.IsNull());
  const auto& foo = Function::Handle(zone, GetFunction(root_lib, "foo"));
  const auto& bar = Function::Handle(zone, GetFunction(root_lib, "bar"));
  const auto& foo_sig = FunctionType::Handle(zone, foo.signature());
  const auto& bar_sig = FunctionType::Handle(zone, bar.signature());

  const auto& nullable_future_or_T =
      AbstractType::Handle(zone, foo_sig.result_type());
  const auto& future_or_nullable_T =
      AbstractType::Handle(zone, bar_sig.result_type());

  const auto& type_nullable_object =
      Type::Handle(object_store->nullable_object_type());
  const auto& type_non_nullable_object =
      Type::Handle(object_store->non_nullable_object_type());
  const auto& type_legacy_object =
      Type::Handle(object_store->legacy_object_type());

  // Testing same cases as AbstractType_NormalizeFutureOrType.

  // FutureOr<T>?[top type] = top type

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, Object::dynamic_type()));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::dynamic_type(), got);
  }

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, Object::void_type()));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::void_type(), got);
  }

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_nullable_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  // FutureOr<T?>[top type] = top type

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, Object::dynamic_type()));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::dynamic_type(), got);
  }

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, Object::void_type()));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(Object::void_type(), got);
  }

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_nullable_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  // FutureOr<T?>[Object] = Object?

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_non_nullable_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  // FutureOr<T?>[Object*] = Object?

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_legacy_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  // FutureOr<T>?[Object] = Object?

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_non_nullable_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  // FutureOr<T>?[Object*] = Object?

  {
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_legacy_object));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(type_nullable_object, got);
  }

  const auto& type_never = Type::Handle(object_store->never_type());
  const auto& type_null = Type::Handle(object_store->null_type());

  // FutureOr<T?>[Never] = Future<Null>?

  {
    const auto& expected =
        Type::Handle(CreateFutureType(type_null, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_never));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T>?[Never] = Future<Never>?

  {
    const auto& expected =
        Type::Handle(CreateFutureType(type_never, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_never));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T?>[Null] = Future<Null>?

  {
    const auto& expected =
        Type::Handle(CreateFutureType(type_null, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_null));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T>?[Null] = Future<Null>?

  {
    const auto& expected =
        Type::Handle(CreateFutureType(type_null, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_null));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  const auto& type_nullable_int =
      Type::Handle(object_store->nullable_int_type());
  const auto& type_non_nullable_int =
      Type::Handle(object_store->non_nullable_int_type());

  // FutureOr<T?>[int] = FutureOr<int?>

  {
    const auto& expected = Type::Handle(
        CreateFutureOrType(type_nullable_int, Nullability::kNonNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_non_nullable_int));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T?>[int?] = FutureOr<int?>

  {
    const auto& expected = Type::Handle(
        CreateFutureOrType(type_nullable_int, Nullability::kNonNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(future_or_nullable_T, type_nullable_int));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T>?[int?] = FutureOr<int?>

  {
    const auto& expected = Type::Handle(
        CreateFutureOrType(type_nullable_int, Nullability::kNonNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_nullable_int));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }

  // FutureOr<T>?[int] = FutureOr<int>?

  {
    const auto& expected = Type::Handle(
        CreateFutureOrType(type_non_nullable_int, Nullability::kNullable));
    const auto& got = AbstractType::Handle(
        instantiate_future_or(nullable_future_or_T, type_non_nullable_int));
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(expected, got);
  }
}

#define __ assembler->

static void GenerateInvokeInstantiateTAVStub(compiler::Assembler* assembler) {
  __ EnterDartFrame(0);

  // Load the arguments into the right stub calling convention registers.
  const intptr_t uninstantiated_offset =
      (kCallerSpSlotFromFp + 2) * compiler::target::kWordSize;
  const intptr_t inst_type_args_offset =
      (kCallerSpSlotFromFp + 1) * compiler::target::kWordSize;
  const intptr_t fun_type_args_offset =
      (kCallerSpSlotFromFp + 0) * compiler::target::kWordSize;

  __ LoadMemoryValue(InstantiationABI::kUninstantiatedTypeArgumentsReg, FPREG,
                     uninstantiated_offset);
  __ LoadMemoryValue(InstantiationABI::kInstantiatorTypeArgumentsReg, FPREG,
                     inst_type_args_offset);
  __ LoadMemoryValue(InstantiationABI::kFunctionTypeArgumentsReg, FPREG,
                     fun_type_args_offset);

  __ Call(StubCode::InstantiateTypeArguments());

  // Set the return from the stub.
  __ MoveRegister(CallingConventions::kReturnReg,
                  InstantiationABI::kResultTypeArgumentsReg);
  __ LeaveDartFrame();
  __ Ret();
}

#undef __

static CodePtr CreateInvokeInstantiateTypeArgumentsStub(Thread* thread) {
  Zone* const zone = thread->zone();
  const auto& klass = Class::Handle(
      zone, thread->isolate_group()->class_table()->At(kInstanceCid));
  const auto& symbol = String::Handle(
      zone, Symbols::New(thread, OS::SCreate(zone, "InstantiateTAVTest")));
  const auto& signature = FunctionType::Handle(zone, FunctionType::New());
  const auto& function = Function::Handle(
      zone, Function::New(signature, symbol, UntaggedFunction::kRegularFunction,
                          false, false, false, false, false, klass,
                          TokenPosition::kNoSource));

  compiler::ObjectPoolBuilder pool_builder;
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  compiler::Assembler assembler(&pool_builder);
  GenerateInvokeInstantiateTAVStub(&assembler);
  const Code& invoke_instantiate_tav = Code::Handle(
      Code::FinalizeCodeAndNotify("InstantiateTAV", nullptr, &assembler,
                                  Code::PoolAttachment::kNotAttachPool,
                                  /*optimized=*/false));

  const auto& pool =
      ObjectPool::Handle(zone, ObjectPool::NewFromBuilder(pool_builder));
  invoke_instantiate_tav.set_object_pool(pool.ptr());
  invoke_instantiate_tav.set_owner(function);
  invoke_instantiate_tav.set_exception_handlers(
      ExceptionHandlers::Handle(zone, ExceptionHandlers::New(0)));
#if defined(TARGET_ARCH_IA32)
  EXPECT_EQ(0, pool.Length());
#else
  EXPECT_EQ(1, pool.Length());  // The InstantiateTypeArguments stub.
#endif
  return invoke_instantiate_tav.ptr();
}

#if !defined(PRODUCT)
// Defined before TypeArguments::InstantiateAndCanonicalizeFrom in object.cc.
extern bool TESTING_runtime_fail_on_existing_cache_entry;
#endif

static void TypeArgumentsHashCacheTest(Thread* thread, intptr_t num_classes) {
  TextBuffer buffer(MB);
  buffer.AddString("class D<T> {}\n");
  for (intptr_t i = 0; i < num_classes; i++) {
    buffer.Printf("class C%" Pd " { String toString() => 'C%" Pd "'; }\n", i,
                  i);
  }
  buffer.AddString("main() {\n");
  for (intptr_t i = 0; i < num_classes; i++) {
    buffer.Printf("  C%" Pd "().toString();\n", i);
  }
  buffer.AddString("}\n");

  Dart_Handle api_lib = TestCase::LoadTestScript(buffer.buffer(), nullptr);
  EXPECT_VALID(api_lib);
  Dart_Handle result = Dart_Invoke(api_lib, NewString("main"), 0, nullptr);
  EXPECT_VALID(result);

  // D + C0...CN, where N = kNumClasses - 1
  EXPECT(IsolateGroup::Current()->class_table()->NumCids() > num_classes);

  TransitionNativeToVM transition(thread);
  Zone* const zone = thread->zone();

  const auto& root_lib =
      Library::CheckedHandle(zone, Api::UnwrapHandle(api_lib));
  EXPECT(!root_lib.IsNull());

  const auto& class_d = Class::Handle(zone, GetClass(root_lib, "D"));
  ASSERT(!class_d.IsNull());
  const auto& decl_type_d = Type::Handle(zone, class_d.DeclarationType());
  const auto& decl_type_d_type_args =
      TypeArguments::Handle(zone, decl_type_d.arguments());

  EXPECT(!decl_type_d_type_args.HasInstantiations());

  auto& class_c = Class::Handle(zone);
  auto& decl_type_c = Type::Handle(zone);
  auto& instantiator_type_args = TypeArguments::Handle(zone);
  const auto& function_type_args = Object::null_type_arguments();
  auto& result_type_args = TypeArguments::Handle(zone);
  auto& result_type = AbstractType::Handle(zone);
  // Cache the first computed set of instantiator type arguments to check that
  // no entries from the cache have been lost when the cache grows.
  auto& first_instantiator_type_args = TypeArguments::Handle(zone);
  // Used for the cache hit in stub check.
  const auto& invoke_instantiate_tav =
      Code::Handle(zone, CreateInvokeInstantiateTypeArgumentsStub(thread));
  const auto& invoke_instantiate_tav_arguments =
      Array::Handle(zone, Array::New(3));
  const auto& invoke_instantiate_tav_args_descriptor =
      Array::Handle(zone, ArgumentsDescriptor::NewBoxed(0, 3));
  for (intptr_t i = 0; i < num_classes; ++i) {
    const bool updated_cache_is_linear =
        i < TypeArguments::Cache::kMaxLinearCacheEntries;
    auto const name = OS::SCreate(zone, "C%" Pd "", i);
    class_c = GetClass(root_lib, name);
    ASSERT(!class_c.IsNull());
    decl_type_c = class_c.DeclarationType();
    instantiator_type_args = TypeArguments::New(1);
    instantiator_type_args.SetTypeAt(0, decl_type_c);
    instantiator_type_args = instantiator_type_args.Canonicalize(thread);

#if !defined(PRODUCT)
    // The first call to InstantiateAndCanonicalizeFrom shouldn't have a cache
    // hit since the instantiator type arguments should be unique for each
    // iteration, and after that we do a check that the InstantiateTypeArguments
    // stub finds the entry (unless the cache is hash-based on IA32).
    TESTING_runtime_fail_on_existing_cache_entry = true;
#endif

    // Check that the key does not currently exist in the cache.
    intptr_t old_capacity;
    {
      SafepointMutexLocker ml(
          thread->isolate_group()->type_arguments_canonicalization_mutex());
      TypeArguments::Cache cache(zone, decl_type_d_type_args);
      EXPECT_EQ(i, cache.NumOccupied());
      auto loc =
          cache.FindKeyOrUnused(instantiator_type_args, function_type_args);
      EXPECT(!loc.present);
      old_capacity = cache.NumEntries();
    }

    decl_type_d_type_args.InstantiateAndCanonicalizeFrom(instantiator_type_args,
                                                         function_type_args);

    // Check that the key now does exist in the cache.
    TypeArguments::Cache::KeyLocation loc;
    bool storage_changed;
    {
      SafepointMutexLocker ml(
          thread->isolate_group()->type_arguments_canonicalization_mutex());
      TypeArguments::Cache cache(zone, decl_type_d_type_args);
      EXPECT_EQ(i + 1, cache.NumOccupied());
      // Double-check that we got the expected type of cache.
      EXPECT(updated_cache_is_linear ? cache.IsLinear() : cache.IsHash());
      loc = cache.FindKeyOrUnused(instantiator_type_args, function_type_args);
      EXPECT(loc.present);
      storage_changed = cache.NumEntries() != old_capacity;
    }

#if defined(TARGET_ARCH_IA32)
    const bool stub_checks_hash_caches = false;
#else
    const bool stub_checks_hash_caches = true;
#endif
    // Now check that we get the expected result from calling the stub if it
    // checks the cache (e.g., in all cases but hash-based caches on IA32).
    if (updated_cache_is_linear || stub_checks_hash_caches) {
      invoke_instantiate_tav_arguments.SetAt(0, decl_type_d_type_args);
      invoke_instantiate_tav_arguments.SetAt(1, instantiator_type_args);
      invoke_instantiate_tav_arguments.SetAt(2, function_type_args);
      result_type_args ^= DartEntry::InvokeCode(
          invoke_instantiate_tav, invoke_instantiate_tav_args_descriptor,
          invoke_instantiate_tav_arguments, thread);
      EXPECT_EQ(1, result_type_args.Length());
      result_type = result_type_args.TypeAt(0);
      EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(decl_type_c, result_type);
    }

#if !defined(PRODUCT)
    // Setting to false prior to re-calling InstantiateAndCanonicalizeFrom with
    // the same keys, as now we want a runtime check of an existing cache entry.
    TESTING_runtime_fail_on_existing_cache_entry = false;
#endif

    result_type_args = decl_type_d_type_args.InstantiateAndCanonicalizeFrom(
        instantiator_type_args, function_type_args);
    result_type = result_type_args.TypeAt(0);
    EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT(decl_type_c, result_type);

    // Check that no new entries were added to the cache.
    {
      SafepointMutexLocker ml(
          thread->isolate_group()->type_arguments_canonicalization_mutex());
      TypeArguments::Cache cache(zone, decl_type_d_type_args);
      EXPECT_EQ(i + 1, cache.NumOccupied());
      auto const loc2 =
          cache.FindKeyOrUnused(instantiator_type_args, function_type_args);
      EXPECT(loc2.present);
      EXPECT_EQ(loc.entry, loc2.entry);
    }

    if (i == 0) {
      first_instantiator_type_args = instantiator_type_args.ptr();
    } else if (storage_changed) {
      // Check that the first instantiator TAV still exists in the new cache.
      SafepointMutexLocker ml(
          thread->isolate_group()->type_arguments_canonicalization_mutex());
      TypeArguments::Cache cache(zone, decl_type_d_type_args);
      EXPECT_EQ(i + 1, cache.NumOccupied());
      // Double-check that we got the expected type of cache.
      EXPECT(i < TypeArguments::Cache::kMaxLinearCacheEntries ? cache.IsLinear()
                                                              : cache.IsHash());
      auto const loc =
          cache.FindKeyOrUnused(instantiator_type_args, function_type_args);
      EXPECT(loc.present);
    }
  }
}

// A smaller version of the following test case, just to ensure some coverage
// on slower builds.
TEST_CASE(TypeArguments_Cache_SomeInstantiations) {
  TypeArgumentsHashCacheTest(thread,
                             2 * TypeArguments::Cache::kMaxLinearCacheEntries);
}

// Too slow in debug mode. Also avoid the sanitizers and simulators for similar
// reasons. Any core issues will likely be found by SomeInstantiations.
#if !defined(DEBUG) && !defined(USING_MEMORY_SANITIZER) &&                     \
    !defined(USING_THREAD_SANITIZER) && !defined(USING_LEAK_SANITIZER) &&      \
    !defined(USING_UNDEFINED_BEHAVIOR_SANITIZER) && !defined(USING_SIMULATOR)
TEST_CASE(TypeArguments_Cache_ManyInstantiations) {
  const intptr_t kNumClasses = 100000;
  static_assert(kNumClasses > TypeArguments::Cache::kMaxLinearCacheEntries,
                "too few classes to trigger change to a hash-based cache");
  TypeArgumentsHashCacheTest(thread, kNumClasses);
}
#endif

#undef EXPECT_TYPES_SYNTACTICALLY_EQUIVALENT

}  // namespace dart
