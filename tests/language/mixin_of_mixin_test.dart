// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

// Validate the following text from section 12 ("Mixins") of the spec:
//
//     "A mixin application of the form S with M; defines a class C ...
//     ... C declares the same instance members as M ..."
//
// This means that if M is itself a mixin application, then things
// mixed into M are accessible through C.  But if M simply *extends* a
// mixin application (e.g. because M is declared as `class M extends X
// with Y { ... }`) then things mixed into the mixin application that
// M extends are not accessible through C.

class A { a() => null; }
class B { b() => null; }
class C { c() => null; }
class D { d() => null; }

// Note: by a slight abuse of syntax, `class M1 = A with B, C;` effectively
// means `class M1 = (A with B) with C;`, therefore M1 declares c(), but it
// merely inherits a() and b().
class M1 = A with B, C; // declares c()

class M2 extends M1 { m2() => null; }
class M3 extends A with B, C { m3() => null; }
class T1 = D with M1; // declares c()
class T2 = D with M2; // declares m2()
class T3 = D with M3; // declares m3()
class T4 extends D with M1 {} // extends a class which declares c()
class T5 extends D with M2 {} // extends a class which declares m2()
class T6 extends D with M3 {} // extends a class which declares m3()

main() {
  /// none: static type warning, ok
  new T1().a();  /// 01: static type warning, runtime error
  new T1().b();  /// 02: static type warning, runtime error
  new T1().c();  /// 03: static type warning, ok
  new T2().a();  /// 04: static type warning, runtime error
  new T2().b();  /// 05: static type warning, runtime error
  new T2().c();  /// 06: static type warning, runtime error
  new T2().m2(); /// 07: static type warning, ok
  new T3().a();  /// 08: static type warning, runtime error
  new T3().b();  /// 09: static type warning, runtime error
  new T3().c();  /// 10: static type warning, runtime error
  new T3().m3(); /// 11: static type warning, ok
  new T4().a();  /// 12: static type warning, runtime error
  new T4().b();  /// 13: static type warning, runtime error
  new T4().c();  /// 14: static type warning, ok
  new T5().a();  /// 15: static type warning, runtime error
  new T5().b();  /// 16: static type warning, runtime error
  new T5().c();  /// 17: static type warning, runtime error
  new T5().m2(); /// 18: static type warning, ok
  new T6().a();  /// 19: static type warning, runtime error
  new T6().b();  /// 20: static type warning, runtime error
  new T6().c();  /// 21: static type warning, runtime error
  new T6().m3(); /// 22: static type warning, ok
}
