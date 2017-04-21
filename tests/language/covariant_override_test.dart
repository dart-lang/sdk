// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library covariant_override_test;

// This test contains cases where `covariant` is used as intended.

abstract class A {
  A(this.f1, this.f2, this.f3);

  // Normal usage, "by design": superclass requests covariance.
  void m1(covariant Object o);

  // Normal usage, "ad hoc": subclass requests covariance.
  void m2(Object o);

  // Syntactic special case: omit the type in subclass.
  void m3(Object o);

  // Positional optional arguments.
  void m4([covariant Object o]);
  void m5([Object o]);
  void m6([Object o]);

  // Named arguments.
  void m7({covariant Object arg});
  void m8({Object arg});
  void m9({Object arg});

  // Normal usage on field, "by design": superclass requests covariance.
  covariant Object f1;

  // Normal usage on field, "ad hoc": subclass requests covariance.
  Object f2;

  // Syntactic special case.
  Object f3;
}

abstract class B extends A {
  B(num f1, num f2, num f3) : super(f1, f2, f3);

  void m1(num n);
  void m2(covariant num n);
  void m3(covariant n);
  void m4([num n]);
  void m5([covariant num n]);
  void m6([covariant n]);
  void m7({num arg});
  void m8({covariant num arg});
  void m9({covariant arg});
  void set f1(num n);
  void set f2(covariant num n);
  void set f3(covariant n);
}

class C extends B {
  C(int f1, int f2, int f3) : super(f1, f2, f3);

  void m1(int i) {}
  void m2(int i) {}
  void m3(int i) {}
  void m4([int i]) {}
  void m5([int i]) {}
  void m6([int i]) {}
  void m7({int arg}) {}
  void m8({int arg}) {}
  void m9({int arg}) {}
  void set f1(int i) {}
  void set f2(int i) {}
  void set f3(int i) {}
}

main() {
  // For Dart 1.x, `covariant` has no runtime semantics; we just ensure
  // that the code is not unused, such that we know it will be parsed.
  A a = new C(39, 40, 41);
  a.m1(42);
  a.m2(42);
  a.m3(42);
  a.m4(42);
  a.m5(42);
  a.m6(42);
  a.m7(arg: 42);
  a.m8(arg: 42);
  a.m9(arg: 42);
  a.f1 = 42;
  a.f2 = 42;
  a.f3 = 42;
}
