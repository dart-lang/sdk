// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

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
  a,
}

/*member: enumValue:[exact=Enum1]*/
enumValue() => Enum1.a;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'index' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum2 {
  a,
}

/*member: enumIndex:[exact=JSUInt31]*/
enumIndex() => Enum2.a. /*[exact=Enum2]*/ index;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'values' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum3 {
  a,
  b,
}

/*member: enumValues:Container([exact=JSUnmodifiableArray], element: [exact=Enum3], length: 2)*/
enumValues() => Enum3.values;

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on a singleton enum.
////////////////////////////////////////////////////////////////////////////////

enum Enum4 {
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
  a,
  b,
}

/*member: enumToString2:[exact=JSString]*/
enumToString2() {
  Enum5.b. /*invoke: [exact=Enum5]*/ toString();
  return Enum5.a. /*invoke: [exact=Enum5]*/ toString();
}
