// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

String foo(obj) => obj is String
    ? /*@promotedType=String*/ obj
        . /*@target=String::toUpperCase*/ toUpperCase()
    : null;

main() {}
