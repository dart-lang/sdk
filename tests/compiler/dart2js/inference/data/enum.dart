// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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
  /*element: Enum1.a:[exact=Enum1]*/
  a,
}

/*element: enumValue:[exact=Enum1]*/
enumValue() => Enum1.a;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'index' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum2 {
  /*element: Enum2.a:[exact=Enum2]*/
  a,
}

/*element: enumIndex:[exact=JSUInt31]*/
enumIndex() => Enum2.a. /*[exact=Enum2]*/ index;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'values' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum3 {
  /*element: Enum3.a:[exact=Enum3]*/
  a,
  /*element: Enum3.b:[exact=Enum3]*/
  b,
}

/*element: enumValues:Container mask: [exact=Enum3] length: 2 type: [exact=JSUnmodifiableArray]*/
enumValues() => Enum3.values;

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on a singleton enum.
////////////////////////////////////////////////////////////////////////////////

enum Enum4 {
  /*element: Enum4.a:[exact=Enum4]*/
  a,
}

/*element: enumToString1:Value mask: ["Enum4.a"] type: [null|exact=JSString]*/
enumToString1() {
  return Enum4.a. /*invoke: [exact=Enum4]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on an enum with multiple values.
////////////////////////////////////////////////////////////////////////////////

enum Enum5 {
  /*element: Enum5.a:[exact=Enum5]*/
  a,
  /*element: Enum5.b:[exact=Enum5]*/
  b,
}
// TODO(johnniwinther): Used the optimized enum encoding this yields
// [exact=JSString] instead of [null|exact=JSString].
/*element: enumToString2:[null|exact=JSString]*/
enumToString2() {
  Enum5.b. /*invoke: [exact=Enum5]*/ toString();
  return Enum5.a. /*invoke: [exact=Enum5]*/ toString();
}
