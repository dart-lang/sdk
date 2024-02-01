// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element.new(); // Ok: invocation of the unnamed constructor.
}

// Error.
enum E2<values> {
  element;
}

enum E3<element> {
  element; // Error.
}

enum values { // Error.
  element;
}

abstract class SuperclassWithEquals {
  bool operator ==(Object other) => true;
}

abstract class SuperclassWithHashCode {
  int get hashCode => 0;
}

abstract class SuperclassWithValues {
  Never get values => throw 0;
}

abstract class A1 extends SuperclassWithEquals implements Enum {} // Error.

abstract class A2 extends SuperclassWithHashCode implements Enum {} // Error.

abstract class A3 extends SuperclassWithValues implements Enum {} // Error.

main() {}
