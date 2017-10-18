// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S { }
class G<T> { }
class M { }

class T0 = S with M;
abstract class T0A = S with M;
class T1 = final S with M; //    //# 01: compile-time error
class T2 = var S with M; //      //# 02: compile-time error
class T3 = const S with M; //    //# 03: compile-time error
class T4 = static S with M; //   //# 04: compile-time error
class T5 = external S with M; // //# 05: compile-time error
class T6 = G<int> with M;
class T7 = G<Map<String,int>> with M;

class C0 extends abstract S with M { } // //# 06: compile-time error
class C1 extends final S with M { } //    //# 07: compile-time error
class C2 extends var S with M { } //      //# 08: compile-time error
class C3 extends const S with M { } //    //# 09: compile-time error
class C4 extends static S with M { } //   //# 10: compile-time error
class C5 extends external S with M { } // //# 11: compile-time error
class C6 extends G<int> with M { }
class C7 extends G<Map<String,int>> with M { }

class D0 extends S with M
    implements M // //# 12: compile-time error
    implements M { }

class D1 extends T0 { }

class X = S; //  //# 14: compile-time error

main() {
  new T0(); // //# 13: compile-time error
  new T0A(); // //# 13: compile-time error
  new T1(); // //# 01: continued
  new T2(); // //# 02: continued
  new T3(); // //# 03: continued
  new T4(); // //# 04: continued
  new T5(); // //# 05: continued
  new T6();
  new T7();

  new C0(); // //# 06: continued
  new C1(); // //# 07: continued
  new C2(); // //# 08: continued
  new C3(); // //# 09: continued
  new C4(); // //# 10: continued
  new C5(); // //# 11: continued
  new C6();
  new C7();

  new D0(); // //# 12: continued
  new D1();
  new X(); //  //# 14: continued
}
