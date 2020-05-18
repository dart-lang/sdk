// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*@testedFeatures=inference*/

void test() {
  dynamic a = 5;
  var /*@ type=String* */ b = a. /*@target=Object.toString*/ toString();
  b = 42;
}

void main() {}
