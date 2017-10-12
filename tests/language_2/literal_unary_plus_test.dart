// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// There is no unary plus operator in Dart.
// Only a number literal can be preceded by a "+'".

main() {
  var a = + 1; //      //# 01: compile-time error
  var x = +"foo"; //   //# 02: compile-time error
  var x = + "foo"; //  //# 03: compile-time error
}
