// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class S {}

class G<T> {}

class M {}

class T = S with M;
typedef T0 = S with M; //        //# 00: syntax error
abstract class TA = S with M;
class T1 = final S with M; //    //# 01: syntax error
class T2 = var S with M; //      //# 02: syntax error
class T3 = const S with M; //    //# 03: syntax error
class T4 = static S with M; //   //# 04: syntax error
class T5 = external S with M; // //# 05: syntax error
class T6 = G<int> with M;
class T7 = G<Map<String, int>> with M;

class C0 extends abstract S with M { } // //# 06: syntax error
class C1 extends final S with M { } //    //# 07: syntax error
class C2 extends var S with M { } //      //# 08: syntax error
class C3 extends const S with M { } //    //# 09: syntax error
class C4 extends static S with M { } //   //# 10: syntax error
class C5 extends external S with M { } // //# 11: syntax error
class C6 extends G<int> with M {}

class C7 extends G<Map<String, int>> with M {}

class D0 extends S
    with
        M
    implements M // //# 12: syntax error
    implements
        M {}

class D1 extends T {}

class X = S; //  //# 14: syntax error

main() {
  new T();
  new TA(); // //# 13: static type warning, runtime error
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
