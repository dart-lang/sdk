// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

class Animal {
  final int numberOfLegs;
  Animal({required this.numberOfLegs});
}

@valueClass
class Cat extends Animal {
  final int numberOfWhiskers;
}

main() {
 Cat cat = new Cat(numberOfWhiskers: 20, numberOfLegs: 4);
 (cat as dynamic).copyWith(numberOfWhiskers: 4);
}



