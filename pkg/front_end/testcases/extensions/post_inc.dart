// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  Object a = "a";

  expect("a.field", a.field++, "a.field=(a.field+1)");
  expect("a.field", a.field--, "a.field=(a.field-1)");
}

// Last value set by a setter.
String setValue = "";

void expect(String expect, Object value, String expectSet) {
  if (expect != value) {
    throw 'Expected value ${expect}, actual ${value}';
  }
  if (expectSet != setValue) {
    throw 'Expected assignment ${expectSet}, actual ${setValue}';
  }
}

extension Ops on Object {
  Object operator +(Object other) => "(${this}+$other)";
  Object operator -(Object other) => "(${this}-$other)";

  Object get field => "${this}.field";
  void set field(Object other) {
    setValue = "${this}.field=$other";
  }
}
