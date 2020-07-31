// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {}

class B {}

class C {}

class D {}

main() {
  ifThenElseSequence(null);
}

ifThenElseSequence(dynamic o) {
  if (/*{}*/ o is A) {
    /*{o:[{true:A}|A]}*/ o;
  } else if (/*{o:[{false:A}|A]}*/ o is B) {
    /*{o:[{true:B,false:A}|A,B]}*/ o;
  } else if (/*{o:[{false:A,B}|A,B]}*/ o is C) {
    /*{o:[{true:C,false:A,B}|A,B,C]}*/ o;
  } else if (/*{o:[{false:A,B,C}|A,B,C]}*/ o is D) {
    /*{o:[{true:D,false:A,B,C}|A,B,C,D]}*/ o;
  } else {
    /*{o:[{false:A,B,C,D}|A,B,C,D]}*/ o;
  }
}
