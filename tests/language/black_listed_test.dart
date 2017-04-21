// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

// Test that certain interfaces/classes are blacklisted from being
// implemented or extended.

// bool.
class MyBool implements bool {} //                    //# 01: compile-time error
abstract class MyBoolInterface implements bool default F { // //# 02: compile-time error
  MyBoolInterface(); //                               //# 02: continued
} //                                                  //# 02: continued

// num.
class MyNum implements num {} //                      //# 03: compile-time error
abstract class MyNumInterface implements num default F { //   //# 04: compile-time error
  MyNumInterface(); //                                //# 04: continued
} //                                                  //# 04: continued

// int.
class MyInt implements int {} //                      //# 05: compile-time error
abstract class MyIntInterface implements int default F { //   //# 06: compile-time error
  MyIntInterface(); //                                //# 06: continued
} //                                                  //# 06: continued

// double.
class MyDouble implements double {} //                    //# 07: compile-time error
abstract class MyDoubleInterface implements double default F { // //# 08: compile-time error
  MyDoubleInterface(); //                                 //# 08: continued
} //                                                      //# 08: continued

// String.
class MyString implements String {} //                    //# 09: compile-time error
abstract class MyStringInterface implements String default F { // //# 10: compile-time error
  MyStringInterface(); //                                 //# 10: continued
} //                                                      //# 10: continued

// Function.
class MyFunction implements Function {}

class MyOtherFunction extends Function {}
abstract class MyFunctionInterface implements Function default F { // //# 12: compile-time error
  MyFunctionInterface(); //                                   //# 12: continued
} //                                                          //# 12: continued

// dynamic.
class MyDynamic implements dynamic {} //                     //# 13: compile-time error
abstract class MyDynamicInterface implements dynamic default F { //  //# 14: compile-time error
  MyDynamicInterface(); //                                   //# 14: continued
} //                                                         //# 14: continued

class F {
  factory MyBoolInterface() { return null; } //     //# 02: continued
  factory MyNumInterface() { return null; } //      //# 04: continued
  factory MyIntInterface() { return null; } //      //# 06: continued
  factory MyDoubleInterface() { return null; } //   //# 08: continued
  factory MyStringInterface() { return null; } //   //# 10: continued
  factory MyFunctionInterface() { return null; } // //# 12: continued
  factory MyDynamicInterface() { return null; } //  //# 14: continued
}

main() {
  new MyBool(); //             //# 01: continued
  new MyBoolInterface(); //    //# 02: continued
  new MyNum(); //              //# 03: continued
  new MyNumInterface(); //     //# 04: continued
  new MyInt(); //              //# 05: continued
  new MyIntInterface(); //     //# 06: continued
  new MyDouble(); //           //# 07: continued
  new MyDoubleInterface(); //  //# 08: continued
  new MyString(); //           //# 09: continued
  new MyStringInterface(); //  //# 10: continued
  new MyFunction();
  new MyOtherFunction();
  new MyFunctionInterface(); //# 12: continued
  new MyDynamic(); //          //# 13: continued
  new MyDynamicInterface(); // //# 14: continued
}
