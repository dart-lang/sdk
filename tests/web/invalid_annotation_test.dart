// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/23893
//
// Because annotations are parsed lazily, dart2js used to crash when an
// annotation had a syntax error.

@Deprecated("m"
,, //                               //# 01: compile-time error
    )
class A {}

main() => new A();
