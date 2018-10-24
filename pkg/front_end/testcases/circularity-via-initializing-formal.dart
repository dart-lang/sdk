// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is intended to trigger a circular top-level type-inference
// dependency involving an initializing formal where the circularity is detected
// when inferring the type of the constructor.
//
// The compiler should generate an error message and it should be properly
// formatted including offset and length of the constructor.
var x = new C._circular(null);

class C {
  var f = new C._circular(null);
  C._circular(this.f);
}

main() {}
