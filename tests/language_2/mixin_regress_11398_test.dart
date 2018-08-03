// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var hva = new HasValueA();
  hva.value = '42';
  Expect.equals('42', hva.value);

  var hvb = new HasValueB();
  hvb.value = '87';
  Expect.equals('87', hvb.value);

  var hvc = new HasValueC();
  hvc.value = '99';
  Expect.equals('99', hvc.value);
}

abstract class Delegate {
  String invoke(String value);
}

abstract class DelegateMixin {
  String invoke(String value) => value;
}

abstract class HasValueMixin implements Delegate {
  String _value;
  set value(String value) {
    _value = invoke(value);
  }

  String get value => _value;
}

class HasValueA extends Object with HasValueMixin, DelegateMixin {}

class HasValueB extends Object with DelegateMixin, HasValueMixin {}

class HasValueC extends Object with HasValueMixin {
  String invoke(String value) => value;
}
