// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A implements Function {}

class B extends Function {}

class C extends Object with Function {}

class D = Object with Function;

main() {}
