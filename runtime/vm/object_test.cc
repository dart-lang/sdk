// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <limits>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/vmservice_impl.h"

#include "platform/globals.h"

#include "vm/class_finalizer.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/compiler_state.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debugger_api_impl_test.h"
#include "vm/isolate.h"
#include "vm/malloc_hooks.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/simulator.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#define Z (thread->zone())

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, write_protect_code);

static ClassPtr CreateDummyClass(const String& class_name,
                                 const Script& script) {
  const Class& cls = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  cls.set_is_synthesized_class();  // Dummy class for testing.
  cls.set_is_declaration_loaded();
  return cls.raw();
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
  interface.set_is_implemented();
  interface_name = Symbols::New(thread, "Norton");
  interface = CreateDummyClass(interface_name, script);
  interfaces.SetAt(1, Type::Handle(Type::NewNonParameterizedType(interface)));
  interface.set_is_implemented();
  cls.set_interfaces(interfaces);

  // Finalization of types happens before the fields and functions have been
  // parsed.
  ClassFinalizer::FinalizeTypesInClass(cls);

  // Create and populate the function arrays.
  const Array& functions = Array::Handle(Array::New(6));
  Function& function = Function::Handle();
  String& function_name = String::Handle();
  function_name = Symbols::New(thread, "foo");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, false,
                    false, false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, function);
  function_name = Symbols::New(thread, "bar");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, false,
                    false, false, false, false, cls, TokenPosition::kMinSource);

  const int kNumFixedParameters = 2;
  const int kNumOptionalParameters = 3;
  const bool kAreOptionalPositional = true;
  function.set_num_fixed_parameters(kNumFixedParameters);
  function.SetNumOptionalParameters(kNumOptionalParameters,
                                    kAreOptionalPositional);
  functions.SetAt(1, function);

  function_name = Symbols::New(thread, "baz");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, false,
                    false, false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(2, function);

  function_name = Symbols::New(thread, "Foo");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, true,
                    false, false, false, false, cls, TokenPosition::kMinSource);

  functions.SetAt(3, function);
  function_name = Symbols::New(thread, "Bar");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, true,
                    false, false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(4, function);
  function_name = Symbols::New(thread, "BaZ");
  function =
      Function::New(function_name, FunctionLayout::kRegularFunction, true,
                    false, false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(5, function);

  // Setup the functions in the class.
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
  }

  // The class can now be finalized.
  cls.Finalize();

  function_name = String::New("Foo");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(function.IsNull());
  function = cls.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.raw(), function.Owner());
  EXPECT(function.is_static());
  function_name = String::New("baz");
  function = Resolver::ResolveDynamicFunction(Z, cls, function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.raw(), function.Owner());
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
  auto isolate = thread->isolate();
  auto class_table = isolate->class_table();

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
  for (intptr_t i = 0; i < (1 << 16); ++i) {
    cls = CreateDummyClass(Symbols::TopLevel(), script);
    cls.Finalize();
    EXPECT(cls.id() > std::numeric_limits<uint16_t>::max());
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
    }
    cls.Finalize();

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
  isolate->heap()->CollectAllGarbage();

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
  EXPECT_NE(type_arguments1.raw(), type_arguments2.raw());
  OS::PrintErr("1: %s\n", type_arguments1.ToCString());
  OS::PrintErr("2: %s\n", type_arguments2.ToCString());
  EXPECT(type_arguments1.Equals(type_arguments2));
  TypeArguments& type_arguments3 = TypeArguments::Handle();
  type_arguments1.Canonicalize(thread, nullptr);
  type_arguments3 ^= type_arguments2.Canonicalize(thread, nullptr);
  EXPECT_EQ(type_arguments1.raw(), type_arguments3.raw());
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
  Dart_Handle lib_h = TestCase::LoadTestScript(kScript, NULL);
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
  empty_class.Finalize();

  EXPECT_EQ(kObjectAlignment, empty_class.host_instance_size());
  Instance& instance = Instance::Handle(Instance::New(empty_class));
  EXPECT_EQ(empty_class.raw(), instance.clazz());

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
  }
  one_field_class.Finalize();
  intptr_t header_size = sizeof(ObjectLayout);
  EXPECT_EQ(Utils::RoundUp((header_size + (1 * kWordSize)), kObjectAlignment),
            one_field_class.host_instance_size());
  EXPECT_EQ(header_size, field.HostOffset());
  EXPECT(!one_field_class.is_implemented());
  one_field_class.set_is_implemented();
  EXPECT(one_field_class.is_implemented());
}

ISOLATE_UNIT_TEST_CASE(Smi) {
  const Smi& smi = Smi::Handle(Smi::New(5));
  Object& smi_object = Object::Handle(smi.raw());
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
#if defined(ARCH_IS_64_BIT)
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
#if !defined(ARCH_IS_64_BIT)
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
  EXPECT_EQ(mint1.raw(), mint2.raw());
#endif
}

ISOLATE_UNIT_TEST_CASE(Double) {
  {
    const double dbl_const = 5.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.raw());
    EXPECT(dbl.IsDouble());
    EXPECT(dbl_object.IsDouble());
    EXPECT_EQ(dbl_const, dbl.value());
  }

  {
    const double dbl_const = -5.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.raw());
    EXPECT(dbl.IsDouble());
    EXPECT(dbl_object.IsDouble());
    EXPECT_EQ(dbl_const, dbl.value());
  }

  {
    const double dbl_const = 0.0;
    const Double& dbl = Double::Handle(Double::New(dbl_const));
    Object& dbl_object = Object::Handle(dbl.raw());
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
    EXPECT_EQ(dbl1.raw(), dbl2.raw());
    EXPECT_EQ(dbl1.raw(), dbl3.raw());
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
  intptr_t hash32 = String::Hash(String::FromUTF32(clef_utf32, 1));
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
      characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
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
      characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
  EXPECT(!str.IsOneByteString());
  EXPECT(str.IsExternalOneByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& empty_str = String::Handle(ExternalOneByteString::New(
      characters, 0, NULL, 0, NoopFinalizer, Heap::kNew));
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
      characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
  EXPECT(str.IsExternalTwoByteString());
  EXPECT_EQ(str.Length(), len);
  EXPECT(str.Equals("a\n\f\b\t\v\r\\$z"));
  const String& escaped_str =
      String::Handle(String::EscapeSpecialCharacters(str));
  EXPECT(escaped_str.Equals("a\\n\\f\\b\\t\\v\\r\\\\\\$z"));

  const String& empty_str = String::Handle(ExternalTwoByteString::New(
      characters, 0, NULL, 0, NoopFinalizer, Heap::kNew));
  const String& escaped_empty_str =
      String::Handle(String::EscapeSpecialCharacters(empty_str));
  EXPECT_EQ(empty_str.Length(), 0);
  EXPECT_EQ(escaped_empty_str.Length(), 0);
}

ISOLATE_UNIT_TEST_CASE(ExternalTwoByteString) {
  uint16_t characters[] = {0x1E6B, 0x1E85, 0x1E53};
  intptr_t len = ARRAY_SIZE(characters);

  const String& str = String::Handle(ExternalTwoByteString::New(
      characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
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
  EXPECT_EQ(one.raw(), eins.raw());
  EXPECT(one.raw() != two.raw());
  EXPECT(two.Equals(String::Handle(String::New("Zwei"))));
  EXPECT_EQ(two.raw(), Symbols::New(thread, "Zwei"));
  EXPECT_EQ(three.raw(), Symbols::New(thread, "Drei"));
  EXPECT_EQ(four.raw(), Symbols::New(thread, "Vier"));
  EXPECT_EQ(five.raw(), Symbols::New(thread, "Fuenf"));
  EXPECT_EQ(six.raw(), Symbols::New(thread, "Sechs"));
  EXPECT_EQ(seven.raw(), Symbols::New(thread, "Sieben"));
  EXPECT_EQ(eight.raw(), Symbols::New(thread, "Acht"));
  EXPECT_EQ(nine.raw(), Symbols::New(thread, "Neun"));
  EXPECT_EQ(ten.raw(), Symbols::New(thread, "Zehn"));

  // Make sure to cause symbol table overflow.
  for (int i = 0; i < 1024; i++) {
    char buf[256];
    Utils::SNPrint(buf, sizeof(buf), "%d", i);
    Symbols::New(thread, buf);
  }
  eins = Symbols::New(thread, "Eins");
  EXPECT_EQ(one.raw(), eins.raw());
  EXPECT_EQ(two.raw(), Symbols::New(thread, "Zwei"));
  EXPECT_EQ(three.raw(), Symbols::New(thread, "Drei"));
  EXPECT_EQ(four.raw(), Symbols::New(thread, "Vier"));
  EXPECT_EQ(five.raw(), Symbols::New(thread, "Fuenf"));
  EXPECT_EQ(six.raw(), Symbols::New(thread, "Sechs"));
  EXPECT_EQ(seven.raw(), Symbols::New(thread, "Sieben"));
  EXPECT_EQ(eight.raw(), Symbols::New(thread, "Acht"));
  EXPECT_EQ(nine.raw(), Symbols::New(thread, "Neun"));
  EXPECT_EQ(ten.raw(), Symbols::New(thread, "Zehn"));

  // Symbols from Strings.
  eins = String::New("Eins");
  EXPECT(!eins.IsSymbol());
  String& ein_symbol = String::Handle(Symbols::New(thread, eins));
  EXPECT_EQ(one.raw(), ein_symbol.raw());
  EXPECT(one.raw() != eins.raw());

  uint16_t char16[] = {'E', 'l', 'f'};
  String& elf1 = String::Handle(Symbols::FromUTF16(thread, char16, 3));
  int32_t char32[] = {'E', 'l', 'f'};
  String& elf2 = String::Handle(
      Symbols::New(thread, String::Handle(String::FromUTF32(char32, 3))));
  EXPECT(elf1.IsSymbol());
  EXPECT(elf2.IsSymbol());
  EXPECT_EQ(elf1.raw(), Symbols::New(thread, "Elf"));
  EXPECT_EQ(elf2.raw(), Symbols::New(thread, "Elf"));
}

ISOLATE_UNIT_TEST_CASE(SymbolUnicode) {
  uint16_t monkey_utf16[] = {0xd83d, 0xdc35};  // Unicode Monkey Face.
  String& monkey = String::Handle(Symbols::FromUTF16(thread, monkey_utf16, 2));
  EXPECT(monkey.IsSymbol());
  const char monkey_utf8[] = {'\xf0', '\x9f', '\x90', '\xb5', 0};
  EXPECT_EQ(monkey.raw(), Symbols::New(thread, monkey_utf8));

  int32_t kMonkeyFace = 0x1f435;
  String& monkey2 = String::Handle(
      Symbols::New(thread, String::Handle(String::FromUTF32(&kMonkeyFace, 1))));
  EXPECT_EQ(monkey.raw(), monkey2.raw());

  // Unicode cat face with tears of joy.
  int32_t kCatFaceWithTearsOfJoy = 0x1f639;
  String& cat = String::Handle(Symbols::New(
      thread, String::Handle(String::FromUTF32(&kCatFaceWithTearsOfJoy, 1))));

  uint16_t cat_utf16[] = {0xd83d, 0xde39};
  String& cat2 = String::Handle(Symbols::FromUTF16(thread, cat_utf16, 2));
  EXPECT(cat2.IsSymbol());
  EXPECT_EQ(cat2.raw(), cat.raw());
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
  EXPECT_EQ(array.raw(), element.raw());
  element = array.At(1);
  EXPECT(element.IsNull());
  element = array.At(2);
  EXPECT_EQ(array.raw(), element.raw());

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

  EXPECT_EQ(1, Object::zero_array().Length());
  element = Object::zero_array().At(0);
  EXPECT(Smi::Cast(element).IsZero());

  array.MakeImmutable();
  Object& obj = Object::Handle(array.raw());
  EXPECT(obj.IsArray());
}

static void TestIllegalArrayLength(intptr_t length) {
  char buffer[1024];
  Utils::SNPrint(buffer, sizeof(buffer),
                 "main() {\n"
                 "  List.filled(%" Pd
                 ", null);\n"
                 "}\n",
                 length);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
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
  addr = ObjectLayout::ToAddr(new_array.raw());
  obj = ObjectLayout::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(2, new_array.Length());
  addr += used_size;
  obj = ObjectLayout::FromAddr(addr);
  EXPECT(obj.IsTypedData());
  left_over_array ^= obj.raw();
  EXPECT_EQ(4 * kWordSize - TypedData::InstanceSize(0),
            left_over_array.Length());

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
  addr = ObjectLayout::ToAddr(new_array.raw());
  obj = ObjectLayout::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(3, new_array.Length());
  addr += used_size;
  obj = ObjectLayout::FromAddr(addr);
  if (TypedData::InstanceSize(0) <= 2 * kWordSize) {
    EXPECT(obj.IsTypedData());
    left_over_array ^= obj.raw();
    EXPECT_EQ(2 * kWordSize - TypedData::InstanceSize(0),
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
  addr = ObjectLayout::ToAddr(new_array.raw());
  obj = ObjectLayout::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(1, new_array.Length());
  addr += used_size;
  obj = ObjectLayout::FromAddr(addr);
  EXPECT(obj.IsTypedData());
  left_over_array ^= obj.raw();
  EXPECT_EQ(8 * kWordSize - TypedData::InstanceSize(0),
            left_over_array.Length());

  // 4. Verify that GC can handle the filler object for a large array.
  array = GrowableObjectArray::New((1 * MB) >> kWordSizeLog2);
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 1; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  Heap* heap = Isolate::Current()->heap();
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

static void CheckLinesWithOffset(Zone* zone, const intptr_t offset) {
  const char* url_chars = "";
  // Nine lines, mix of \n, \r, \r\n line terminators, lines 3, 4, 7, and 8
  // are non-empty. Ends with a \r as a double-check that the \r followed by
  // \n check doesn't go out of bounds.
  //
  // Line starts:             1 2 3    4      5 6   7    8    9
  const char* source_chars = "\n\nxyz\nabc\r\n\n\r\ndef\rghi\r";
  const String& url = String::Handle(zone, String::New(url_chars));
  const String& source = String::Handle(zone, String::New(source_chars));
  const Script& script = Script::Handle(zone, Script::New(url, source));
  EXPECT(!script.IsNull());
  EXPECT(script.IsScript());
  script.SetLocationOffset(offset, 10);
  auto& str = String::Handle(zone);
  str = script.GetLine(offset + 1);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 2);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 3);
  EXPECT_STREQ("xyz", str.ToCString());
  str = script.GetLine(offset + 4);
  EXPECT_STREQ("abc", str.ToCString());
  str = script.GetLine(offset + 5);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 6);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 7);
  EXPECT_STREQ("def", str.ToCString());
  str = script.GetLine(offset + 8);
  EXPECT_STREQ("ghi", str.ToCString());
  str = script.GetLine(offset + 9);
  EXPECT_STREQ("", str.ToCString());
  // Using "column" of \r at end of line for to_column.
  str = script.GetSnippet(offset + 3, 1, offset + 7, 4);
  EXPECT_STREQ("xyz\nabc\r\n\n\r\ndef", str.ToCString());
  // Lines not in the range of (1-based) line indices in the source should
  // return the empty string.
  str = script.GetLine(-500);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(0);
  EXPECT_STREQ("", str.ToCString());
  if (offset > 0) {
    str = script.GetLine(1);  // Absolute, not relative to offset.
    EXPECT_STREQ("", str.ToCString());
  }
  if (offset > 2) {
    str = script.GetLine(3);  // Absolute, not relative to offset.
    EXPECT_STREQ("", str.ToCString());
  }
  str = script.GetLine(offset - 500);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 10);
  EXPECT_STREQ("", str.ToCString());
  str = script.GetLine(offset + 10000);
  EXPECT_STREQ("", str.ToCString());
  // Snippets not contained within the source should be the null string.
  str = script.GetSnippet(-1, 1, 2, 2);
  EXPECT(str.IsNull());
  str = script.GetSnippet(offset - 1, 1, offset + 2, 2);
  EXPECT(str.IsNull());
  str = script.GetSnippet(offset + 5, 15, offset + 6, 2);
  EXPECT(str.IsNull());
  str = script.GetSnippet(offset + 20, 1, offset + 30, 1);
  EXPECT(str.IsNull());
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

  CheckLinesWithOffset(Z, 0);
  CheckLinesWithOffset(Z, 500);
  CheckLinesWithOffset(Z, 10000);

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
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}

ISOLATE_UNIT_TEST_CASE(Context) {
  const int kNumVariables = 5;
  const Context& parent_context = Context::Handle(Context::New(0));
  const Context& context = Context::Handle(Context::New(kNumVariables));
  context.set_parent(parent_context);
  EXPECT_EQ(kNumVariables, context.num_variables());
  EXPECT(Context::Handle(context.parent()).raw() == parent_context.raw());
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
      new LocalScope(NULL, parent_scope_function_level, 0);

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
  var_ta = local_scope->LookupVariable(ta, test_only);
  EXPECT(var_ta->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_ta->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(ta) == var_ta);  // Alias.

  var_a = local_scope->LookupVariable(a, test_only);
  EXPECT(var_a->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_a->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(a) == var_a);  // Alias.

  var_b = local_scope->LookupVariable(b, test_only);
  EXPECT(!var_b->is_captured());
  EXPECT_EQ(local_scope_function_level, var_b->owner()->function_level());
  EXPECT(local_scope->LocalLookupVariable(b) == var_b);

  test_only = true;  // Please, do not insert alias.
  var_c = local_scope->LookupVariable(c, test_only);
  EXPECT(!var_c->is_captured());
  EXPECT_EQ(parent_scope_function_level, var_c->owner()->function_level());
  // c is not in local_scope.
  EXPECT(local_scope->LocalLookupVariable(c) == NULL);

  test_only = false;  // Please, insert alias.
  var_c = local_scope->LookupVariable(c, test_only);
  EXPECT(var_c->is_captured());

  EXPECT_EQ(4, local_scope->num_variables());         // ta, a, b, c.
  EXPECT_EQ(3, local_scope->NumCapturedVariables());  // ta, a, c.

  const VariableIndex first_parameter_index(0);
  const int num_parameters = 0;
  const VariableIndex first_local_index(-1);
  bool found_captured_vars = false;
  VariableIndex next_index = parent_scope->AllocateVariables(
      first_parameter_index, num_parameters, first_local_index, NULL,
      &found_captured_vars);
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

  var_ta = outer_scope->LocalLookupVariable(ta);
  EXPECT(var_ta->is_captured());
  EXPECT_EQ(0, var_ta->index().value());  // First index.
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_ta->owner()->context_level());  // Adjusted context level.

  var_a = outer_scope->LocalLookupVariable(a);
  EXPECT(var_a->is_captured());
  EXPECT_EQ(1, var_a->index().value());  // First index.
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_a->owner()->context_level());  // Adjusted context level.

  // var b was not captured.
  EXPECT(outer_scope->LocalLookupVariable(b) == NULL);

  var_c = outer_scope->LocalLookupVariable(c);
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
  parent =
      Function::New(parent_name, FunctionLayout::kRegularFunction, false, false,
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
  const Closure& closure = Closure::Handle(
      Closure::New(Object::null_type_arguments(), Object::null_type_arguments(),
                   function, context));
  const Class& closure_class = Class::Handle(closure.clazz());
  EXPECT_EQ(closure_class.id(), kClosureCid);
  const Function& closure_function = Function::Handle(closure.function());
  EXPECT_EQ(closure_function.raw(), function.raw());
  const Context& closure_context = Context::Handle(closure.context());
  EXPECT_EQ(closure_context.raw(), context.raw());
}

ISOLATE_UNIT_TEST_CASE(ObjectPrinting) {
  // Simple Smis.
  EXPECT_STREQ("2", Smi::Handle(Smi::New(2)).ToCString());
  EXPECT_STREQ("-15", Smi::Handle(Smi::New(-15)).ToCString());

  // bool class and true/false values.
  ObjectStore* object_store = Isolate::Current()->object_store();
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
  return Function::New(function_name, FunctionLayout::kRegularFunction, true,
                       false, false, false, false, owner_class,
                       TokenPosition::kMinSource);
}

// Test for Code and Instruction object creation.
ISOLATE_UNIT_TEST_CASE(Code) {
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.raw(), Instructions::FromPayloadStart(payload_start));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT_EQ(1, Smi::Cast(result).Value());
}

// Test for immutability of generated instructions. The test crashes with a
// segmentation fault when writing into it.
ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(CodeImmutability, "Crash") {
  bool stack_trace_collection_enabled =
      MallocHooks::stack_trace_collection_enabled();
  MallocHooks::set_stack_trace_collection_enabled(false);
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.raw(), Instructions::FromPayloadStart(payload_start));
  // Try writing into the generated code, expected to crash.
  *(reinterpret_cast<char*>(payload_start) + 1) = 1;
  if (!FLAG_write_protect_code) {
    // Since this test is expected to crash, crash if write protection of code
    // is switched off.
    FATAL("Test requires --write-protect-code; skip by forcing expected crash");
  }
  MallocHooks::set_stack_trace_collection_enabled(
      stack_trace_collection_enabled);
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
  bool stack_trace_collection_enabled =
      MallocHooks::stack_trace_collection_enabled();
  MallocHooks::set_stack_trace_collection_enabled(false);
  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  const Function& function = Function::Handle(CreateFunction("Test_Code"));
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  Instructions& instructions = Instructions::Handle(code.instructions());
  uword payload_start = code.PayloadStart();
  const uword unchecked_offset = code.UncheckedEntryPoint() - code.EntryPoint();
  EXPECT_EQ(instructions.raw(), Instructions::FromPayloadStart(payload_start));
  // Execute the executable view of the instructions (default).
  Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT_EQ(1, Smi::Cast(result).Value());
  // Switch to the writeable but non-executable view of the instructions.
  instructions ^= OldPage::ToWritable(instructions.raw());
  payload_start = instructions.PayloadStart();
  EXPECT_EQ(instructions.raw(), Instructions::FromPayloadStart(payload_start));
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
  MallocHooks::set_stack_trace_collection_enabled(
      stack_trace_collection_enabled);
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
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(result.raw()->IsHeapObject());
  String& string_object = String::Handle();
  string_object ^= result.raw();
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
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(Smi::Cast(result).Value() == kSmiTestValue);
}

#if defined(ARCH_IS_64_BIT)
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
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &_assembler_, Code::PoolAttachment::kAttachPool));
  function.AttachCode(code);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, Array::empty_array()));
  EXPECT(Smi::Cast(result).Value() == kSmiTestValue);
}
#endif  // ARCH_IS_64_BIT

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
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 10, 1,
                         TokenPosition::Deserialize(20), 1, 1);
  builder->AddDescriptor(PcDescriptorsLayout::kDeopt, 20, 2,
                         TokenPosition::Deserialize(30), 0, -1);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 30, 3,
                         TokenPosition::Deserialize(40), 1, 10);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 10, 4,
                         TokenPosition::Deserialize(40), 2, 20);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 10, 5,
                         TokenPosition::Deserialize(80), 3, 30);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 80, 6,
                         TokenPosition::Deserialize(150), 3, 30);

  PcDescriptors& descriptors = PcDescriptors::Handle();
  descriptors ^= builder->FinalizePcDescriptors(0);

  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      Function::Handle(CreateFunction("Test_Code")), nullptr, &_assembler_,
      Code::PoolAttachment::kAttachPool));
  code.set_pc_descriptors(descriptors);

  // Verify the PcDescriptor entries by accessing them.
  const PcDescriptors& pc_descs = PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(pc_descs, PcDescriptorsLayout::kAnyKind);

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(1, iter.YieldIndex());
  EXPECT_EQ(20, iter.TokenPos().Pos());
  EXPECT_EQ(1, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(10), iter.PcOffset());
  EXPECT_EQ(1, iter.DeoptId());
  EXPECT_EQ(PcDescriptorsLayout::kOther, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(-1, iter.YieldIndex());
  EXPECT_EQ(30, iter.TokenPos().Pos());
  EXPECT_EQ(PcDescriptorsLayout::kDeopt, iter.Kind());

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
  EXPECT_EQ(PcDescriptorsLayout::kOther, iter.Kind());

  EXPECT_EQ(false, iter.MoveNext());
}

ISOLATE_UNIT_TEST_CASE(PcDescriptorsLargeDeltas) {
  DescriptorList* builder = new DescriptorList(thread->zone());

  // kind, pc_offset, deopt_id, token_pos, try_index
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 100, 1,
                         TokenPosition::Deserialize(200), 1, 10);
  builder->AddDescriptor(PcDescriptorsLayout::kDeopt, 200, 2,
                         TokenPosition::Deserialize(300), 0, -1);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 300, 3,
                         TokenPosition::Deserialize(400), 1, 10);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 100, 4,
                         TokenPosition::Deserialize(0), 2, 20);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 100, 5,
                         TokenPosition::Deserialize(800), 3, 30);
  builder->AddDescriptor(PcDescriptorsLayout::kOther, 800, 6,
                         TokenPosition::Deserialize(150), 3, 30);

  PcDescriptors& descriptors = PcDescriptors::Handle();
  descriptors ^= builder->FinalizePcDescriptors(0);

  extern void GenerateIncrement(compiler::Assembler * assembler);
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler _assembler_(&object_pool_builder);
  GenerateIncrement(&_assembler_);
  Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      Function::Handle(CreateFunction("Test_Code")), nullptr, &_assembler_,
      Code::PoolAttachment::kAttachPool));
  code.set_pc_descriptors(descriptors);

  // Verify the PcDescriptor entries by accessing them.
  const PcDescriptors& pc_descs = PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(pc_descs, PcDescriptorsLayout::kAnyKind);

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(10, iter.YieldIndex());
  EXPECT_EQ(200, iter.TokenPos().Pos());
  EXPECT_EQ(1, iter.TryIndex());
  EXPECT_EQ(static_cast<uword>(100), iter.PcOffset());
  EXPECT_EQ(1, iter.DeoptId());
  EXPECT_EQ(PcDescriptorsLayout::kOther, iter.Kind());

  EXPECT_EQ(true, iter.MoveNext());
  EXPECT_EQ(-1, iter.YieldIndex());
  EXPECT_EQ(300, iter.TokenPos().Pos());
  EXPECT_EQ(PcDescriptorsLayout::kDeopt, iter.Kind());

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
  EXPECT_EQ(PcDescriptorsLayout::kOther, iter.Kind());

  EXPECT_EQ(false, iter.MoveNext());
}

static ClassPtr CreateTestClass(const char* name) {
  const String& class_name =
      String::Handle(Symbols::New(Thread::Current(), name));
  const Class& cls =
      Class::Handle(CreateDummyClass(class_name, Script::Handle()));
  return cls.raw();
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
    thread->isolate_group()->RegisterStaticField(field, Instance::sentinel());
  }
  return field.raw();
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
    EXPECT((cls.raw() == ae66.raw()) || (cls.raw() == re44.raw()));
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
  return Function::New(function_name, FunctionLayout::kRegularFunction,
                       is_static, is_const, is_abstract, is_external, is_native,
                       cls, TokenPosition::kMinSource);
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
  EXPECT_EQ(function.raw(), o1.Owner());
  EXPECT_EQ(0, o1.NumberOfChecks());
  EXPECT_EQ(target_name.raw(), o1.target_name());
  EXPECT_EQ(args_descriptor.raw(), o1.arguments_descriptor());

  const Function& target1 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kSmiCid, target1);
  EXPECT_EQ(1, o1.NumberOfChecks());
  EXPECT_EQ(1, o1.NumberOfUsedChecks());
  intptr_t test_class_id = -1;
  Function& test_target = Function::Handle();
  o1.GetOneClassCheckAt(0, &test_class_id, &test_target);
  EXPECT_EQ(kSmiCid, test_class_id);
  EXPECT_EQ(target1.raw(), test_target.raw());
  EXPECT_EQ(kSmiCid, o1.GetCidAt(0));
  GrowableArray<intptr_t> test_class_ids;
  o1.GetCheckAt(0, &test_class_ids, &test_target);
  EXPECT_EQ(1, test_class_ids.length());
  EXPECT_EQ(kSmiCid, test_class_ids[0]);
  EXPECT_EQ(target1.raw(), test_target.raw());

  const Function& target2 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kDoubleCid, target2);
  EXPECT_EQ(2, o1.NumberOfChecks());
  EXPECT_EQ(2, o1.NumberOfUsedChecks());
  o1.GetOneClassCheckAt(1, &test_class_id, &test_target);
  EXPECT_EQ(kDoubleCid, test_class_id);
  EXPECT_EQ(target2.raw(), test_target.raw());
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
  EXPECT_EQ(function.raw(), o2.Owner());
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
  EXPECT_EQ(target1.raw(), test_target.raw());

  // Check ICData for unoptimized static calls.
  const intptr_t kNumArgsChecked = 0;
  const ICData& scall_icdata = ICData::Handle(
      ICData::NewForStaticCall(function, target1, args_descriptor, 57,
                               kNumArgsChecked, ICData::kInstance));
  EXPECT_EQ(target1.raw(), scall_icdata.GetTargetAt(0));
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
  EXPECT_EQ(class_id_or_fun.raw(), test_class_id_or_fun.raw());
  EXPECT_EQ(dest_type.raw(), test_dest_type.raw());
  EXPECT_EQ(targ_0.raw(), test_targ_0.raw());
  EXPECT_EQ(targ_1.raw(), test_targ_1.raw());
  EXPECT_EQ(targ_2.raw(), test_targ_2.raw());
  EXPECT_EQ(targ_3.raw(), test_targ_3.raw());
  EXPECT_EQ(targ_4.raw(), test_targ_4.raw());
  EXPECT_EQ(Bool::True().raw(), test_result.raw());
}

ISOLATE_UNIT_TEST_CASE(MegamorphicCache) {
  const auto& name = String::Handle(String::New("name"));
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
    EXPECT(cache.Lookup(cidA) == valueA.raw());

    EXPECT(cache.Lookup(cidB) == Object::null());
    cache.EnsureContains(cidB, valueB);
    EXPECT(cache.Lookup(cidB) == valueB.raw());
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
      strlen(ext_mangled_str), NULL, 0, NoopFinalizer, Heap::kNew);
  EXPECT(ext_mangled_name.IsExternalOneByteString());
  ext_bare_name = ExternalOneByteString::New(
      reinterpret_cast<const uint8_t*>(ext_bare_str), strlen(ext_bare_str),
      NULL, 0, NoopFinalizer, Heap::kNew);
  EXPECT(ext_bare_name.IsExternalOneByteString());
  ext_bad_bare_name = ExternalOneByteString::New(
      reinterpret_cast<const uint8_t*>(ext_bad_bare_str),
      strlen(ext_bad_bare_str), NULL, 0, NoopFinalizer, Heap::kNew);
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
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);

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
           "#6      MyClass.foo (%1$s:32:14)\n"
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
  GCTestHelper::CollectAllGarbage();
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
  GCTestHelper::CollectAllGarbage();
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
  GCTestHelper::CollectAllGarbage();
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
  GCTestHelper::CollectAllGarbage();
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
  GCTestHelper::CollectAllGarbage();
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
  EXPECT_EQ(returned_referent.raw(), library.raw());

  const MirrorReference& other_reference =
      MirrorReference::Handle(MirrorReference::New(Object::Handle()));
  EXPECT_NE(reference.raw(), other_reference.raw());
  other_reference.set_referent(library);
  EXPECT_NE(reference.raw(), other_reference.raw());
  EXPECT_EQ(reference.referent(), other_reference.referent());

  Object& obj = Object::Handle(reference.raw());
  EXPECT(obj.IsMirrorReference());
}

static FunctionPtr GetFunction(const Class& cls, const char* name) {
  Thread* thread = Thread::Current();
  const auto& error = cls.EnsureIsFinalized(thread);
  EXPECT(error == Error::null());
  const Function& result = Function::Handle(Resolver::ResolveDynamicFunction(
      Z, cls, String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.raw();
}

static FunctionPtr GetStaticFunction(const Class& cls, const char* name) {
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  EXPECT(error == Error::null());
  const Function& result = Function::Handle(
      cls.LookupStaticFunction(String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.raw();
}

static FieldPtr GetField(const Class& cls, const char* name) {
  const Field& field =
      Field::Handle(cls.LookupField(String::Handle(String::New(name))));
  EXPECT(!field.IsNull());
  return field.raw();
}

static ClassPtr GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.raw();
}

ISOLATE_UNIT_TEST_CASE(FindClosureIndex) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));
  const Array& functions = Array::Handle(Array::New(1));
  const Isolate* iso = Isolate::Current();

  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New(thread, "foo_papa"));
  parent =
      Function::New(parent_name, FunctionLayout::kRegularFunction, false, false,
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
  iso->AddClosureFunction(function);

  // The closure should return a valid index.
  intptr_t good_closure_index = iso->FindClosureIndex(function);
  EXPECT_GE(good_closure_index, 0);
  // The parent function should return an invalid index.
  intptr_t bad_closure_index = iso->FindClosureIndex(parent);
  EXPECT_EQ(bad_closure_index, -1);

  // Retrieve closure function via index.
  Function& func_from_index = Function::Handle();
  func_from_index ^= iso->ClosureFunctionFromIndex(good_closure_index);
  // Same closure function.
  EXPECT_EQ(func_from_index.raw(), function.raw());
}

ISOLATE_UNIT_TEST_CASE(FindInvocationDispatcherFunctionIndex) {
  const String& class_name = String::Handle(Symbols::New(thread, "MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(CreateDummyClass(class_name, script));
  ClassFinalizer::FinalizeTypesInClass(cls);

  const Array& functions = Array::Handle(Array::New(1));
  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New(thread, "foo_papa"));
  parent =
      Function::New(parent_name, FunctionLayout::kRegularFunction, false, false,
                    false, false, false, cls, TokenPosition::kMinSource);
  functions.SetAt(0, parent);
  {
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(functions);
  }
  cls.Finalize();

  // Add invocation dispatcher.
  const String& invocation_dispatcher_name =
      String::Handle(Symbols::New(thread, "myMethod"));
  const Array& args_desc = Array::Handle(ArgumentsDescriptor::NewBoxed(0, 1));
  Function& invocation_dispatcher = Function::Handle();
  invocation_dispatcher ^= cls.GetInvocationDispatcher(
      invocation_dispatcher_name, args_desc,
      FunctionLayout::kNoSuchMethodDispatcher, true /* create_if_absent */);
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
  EXPECT_EQ(invocation_dispatcher.raw(),
            invocation_dispatcher_from_index.raw());
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

  Dart_Handle h_lib = TestCase::LoadTestScript(kScriptChars.get(), NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
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
  TestCase::LoadTestScript(kScriptChars, NULL);
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
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  // Run function A.b one time.
  Dart_Handle result = Dart_Invoke(lib, NewString("test"), 0, NULL);
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
  ObjectStore* object_store = Isolate::Current()->object_store();
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
  char buffer[1024];
  Isolate* isolate = Isolate::Current();

  // Class reference
  {
    JSONStream js;
    Class& cls = Class::Handle(isolate->object_store()->bool_class());
    cls.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\",\"name\":\"bool\"}",
        buffer);
  }
  // Function reference
  {
    Thread* thread = Thread::Current();
    JSONStream js;
    Class& cls = Class::Handle(isolate->object_store()->bool_class());
    const String& func_name = String::Handle(String::New("toString"));
    Function& func =
        Function::Handle(Resolver::ResolveFunction(Z, cls, func_name));
    ASSERT(!func.IsNull());
    func.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Function\",\"fixedId\":true,"
        "\"id\":\"\",\"name\":\"toString\","
        "\"owner\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"bool\"},"
        "\"_kind\":\"RegularFunction\","
        "\"static\":false,\"const\":false,"
        "\"_intrinsic\":false,\"_native\":false}",
        buffer);
  }
  // Library reference
  {
    JSONStream js;
    Library& lib = Library::Handle(isolate->object_store()->core_library());
    lib.PrintJSON(&js, true);
    ElideJSONSubstring("libraries", js.ToCString(), buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Library\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"dart.core\",\"uri\":\"dart:core\"}",
        buffer);
  }
  // Bool reference
  {
    JSONStream js;
    Bool::True().PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Bool\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"bool\"},"
        "\"kind\":\"Bool\","
        "\"fixedId\":true,"
        "\"id\":\"objects\\/bool-true\",\"valueAsString\":\"true\"}",
        buffer);
  }
  // Smi reference
  {
    JSONStream js;
    const Integer& smi = Integer::Handle(Integer::New(7));
    smi.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("_Smi@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Smi\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_Smi\","
        "\"_vmName\":\"\"},"
        "\"kind\":\"Int\","
        "\"fixedId\":true,"
        "\"id\":\"objects\\/int-7\",\"valueAsString\":\"7\"}",
        buffer);
  }
  // Mint reference
  {
    JSONStream js;
    const Integer& smi = Integer::Handle(Integer::New(Mint::kMinValue));
    smi.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_Mint@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Mint\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_Mint\",\"_vmName\":\"\"},"
        "\"kind\":\"Int\","
        "\"id\":\"\",\"valueAsString\":\"-9223372036854775808\"}",
        buffer);
  }
  // Double reference
  {
    JSONStream js;
    const Double& dub = Double::Handle(Double::New(0.1234));
    dub.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_Double@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Double\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_Double\",\"_vmName\":\"\"},"
        "\"kind\":\"Double\","
        "\"id\":\"\",\"valueAsString\":\"0.1234\"}",
        buffer);
  }
  // String reference
  {
    JSONStream js;
    const String& str = String::Handle(String::New("dw"));
    str.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_OneByteString@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"String\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_OneByteString\",\"_vmName\":\"\"},"
        "\"kind\":\"String\","
        "\"id\":\"\",\"length\":2,\"valueAsString\":\"dw\"}",
        buffer);
  }
  // Array reference
  {
    JSONStream js;
    const Array& array = Array::Handle(Array::New(0));
    array.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_List@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Array\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_List\",\"_vmName\":\"\"},"
        "\"kind\":\"List\","
        "\"id\":\"\",\"length\":0}",
        buffer);
  }
  // GrowableObjectArray reference
  {
    JSONStream js;
    const GrowableObjectArray& array =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    array.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_GrowableList@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"GrowableObjectArray\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_GrowableList\","
        "\"_vmName\":\"\"},"
        "\"kind\":\"List\","
        "\"id\":\"\",\"length\":0}",
        buffer);
  }
  // LinkedHashMap reference
  {
    JSONStream js;
    const LinkedHashMap& array =
        LinkedHashMap::Handle(LinkedHashMap::NewDefault());
    array.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_InternalLinkedHashMap@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"LinkedHashMap\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_InternalLinkedHashMap\",\"_vmName\":\"\"},"
        "\"kind\":\"Map\","
        "\"id\":\"\","
        "\"length\":0}",
        buffer);
  }
  // UserTag reference
  {
    JSONStream js;
    Instance& tag = Instance::Handle(isolate->default_tag());
    tag.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_UserTag@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"UserTag\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_UserTag\",\"_vmName\":\"\"},"
        "\"kind\":\"PlainInstance\","
        "\"id\":\"\"}",
        buffer);
  }
  // Type reference
  // TODO(turnidge): Add in all of the other Type siblings.
  {
    JSONStream js;
    Instance& type = Instance::Handle(isolate->object_store()->bool_type());
    type.PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    ElideJSONSubstring("objects", buffer, buffer);
    ElideJSONSubstring("_Type@", buffer, buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"Type\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"_Type\",\"_vmName\":\"\"},"
        "\"kind\":\"Type\","
        "\"fixedId\":true,\"id\":\"\","
        "\"typeClass\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"bool\"},\"name\":\"bool\"}",
        buffer);
  }
  // Null reference
  {
    JSONStream js;
    Object::null_object().PrintJSON(&js, true);
    ElideJSONSubstring("classes", js.ToCString(), buffer);
    EXPECT_STREQ(
        "{\"type\":\"@Instance\","
        "\"_vmType\":\"null\","
        "\"class\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
        "\"name\":\"Null\"},"
        "\"kind\":\"Null\","
        "\"fixedId\":true,"
        "\"id\":\"objects\\/null\","
        "\"valueAsString\":\"null\"}",
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

  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  TransitionNativeToVM transition(thread);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  const Class& clazz = Class::Handle(GetClass(lib, "A"));
  EXPECT(!clazz.IsNull());
  const Instance& a0 = Instance::Handle(Instance::New(clazz));
  const Instance& a1 = Instance::Handle(Instance::New(clazz));
  EXPECT(a0.raw() != a1.raw());
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

  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);
  Integer& result = Integer::Handle();
  result ^= Api::UnwrapHandle(h_result);
  String& foo = String::Handle(String::New("foo"));
  Integer& expected = Integer::Handle();
  expected ^= foo.HashCode();
  EXPECT(result.IsIdenticalTo(expected));
}

static void CheckIdenticalHashStructure(Thread* T,
                                        const Instance& a,
                                        const Instance& b) {
  const char* kScript =
      "(a, b) {\n"
      "  if (a._usedData != b._usedData ||\n"
      "      a._deletedKeys != b._deletedKeys ||\n"
      "      a._hashMask != b._hashMask ||\n"
      "      a._index.length != b._index.length ||\n"
      "      a._data.length != b._data.length) {\n"
      "    return false;\n"
      "  }\n"
      "  for (var i = 0; i < a._index.length; ++i) {\n"
      "    if (a._index[i] != b._index[i]) {\n"
      "      return false;\n"
      "    }\n"
      "  }\n"
      "  for (var i = 0; i < a._data.length; ++i) {\n"
      "    var ad = a._data[i];\n"
      "    var bd = b._data[i];\n"
      "    if (!identical(ad, bd) && !(ad == a && bd == b)) {\n"
      "      return false;\n"
      "    }\n"
      "  }\n"
      "  return true;\n"
      "}(a, b)";
  String& name = String::Handle();
  Array& param_names = Array::Handle(Array::New(2));
  name = String::New("a");
  param_names.SetAt(0, name);
  name = String::New("b");
  param_names.SetAt(1, name);
  Array& param_values = Array::Handle(Array::New(2));
  param_values.SetAt(0, a);
  param_values.SetAt(1, b);
  name = String::New(kScript);
  Library& lib = Library::Handle(Library::CollectionLibrary());
  EXPECT(Api::UnwrapHandle(TestCase::EvaluateExpression(
             lib, name, param_names, param_values)) == Bool::True().raw());
}

TEST_CASE(LinkedHashMap) {
  // Check that initial index size and hash mask match in Dart vs. C++.
  // 1. Create an empty custom linked hash map in Dart.
  const char* kScript =
      "import 'dart:collection';\n"
      "makeMap() {\n"
      "  bool Function(dynamic, dynamic) eq = (a, b) => true;\n"
      "  int Function(dynamic) hc = (a) => 42;\n"
      "  return new LinkedHashMap(equals: eq, hashCode: hc);\n"
      "}";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("makeMap"), 0, NULL);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);

  // 2. Create an empty internalized LinkedHashMap in C++.
  Instance& dart_map = Instance::Handle();
  dart_map ^= Api::UnwrapHandle(h_result);
  LinkedHashMap& cc_map = LinkedHashMap::Handle(LinkedHashMap::NewDefault());

  // 3. Expect them to have identical structure.
  CheckIdenticalHashStructure(thread, dart_map, cc_map);
}

TEST_CASE(LinkedHashMap_iteration) {
  const char* kScript =
      "makeMap() {\n"
      "  var map = {'x': 3, 'y': 4, 'z': 5, 'w': 6};\n"
      "  map.remove('y');\n"
      "  map.remove('w');\n"
      "  return map;\n"
      "}";
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Dart_Handle h_result = Dart_Invoke(h_lib, NewString("makeMap"), 0, NULL);
  EXPECT_VALID(h_result);

  TransitionNativeToVM transition(thread);
  Instance& dart_map = Instance::Handle();
  dart_map ^= Api::UnwrapHandle(h_result);
  ASSERT(dart_map.IsLinkedHashMap());
  const LinkedHashMap& cc_map = LinkedHashMap::Cast(dart_map);

  EXPECT_EQ(2, cc_map.Length());

  LinkedHashMap::Iterator iterator(cc_map);
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
    const String* data[3] = {&Symbols::FallThroughError(), &Symbols::Dot(),
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
        characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str, &Symbols::Dot(), &str};
    CheckConcatAll(data, 3);
  }

  {
    uint16_t characters[] = {'a',  '\n', '\f', '\b', '\t',
                             '\v', '\r', '\\', '$',  'z'};
    intptr_t len = ARRAY_SIZE(characters);

    const String& str = String::Handle(ExternalTwoByteString::New(
        characters, len, NULL, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str, &Symbols::Dot(), &str};
    CheckConcatAll(data, 3);
  }

  {
    uint8_t characters1[] = {0xF6, 0xF1, 0xE9};
    intptr_t len1 = ARRAY_SIZE(characters1);

    const String& str1 = String::Handle(ExternalOneByteString::New(
        characters1, len1, NULL, 0, NoopFinalizer, Heap::kNew));

    uint16_t characters2[] = {'a',  '\n', '\f', '\b', '\t',
                              '\v', '\r', '\\', '$',  'z'};
    intptr_t len2 = ARRAY_SIZE(characters2);

    const String& str2 = String::Handle(ExternalTwoByteString::New(
        characters2, len2, NULL, 0, NoopFinalizer, Heap::kNew));
    const String* data[3] = {&str1, &Symbols::Dot(), &str2};
    CheckConcatAll(data, 3);
  }

  {
    const String& empty = String::Handle(String::New(""));
    const String* data[3] = {&Symbols::FallThroughError(), &empty,
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

}  // namespace dart
