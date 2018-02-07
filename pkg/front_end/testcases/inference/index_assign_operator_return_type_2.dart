// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

class C {
  dynamic operator []=(int index, dynamic value) {}
}

abstract class I {
  void operator []=(int index, dynamic value) {}
}

class D extends C implements I {
  operator /*@topType=void*/ []=(int index, /*@topType=dynamic*/ value) {}
}

main() {}
