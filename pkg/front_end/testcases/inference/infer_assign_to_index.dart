// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

List<double> a = <double>[];
var /*@topType=dynamic*/ b =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ a /*@target=List::[]=*/ [0] = 1.0);

main() {}
