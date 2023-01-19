// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=records

// Verify that the use of a constant expression denoting an object that does
// not have primitive equality in a constant set or as a key of a constant map
// gives rise to a compile-time error.

class A {
  const A();
  int get hashCode => super.hashCode + 1;
}

class B {
  const B();
  bool operator ==(Object other) => super == other;
}

class C {
  const C();
  int get hashCode => super.hashCode + 1;
  bool operator ==(Object other) => super == other;
}

// Check that implicitly induced `noSuchMethod` forwarders are detected.

abstract class WeirdEquals {
  bool operator ==(Object? other);
}

class SecretNonPrimitiveEquals implements WeirdEquals {
  noSuchMethod(Invocation invocation) => true;
}

abstract class WeirdHashCode {
  Never get hashCode;
}

class SecretNonPrimitiveHashCode implements WeirdHashCode {
  noSuchMethod(Invocation invocation) => 0;
}

// An enum cannot override `==` or `hashCode`, hence no cases with enums.

const aSet = <Object?>{
  0.5,
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  Duration(days: 2),
//^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  A(),
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  B(),
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  C(),
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  SecretNonPrimitiveEquals(),
//^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  SecretNonPrimitiveHashCode(),
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  (A(), false, 1),
//^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
};

const aMap = <Object?, Null>{
  0.5: null,
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  Duration(days: 2): null,
//^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  A(): null,
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  B(): null,
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  C(): null,
//^^^
// [analyzer] unspecified
// [cfe] unspecified
  SecretNonPrimitiveEquals(): null,
//^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  SecretNonPrimitiveHashCode(): null,
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  (A(), false, 1): null,
//^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
};

void main() {}
