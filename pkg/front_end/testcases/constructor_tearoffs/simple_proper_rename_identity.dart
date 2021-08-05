// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1<T> {}

typedef B1<T> = A1<T>;

class A2<T extends num> {}

typedef B2<T extends num> = A2<T>;

class A3<T extends List<dynamic>, S extends Never?> {}

typedef B3<T extends List<Object?>, S extends Null> = A3<T, S>;

class A4<T extends num> {}

typedef B4<T extends int> = A4<T>;

class A5<T extends List<dynamic>, S extends Never?> {}

typedef B5<T extends List<Object?>, S extends Null> = A5;

class StaticIdentityTest {
  const StaticIdentityTest(a, b) : assert(identical(a, b));
}

test1() => const StaticIdentityTest(A1.new, B1.new); // Ok.
test2() => const StaticIdentityTest(A2.new, B2.new); // Ok.
test3() => const StaticIdentityTest(A3.new, B3.new); // Ok.
test4() => const StaticIdentityTest(A4.new, B4.new); // Error.
test5() => const StaticIdentityTest(A5.new, B5.new); // Error.


main() {}
