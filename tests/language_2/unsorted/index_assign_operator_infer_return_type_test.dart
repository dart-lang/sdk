// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  operator []=(dynamic index, dynamic value) {}
}

abstract class I {
  void operator []=(dynamic index, dynamic value) {}
}

class D extends C implements I {
  // Even though `C` and `I` define different return types for `operator[]=`, it
  // should still be possible to infer a return type here, since the return type
  // of `operator[]=` is always inferred as `void`.
  operator []=(dynamic index, dynamic value) {}
}

main() {}
