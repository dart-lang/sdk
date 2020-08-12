// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String valueClass = "valueClass";

@valueClass
class A {}

class B {}

class C extends B with A {} // error, value class as mixin
class C extends A with B {} // error, C extends a value class

main() {}