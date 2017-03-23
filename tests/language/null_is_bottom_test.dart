// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Null is a subtype of any other type.

import 'package:expect/expect.dart';

class A {}

typedef A ReturnA();
typedef TakeA(A a);
typedef Null ReturnNull();
typedef TakeNull(Null n);

@NoInline()
testA(A a) {}

@NoInline()
testListA(List<A> list) {}

@NoInline()
testIsListA(var a) => a is List<A>;

@NoInline()
testAsListA(var a) => a as List<A>;

@NoInline()
testNull(Null n) {}

@NoInline()
testListNull(List<Null> list) {}

@NoInline()
testIsListNull(var a) => a is List<Null>;

@NoInline()
testAsListNull(var a) => a as List<Null>;

@NoInline()
testReturnA(ReturnA f) {}

@NoInline()
testIsReturnA(var f) => f is ReturnA;

@NoInline()
testAsReturnA(var f) => f as ReturnA;

@NoInline()
testReturnNull(ReturnNull f) {}

@NoInline()
testIsReturnNull(var f) => f is ReturnNull;

@NoInline()
testAsReturnNull(var f) => f as ReturnNull;

@NoInline()
testTakeA(TakeA f) {}

@NoInline()
testIsTakeA(var f) => f is TakeA;

@NoInline()
testAsTakeA(var f) => f as TakeA;

@NoInline()
testTakeNull(TakeNull f) {}

@NoInline()
testIsTakeNull(var f) => f is TakeNull;

@NoInline()
testAsTakeNull(var f) => f as TakeNull;

Null returnNullFunc() => null;
takeNullFunc(Null n) {}
A returnAFunc() => null;
takeAFunc(A a) {}

main() {
  var n = null;
  var listNull = new List<Null>();
  var a = new A();
  var listA = new List<A>();

  testA(n); //                                                         //# 01: ok
  testA(a); //                                                         //# 02: ok
  testListA(listNull); //                                              //# 03: ok
  testListA(listA); //                                                 //# 04: ok
  Expect.isTrue(testIsListA(listNull)); //                             //# 05: ok
  Expect.isTrue(testIsListA(listA)); //                                //# 06: ok
  testAsListA(listNull); //                                            //# 07: ok
  testAsListA(listA); //                                               //# 08: ok

  testNull(n); //                                                      //# 09: ok
  testNull(a); //                                      //# 10: dynamic type error
  testListNull(listNull); //                                           //# 11: ok
  testListNull(listA); //                              //# 12: dynamic type error
  Expect.isTrue(testIsListNull(listNull)); //                          //# 13: ok
  Expect.isFalse(testIsListNull(listA)); //                            //# 14: ok
  testAsListNull(listNull); //                                         //# 15: ok
  Expect.throws(() => testAsListNull(listA), (e) => e is CastError); //# 16: ok

  var returnNull = returnNullFunc;
  var takeNull = takeNullFunc;
  var returnA = returnAFunc;
  var takeA = takeAFunc;

  testReturnA(returnA); //                                             //# 17: ok
  testReturnA(returnNull); //                                          //# 18: ok
  Expect.isTrue(testIsReturnA(returnA)); //                            //# 19: ok
  Expect.isTrue(testIsReturnA(returnNull)); //                         //# 20: ok
  testAsReturnA(returnA); //                                           //# 21: ok
  testAsReturnA(returnNull); //                                        //# 22: ok

  // This is not valid in strong-mode: ()->A <: ()->Null
  testReturnNull(returnA); //                                          //# 23: ok
  testReturnNull(returnNull); //                                       //# 24: ok
  // This is not valid in strong-mode: ()->A <: ()->Null
  Expect.isTrue(testIsReturnNull(returnA)); //                         //# 25: ok
  Expect.isTrue(testIsReturnNull(returnNull)); //                      //# 26: ok
  // This is not valid in strong-mode: ()->A <: ()->Null
  testAsReturnNull(returnA); //                                        //# 27: ok
  testAsReturnNull(returnNull); //                                     //# 28: ok

  testTakeA(takeA); //                                                 //# 29: ok
  // This is not valid in strong-mode: (Null)-> <: (A)->
  testTakeA(takeNull); //                                              //# 30: ok
  Expect.isTrue(testIsTakeA(takeA)); //                                //# 31: ok
  // This is not valid in strong-mode: (Null)-> <: (A)->
  Expect.isTrue(testIsTakeA(takeNull)); //                             //# 32: ok
  testAsTakeA(takeA); //                                               //# 33: ok
  // This is not valid in strong-mode: (Null)-> <: (A)->
  testAsTakeA(takeNull); //                                            //# 34: ok

  testTakeNull(takeA); //                                              //# 35: ok
  testTakeNull(takeNull); //                                           //# 36: ok
  Expect.isTrue(testIsTakeNull(takeA)); //                             //# 37: ok
  Expect.isTrue(testIsTakeNull(takeNull)); //                          //# 38: ok
  testAsTakeNull(takeA); //                                            //# 39: ok
  testAsTakeNull(takeNull); //                                         //# 40: ok
}
