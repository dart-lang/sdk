// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks for compile-time errors in cases when either Never or T? is
// extended, implemented, or mixed in, where T is a type.

class A {}

class B {}

class C extends B with A? {}
class C1 extends B with Never {}

class D extends A? {}
class D1 extends Never {}

class E implements B? {}
class E1 implements Never {}

main() {}
