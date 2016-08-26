// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/23893/
//
// Because annotations are parsed lazily, dart2js used to crash when an
// annotation had a syntax error.
// This checks the same behavior as invalid_annotation_test.dart, except that we
// use mirrors to trigger the error in the vm. This also triggers the error in
// dart2js differently.

@MirrorsUsed(targets: const [A])
import 'dart:mirrors';

@Deprecated("m"
,,                                /// 01: compile-time error
)
class A {
}

main() {
  reflectClass(A).metadata;
}
