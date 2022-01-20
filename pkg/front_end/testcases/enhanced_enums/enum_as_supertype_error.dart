// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends Enum { // Error.
  int get foo => index;
}

class B implements Enum { // Error.
  int get foo => index;
}

abstract class EnumInterface implements Enum {}

class EnumClass extends EnumInterface { // Error.
  int get index => 0;
}

abstract class AbstractEnumClass extends EnumInterface {}

class EnumClass2 extends AbstractEnumClass {} // Error.

mixin EnumMixin on Enum {}

abstract class AbstractEnumClass2 with EnumMixin {}

class EnumClass3 extends AbstractEnumClass2 {} // Error.

main() {}
