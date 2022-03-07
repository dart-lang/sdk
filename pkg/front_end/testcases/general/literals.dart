// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testString() {
  print("a");
}

testInt() {
  print(1);
}

testBool() {
  print(true);
  print(false);
}

testDouble() {
  print(1.0);
}

testNull() {
  print(null);
}

testList() {
  print([]);
  print(["a", "b"]);
}

testMap() {
  print({});
  print({"a": "b"});
}

testSymbol() {
  print(#fisk);
  print(#_fisk);
  print(#fisk.hest.ko);
}

main() {
  testString();
  testInt();
  testBool();
  testDouble();
  testNull();
  testList();
  testMap();
  testSymbol();
}
