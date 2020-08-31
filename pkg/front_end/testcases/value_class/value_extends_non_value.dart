// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String valueClass = "valueClass";

class Animal {
  final int numberOfLegs;
  Animal({required this.numberOfLegs});
}

@valueClass
class Cat extends Animal {
  final int numberOfWhiskers;
}

main() {}