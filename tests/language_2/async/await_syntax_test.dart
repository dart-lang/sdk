// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test async/await syntax.

import 'dart:async' show Stream;

var yield = 0;
var await = 0;
get st => new Stream.fromIterable([]);

a01a() async => null; //                       //# a01a: ok
a01b() async* => null; //                      //# a01b: syntax error
a01c() sync* => null; //                       //# a01c: syntax error
a01d() async => yield 5; //                    //# a01d: syntax error
a02a() async {} //                             //# a02a: ok
a03a() async* {} //                            //# a03a: ok
a03b() async * {} //                           //# a03b: ok
a04a() sync* {} //                             //# a04a: ok
a04b() sync {} //                              //# a04b: syntax error
a04c() sync * {} //                            //# a04c: ok
a05a() async { await 0; } //                   //# a05a: ok
a05b() async { //                              //# a05b: ok
  await(a) {}; //                              //# a05b: continued
  await(0); //                                 //# a05b: continued
} //                                           //# a05b: continued
a05c() { //                                    //# a05c: ok
  await(a) {}; //                              //# a05c: continued
  await(0); //                                 //# a05c: continued
} //                                           //# a05c: continued
a05d() async { //                              //# a05d: syntax error
  await(a) {} //                               //# a05d: continued
  await(0); //                                 //# a05d: continued
} //                                           //# a05d: continued
a05e() { //                                    //# a05e: ok
  await(a) {} //                               //# a05e: continued
  await(0); //                                 //# a05e: continued
} //                                           //# a05e: continued
a05f() async { //                              //# a05f: syntax error
  var await = (a) {}; //                       //# a05f: continued
  await(0); //                                 //# a05f: continued
} //                                           //# a05f: continued
a05g() async { //                              //# a05g: compile-time error
    yield 5; //                                //# a05g: continued
} //                                           //# a05g: continued
a05h() async { //                              //# a05h: continued
    yield* st; //                              //# a05h: compile-time error
} //                                           //# a05h: continued
a06a() async { await for (var o in st) {} } // //# a06a: ok
a06b() sync* { await for (var o in st) {} } // //# a06b: compile-time error
a07a() sync* { yield 0; } //                   //# a07a: ok
a07b() sync { yield 0; } //                    //# a07b: syntax error
a08a() sync* { yield* []; } //                 //# a08a: ok
a08b() sync { yield 0; } //                    //# a08b: syntax error
a09a() async* { yield 0; } //                  //# a09a: ok
a10a() async* { yield* []; } //                //# a10a: compile-time error

get sync sync {} //                            //# a11a: syntax error
get sync sync* {} //                           //# a11b: ok
get async async {} //                          //# a11c: ok
get async async* {} //                         //# a11d: ok

get sync {} //                                 //# a12a: ok
get sync* {} //                                //# a12b: syntax error
get async {} //                                //# a12c: ok
get async* {} //                               //# a12d: syntax error
get a12e sync* => null; //                     //# a12e: syntax error
get a12f async* => null; //                    //# a12f: syntax error
get a12g async => null; //                     //# a12g: ok

int sync; //                                   //# a13a: ok
int sync*; //                                  //# a13b: syntax error
int async; //                                  //# a13c: ok
int async*; //                                 //# a13d: syntax error

var sync; //                                   //# a14a: ok
var sync*; //                                  //# a14b: syntax error
var async; //                                  //# a14c: ok
var async*; //                                 //# a14d: syntax error

sync() {} //                                   //# a15a: ok
sync*() {} //                                  //# a15b: syntax error
async() {} //                                  //# a15c: ok
async*() {} //                                 //# a15d: syntax error

abstract class B {
  b00a() async; //  //# b00a: syntax error
  b00b() async*; // //# b00b: syntax error
  b00c() sync*; //  //# b00c: syntax error
  b00d() sync; //   //# b00d: syntax error
}

class C extends B {
  C();

  factory C.e1() async { return null; } //  //# e1: compile-time error
  factory C.e2() async* { return null; } // //# e2: compile-time error
  factory C.e3() sync* { return null; } //  //# e3: compile-time error
  factory C.e4() async = C; //              //# e4: syntax error
  factory C.e5() async* = C; //             //# e5: syntax error
  factory C.e6() sync* = C; //              //# e6: syntax error
  C.e7() async {} //                        //# e7: compile-time error
  C.e8() async* {} //                       //# e8: compile-time error
  C.e9() sync* {} //                        //# e9: compile-time error

  b00a() {} //  //# b00a: continued
  b00b() {} //  //# b00b: continued
  b00c() {} //  //# b00c: continued
  b00d() {} //  //# b00d: continued

  b01a() async => null; //                       //# b01a: ok
  b01b() async* => null; //                      //# b01b: syntax error
  b01c() sync* => null; //                       //# b01c: syntax error
  b02a() async {} //                             //# b02a: ok
  b03a() async* {} //                            //# b03a: ok
  b04a() sync* {} //                             //# b04a: ok
  b04b() sync {} //                              //# b04b: syntax error
  b05a() async { await 0; } //                   //# b05a: ok
  b06a() async { await for (var o in st) {} } // //# b06a: ok
  b06b() async { await for ( ; ; ) {} } //       //# b06b: compile-time error
  b07a() sync* { yield 0; } //                   //# b07a: ok
  b08a() sync* { yield* []; } //                 //# b08a: ok
  b09a() async* { yield 0; } //                  //# b09a: ok
  b10a() async* { yield* []; } //                //# b10a: compile-time error
  b10b() async { yield 0; } //                   //# b10b: compile-time error

  get sync sync {} //                            //# b11a: syntax error
  get sync sync* {} //                           //# b11b: ok
  get async async {} //                          //# b11c: ok
  get async async* {} //                         //# b11d: ok

  get sync {} //                                 //# b12a: ok
  get sync* {} //                                //# b12b: syntax error
  get async {} //                                //# b12c: ok
  get async* {} //                               //# b12d: syntax error
  get b12e sync* => null; //                     //# b12e: syntax error
  get b12f async* => null; //                    //# b12f: syntax error
  get b12g async => null; //                     //# b12g: ok

  int sync; //                                   //# b13a: ok
  int sync*; //                                  //# b13b: syntax error
  int async; //                                  //# b13c: ok
  int async*; //                                 //# b13d: syntax error

  var sync; //                                   //# b14a: ok
  var sync*; //                                  //# b14b: syntax error
  var async; //                                  //# b14c: ok
  var async*; //                                 //# b14d: syntax error

  sync() {} //                                   //# b15a: ok
  sync*() {} //                                  //# b15b: syntax error
  async() {} //                                  //# b15c: ok
  async*() {} //                                 //# b15d: syntax error
}

method1() {
  c01a() async => null; c01a(); //                       //# c01a: ok
  c01b() async* => null; c01b(); //                      //# c01b: syntax error
  c01c() sync* => null; c01c(); //                       //# c01c: syntax error
  c02a() async {} c02a(); //                             //# c02a: ok
  c03a() async* {} c03a(); //                            //# c03a: ok
  c04a() sync* {} c04a(); //                             //# c04a: ok
  c04b() sync {} c04b(); //                              //# c04b: syntax error
  c05a() async { await 0; } c05a(); //                   //# c05a: ok
  c06a() async { await for (var o in st) {} } c06a(); // //# c06a: ok
  c07a() sync* { yield 0; } c07a(); //                   //# c07a: ok
  c08a() sync* { yield* []; } c08a(); //                 //# c08a: ok
  c09a() async* { yield 0; } c09a(); //                  //# c09a: ok
  c10a() async* { yield* []; } c10a(); //                //# c10a: compile-time error
  c11a() async { yield -5; } c11a(); //                  //# c11a: compile-time error
  c11b() async { yield* st; } c11b(); //                 //# c11b: compile-time error
}

method2() {
  var d01a = () async => null; d01a(); //                        //# d01a: ok
  var d01b = () async* => null; d01b(); //                       //# d01b: syntax error
  var d01c = () sync* => null; d01c(); //                        //# d01c: syntax error
  var d02a = () async {}; d02a(); //                             //# d02a: ok
  var d03a = () async* {}; d03a(); //                            //# d03a: ok
  var d04a = () sync* {}; d04a(); //                             //# d04a: ok
  var d04b = () sync {}; d04b(); //                              //# d04b: syntax error
  var d05a = () async { await 0; }; d05a(); //                   //# d05a: ok
  var d06a = () async { await for (var o in st) {} }; d06a(); // //# d06a: ok
  var d07a = () sync* { yield 0; }; d07a(); //                   //# d07a: ok
  var d08a = () sync* { yield* []; }; d08a(); //                 //# d08a: ok
  var d08b = () sync* { yield*0+1; }; d08b(); //                 //# d08b: compile-time error
  var d08c = () { yield*0+1; }; d08c(); //                       //# d08c: ok
  var d09a = () async* { yield 0; }; d09a(); //                  //# d09a: ok
  var d10a = () async* { yield* []; }; d10a(); //                //# d10a: compile-time error
}

void main() {
  var a;
  var c = new C();
  c = new C.e1(); //# e1: continued
  c = new C.e2(); //# e2: continued
  c = new C.e3(); //# e3: continued
  c = new C.e4(); //# e4: continued
  c = new C.e5(); //# e5: continued
  c = new C.e6(); //# e6: continued
  c = new C.e7(); //# e7: continued
  c = new C.e8(); //# e8: continued
  c = new C.e9(); //# e9: continued

  a01a(); //    //# a01a: continued
  a01b(); //    //# a01b: continued
  a01c(); //    //# a01c: continued
  a01d(); //    //# a01d: continued
  a02a(); //    //# a02a: continued
  a03a(); //    //# a03a: continued
  a03b(); //    //# a03b: continued
  a04a(); //    //# a04a: continued
  a04b(); //    //# a04b: continued
  a04c(); //    //# a04c: continued
  a05a(); //    //# a05a: continued
  a05b(); //    //# a05b: continued
  a05c(); //    //# a05c: continued
  a05d(); //    //# a05d: continued
  a05e(); //    //# a05e: continued
  a05f(); //    //# a05f: continued
  a05g(); //    //# a05g: continued
  a05h(); //    //# a05h: continued
  a06a(); //    //# a06a: continued
  a06b(); //    //# a06b: continued
  a07a(); //    //# a07a: continued
  a07b(); //    //# a07b: continued
  a08a(); //    //# a08a: continued
  a08b(); //    //# a08b: continued
  a09a(); //    //# a09a: continued
  a10a(); //    //# a10a: continued
  a = sync; //  //# a11a: continued
  a = sync; //  //# a11b: continued
  a = async; // //# a11c: continued
  a = async; // //# a11d: continued
  a = sync; //  //# a12a: continued
  a = sync; //  //# a12b: continued
  a = async; // //# a12c: continued
  a = async; // //# a12d: continued
  a = a12e; //  //# a12e: continued
  a = a12f; //  //# a12f: continued
  a = a12g; //  //# a12g: continued
  a = sync; //  //# a13a: continued
  a = sync; //  //# a13b: continued
  a = async; // //# a13c: continued
  a = async; // //# a13d: continued
  a = sync; //  //# a14a: continued
  a = sync; //  //# a14b: continued
  a = async; // //# a14c: continued
  a = async; // //# a14d: continued
  sync(); //    //# a15a: continued
  sync(); //    //# a15b: continued
  async(); //   //# a15c: continued
  async(); //   //# a15d: continued

  c.b00a(); //  //# b00a: continued
  c.b00b(); //  //# b00b: continued
  c.b00c(); //  //# b00c: continued
  c.b00d(); //  //# b00d: continued
  c.b01a(); //  //# b01a: continued
  c.b01b(); //  //# b01b: continued
  c.b01c(); //  //# b01c: continued
  c.b02a(); //  //# b02a: continued
  c.b03a(); //  //# b03a: continued
  c.b04a(); //  //# b04a: continued
  c.b04b(); //  //# b04b: continued
  c.b05a(); //  //# b05a: continued
  c.b06a(); //  //# b06a: continued
  c.b06b(); //  //# b06b: continued
  c.b07a(); //  //# b07a: continued
  c.b08a(); //  //# b08a: continued
  c.b09a(); //  //# b09a: continued
  c.b10a(); //  //# b10a: continued
  c.b10b(); //  //# b10b: continued
  a = c.sync; //  //# b11a: continued
  a = c.sync; //  //# b11b: continued
  a = c.async; // //# b11c: continued
  a = c.async; // //# b11d: continued
  a = c.sync; //  //# b12a: continued
  a = c.sync; //  //# b12b: continued
  a = c.async; // //# b12c: continued
  a = c.async; // //# b12d: continued
  a = c.b12e; //  //# b12e: continued
  a = c.b12f; //  //# b12f: continued
  a = c.b12g; //  //# b12g: continued
  a = c.sync; //  //# b13a: continued
  a = c.sync; //  //# b13b: continued
  a = c.async; // //# b13c: continued
  a = c.async; // //# b13d: continued
  a = c.sync; //  //# b14a: continued
  a = c.sync; //  //# b14b: continued
  a = c.async; // //# b14c: continued
  a = c.async; // //# b14d: continued
  c.sync(); //    //# b15a: continued
  c.sync(); //    //# b15b: continued
  c.async(); //   //# b15c: continued
  c.async(); //   //# b15d: continued

  method1();
  method2();
}
