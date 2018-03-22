// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_single_cascade_in_expression_statements`

main(){
  var o;
  o..toString(); // LINT
  o..toString()..toString(); // OK
  f(o..toString()); // OK
  if(o..hashCode){} // OK
  throw o..toString(); // OK
}

f(o) => null;