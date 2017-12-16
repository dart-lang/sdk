// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

var /*@topType=dynamic*/ /*@error=CantInferTypeDueToCircularity*/ x = /*@returnType=dynamic*/ () =>
    y;
var /*@topType=dynamic*/ /*@error=CantInferTypeDueToCircularity*/ y = /*@returnType=dynamic*/ () =>
    x;

main() {}
