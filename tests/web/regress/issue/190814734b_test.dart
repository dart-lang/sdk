// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2jsOptions=--null-assertions --enable-asserts

@pragma('dart2js:noInline')
confuse(x) => x;

class MyObject {
  // Operator == _not_ overridden.
}

class MyObject2 {
  @override
  bool operator ==(other) => other is MyObject2;
}

void main() {
  confuse(MyObject2());
  print(confuse(MyObject()) == confuse(null));
}
