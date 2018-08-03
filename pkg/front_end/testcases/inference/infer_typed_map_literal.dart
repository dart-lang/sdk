// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=Map<int, String>*/ a = <int, String>{0: 'aaa', 1: 'bbb'};
var /*@topType=Map<double, int>*/ b = <double, int>{1.1: 1, 2.2: 2};
var /*@topType=Map<List<int>, Map<String, double>>*/ c =
    <List<int>, Map<String, double>>{};
var /*@topType=Map<int, dynamic>*/ d = <int, dynamic>{};
var /*@topType=Map<dynamic, int>*/ e = <dynamic, int>{};
var /*@topType=Map<dynamic, dynamic>*/ f = <dynamic, dynamic>{};

main() {
  a;
  b;
  c;
  d;
  e;
  f;
}
