// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=List<int>*/ a = <int>[];
var /*@topType=List<double>*/ b = <double>[1.0, 2.0, 3.0];
var /*@topType=List<List<int>>*/ c = <List<int>>[];
var /*@topType=List<dynamic>*/ d = <dynamic>[1, 2.0, false];

main() {
  var /*@type=List<int>*/ a = <int>[];
  var /*@type=List<double>*/ b = <double>[1.0, 2.0, 3.0];
  var /*@type=List<List<int>>*/ c = <List<int>>[];
  var /*@type=List<dynamic>*/ d = <dynamic>[1, 2.0, false];
}
