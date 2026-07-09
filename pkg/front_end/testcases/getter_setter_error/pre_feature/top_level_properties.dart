// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.6

// No getter/setter check due to invalid getter type.
Unknown get foo1 => throw 0;
void set foo1(dynamic value) {}

// No getter/setter check due to invalid setter type.
Never get foo2 => throw 0;
void set foo2(Unknown value) {}

// Passing getter/setter check.
String get foo3 => "";
void set foo3(String value) {}

// Non-passing getter/setter check.
Symbol get foo4 => #foo4;
void set foo4(double value) {}
