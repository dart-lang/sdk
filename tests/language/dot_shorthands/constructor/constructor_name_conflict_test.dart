// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We allow using dot shorthands on constructors with the same name as an
// instance method or field.

// SharedOptions=--enable-experiment=dot-shorthands

import 'package:expect/expect.dart';

class Getter {
  final int value; // Same name as constructor
  Getter.value(this.value);
}

class Setter {
  int? val;
  Setter.value(this.val);
  // Same name as constructor
  set value(int v) {
    val = v;
  }
}

class Method {
  final int val;
  Method.value(this.val);
  Method? value() => null; // Same name as constructor
}

class Factory {
  final int val;
  Factory._(this.val);
  factory Factory.foo() => Factory._(1);
  Factory? foo() => Factory._(2); // Same name as constructor
}

void main() {
  Getter getter = .value(1);
  Expect.equals(1, getter.value);

  Setter setter = .value(1);
  Expect.equals(1, setter.val);

  Method method = .value(1);
  Expect.equals(1, method.val);

  Factory f = .foo();
  Expect.equals(1, f.val);
}
