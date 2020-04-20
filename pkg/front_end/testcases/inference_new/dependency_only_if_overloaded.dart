// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int intValue = 0;
num numValue = 0;
double doubleValue = 0.0;

// There's a circularity between a and b because the type of `int + x` depends
// on the type of x.

var a = /*@ returnType=num* */ () => intValue /*@target=num::+*/ + b;
var b = a();

// But there's no circularity between c and d because the type of `num + x` is
// always num.

var c = /*@ returnType=num* */ () => numValue /*@target=num::+*/ + d;
var d = c();

// Similar for double.

var e = /*@ returnType=double* */ () => doubleValue /*@target=double::+*/ + f;
var f = e();

main() {}
