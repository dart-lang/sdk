// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/assembler.h"
#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Class) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New("MyClass"));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(
      Class::New(class_name, script, Scanner::kDummyTokenIndex));

  // Class has no fields.
  const Array& no_fields = Array::Handle(Object::empty_array());
  cls.SetFields(no_fields);

  // Create and populate the function arrays.
  const Array& functions = Array::Handle(Array::New(6));
  Function& function = Function::Handle();
  String& function_name = String::Handle();
  function_name = Symbols::New("foo");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      false, false, false, false, cls, 0);
  functions.SetAt(0, function);
  function_name = Symbols::New("bar");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      false, false, false, false, cls, 0);

  const int kNumFixedParameters = 2;
  const int kNumOptionalParameters = 3;
  const bool kAreOptionalPositional = true;
  function.set_num_fixed_parameters(kNumFixedParameters);
  function.SetNumOptionalParameters(kNumOptionalParameters,
                                    kAreOptionalPositional);
  functions.SetAt(1, function);

  function_name = Symbols::New("baz");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      false, false, false, false, cls, 0);
  functions.SetAt(2, function);

  function_name = Symbols::New("Foo");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      true, false, false, false, cls, 0);

  functions.SetAt(3, function);
  function_name = Symbols::New("Bar");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      true, false, false, false, cls, 0);
  functions.SetAt(4, function);
  function_name = Symbols::New("BaZ");
  function = Function::New(
      function_name, RawFunction::kRegularFunction,
      true, false, false, false, cls, 0);
  functions.SetAt(5, function);

  // Setup the functions in the class.
  cls.SetFunctions(functions);

  function_name = String::New("Foo");
  function = cls.LookupDynamicFunction(function_name);
  EXPECT(function.IsNull());
  function = cls.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.raw(), function.Owner());
  EXPECT(function.is_static());
  function_name = String::New("baz");
  function = cls.LookupDynamicFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT(function_name.Equals(String::Handle(function.name())));
  EXPECT_EQ(cls.raw(), function.Owner());
  EXPECT(!function.is_static());
  function = cls.LookupStaticFunction(function_name);
  EXPECT(function.IsNull());

  function_name = String::New("foo");
  function = cls.LookupDynamicFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT_EQ(0, function.num_fixed_parameters());
  EXPECT(!function.HasOptionalParameters());

  function_name = String::New("bar");
  function = cls.LookupDynamicFunction(function_name);
  EXPECT(!function.IsNull());
  EXPECT_EQ(kNumFixedParameters, function.num_fixed_parameters());
  EXPECT_EQ(kNumOptionalParameters, function.NumOptionalParameters());

  const Array& interfaces = Array::Handle(Array::New(2));
  Class& interface = Class::Handle();
  String& interface_name = String::Handle();
  interface_name = Symbols::New("Harley");
  interface = Class::New(interface_name, script, Scanner::kDummyTokenIndex);
  interfaces.SetAt(0, Type::Handle(Type::NewNonParameterizedType(interface)));
  interface_name = Symbols::New("Norton");
  interface = Class::New(interface_name, script, Scanner::kDummyTokenIndex);
  interfaces.SetAt(1, Type::Handle(Type::NewNonParameterizedType(interface)));
  cls.set_interfaces(interfaces);
  cls.Finalize();
}


TEST_CASE(TypeArguments) {
  const Type& type1 = Type::Handle(Type::Double());
  const Type& type2 = Type::Handle(Type::StringType());
  const TypeArguments& type_arguments1 = TypeArguments::Handle(
    TypeArguments::New(2));
  type_arguments1.SetTypeAt(0, type1);
  type_arguments1.SetTypeAt(1, type2);
  const TypeArguments& type_arguments2 = TypeArguments::Handle(
    TypeArguments::New(2));
  type_arguments2.SetTypeAt(0, type1);
  type_arguments2.SetTypeAt(1, type2);
  EXPECT_NE(type_arguments1.raw(), type_arguments2.raw());
  OS::Print("1: %s\n", type_arguments1.ToCString());
  OS::Print("2: %s\n", type_arguments2.ToCString());
  ASSERT(type_arguments1.Equals(type_arguments2));
  TypeArguments& type_arguments3 = TypeArguments::Handle();
  type_arguments1.Canonicalize();
  type_arguments3 ^= type_arguments2.Canonicalize();
  EXPECT_EQ(type_arguments1.raw(), type_arguments3.raw());
}


TEST_CASE(TokenStream) {
  String& source = String::Handle(String::New("= ( 9 , ."));
  String& private_key = String::Handle(String::New(""));
  Scanner scanner(source, private_key);
  const Scanner::GrowableTokenStream& ts = scanner.GetStream();
  EXPECT_EQ(6, ts.length());
  EXPECT_EQ(Token::kLPAREN, ts[1].kind);
  const TokenStream& token_stream = TokenStream::Handle(
      TokenStream::New(ts, private_key));
  TokenStream::Iterator iterator(token_stream, 0);
  // EXPECT_EQ(6, token_stream.Length());
  iterator.Advance();  // Advance to '(' token.
  EXPECT_EQ(Token::kLPAREN, iterator.CurrentTokenKind());
  iterator.Advance();
  iterator.Advance();
  iterator.Advance();  // Advance to '.' token.
  EXPECT_EQ(Token::kPERIOD, iterator.CurrentTokenKind());
  iterator.Advance();  // Advance to end of stream.
  EXPECT_EQ(Token::kEOS, iterator.CurrentTokenKind());
}


TEST_CASE(InstanceClass) {
  // Allocate the class first.
  String& class_name = String::Handle(Symbols::New("EmptyClass"));
  Script& script = Script::Handle();
  const Class& empty_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));

  // No functions and no super class for the EmptyClass.
  const Array& no_fields = Array::Handle(Object::empty_array());
  empty_class.SetFields(no_fields);
  empty_class.Finalize();
  EXPECT_EQ(kObjectAlignment, empty_class.instance_size());
  Instance& instance = Instance::Handle(Instance::New(empty_class));
  EXPECT_EQ(empty_class.raw(), instance.clazz());

  class_name = Symbols::New("OneFieldClass");
  const Class& one_field_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));

  // No functions and no super class for the OneFieldClass.
  const Array& one_fields = Array::Handle(Array::New(1));
  const String& field_name = String::Handle(Symbols::New("the_field"));
  const Field& field = Field::Handle(
       Field::New(field_name, false, false, false, one_field_class, 0));
  one_fields.SetAt(0, field);
  one_field_class.SetFields(one_fields);
  one_field_class.Finalize();
  intptr_t header_size = sizeof(RawObject);
  EXPECT_EQ(Utils::RoundUp((header_size + (1 * kWordSize)), kObjectAlignment),
            one_field_class.instance_size());
  EXPECT_EQ(header_size, field.Offset());
}


TEST_CASE(Interface) {
  String& class_name = String::Handle(Symbols::New("EmptyClass"));
  Script& script = Script::Handle();
  const Class& factory_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  const Array& no_fields = Array::Handle(Object::empty_array());
  // Finalizes the class.
  factory_class.SetFields(no_fields);

  String& interface_name = String::Handle(Symbols::New("MyInterface"));
  const Class& interface = Class::Handle(
      Class::NewInterface(interface_name, script, Scanner::kDummyTokenIndex));
  EXPECT(interface.is_interface());
  EXPECT(!factory_class.is_interface());
  EXPECT(!interface.HasFactoryClass());
  interface.set_factory_class(factory_class);
  EXPECT_EQ(factory_class.raw(), interface.FactoryClass());
}


TEST_CASE(Smi) {
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
  // Upper two bits must be either 00 or 11.
#if defined(ARCH_IS_64_BIT)
  EXPECT(!Smi::IsValid(kMaxInt64));
  EXPECT(Smi::IsValid(0x3FFFFFFFFFFFFFFF));
  EXPECT(Smi::IsValid(0xFFFFFFFFFFFFFFFF));
#else
  EXPECT(!Smi::IsValid(kMaxInt32));
  EXPECT(Smi::IsValid(0x3FFFFFFF));
  EXPECT(Smi::IsValid(0xFFFFFFFF));
#endif

  EXPECT_EQ(5, smi.AsInt64Value());
  EXPECT_EQ(5.0, smi.AsDoubleValue());

  Smi& a = Smi::Handle(Smi::New(5));
  Smi& b = Smi::Handle(Smi::New(3));
  EXPECT_EQ(1, a.CompareWith(b));
  EXPECT_EQ(-1, b.CompareWith(a));
  EXPECT_EQ(0, a.CompareWith(a));

  Smi& c = Smi::Handle(Smi::New(-1));

  Mint& mint1 = Mint::Handle(
      Mint::New(DART_2PART_UINT64_C(0x7FFFFFFF, 100)));
  Mint& mint2 = Mint::Handle(
      Mint::New(-DART_2PART_UINT64_C(0x7FFFFFFF, 100)));
  EXPECT_EQ(-1, a.CompareWith(mint1));
  EXPECT_EQ(1, a.CompareWith(mint2));
  EXPECT_EQ(-1, c.CompareWith(mint1));
  EXPECT_EQ(1, c.CompareWith(mint2));

  Bigint& big1 = Bigint::Handle(BigintOperations::NewFromCString(
      "10000000000000000000"));
  Bigint& big2 = Bigint::Handle(BigintOperations::NewFromCString(
      "-10000000000000000000"));
  EXPECT_EQ(-1, a.CompareWith(big1));
  EXPECT_EQ(1, a.CompareWith(big2));
  EXPECT_EQ(-1, c.CompareWith(big1));
  EXPECT_EQ(1, c.CompareWith(big2));
}


TEST_CASE(Mint) {
// On 64-bit architectures a Smi is stored in a 64 bit word. A Midint cannot
// be allocated if it does fit into a Smi.
#if !defined(ARCH_IS_64_BIT)
  { Mint& med = Mint::Handle();
    EXPECT(med.IsNull());
    int64_t v = DART_2PART_UINT64_C(1, 0);
    med = Mint::New(v);
    EXPECT_EQ(v, med.value());
    const String& smi_str = String::Handle(String::New("1"));
    const String& mint1_str = String::Handle(String::New("2147419168"));
    const String& mint2_str = String::Handle(String::New("-2147419168"));
    Integer& i = Integer::Handle(Integer::New(smi_str));
    EXPECT(i.IsSmi());
    i = Integer::New(mint1_str);
    EXPECT(i.IsMint());
    EXPECT(!i.IsZero());
    EXPECT(!i.IsNegative());
    i = Integer::New(mint2_str);
    EXPECT(i.IsMint());
    EXPECT(!i.IsZero());
    EXPECT(i.IsNegative());
  }
  Integer& i = Integer::Handle(Mint::New(DART_2PART_UINT64_C(1, 0)));
  EXPECT(i.IsMint());
  EXPECT(!i.IsZero());
  EXPECT(!i.IsNegative());
  Integer& i1 = Integer::Handle(Mint::New(DART_2PART_UINT64_C(1010, 0)));
  Mint& i2 = Mint::Handle(Mint::New(DART_2PART_UINT64_C(1010, 0)));
  EXPECT(i1.Equals(i2));
  EXPECT(!i.Equals(i1));
  int64_t test = DART_2PART_UINT64_C(1010, 0);
  EXPECT_EQ(test, i2.value());

  Mint& a = Mint::Handle(Mint::New(DART_2PART_UINT64_C(5, 0)));
  Mint& b = Mint::Handle(Mint::New(DART_2PART_UINT64_C(3, 0)));
  EXPECT_EQ(1, a.CompareWith(b));
  EXPECT_EQ(-1, b.CompareWith(a));
  EXPECT_EQ(0, a.CompareWith(a));

  Mint& c = Mint::Handle(Mint::New(-DART_2PART_UINT64_C(3, 0)));
  Smi& smi1 = Smi::Handle(Smi::New(4));
  Smi& smi2 = Smi::Handle(Smi::New(-4));
  EXPECT_EQ(1, a.CompareWith(smi1));
  EXPECT_EQ(1, a.CompareWith(smi2));
  EXPECT_EQ(-1, c.CompareWith(smi1));
  EXPECT_EQ(-1, c.CompareWith(smi2));

  Bigint& big1 = Bigint::Handle(BigintOperations::NewFromCString(
      "10000000000000000000"));
  Bigint& big2 = Bigint::Handle(BigintOperations::NewFromCString(
      "-10000000000000000000"));
  EXPECT_EQ(-1, a.CompareWith(big1));
  EXPECT_EQ(1, a.CompareWith(big2));
  EXPECT_EQ(-1, c.CompareWith(big1));
  EXPECT_EQ(1, c.CompareWith(big2));

  int64_t mint_value = DART_2PART_UINT64_C(0x7FFFFFFF, 100);
  Mint& mint1 = Mint::Handle(Mint::NewCanonical(mint_value));
  Mint& mint2 = Mint::Handle(Mint::NewCanonical(mint_value));
  EXPECT_EQ(mint1.value(), mint_value);
  EXPECT_EQ(mint2.value(), mint_value);
  EXPECT_EQ(mint1.raw(), mint2.raw());
#endif
}


TEST_CASE(Double) {
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
    EXPECT(dbl1.Equals(dbl2));
    const Double& dbl3 = Double::Handle(Double::New(3.3));
    EXPECT(!dbl1.Equals(dbl3));
    EXPECT(!dbl1.Equals(Smi::Handle(Smi::New(3))));
    EXPECT(!dbl1.Equals(Double::Handle()));
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


TEST_CASE(Bigint) {
  Bigint& b = Bigint::Handle();
  EXPECT(b.IsNull());
  const String& test = String::Handle(String::New("1234"));
  b = Bigint::New(test);
  const char* str = b.ToCString();
  EXPECT_STREQ("1234", str);

  int64_t t64 = DART_2PART_UINT64_C(1, 0);
  Bigint& big = Bigint::Handle();
  big = BigintOperations::NewFromInt64(t64);
  EXPECT_EQ(t64, big.AsInt64Value());
  big = BigintOperations::NewFromCString("10000000000000000000");
  EXPECT_EQ(1e19, big.AsDoubleValue());

  Bigint& big1 = Bigint::Handle(BigintOperations::NewFromCString(
      "100000000000000000000"));
  Bigint& big2 = Bigint::Handle(BigintOperations::NewFromCString(
      "100000000000000000010"));
  Bigint& big3 = Bigint::Handle(BigintOperations::NewFromCString(
      "-10000000000000000000"));

  EXPECT_EQ(0, big1.CompareWith(big1));
  EXPECT_EQ(-1, big1.CompareWith(big2));
  EXPECT_EQ(1, big2.CompareWith(big1));
  EXPECT_EQ(1, big1.CompareWith(big3));
  EXPECT_EQ(-1, big3.CompareWith(big1));

  Smi& smi1 = Smi::Handle(Smi::New(5));
  Smi& smi2 = Smi::Handle(Smi::New(-2));

  EXPECT_EQ(-1, smi1.CompareWith(big1));
  EXPECT_EQ(-1, smi2.CompareWith(big1));

  EXPECT_EQ(1, smi1.CompareWith(big3));
  EXPECT_EQ(1, smi2.CompareWith(big3));
}


TEST_CASE(Integer) {
  Integer& i = Integer::Handle();
  i = Integer::New(String::Handle(String::New("12")));
  EXPECT(i.IsSmi());
  i = Integer::New(String::Handle(String::New("-120")));
  EXPECT(i.IsSmi());
  i = Integer::New(String::Handle(String::New("0")));
  EXPECT(i.IsSmi());
  i = Integer::New(String::Handle(String::New("12345678901234567890")));
  EXPECT(i.IsBigint());
  i = Integer::New(String::Handle(String::New("-12345678901234567890111222")));
  EXPECT(i.IsBigint());
}


TEST_CASE(String) {
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
  const String& str2 = String::Handle(String::New(motto+7, 4));
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
  const uint8_t chars[kCharsLen] = { 1, 2, 127, 64, 92, 0, 55, 55 };
  const String& str8 = String::Handle(String::New(chars, kCharsLen));
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
  uint16_t wide_chars[kWideCharsLen] = { 'H', 'e', 'l', 'l', 'o', 256, '!' };
  const String& two_str = String::Handle(String::New(wide_chars,
                                                     kWideCharsLen));
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

  const uint32_t four_chars[] = { 'C', 0xFF, 'h', 0xFFFF, 'a', 0x10FFFF, 'r' };
  const String& four_str = String::Handle(String::New(four_chars, 7));
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
    const uint16_t char16[] = { 0x00, 0x7F, 0xFF };
    const String& str8 = String::Handle(String::New(char16, 3));
    EXPECT(str8.IsOneByteString());
    EXPECT(!str8.IsTwoByteString());
    EXPECT_EQ(0x00, str8.CharAt(0));
    EXPECT_EQ(0x7F, str8.CharAt(1));
    EXPECT_EQ(0xFF, str8.CharAt(2));
  }

  // Create a 1-byte string from an array of 4-byte elements.
  {
    const uint32_t char32[] = { 0x00, 0x1F, 0x7F };
    const String& str8 = String::Handle(String::New(char32, 3));
    EXPECT(str8.IsOneByteString());
    EXPECT(!str8.IsTwoByteString());
    EXPECT_EQ(0x00, str8.CharAt(0));
    EXPECT_EQ(0x1F, str8.CharAt(1));
    EXPECT_EQ(0x7F, str8.CharAt(2));
  }

  // Create a 2-byte string from an array of 4-byte elements.
  {
    const uint32_t char32[] = { 0, 0x7FFF, 0xFFFF };
    const String& str16 = String::Handle(String::New(char32, 3));
    EXPECT(!str16.IsOneByteString());
    EXPECT(str16.IsTwoByteString());
    EXPECT_EQ(0x0000, str16.CharAt(0));
    EXPECT_EQ(0x7FFF, str16.CharAt(1));
    EXPECT_EQ(0xFFFF, str16.CharAt(2));
  }
}


TEST_CASE(StringFormat) {
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


TEST_CASE(StringConcat) {
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

    uint16_t two[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& str2 = String::Handle(String::New(two, two_len));
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
    uint16_t twotwo[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                          0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t twotwo_len = sizeof(twotwo) / sizeof(twotwo[0]);
    EXPECT(str7.IsTwoByteString());
    EXPECT(str7.Equals(twotwo, twotwo_len));
  }

  // Concatenating non-empty 2-byte strings.
  {
    const uint16_t one[] = { 0x05D0, 0x05D9, 0x05D9, 0x05DF };
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& str1 = String::Handle(String::New(one, one_len));
    EXPECT(str1.IsTwoByteString());
    EXPECT_EQ(one_len, str1.Length());

    const uint16_t two[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& str2 = String::Handle(String::New(two, two_len));
    EXPECT(str2.IsTwoByteString());
    EXPECT_EQ(two_len, str2.Length());

    // Concat

    const String& one_two_str = String::Handle(String::Concat(str1, str2));
    EXPECT(one_two_str.IsTwoByteString());
    const uint16_t one_two[] = { 0x05D0, 0x05D9, 0x05D9, 0x05DF,
                                 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ(one_two_len, one_two_str.Length());
    EXPECT(one_two_str.Equals(one_two, one_two_len));

    const String& two_one_str = String::Handle(String::Concat(str2, str1));
    EXPECT(two_one_str.IsTwoByteString());
    const uint16_t two_one[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                                 0x05D0, 0x05D9, 0x05D9, 0x05DF };
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
    const uint16_t one_two_one[] = { 0x05D0, 0x05D9, 0x05D9, 0x05DF,
                                     0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                                     0x05D0, 0x05D9, 0x05D9, 0x05DF };
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
    const uint16_t two_one_two[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                                     0x05D0, 0x05D9, 0x05D9, 0x05DF,
                                     0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT_EQ(two_one_two_len, str6.Length());
    EXPECT(str6.Equals(two_one_two, two_one_two_len));
  }

  // Concatenated emtpy and non-empty strings built from 4-byte elements.
  {
    const String& str1 = String::Handle(String::New(""));
    EXPECT(str1.IsOneByteString());
    EXPECT_EQ(0, str1.Length());

    uint32_t four[] = { 0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1 };
    intptr_t four_len = sizeof(four) / sizeof(four[0]);
    intptr_t expected_len = (four_len * 2);
    const String& str2 = String::Handle(String::New(four, four_len));
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
    uint32_t fourfour[] = { 0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1,
                            0x1D4D5, 0x1D4DE, 0x1D4E4, 0x1D4E1 };
    intptr_t fourfour_len = sizeof(fourfour) / sizeof(fourfour[0]);
    EXPECT_EQ((fourfour_len * 2), str7.Length());
    const String& fourfour_str =
        String::Handle(String::New(fourfour, fourfour_len));
    EXPECT(str7.Equals(fourfour_str));
  }

  // Concatenate non-empty strings built from 4-byte elements.
  {
    const uint32_t one[] = { 0x105D0, 0x105D9, 0x105D9, 0x105DF };
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& onestr = String::Handle(String::New(one, one_len));
    EXPECT(onestr.IsTwoByteString());
    EXPECT_EQ((one_len *2), onestr.Length());

    const uint32_t two[] = { 0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9 };
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& twostr = String::Handle(String::New(two, two_len));
    EXPECT(twostr.IsTwoByteString());
    EXPECT_EQ((two_len * 2), twostr.Length());

    // Concat

    const String& str1 = String::Handle(String::Concat(onestr, twostr));
    EXPECT(str1.IsTwoByteString());
    const uint32_t one_two[] = { 0x105D0, 0x105D9, 0x105D9, 0x105DF,
                                 0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9 };
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ((one_two_len * 2), str1.Length());
    const String& one_two_str =
        String::Handle(String::New(one_two, one_two_len));
    EXPECT(str1.Equals(one_two_str));

    const String& str2 = String::Handle(String::Concat(twostr, onestr));
    EXPECT(str2.IsTwoByteString());
    const uint32_t two_one[] = { 0x105E6, 0x105D5, 0x105D5, 0x105D9, 0x105D9,
                                 0x105D0, 0x105D9, 0x105D9, 0x105DF };
    intptr_t two_one_len = sizeof(two_one) / sizeof(two_one[0]);
    EXPECT_EQ((two_one_len * 2), str2.Length());
    const String& two_one_str =
        String::Handle(String::New(two_one, two_one_len));
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
    const uint32_t one_two_one[] = { 0x105D0, 0x105D9, 0x105D9, 0x105DF,
                                     0x105E6, 0x105D5, 0x105D5, 0x105D9,
                                     0x105D9,
                                     0x105D0, 0x105D9, 0x105D9, 0x105DF };
    intptr_t one_two_one_len = sizeof(one_two_one) / sizeof(one_two_one[0]);
    EXPECT_EQ((one_two_one_len * 2), str5.Length());
    const String& one_two_one_str =
        String::Handle(String::New(one_two_one, one_two_one_len));
    EXPECT(str5.Equals(one_two_one_str));

    const Array& array4 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array4.Length());
    array4.SetAt(0, twostr);
    array4.SetAt(1, onestr);
    array4.SetAt(2, twostr);
    const String& str6 = String::Handle(String::ConcatAll(array4));
    EXPECT(str6.IsTwoByteString());
    const uint32_t two_one_two[] = { 0x105E6, 0x105D5, 0x105D5, 0x105D9,
                                     0x105D9,
                                     0x105D0, 0x105D9, 0x105D9, 0x105DF,
                                     0x105E6, 0x105D5, 0x105D5, 0x105D9,
                                     0x105D9 };
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT_EQ((two_one_two_len * 2), str6.Length());
    const String& two_one_two_str =
        String::Handle(String::New(two_one_two, two_one_two_len));
    EXPECT(str6.Equals(two_one_two_str));
  }

  // Concatenate 1-byte strings and 2-byte strings.
  {
    const uint8_t one[] = { 'o', 'n', 'e', ' ', 'b', 'y', 't', 'e' };
    intptr_t one_len = sizeof(one) / sizeof(one[0]);
    const String& onestr = String::Handle(String::New(one, one_len));
    EXPECT(onestr.IsOneByteString());
    EXPECT_EQ(one_len, onestr.Length());
    EXPECT(onestr.Equals(one, one_len));

    uint16_t two[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t two_len = sizeof(two) / sizeof(two[0]);
    const String& twostr = String::Handle(String::New(two, two_len));
    EXPECT(twostr.IsTwoByteString());
    EXPECT_EQ(two_len, twostr.Length());
    EXPECT(twostr.Equals(two, two_len));

    // Concat

    const String& one_two_str = String::Handle(String::Concat(onestr, twostr));
    EXPECT(one_two_str.IsTwoByteString());
    uint16_t one_two[] = { 'o', 'n', 'e', ' ', 'b', 'y', 't', 'e',
                           0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t one_two_len = sizeof(one_two) / sizeof(one_two[0]);
    EXPECT_EQ(one_two_len, one_two_str.Length());
    EXPECT(one_two_str.Equals(one_two, one_two_len));

    const String& two_one_str = String::Handle(String::Concat(twostr, onestr));
    EXPECT(two_one_str.IsTwoByteString());
    uint16_t two_one[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                           'o', 'n', 'e', ' ', 'b', 'y', 't', 'e' };
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
    EXPECT_EQ(onestr.Length()*2 + twostr.Length(), one_two_one_str.Length());
    uint16_t one_two_one[] = { 'o', 'n', 'e', ' ', 'b', 'y', 't', 'e',
                               0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                               'o', 'n', 'e', ' ', 'b', 'y', 't', 'e' };
    intptr_t one_two_one_len = sizeof(one_two_one) / sizeof(one_two_one[0]);
    EXPECT(one_two_one_str.Equals(one_two_one, one_two_one_len));

    const Array& array2 = Array::Handle(Array::New(3));
    EXPECT_EQ(3, array2.Length());
    array2.SetAt(0, twostr);
    array2.SetAt(1, onestr);
    array2.SetAt(2, twostr);
    const String& two_one_two_str = String::Handle(String::ConcatAll(array2));
    EXPECT(two_one_two_str.IsTwoByteString());
    EXPECT_EQ(twostr.Length()*2 + onestr.Length(), two_one_two_str.Length());
    uint16_t two_one_two[] = { 0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9,
                               'o', 'n', 'e', ' ', 'b', 'y', 't', 'e',
                               0x05E6, 0x05D5, 0x05D5, 0x05D9, 0x05D9 };
    intptr_t two_one_two_len = sizeof(two_one_two) / sizeof(two_one_two[0]);
    EXPECT(two_one_two_str.Equals(two_one_two, two_one_two_len));
  }
}


TEST_CASE(StringSubStringDifferentWidth) {
  // Create 1-byte substring from a 1-byte source string.
  const char* onechars =
      "\xC3\xB6\xC3\xB1\xC3\xA9";

  const String& onestr = String::Handle(String::New(onechars));
  EXPECT(!onestr.IsNull());
  EXPECT(!onestr.IsOneByteString());
  EXPECT(onestr.IsTwoByteString());

  const String& onesub = String::Handle(String::SubString(onestr, 0));
  EXPECT(!onesub.IsNull());
  EXPECT(!onestr.IsOneByteString());
  EXPECT(onestr.IsTwoByteString());
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


TEST_CASE(StringFromUtf8Literal) {
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
      0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
      0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF,
      0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7,
      0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF,
      0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7,
      0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF,
      0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7,
      0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF,
      0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7,
      0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF,
      0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7,
      0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF,
    };
    const String& str = String::Handle(String::New(src));
    EXPECT(str.IsTwoByteString());
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
    const uint16_t expected[] = {
      0x5D2, 0x5DC, 0x5E2, 0x5D3,
      0x5D1, 0x5E8, 0x5DB, 0x5D4
    };
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
      0x0E00, 0x0F00, 0xA000, 0xB000, 0xC000, 0xD000, 0xE000, 0xF000
    };
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
    const intptr_t expected[] = { 0xd835, 0xdc60, 0xd835, 0xdc61,
                                  0xd835, 0xdc62, 0xd835, 0xdc63 };
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
      0x0A00, 0x0B00, 0x0C00, 0x0D00, 0x0E00, 0x0F00, 0xA000, 0xB000, 0xC000,
      0xD000, 0xE000, 0xF000, 0xD828, 0xDC00, 0xD82c, 0xDC00, 0xD834, 0xDC00,
      0xD838, 0xDC00, 0xD83c, 0xDC00,
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
      0x000A, 0x000B, 0x000D, 0x000C, 0x000E, 0x000F, 0x00A0, 0x00B0,
      0x00C0, 0x00D0, 0x00E0, 0x00F0, 0x0A00, 0x0B00, 0x0C00, 0x0D00,
      0x0E00, 0x0F00, 0xA000, 0xB000, 0xC000, 0xD000, 0xE000, 0xF000,
      0xD828, 0xDC00, 0xD82c, 0xDC00, 0xD834, 0xDC00, 0xD838, 0xDC00,
      0xD83c, 0xDC00,
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


TEST_CASE(ExternalOneByteString) {
  uint8_t characters[] = { 0xF6, 0xF1, 0xE9 };
  intptr_t len = ARRAY_SIZE(characters);

  const String& str =
      String::Handle(
          ExternalOneByteString::New(characters, len, NULL, NULL, Heap::kNew));
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


TEST_CASE(ExternalTwoByteString) {
  uint16_t characters[] = { 0x1E6B, 0x1E85, 0x1E53 };
  intptr_t len = ARRAY_SIZE(characters);

  const String& str =
      String::Handle(
          ExternalTwoByteString::New(characters, len, NULL, NULL, Heap::kNew));
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
  EXPECT(concat.Equals("\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"
                       "\xE1\xB9\xAB\xE1\xBA\x85\xE1\xB9\x93"));

  const String& substr = String::Handle(String::SubString(str, 1, 1));
  EXPECT(!substr.IsExternalTwoByteString());
  EXPECT(substr.IsTwoByteString());
  EXPECT_EQ(1, substr.Length());
  EXPECT(substr.Equals("\xE1\xBA\x85"));
}


TEST_CASE(Symbol) {
  const String& one = String::Handle(Symbols::New("Eins"));
  EXPECT(one.IsSymbol());
  const String& two = String::Handle(Symbols::New("Zwei"));
  const String& three = String::Handle(Symbols::New("Drei"));
  const String& four = String::Handle(Symbols::New("Vier"));
  const String& five = String::Handle(Symbols::New("Fuenf"));
  const String& six = String::Handle(Symbols::New("Sechs"));
  const String& seven = String::Handle(Symbols::New("Sieben"));
  const String& eight = String::Handle(Symbols::New("Acht"));
  const String& nine = String::Handle(Symbols::New("Neun"));
  const String& ten = String::Handle(Symbols::New("Zehn"));
  String& eins = String::Handle(Symbols::New("Eins"));
  EXPECT_EQ(one.raw(), eins.raw());
  EXPECT(one.raw() != two.raw());
  EXPECT(two.Equals(String::Handle(String::New("Zwei"))));
  EXPECT_EQ(two.raw(), Symbols::New("Zwei"));
  EXPECT_EQ(three.raw(), Symbols::New("Drei"));
  EXPECT_EQ(four.raw(), Symbols::New("Vier"));
  EXPECT_EQ(five.raw(), Symbols::New("Fuenf"));
  EXPECT_EQ(six.raw(), Symbols::New("Sechs"));
  EXPECT_EQ(seven.raw(), Symbols::New("Sieben"));
  EXPECT_EQ(eight.raw(), Symbols::New("Acht"));
  EXPECT_EQ(nine.raw(), Symbols::New("Neun"));
  EXPECT_EQ(ten.raw(), Symbols::New("Zehn"));

  // Make sure to cause symbol table overflow.
  for (int i = 0; i < 1024; i++) {
    char buf[256];
    OS::SNPrint(buf, sizeof(buf), "%d", i);
    Symbols::New(buf);
  }
  eins = Symbols::New("Eins");
  EXPECT_EQ(one.raw(), eins.raw());
  EXPECT_EQ(two.raw(), Symbols::New("Zwei"));
  EXPECT_EQ(three.raw(), Symbols::New("Drei"));
  EXPECT_EQ(four.raw(), Symbols::New("Vier"));
  EXPECT_EQ(five.raw(), Symbols::New("Fuenf"));
  EXPECT_EQ(six.raw(), Symbols::New("Sechs"));
  EXPECT_EQ(seven.raw(), Symbols::New("Sieben"));
  EXPECT_EQ(eight.raw(), Symbols::New("Acht"));
  EXPECT_EQ(nine.raw(), Symbols::New("Neun"));
  EXPECT_EQ(ten.raw(), Symbols::New("Zehn"));

  // Symbols from Strings.
  eins = String::New("Eins");
  EXPECT(!eins.IsSymbol());
  String& ein_symbol = String::Handle(Symbols::New(eins));
  EXPECT_EQ(one.raw(), ein_symbol.raw());
  EXPECT(one.raw() != eins.raw());

  uint32_t char32[] = { 'E', 'l', 'f' };
  String& elf = String::Handle(Symbols::New(char32, 3));
  EXPECT(elf.IsSymbol());
  EXPECT_EQ(elf.raw(), Symbols::New("Elf"));
}


TEST_CASE(Bool) {
  const Bool& true_value = Bool::Handle(Bool::True());
  EXPECT(true_value.value());
  const Bool& false_value = Bool::Handle(Bool::False());
  EXPECT(!false_value.value());
}


TEST_CASE(Array) {
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

  EXPECT(array.Equals(array));
  EXPECT(array.Equals(other_array));

  other_array.SetAt(1, other_array);
  EXPECT(!array.Equals(other_array));

  other_array = Array::New(kArrayLen - 1);
  other_array.SetAt(0, array);
  other_array.SetAt(2, array);
  EXPECT(!array.Equals(other_array));

  EXPECT_EQ(0, Array::Handle(Object::empty_array()).Length());
}


TEST_CASE(StringCodePointIterator) {
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

  const String& str2 = String::Handle(String::New("\xD7\x92\xD7\x9C"
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

  const String& str3 = String::Handle(String::New("\xF0\x9D\x91\xA0"
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


TEST_CASE(GrowableObjectArray) {
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

  // Test the MakeArray functionality to make sure the resulting array
  // object is properly setup.
  // 1. Should produce an array of length 2 and a remainder array of length 1.
  Array& new_array = Array::Handle();
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
  new_array = Array::MakeArray(array);
  addr = RawObject::ToAddr(new_array.raw());
  obj = RawObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(2, new_array.Length());
  addr += used_size;
  obj = RawObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(0, new_array.Length());

  // 2. Should produce an array of length 3 and a remainder object.
  array = GrowableObjectArray::New(kArrayLen);
  EXPECT_EQ(kArrayLen, array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 3; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  used_size = Array::InstanceSize(array.Length());
  new_array = Array::MakeArray(array);
  addr = RawObject::ToAddr(new_array.raw());
  obj = RawObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(3, new_array.Length());
  addr += used_size;
  obj = RawObject::FromAddr(addr);
  EXPECT(!obj.IsArray());

  // 3. Should produce an array of length 1 and a remainder array of length 2.
  array = GrowableObjectArray::New(kArrayLen + 3);
  EXPECT_EQ((kArrayLen + 3), array.Capacity());
  EXPECT_EQ(0, array.Length());
  for (intptr_t i = 0; i < 1; i++) {
    value = Smi::New(i);
    array.Add(value);
  }
  used_size = Array::InstanceSize(array.Length());
  new_array = Array::MakeArray(array);
  addr = RawObject::ToAddr(new_array.raw());
  obj = RawObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(1, new_array.Length());
  addr += used_size;
  obj = RawObject::FromAddr(addr);
  EXPECT(obj.IsArray());
  new_array ^= obj.raw();
  EXPECT_EQ(4, new_array.Length());
}


TEST_CASE(InternalByteArray) {
  uint8_t data[] = { 253, 254, 255, 0, 1, 2, 3, 4 };
  intptr_t data_length = ARRAY_SIZE(data);

  const Int8Array& int8_array =
      Int8Array::Handle(Int8Array::New(reinterpret_cast<int8_t*>(data),
                                       data_length));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());

  EXPECT_EQ(-3, int8_array.At(0));
  uint8_t at_0;
  ByteArray::Copy(&at_0, int8_array, 0, sizeof(at_0));
  EXPECT_EQ(253, at_0);

  EXPECT_EQ(-2, int8_array.At(1));
  uint8_t at_1;
  ByteArray::Copy(&at_1, int8_array, 1, sizeof(at_1));
  EXPECT_EQ(254, at_1);

  EXPECT_EQ(-1, int8_array.At(2));
  uint8_t at_2;
  ByteArray::Copy(&at_2, int8_array, 2, sizeof(at_2));
  EXPECT_EQ(255, at_2);

  EXPECT_EQ(0, int8_array.At(3));
  uint8_t at_3;
  ByteArray::Copy(&at_3, int8_array, 3, sizeof(at_3));
  EXPECT_EQ(0, at_3);

  EXPECT_EQ(1, int8_array.At(4));
  uint8_t at_4;
  ByteArray::Copy(&at_4, int8_array, 4, sizeof(at_4));
  EXPECT_EQ(1, at_4);

  EXPECT_EQ(2, int8_array.At(5));
  uint8_t at_5;
  ByteArray::Copy(&at_5, int8_array, 5, sizeof(at_5));
  EXPECT_EQ(2, at_5);

  EXPECT_EQ(3, int8_array.At(6));
  uint8_t at_6;
  ByteArray::Copy(&at_6, int8_array, 6, sizeof(at_6));
  EXPECT_EQ(3, at_6);

  EXPECT_EQ(4, int8_array.At(7));
  uint8_t at_7;
  ByteArray::Copy(&at_7, int8_array, 7, sizeof(at_7));
  EXPECT_EQ(4, at_7);

  const Int8Array& int8_array2 =
      Int8Array::Handle(Int8Array::New(reinterpret_cast<int8_t*>(data),
                                       data_length));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());

  for (intptr_t i = 0; i < data_length; ++i) {
    EXPECT_EQ(int8_array.At(i), int8_array2.At(i));
  }
  for (intptr_t i = 0; i < data_length; ++i) {
    int8_array.SetAt(i, 123 + i);
  }
  for (intptr_t i = 0; i < data_length; ++i) {
    EXPECT(int8_array.At(i) != int8_array2.At(i));
  }
}


TEST_CASE(ExternalByteArray) {
  uint8_t data[] = { 253, 254, 255, 0, 1, 2, 3, 4 };
  intptr_t data_length = ARRAY_SIZE(data);

  const ExternalInt8Array& int8_array =
      ExternalInt8Array::Handle(
          ExternalInt8Array::New(reinterpret_cast<int8_t*>(data),
                                 data_length, NULL, NULL));
  EXPECT(!int8_array.IsNull());
  EXPECT_EQ(data_length, int8_array.Length());

  const ExternalUint8Array& uint8_array =
      ExternalUint8Array::Handle(
          ExternalUint8Array::New(data, data_length, NULL, NULL));
  EXPECT(!uint8_array.IsNull());
  EXPECT_EQ(data_length, uint8_array.Length());

  EXPECT_EQ(-3, int8_array.At(0));
  EXPECT_EQ(253, uint8_array.At(0));

  EXPECT_EQ(-2, int8_array.At(1));
  EXPECT_EQ(254, uint8_array.At(1));

  EXPECT_EQ(-1, int8_array.At(2));
  EXPECT_EQ(255, uint8_array.At(2));

  EXPECT_EQ(0, int8_array.At(3));
  EXPECT_EQ(0, uint8_array.At(3));

  EXPECT_EQ(1, int8_array.At(4));
  EXPECT_EQ(1, uint8_array.At(4));

  EXPECT_EQ(2, int8_array.At(5));
  EXPECT_EQ(2, uint8_array.At(5));

  for (intptr_t i = 0 ; i < int8_array.Length(); ++i) {
    uint8_t value = 0;
    ByteArray::Copy(&value, int8_array, i, sizeof(value));
    EXPECT_EQ(value, uint8_array.At(i));
  }

  int8_array.SetAt(2, -123);
  uint8_array.SetAt(0, 123);
  for (intptr_t i = 0 ; i < int8_array.Length(); ++i) {
    int8_t value = 0;
    ByteArray::Copy(&value, uint8_array, i, sizeof(value));
    EXPECT_EQ(int8_array.At(i), value);
  }
}


TEST_CASE(ByteArrayCopyInternal) {
  const uint8_t b_0_1_2_3[] = { 0, 1, 2, 3 };
  const uint8_t b_4_5_6_7[] = { 4, 5, 6, 7 };

  const Uint8Array& internal =
      Uint8Array::Handle(Uint8Array::New(b_0_1_2_3, ARRAY_SIZE(b_0_1_2_3)));
  EXPECT(!internal.IsNull());
  EXPECT_EQ(4, internal.Length());
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A zero length copy.
  ByteArray::Copy(internal, 0, b_4_5_6_7, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // Another zero length copy.
  ByteArray::Copy(internal, 4, b_4_5_6_7, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A one element copy.
  ByteArray::Copy(internal, 0, b_4_5_6_7, 1);
  EXPECT_EQ(4, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A two element copy.
  ByteArray::Copy(internal, 2, b_4_5_6_7, 2);
  EXPECT_EQ(4, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(4, internal.At(2));
  EXPECT_EQ(5, internal.At(3));

  // A three element copy.
  ByteArray::Copy(internal, 1, b_4_5_6_7, 3);
  EXPECT_EQ(4, internal.At(0));
  EXPECT_EQ(4, internal.At(1));
  EXPECT_EQ(5, internal.At(2));
  EXPECT_EQ(6, internal.At(3));

  // A four element copy.
  ByteArray::Copy(internal, 0, b_0_1_2_3, 4);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));
}


TEST_CASE(ByteArrayCopyExternal) {
  const uint8_t b_0_1_2_3[] = { 0, 1, 2, 3 };
  const uint8_t b_4_5_6_7[] = { 4, 5, 6, 7 };

  uint8_t data[] = { 0, 1, 2, 3 };
  const ExternalUint8Array& external =
      ExternalUint8Array::Handle(
          ExternalUint8Array::New(data, ARRAY_SIZE(data), NULL, NULL));
  EXPECT(!external.IsNull());
  EXPECT_EQ(4, external.Length());
  EXPECT_EQ(0, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));

  // A zero length copy.
  ByteArray::Copy(external, 0, b_4_5_6_7, 0);
  EXPECT_EQ(0, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));

  // Another zero length copy.
  ByteArray::Copy(external, 4, b_4_5_6_7, 0);
  EXPECT_EQ(0, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));

  // A one element copy.
  ByteArray::Copy(external, 0, b_4_5_6_7, 1);
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));

  // A two element copy.
  ByteArray::Copy(external, 2, b_4_5_6_7, 2);
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(4, external.At(2));
  EXPECT_EQ(5, external.At(3));

  // A three element copy.
  ByteArray::Copy(external, 1, b_4_5_6_7, 3);
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(4, external.At(1));
  EXPECT_EQ(5, external.At(2));
  EXPECT_EQ(6, external.At(3));

  // A four element copy.
  ByteArray::Copy(external, 0, b_0_1_2_3, 4);
  EXPECT_EQ(0, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));
}


TEST_CASE(ByteArrayCopyInternalExternal) {
  const uint8_t b_0_1_2_3[] = { 0, 1, 2, 3 };

  const Uint8Array& internal =
      Uint8Array::Handle(Uint8Array::New(b_0_1_2_3, ARRAY_SIZE(b_0_1_2_3)));
  EXPECT(!internal.IsNull());
  EXPECT_EQ(4, internal.Length());
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  uint8_t data[] = { 4, 5, 6, 7 };
  const ExternalUint8Array& external =
      ExternalUint8Array::Handle(
          ExternalUint8Array::New(data, ARRAY_SIZE(data), NULL, NULL));
  EXPECT(!external.IsNull());
  EXPECT_EQ(4, external.Length());
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(5, external.At(1));
  EXPECT_EQ(6, external.At(2));
  EXPECT_EQ(7, external.At(3));

  // A zero length copy.
  ByteArray::Copy(internal, 0, external, 0, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A zero length copy, take 2.
  ByteArray::Copy(internal, 4, external, 0, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A zero length copy, take 3.
  ByteArray::Copy(internal, 0, external, 4, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A zero length copy, take 4.
  ByteArray::Copy(internal, 4, external, 4, 0);
  EXPECT_EQ(0, internal.At(0));
  EXPECT_EQ(1, internal.At(1));
  EXPECT_EQ(2, internal.At(2));
  EXPECT_EQ(3, internal.At(3));

  // A four element copy.
  ByteArray::Copy(internal, 0, external, 0, 4);
  EXPECT_EQ(4, internal.At(0));
  EXPECT_EQ(5, internal.At(1));
  EXPECT_EQ(6, internal.At(2));
  EXPECT_EQ(7, internal.At(3));
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(5, external.At(1));
  EXPECT_EQ(6, external.At(2));
  EXPECT_EQ(7, external.At(3));

  // A four element copy, take 2.
  ByteArray::Copy(external, 0, b_0_1_2_3, 4);
  EXPECT_EQ(0, external.At(0));
  EXPECT_EQ(1, external.At(1));
  EXPECT_EQ(2, external.At(2));
  EXPECT_EQ(3, external.At(3));
  ByteArray::Copy(external, 0, internal, 0, 4);
  EXPECT_EQ(4, internal.At(0));
  EXPECT_EQ(5, internal.At(1));
  EXPECT_EQ(6, internal.At(2));
  EXPECT_EQ(7, internal.At(3));
  EXPECT_EQ(4, external.At(0));
  EXPECT_EQ(5, external.At(1));
  EXPECT_EQ(6, external.At(2));
  EXPECT_EQ(7, external.At(3));
}


TEST_CASE(Script) {
  const char* url_chars = "builtin:test-case";
  const char* source_chars = "This will not compile.";
  const String& url = String::Handle(String::New(url_chars));
  const String& source = String::Handle(String::New(source_chars));
  const Script& script = Script::Handle(Script::New(url,
                                                    source,
                                                    RawScript::kSourceTag));
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


TEST_CASE(Context) {
  const int kNumVariables = 5;
  const Context& parent_context = Context::Handle(Context::New(0));
  EXPECT_EQ(parent_context.isolate(), Isolate::Current());
  const Context& context = Context::Handle(Context::New(kNumVariables));
  context.set_parent(parent_context);
  const Context& check_parent_context = Context::Handle(context.parent());
  EXPECT_EQ(context.isolate(), check_parent_context.isolate());
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


TEST_CASE(ContextScope) {
  const intptr_t parent_scope_function_level = 0;
  LocalScope* parent_scope =
      new LocalScope(NULL, parent_scope_function_level, 0);

  const intptr_t local_scope_function_level = 1;
  LocalScope* local_scope =
      new LocalScope(parent_scope, local_scope_function_level, 0);

  const Type& dynamic_type = Type::ZoneHandle(Type::DynamicType());
  const String& a = String::ZoneHandle(String::New("a"));
  LocalVariable* var_a =
      new LocalVariable(Scanner::kDummyTokenIndex, a, dynamic_type);
  parent_scope->AddVariable(var_a);

  const String& b = String::ZoneHandle(String::New("b"));
  LocalVariable* var_b =
      new LocalVariable(Scanner::kDummyTokenIndex, b, dynamic_type);
  local_scope->AddVariable(var_b);

  const String& c = String::ZoneHandle(String::New("c"));
  LocalVariable* var_c =
      new LocalVariable(Scanner::kDummyTokenIndex, c, dynamic_type);
  parent_scope->AddVariable(var_c);

  bool test_only = false;  // Please, insert alias.
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

  EXPECT_EQ(3, local_scope->num_variables());  // a, b, and c alias.
  EXPECT_EQ(2, local_scope->NumCapturedVariables());  // a, c alias.

  const int first_parameter_index = 0;
  const int num_parameters = 0;
  const int first_frame_index = -1;
  LocalScope* loop_owner = parent_scope;
  LocalScope* context_owner = NULL;   // No context allocated yet.
  int next_frame_index = parent_scope->AllocateVariables(first_parameter_index,
                                                         num_parameters,
                                                         first_frame_index,
                                                         loop_owner,
                                                         &context_owner);
  EXPECT_EQ(first_frame_index, next_frame_index);  // a and c not in frame.
  EXPECT_EQ(parent_scope, context_owner);  // parent_scope allocated a context.
  const intptr_t parent_scope_context_level = 1;
  EXPECT_EQ(parent_scope_context_level, parent_scope->context_level());

  const intptr_t local_scope_context_level = 5;
  const ContextScope& context_scope = ContextScope::Handle(
      local_scope->PreserveOuterScope(local_scope_context_level));
  LocalScope* outer_scope = LocalScope::RestoreOuterScope(context_scope);
  EXPECT_EQ(2, outer_scope->num_variables());

  var_a = outer_scope->LocalLookupVariable(a);
  EXPECT(var_a->is_captured());
  EXPECT_EQ(0, var_a->index());  // First index.
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_a->owner()->context_level());  // Adjusted context level.

  // var b was not captured.
  EXPECT(outer_scope->LocalLookupVariable(b) == NULL);

  var_c = outer_scope->LocalLookupVariable(c);
  EXPECT(var_c->is_captured());
  EXPECT_EQ(1, var_c->index());
  EXPECT_EQ(parent_scope_context_level - local_scope_context_level,
            var_c->owner()->context_level());  // Adjusted context level.
}


TEST_CASE(Closure) {
  // Allocate the class first.
  const String& class_name = String::Handle(Symbols::New("MyClass"));
  const Script& script = Script::Handle();
  const Class& cls =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  const Array& functions = Array::Handle(Array::New(1));

  const Context& context = Context::Handle(Context::New(0));
  Function& parent = Function::Handle();
  const String& parent_name = String::Handle(Symbols::New("foo_papa"));
  parent = Function::New(parent_name, RawFunction::kRegularFunction,
                         false, false, false, false, cls, 0);
  functions.SetAt(0, parent);
  cls.SetFunctions(functions);

  Function& function = Function::Handle();
  const String& function_name = String::Handle(Symbols::New("foo"));
  function = Function::NewClosureFunction(function_name, parent, 0);
  const Class& signature_class = Class::Handle(
      Class::NewSignatureClass(function_name, function, script));
  const Instance& closure = Instance::Handle(Closure::New(function, context));
  const Class& closure_class = Class::Handle(closure.clazz());
  EXPECT(closure_class.IsSignatureClass());
  EXPECT(closure_class.IsCanonicalSignatureClass());
  EXPECT_EQ(closure_class.raw(), signature_class.raw());
  const Function& signature_function =
    Function::Handle(signature_class.signature_function());
  EXPECT_EQ(signature_function.raw(), function.raw());
  const Context& closure_context = Context::Handle(Closure::context(closure));
  EXPECT_EQ(closure_context.raw(), closure_context.raw());
}


TEST_CASE(ObjectPrinting) {
  // Simple Smis.
  EXPECT_STREQ("2", Smi::Handle(Smi::New(2)).ToCString());
  EXPECT_STREQ("-15", Smi::Handle(Smi::New(-15)).ToCString());

  // bool class and true/false values.
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& bool_class = Class::Handle(object_store->bool_class());
  EXPECT_STREQ("Library:'dart:core' Class: bool",
               bool_class.ToCString());
  EXPECT_STREQ("true", Bool::Handle(Bool::True()).ToCString());
  EXPECT_STREQ("false", Bool::Handle(Bool::False()).ToCString());

  // Strings.
  EXPECT_STREQ("Sugarbowl",
               String::Handle(String::New("Sugarbowl")).ToCString());
}


TEST_CASE(CheckedHandle) {
  // Ensure that null handles have the correct C++ vtable setup.
  const String& str1 = String::Handle();
  EXPECT(str1.IsString());
  EXPECT(str1.IsNull());
  const String& str2 = String::CheckedHandle(Object::null());
  EXPECT(str2.IsString());
  EXPECT(str2.IsNull());
  String& str3 = String::Handle();
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


// only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

static Function* CreateFunction(const char* name) {
  const String& class_name = String::Handle(Symbols::New("ownerClass"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  const String& function_name = String::ZoneHandle(Symbols::New(name));
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, owner_class, 0));
  return &function;
}

// Test for Code and Instruction object creation.
TEST_CASE(Code) {
  extern void GenerateIncrement(Assembler* assembler);
  Assembler _assembler_;
  GenerateIncrement(&_assembler_);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_Code"), &_assembler_));
  Instructions& instructions = Instructions::Handle(code.instructions());
  typedef int (*IncrementCode)();
  EXPECT_EQ(2, reinterpret_cast<IncrementCode>(instructions.EntryPoint())());
  uword entry_point = instructions.EntryPoint();
  EXPECT_EQ(instructions.raw(), Instructions::FromEntryPoint(entry_point));
}


// Test for Embedded String object in the instructions.
TEST_CASE(EmbedStringInCode) {
  extern void GenerateEmbedStringInCode(Assembler* assembler, const char* str);
  const char* kHello = "Hello World!";
  word expected_length = static_cast<word>(strlen(kHello));
  Assembler _assembler_;
  GenerateEmbedStringInCode(&_assembler_, kHello);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_EmbedStringInCode"), &_assembler_));
  Instructions& instructions = Instructions::Handle(code.instructions());
  typedef uword (*EmbedStringCode)();
  uword retval = reinterpret_cast<EmbedStringCode>(instructions.EntryPoint())();
  EXPECT((retval & kSmiTagMask) == kHeapObjectTag);
  String& string_object = String::Handle();
  string_object ^= reinterpret_cast<RawInstructions*>(retval);
  EXPECT(string_object.Length() == expected_length);
  for (int i = 0; i < expected_length; i ++) {
    EXPECT(string_object.CharAt(i) == kHello[i]);
  }
}


// Test for Embedded Smi object in the instructions.
TEST_CASE(EmbedSmiInCode) {
  extern void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value);
  const intptr_t kSmiTestValue = 5;
  Assembler _assembler_;
  GenerateEmbedSmiInCode(&_assembler_, kSmiTestValue);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_EmbedSmiInCode"), &_assembler_));
  Instructions& instructions = Instructions::Handle(code.instructions());
  typedef intptr_t (*EmbedSmiCode)();
  intptr_t retval =
      reinterpret_cast<EmbedSmiCode>(instructions.EntryPoint())();
  EXPECT((retval >> kSmiTagShift) == kSmiTestValue);
}


#if defined(ARCH_IS_64_BIT)
// Test for Embedded Smi object in the instructions.
TEST_CASE(EmbedSmiIn64BitCode) {
  extern void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value);
  const intptr_t kSmiTestValue = 5L << 32;
  Assembler _assembler_;
  GenerateEmbedSmiInCode(&_assembler_, kSmiTestValue);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_EmbedSmiIn64BitCode"), &_assembler_));
  Instructions& instructions = Instructions::Handle(code.instructions());
  typedef intptr_t (*EmbedSmiCode)();
  intptr_t retval =
      reinterpret_cast<EmbedSmiCode>(instructions.EntryPoint())();
  EXPECT((retval >> kSmiTagShift) == kSmiTestValue);
}
#endif


TEST_CASE(ExceptionHandlers) {
  const int kNumEntries = 6;
  // Add an exception handler table to the code.
  ExceptionHandlers& exception_handlers = ExceptionHandlers::Handle();
  exception_handlers ^= ExceptionHandlers::New(kNumEntries);
  exception_handlers.SetHandlerEntry(0, 10, 20);
  exception_handlers.SetHandlerEntry(1, 20, 30);
  exception_handlers.SetHandlerEntry(2, 30, 40);
  exception_handlers.SetHandlerEntry(3, 10, 40);
  exception_handlers.SetHandlerEntry(4, 10, 80);
  exception_handlers.SetHandlerEntry(5, 80, 150);

  extern void GenerateIncrement(Assembler* assembler);
  Assembler _assembler_;
  GenerateIncrement(&_assembler_);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_Code"), &_assembler_));
  code.set_exception_handlers(exception_handlers);

  // Verify the exception handler table entries by accessing them.
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(code.exception_handlers());
  EXPECT_EQ(kNumEntries, handlers.Length());
  EXPECT_EQ(10, handlers.TryIndex(0));
  EXPECT_EQ(20, handlers.HandlerPC(0));
  EXPECT_EQ(80, handlers.TryIndex(5));
  EXPECT_EQ(150, handlers.HandlerPC(5));
}


TEST_CASE(PcDescriptors) {
  const int kNumEntries = 6;
  // Add PcDescriptors to the code.
  PcDescriptors& descriptors = PcDescriptors::Handle();
  descriptors ^= PcDescriptors::New(kNumEntries);
  descriptors.AddDescriptor(0, 10, PcDescriptors::kOther, 1, 20, 1);
  descriptors.AddDescriptor(1, 20, PcDescriptors::kDeoptBefore, 2, 30, 0);
  descriptors.AddDescriptor(2, 30, PcDescriptors::kOther, 3, 40, 1);
  descriptors.AddDescriptor(3, 10, PcDescriptors::kOther, 4, 40, 2);
  descriptors.AddDescriptor(4, 10, PcDescriptors::kOther, 5, 80, 3);
  descriptors.AddDescriptor(5, 80, PcDescriptors::kOther, 6, 150, 3);

  extern void GenerateIncrement(Assembler* assembler);
  Assembler _assembler_;
  GenerateIncrement(&_assembler_);
  Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_Code"), &_assembler_));
  code.set_pc_descriptors(descriptors);

  // Verify the PcDescriptor entries by accessing them.
  const PcDescriptors& pc_descs = PcDescriptors::Handle(code.pc_descriptors());
  EXPECT_EQ(kNumEntries, pc_descs.Length());
  EXPECT_EQ(1, pc_descs.TryIndex(0));
  EXPECT_EQ(static_cast<uword>(10), pc_descs.PC(0));
  EXPECT_EQ(1, pc_descs.DeoptId(0));
  EXPECT_EQ(20, pc_descs.TokenPos(0));
  EXPECT_EQ(3, pc_descs.TryIndex(5));
  EXPECT_EQ(static_cast<uword>(80), pc_descs.PC(5));
  EXPECT_EQ(150, pc_descs.TokenPos(5));
  EXPECT_EQ(PcDescriptors::kOther, pc_descs.DescriptorKind(0));
  EXPECT_EQ(PcDescriptors::kDeoptBefore, pc_descs.DescriptorKind(1));
}


static RawClass* CreateTestClass(const char* name) {
  const String& class_name = String::Handle(Symbols::New(name));
  const Class& cls = Class::Handle(
      Class::New(class_name, Script::Handle(), Scanner::kDummyTokenIndex));
  return cls.raw();
}


static RawField* CreateTestField(const char* name) {
  const Class& cls = Class::Handle(CreateTestClass("global:"));
  const String& field_name = String::Handle(Symbols::New(name));
  const Field& field =
      Field::Handle(Field::New(field_name, true, false, false, cls, 0));
  return field.raw();
}


TEST_CASE(ClassDictionaryIterator) {
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
    ASSERT((cls.raw() == ae66.raw()) || (cls.raw() == re44.raw()));
    count++;
  }
  ASSERT(count == 2);
}


static RawFunction* GetDummyTarget(const char* name) {
  const String& function_name = String::Handle(Symbols::New(name));
  const Class& cls = Class::Handle(
       Class::New(function_name, Script::Handle(), Scanner::kDummyTokenIndex));
  const bool is_static = false;
  const bool is_const = false;
  const bool is_abstract = false;
  const bool is_external = false;
  return Function::New(function_name,
                       RawFunction::kRegularFunction,
                       is_static,
                       is_const,
                       is_abstract,
                       is_external,
                       cls,
                       0);
}


TEST_CASE(ICData) {
  Function& function = Function::Handle(GetDummyTarget("Bern"));
  const intptr_t id = 12;
  const intptr_t num_args_tested = 1;
  const String& target_name = String::Handle(String::New("Thun"));
  ICData& o1 = ICData::Handle();
  o1 = ICData::New(function, target_name, id, num_args_tested);
  EXPECT_EQ(1, o1.num_args_tested());
  EXPECT_EQ(id, o1.deopt_id());
  EXPECT_EQ(function.raw(), o1.function());
  EXPECT_EQ(0, o1.NumberOfChecks());
  EXPECT_EQ(target_name.raw(), o1.target_name());

  const Function& target1 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kSmiCid, target1);
  EXPECT_EQ(1, o1.NumberOfChecks());
  intptr_t test_class_id = -1;
  Function& test_target = Function::Handle();
  o1.GetOneClassCheckAt(0, &test_class_id, &test_target);
  EXPECT_EQ(kSmiCid, test_class_id);
  EXPECT_EQ(target1.raw(), test_target.raw());
  GrowableArray<intptr_t> test_class_ids;
  o1.GetCheckAt(0, &test_class_ids, &test_target);
  EXPECT_EQ(1, test_class_ids.length());
  EXPECT_EQ(kSmiCid, test_class_ids[0]);
  EXPECT_EQ(target1.raw(), test_target.raw());

  const Function& target2 = Function::Handle(GetDummyTarget("Thun"));
  o1.AddReceiverCheck(kDoubleCid, target2);
  EXPECT_EQ(2, o1.NumberOfChecks());
  o1.GetOneClassCheckAt(1, &test_class_id, &test_target);
  EXPECT_EQ(kDoubleCid, test_class_id);
  EXPECT_EQ(target2.raw(), test_target.raw());

  ICData& o2 = ICData::Handle();
  o2 = ICData::New(function, target_name, 57, 2);
  EXPECT_EQ(2, o2.num_args_tested());
  EXPECT_EQ(57, o2.deopt_id());
  EXPECT_EQ(function.raw(), o2.function());
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
}


TEST_CASE(SubtypeTestCache) {
  String& class_name = String::Handle(Symbols::New("EmptyClass"));
  Script& script = Script::Handle();
  const Class& empty_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  SubtypeTestCache& cache = SubtypeTestCache::Handle(SubtypeTestCache::New());
  ASSERT(!cache.IsNull());
  EXPECT_EQ(0, cache.NumberOfChecks());
  const TypeArguments& targ_0 = TypeArguments::Handle(TypeArguments::New(2));
  const TypeArguments& targ_1 = TypeArguments::Handle(TypeArguments::New(3));
  cache.AddCheck(empty_class.id(), targ_0, targ_1, Bool::Handle(Bool::True()));
  EXPECT_EQ(1, cache.NumberOfChecks());
  intptr_t test_class_id = -1;
  AbstractTypeArguments& test_targ_0 = AbstractTypeArguments::Handle();
  AbstractTypeArguments& test_targ_1 = AbstractTypeArguments::Handle();
  Bool& test_result = Bool::Handle();
  cache.GetCheck(0, &test_class_id, &test_targ_0, &test_targ_1, &test_result);
  EXPECT_EQ(empty_class.id(), test_class_id);
  EXPECT_EQ(targ_0.raw(), test_targ_0.raw());
  EXPECT_EQ(targ_1.raw(), test_targ_1.raw());
  EXPECT_EQ(Bool::True(), test_result.raw());
}


TEST_CASE(FieldTests) {
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


TEST_CASE(EqualsIgnoringPrivate) {
  String& mangled_name = String::Handle();
  String& bare_name = String::Handle();

  // Simple matches.
  mangled_name = OneByteString::New("foo");
  bare_name = OneByteString::New("foo");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.");
  bare_name = OneByteString::New("foo.");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.named");
  bare_name = OneByteString::New("foo.named");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Simple mismatches.
  mangled_name = OneByteString::New("bar");
  bare_name = OneByteString::New("foo");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.");
  bare_name = OneByteString::New("foo");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo");
  bare_name = OneByteString::New("foo.");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.name");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  mangled_name = OneByteString::New("foo.named");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private match.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("foo");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mismatch.
  mangled_name = OneByteString::New("food@12345");
  bare_name = OneByteString::New("foo");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private mismatch 2.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("food");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor match.
  mangled_name = OneByteString::New("foo@12345.");
  bare_name = OneByteString::New("foo.");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.");
  bare_name = OneByteString::New("foo");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Private constructor mismatch 2.
  mangled_name = OneByteString::New("foo@12345");
  bare_name = OneByteString::New("foo.");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor match.
  mangled_name = OneByteString::New("foo@12345.named");
  bare_name = OneByteString::New("foo.named");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.name");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named private constructor mismatch 2.
  mangled_name = OneByteString::New("foo@12345.named");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor match.  Yes, this happens.
  mangled_name = OneByteString::New("foo@12345.named@12345");
  bare_name = OneByteString::New("foo.named");
  EXPECT(OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.name@12345");
  bare_name = OneByteString::New("foo.named");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));

  // Named double-private constructor mismatch.
  mangled_name = OneByteString::New("foo@12345.named@12345");
  bare_name = OneByteString::New("foo.name");
  EXPECT(!OneByteString::EqualsIgnoringPrivateKey(mangled_name, bare_name));
}


TEST_CASE(ArrayNew_Overflow_Crash) {
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
  EXPECT_ERROR(
      result,
      "Unhandled exception:\n"
      "MyException\n"
      "#0      baz (dart:test-lib:2:3)\n"
      "#1      _OtherClass._OtherClass._named (dart:test-lib:7:8)\n"
      "#2      globalVar= (dart:test-lib:12:3)\n"
      "#3      _bar (dart:test-lib:16:3)\n"
      "#4      MyClass.field (dart:test-lib:25:9)\n"
      "#5      MyClass.foo.fooHelper (dart:test-lib:30:7)\n"
      "#6      MyClass.foo (dart:test-lib:32:14)\n"
      "#7      MyClass.MyClass.<anonymous closure> (dart:test-lib:21:15)\n"
      "#8      MyClass.MyClass (dart:test-lib:21:18)\n"
      "#9      main.<anonymous closure> (dart:test-lib:37:10)\n"
      "#10     main (dart:test-lib:37:24)");
}


TEST_CASE(WeakProperty_PreserveCrossGen) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  {
    // Weak property and value in new. Key in old.
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key in new.
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in new. Key is a Smi.
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due implicit liveness of
  // non-heap objects.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key is a Smi.
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due implicit liveness of
  // non-heap objects.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in new. Key in VM isolate.
    HANDLESCOPE(isolate);
    String& key = String::Handle();
    key ^= Symbols::Dot();
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kNew);
    weak ^= WeakProperty::New(Heap::kNew);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
  {
    // Weak property and value in old. Key in VM isolate.
    HANDLESCOPE(isolate);
    String& key = String::Handle();
    key ^= Symbols::Dot();
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
    key ^= OneByteString::null();
    value ^= OneByteString::null();
  }
  isolate->heap()->CollectAllGarbage();
  // Weak property key and value should survive due to cross-generation
  // pointers.
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveRecurse) {
  // This used to end in an infinite recursion. Caused by scavenging the weak
  // property before scavenging the key.
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  Array& arr = Array::Handle(Array::New(1));
  {
    HANDLESCOPE(isolate);
    String& key = String::Handle();
    key ^= OneByteString::New("key");
    arr.SetAt(0, key);
    String& value = String::Handle();
    value ^= OneByteString::New("value");
    weak ^= WeakProperty::New();
    weak.set_key(key);
    weak.set_value(value);
  }
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveOne_NewSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key");
  {
    HANDLESCOPE(isolate);
    String& value = String::Handle();
    value ^= OneByteString::New("value");
    weak ^= WeakProperty::New();
    weak.set_key(key);
    weak.set_value(value);
  }
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveTwo_NewSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  String& key1 = String::Handle();
  key1 ^= OneByteString::New("key1");
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key2 = String::Handle();
  key2 ^= OneByteString::New("key2");
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveTwoShared_NewSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key");
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveOne_OldSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key", Heap::kOld);
  {
    HANDLESCOPE(isolate);
    String& value = String::Handle();
    value ^= OneByteString::New("value", Heap::kOld);
    weak ^= WeakProperty::New(Heap::kOld);
    weak.set_key(key);
    weak.set_value(value);
  }
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak.key() != Object::null());
  EXPECT(weak.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveTwo_OldSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  String& key1 = String::Handle();
  key1 ^= OneByteString::New("key1", Heap::kOld);
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key2 = String::Handle();
  key2 ^= OneByteString::New("key2", Heap::kOld);
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}


TEST_CASE(WeakProperty_PreserveTwoShared_OldSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  String& key = String::Handle();
  key ^= OneByteString::New("key", Heap::kOld);
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() != Object::null());
  EXPECT(weak1.value() != Object::null());
  EXPECT(weak2.key() != Object::null());
  EXPECT(weak2.value() != Object::null());
}


TEST_CASE(WeakProperty_ClearOne_NewSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak.key() == Object::null());
  EXPECT(weak.value() == Object::null());
}


TEST_CASE(WeakProperty_ClearTwoShared_NewSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() == Object::null());
  EXPECT(weak1.value() == Object::null());
  EXPECT(weak2.key() == Object::null());
  EXPECT(weak2.value() == Object::null());
}


TEST_CASE(WeakProperty_ClearOne_OldSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak = WeakProperty::Handle();
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak.key() == Object::null());
  EXPECT(weak.value() == Object::null());
}


TEST_CASE(WeakProperty_ClearTwoShared_OldSpace) {
  Isolate* isolate = Isolate::Current();
  WeakProperty& weak1 = WeakProperty::Handle();
  WeakProperty& weak2 = WeakProperty::Handle();
  {
    HANDLESCOPE(isolate);
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
  isolate->heap()->CollectAllGarbage();
  EXPECT(weak1.key() == Object::null());
  EXPECT(weak1.value() == Object::null());
  EXPECT(weak2.key() == Object::null());
  EXPECT(weak2.value() == Object::null());
}


static RawFunction* GetFunction(const Class& cls, const char* name) {
  const Function& result = Function::Handle(cls.LookupDynamicFunction(
      String::Handle(String::New(name))));
  ASSERT(!result.IsNull());
  return result.raw();
}


TEST_CASE(FunctionSourceFingerprint) {
  const char* kScriptChars =
      "class A {\n"
      "  void test1(int a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "  void test2(int a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "  void test3(a) {\n"
      "    return a > 1 ? a + 1 : a;\n"
      "  }\n"
      "  void test4(b) {\n"
      "    return b > 1 ? b + 1 : b;\n"
      "  }\n"
      "  void test5(b) {\n"
      "    return b > 1 ? b - 1 : b;\n"
      "  }\n"
      "  void test6(b) {\n"
      "    return b > 1 ? b - 2 : b;\n"
      "  }\n"
      "  void test7(b) {\n"
      "    return b > 1 ?\n"
      "        b - 2 : b;\n"
      "  }\n"
      "}";
  TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(name));
  EXPECT(!lib.IsNull());

  const Class& class_a = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("A"))));
  const Function& test1 = Function::Handle(GetFunction(class_a, "test1"));
  const Function& test2 = Function::Handle(GetFunction(class_a, "test2"));
  const Function& test3 = Function::Handle(GetFunction(class_a, "test3"));
  const Function& test4 = Function::Handle(GetFunction(class_a, "test4"));
  const Function& test5 = Function::Handle(GetFunction(class_a, "test5"));
  const Function& test6 = Function::Handle(GetFunction(class_a, "test6"));
  const Function& test7 = Function::Handle(GetFunction(class_a, "test7"));
  EXPECT_EQ(test1.SourceFingerprint(), test2.SourceFingerprint());
  EXPECT_NE(test1.SourceFingerprint(), test3.SourceFingerprint());
  EXPECT_NE(test3.SourceFingerprint(), test4.SourceFingerprint());
  EXPECT_NE(test4.SourceFingerprint(), test5.SourceFingerprint());
  EXPECT_NE(test5.SourceFingerprint(), test6.SourceFingerprint());
  EXPECT_EQ(test6.SourceFingerprint(), test7.SourceFingerprint());
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
