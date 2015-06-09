// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate that an attempt to invoke a prefix is handled consistently with the
// following spec text from section 16.14.3 (Unqualified invocation):
//     An unqualifiedfunction invocation i has the form
//     id(a1, ..., an, xn+1 : an+1, ..., xn+k : an+k),
//     where id is an identifier.
//     If there exists a lexically visible declaration named id, let fid be the
//   innermost such declaration.  Then
//     - If fid isa local function, a library function, a library or static
//       getter or a variable then ...
//     - Otherwise, if fid is a static method of the enclosing class C, ...
//     - Otherwise, fid is considered equivalent to the ordinary method
//       invocation this.id(a1, ..., an, xn+1 : an+1, ..., xn+k : an+k).
//
// Therefore, if p is an import prefix, evaluation of "p()" should be
// equivalent to "this.p()".  That is, it should call the method "p"
// dynamically if inside a method, and should produce a NoSucMethodError (and a
// static warning) outside a method.

import "package:expect/expect.dart";
import "empty_library.dart" as p;

class Base {
  var pCalled = false;

  void p() {
    pCalled = true;
  }
}

class Derived extends Base {
  void f() {
    p(); Expect.isTrue(pCalled); /// 01: ok
  }
}

noMethod(e) => e is NoSuchMethodError;

main() {
  new Derived().f();
  Expect.throws(() { p(); }, noMethod); /// 02: static type warning
}
