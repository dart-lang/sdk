// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A value class will automatically create an empty constructor if there is none yet

const String valueClass = "valueClass";

@valueClass
class Animal {
  final int numberOfLegs;
}

main() {
  var cat = Animal(numberOfLegs: 4);
}
