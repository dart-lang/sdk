// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@native("*A")
class A {}
@native makeA();

@native("""
function A() {}
makeA = function(){return new A;};
""")
void setup();


main() {
  setup();
  Expect.isTrue(makeA().toString() is String);
}
