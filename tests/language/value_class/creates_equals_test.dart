// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Equals operator == by value should be implicitly created

import 'package:expect/expect.dart';
import 'value_class_support_lib.dart';

// A value class will automatically create an == operator if there is none yet

@valueClass
class Animal {
  final int numberOfLegs;
}

main() {
  var cat = Animal(numberOfLegs: 4);
  var dog = Animal(numberOfLegs: 4);
  var human = Animal(numberOfLegs: 2);

  Expect.equals(true, cat == dog);
  Expect.equals(false, cat == human);
}
