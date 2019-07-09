// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
main() {
  enumValue();
  enumIndex();
  enumValues();
  enumToString1();
  enumToString2();
}

////////////////////////////////////////////////////////////////////////////////
/// Access an enum value.
////////////////////////////////////////////////////////////////////////////////

enum Enum1 {
  /*strong.member: Enum1.a:[exact=Enum1]*/
  /*omit.member: Enum1.a:[exact=Enum1]*/
  a,
}

/*member: enumValue:[exact=Enum1]*/
enumValue() => Enum1.a;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'index' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum2 {
  /*strong.member: Enum2.a:[exact=Enum2]*/
  /*omit.member: Enum2.a:[exact=Enum2]*/
  a,
}

/*member: enumIndex:[exact=JSUInt31]*/
enumIndex() => Enum2.a. /*[exact=Enum2]*/ index;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'values' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum3 {
  /*strong.member: Enum3.a:[exact=Enum3]*/
  /*omit.member: Enum3.a:[exact=Enum3]*/
  a,
  /*strong.member: Enum3.b:[exact=Enum3]*/
  /*omit.member: Enum3.b:[exact=Enum3]*/
  b,
}

/*member: enumValues:Container([exact=JSUnmodifiableArray], element: [exact=Enum3], length: 2)*/
enumValues() => Enum3.values;

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on a singleton enum.
////////////////////////////////////////////////////////////////////////////////

enum Enum4 {
  /*strong.member: Enum4.a:[exact=Enum4]*/
  /*omit.member: Enum4.a:[exact=Enum4]*/
  a,
}

/*member: enumToString1:Value([exact=JSString], value: "Enum4.a")*/
enumToString1() {
  return Enum4.a. /*invoke: [exact=Enum4]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on an enum with multiple values.
////////////////////////////////////////////////////////////////////////////////

enum Enum5 {
  /*strong.member: Enum5.a:[exact=Enum5]*/
  /*omit.member: Enum5.a:[exact=Enum5]*/
  a,
  /*strong.member: Enum5.b:[exact=Enum5]*/
  /*omit.member: Enum5.b:[exact=Enum5]*/
  b,
}

/*member: enumToString2:[exact=JSString]*/
enumToString2() {
  Enum5.b. /*invoke: [exact=Enum5]*/ toString();
  return Enum5.a. /*invoke: [exact=Enum5]*/ toString();
}
