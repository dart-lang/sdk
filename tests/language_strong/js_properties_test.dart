// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that JavaScript properties on Object can still be classes in
// Dart.

import "package:expect/expect.dart";

void main() {
  Expect.equals(42, new __defineGetter__().hello());
  Expect.equals(42, new __defineSetter__().hello());
  Expect.equals(42, new __lookupGetter__().hello());
  Expect.equals(42, new __lookupSetter__().hello());
  Expect.equals(42, new constructor().hello());
  Expect.equals(42, new hasOwnProperty().hello());
  Expect.equals(42, new isPrototypeOf().hello());
  Expect.equals(42, new propertyIsEnumerable().hello());
  Expect.equals(42, new toLocaleString().hello());
  Expect.equals(42, new toString().hello());
  Expect.equals(42, new valueOf().hello());
}

class Hello {
  int hello() => 42;
}

class __defineGetter__ extends Hello {}

class __defineSetter__ extends Hello {}

class __lookupGetter__ extends Hello {}

class __lookupSetter__ extends Hello {}

class constructor extends Hello {}

class hasOwnProperty extends Hello {}

class isPrototypeOf extends Hello {}

class propertyIsEnumerable extends Hello {}

class toLocaleString extends Hello {}

class toString extends Hello {}

class valueOf extends Hello {}
