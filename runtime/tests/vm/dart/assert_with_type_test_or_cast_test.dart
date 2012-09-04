// VMOptions=
// VMOptions=--enable_asserts

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Issue 3741: generic type tests and casts fail in assertion statements
// when run in production mode.  
//
// The cause was incomplete generic type skipping, so each of the assert
// statements below would fail.
main() {
 var names = new List<String>();
 
 // Generic type test.
 assert(names is List<String>);
 
 // Negated generic type test.
 assert(names is !List<int>);
 
 // Generic type cast.
 assert((names as List<int>).length == 0);
 
 // Generic type test inside expression.
 assert((names is List<String>));
}
