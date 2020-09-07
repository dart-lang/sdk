// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

class Animal {
  int numberOfLegs;
}

@valueClass
class Cat extends Animal {}

class Animal2 {
  final int numberOfLegs;
}

@valueClass
class Cat2 extends Animal2 {}

main() {}