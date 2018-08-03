// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var get; //                //# ok: ok
var get a; //              //# 00: syntax error
var get b, c; //           //# 01: syntax error

var set; //                //# ok: continued
var set d; //              //# 02: syntax error
var set e, f; //           //# 03: syntax error

class C0 {
  var get; //              //# ok: continued
  var get a; //            //# 04: syntax error
  var get b, c; //         //# 05: syntax error

  var set; //              //# ok: continued
  var set d; //            //# 06: syntax error
  var set e, f; //         //# 07: syntax error
}

class C1 {
  List get; //             //# ok: continued
  List get a => null; //   //# ok: continued
  List get b, c; //        //# 09: syntax error

  List set; //             //# ok: continued
  List set d; //           //# 10: syntax error
  List set e, f; //        //# 11: syntax error
}

class C2 {
  List<int> get; //        //# ok: continued
  List<int> get a => null; //# ok: continued
  List<int> get b, c; //   //# 13: syntax error

  List<int> set; //        //# ok: continued
  List<int> set d; //      //# 14: syntax error
  List<int> set e, f; //   //# 15: syntax error
}

main() {
  new C0();
  new C1();
  new C2();
}
