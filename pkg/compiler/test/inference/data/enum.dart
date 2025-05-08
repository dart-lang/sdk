// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

enum Enum1 { a }

/*member: enumValue:[exact=Enum1|powerset={N}{O}]*/
enumValue() => Enum1.a;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'index' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum2 { a }

/*member: enumIndex:[exact=JSUInt31|powerset={I}{O}]*/
enumIndex() => Enum2.a. /*[exact=Enum2|powerset={N}{O}]*/ index;

////////////////////////////////////////////////////////////////////////////////
/// Access an enum 'values' property.
////////////////////////////////////////////////////////////////////////////////

enum Enum3 { a, b }

/*member: enumValues:Container([exact=JSUnmodifiableArray|powerset={I}{U}], element: [exact=Enum3|powerset={N}{O}], length: 2, powerset: {I}{U})*/
enumValues() => Enum3.values;

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on a singleton enum.
////////////////////////////////////////////////////////////////////////////////

enum Enum4 { a }

/*member: enumToString1:[exact=JSString|powerset={I}{O}]*/
enumToString1() {
  return Enum4.a. /*invoke: [exact=Enum4|powerset={N}{O}]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
/// Call an enum 'toString' method on an enum with multiple values.
////////////////////////////////////////////////////////////////////////////////

enum Enum5 { a, b }

/*member: enumToString2:[exact=JSString|powerset={I}{O}]*/
enumToString2() {
  Enum5.b. /*invoke: [exact=Enum5|powerset={N}{O}]*/ toString();
  return Enum5.a. /*invoke: [exact=Enum5|powerset={N}{O}]*/ toString();
}
