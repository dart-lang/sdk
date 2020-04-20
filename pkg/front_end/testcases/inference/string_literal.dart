// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/*@testedFeatures=inference*/
library test;

var x = 1;
var a = 'aaa';
var b = 'b ${x} bb';
var c = 'c ${x} cc' 'ccc';

main() {
  var /*@ type=int* */ x = 1;
  var /*@ type=String* */ a = 'aaa';
  var /*@ type=String* */ b = 'b ${x} bb';
  var /*@ type=String* */ c = 'c ${x} cc' 'ccc';
}
