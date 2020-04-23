// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// Test error messages for invalid override in a mixin application.

class S {
  foo([x]) {}
}

class M {
  foo() {}
}

class M1 {}

class M2 {}

class MX {}

class A0 = S with M;
class A1 = S with M1, M;
class A2 = S with M1, M2, M;

class A0X = S with M, MX;
class A1X = S with M1, M, MX;
class A2X = S with M1, M2, M, MX;

class B0 extends S with M {}

class B1 extends S with M1, M {}

class B2 extends S with M1, M2, M {}

class B0X extends S with M, MX {}

class B1X extends S with M1, M, MX {}

class B2X extends S with M1, M2, M, MX {}

main() {}
