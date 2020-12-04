// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SuperClass {
  void method(covariant int i) {}
}

class Mixin {
  void method(num i) {}
}

class Class extends SuperClass with Mixin {}
