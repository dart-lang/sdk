// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

/*element: Class.:[exact=Class]*/
class Class<T> {
  /*element: Class.method:[null]*/
  method() {
    /*iterator: Container mask: [empty] length: 0 type: [exact=JSExtendableArray]*/
    /*current: [exact=ArrayIterator]*/
    /*moveNext: [exact=ArrayIterator]*/
    for (var a in []) {
      // ignore: invocation_of_non_function_expression
      (T) /*invoke: [exact=TypeImpl]*/ (a);
      // ignore: invocation_of_non_function_expression
      (Object) /*invoke: [exact=TypeImpl]*/ ();
      // ignore: invocation_of_non_function_expression
      (this) /*invoke: [exact=Class]*/ ();
      // ignore: invocation_of_non_function_expression
      (1) /*invoke: [exact=JSUInt31]*/ ();
    }
  }
}

/*element: main:[null]*/
main() {
  new Class(). /*invoke: [exact=Class]*/ method();
}
