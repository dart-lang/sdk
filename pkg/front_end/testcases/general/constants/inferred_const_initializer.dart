// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  final field;

  const Class1() : field = []; // Error
}

class Class2 {
  final field;

  const Class2() : field = const []; // Ok
}

class Class3 {
  final field;

  const Class3() : field = Class2(); // Error
}

class Class4 {
  final field;

  const Class4() : field = const Class2(); // Ok
}
