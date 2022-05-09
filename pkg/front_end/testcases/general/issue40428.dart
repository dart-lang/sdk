// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class SuperClass1 {
  final String value;

  SuperClass1(this.value);
}

abstract class SuperClass2 {
  final String value;

  SuperClass2(String i) : value = i;
}

class Mixin {}

class NamedMixin1 = SuperClass1 with Mixin;
class NamedMixin2 = SuperClass2 with Mixin;

void main() {
  new NamedMixin1('');
  new NamedMixin2('');
}

errors() {
  new NamedMixin1(0);
  new NamedMixin2(0);
}
