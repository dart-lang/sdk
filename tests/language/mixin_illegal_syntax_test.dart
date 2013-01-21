// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S { }
class M { }

typedef T0 = abstract S with M;
typedef T1 = final S with M;     /// 01: compile-time error
typedef T2 = var S with M;       /// 02: compile-time error
typedef T3 = const S with M;     /// 03: compile-time error
typedef T4 = static S with M;    /// 04: compile-time error
typedef T5 = external S with M;  /// 05: compile-time error

class C0 extends abstract S with M { }  /// 06: compile-time error
class C1 extends final S with M { }     /// 07: compile-time error
class C2 extends var S with M { }       /// 08: compile-time error
class C3 extends const S with M { }     /// 09: compile-time error
class C4 extends static S with M { }    /// 10: compile-time error
class C5 extends external S with M { }  /// 11: compile-time error

class D0 extends S with M
    implements M  /// 12: compile-time error
    implements M { }

class D1 extends T0 { }

main() {
  new T0();  /// 13: static type warning, runtime error
  new T1();  /// 01: continued
  new T2();  /// 02: continued
  new T3();  /// 03: continued
  new T4();  /// 04: continued
  new T5();  /// 05: continued

  new C0();  /// 06: continued
  new C1();  /// 07: continued
  new C2();  /// 08: continued
  new C3();  /// 09: continued
  new C4();  /// 10: continued
  new C5();  /// 11: continued

  new D0();  /// 12: continued
  new D1();
}
