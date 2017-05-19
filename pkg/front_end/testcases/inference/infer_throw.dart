// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=bool*/ t = true;
var /*@topType=dynamic*/ a = (throw 0);
var /*@topType=int*/ b = (throw 0) ? 1 : 2;
var /*@topType=int*/ c = t ? (throw 1) : 2;
var /*@topType=int*/ d = t ? 1 : (throw 2);

main() {}
