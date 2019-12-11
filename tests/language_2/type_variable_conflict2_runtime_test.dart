// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13134. Invocation of a type parameter.

import "package:expect/expect.dart";

class C<T> {
  noSuchMethod(Invocation im) {
    throw "noSuchMethod shouldn't be called in this test.";
  }

  // This is equivalent to (T).call(). See issue 19725


  // T is in scope, even in static context. Compile-time error to call this.T().


  // X is not in scope. NoSuchMethodError.


  // Class 'C' has no static method 'T': NoSuchMethodError.


  // Class '_Type' has no instance method 'call': NoSuchMethodError.


  // Runtime type T not accessible from static context. Compile-time error.


  // Class '_Type' has no [] operator: NoSuchMethodError.


  // Runtime type T not accessible from static context. Compile-time error.


  // Class '_Type' has no member m: NoSuchMethodError.


  // Runtime type T not accessible from static context. Compile-time error.

}

main() {










}
