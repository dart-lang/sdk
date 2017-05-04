// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to see if a Dart class name is confused with dispatch tag.  Both class A
// and class Z have a JavaScript constructor named "A".  The dynamic native
// class dispatch hook on Object.prototype should avoid patching the Dart class
// A.  This could be done by renaming the Dart constructor or by being able to
// check that objects are Dart classes.

import "native_testing.dart";

class A {}

@Native("A")
class Z {
  foo() => 100;
}

makeZ() native;

void setup() native """
function A(){}
makeZ = function(){return new A};
self.nativeConstructor(A);
""";

main() {
  nativeTesting();
  setup();

  var a = new A();
  var z = makeZ();

  Expect.equals(100, z.foo());

  Expect.throws(() => a.foo(), (ex) => ex is NoSuchMethodError);
}
