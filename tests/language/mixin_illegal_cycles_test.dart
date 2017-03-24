// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M {}
class M0 extends Object with M0 { } // //# 01: compile-time error
class M1 = Object with M1; //        //# 02: compile-time error

class M2 = Object with M3; //        //# 03: compile-time error
class M3 = Object with M2; //        //# 03: continued

class M4 = Object with M5; //        //# 04: compile-time error
class M5 = Object with M6; //        //# 04: continued
class M6 = Object with M4; //        //# 04: continued

class M7 extends Object with M8 { } // //# 05: compile-time error
class M8 extends Object with M7 { } // //# 05: continued

class M9  = Object with M91; //      //# 06: compile-time error
class M91 = Object with M92; //      //# 06: continued
class M92 = Object with M91; //      //# 06: continued

main() {
  new M0(); // //# 01: continued

  new M1(); // //# 02: continued

  new M2(); // //# 03: continued
  new M3(); // //# 03: continued

  new M4(); // //# 04: continued
  new M5(); // //# 04: continued
  new M6(); // //# 04: continued

  new M7(); // //# 05: continued
  new M8(); // //# 05: continued

  new M9(); // //# 06: continued
}
