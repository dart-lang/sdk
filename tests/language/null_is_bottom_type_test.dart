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

testA(A a) {}
testListA(List<A> list) {}
testNull(Null n) {}
testListNull(List<Null> list) {}
testReturnA(ReturnA f) {}
testReturnNull(ReturnNull f) {}
testTakeA(TakeA f) {}
testTakeNull(TakeNull f) {}

Null returnNull() => null;
takeNull(Null n) {}
A returnA() => null;
takeA(A a) {}

main() {
  if (false) test(); // Perform static checks only.
}

test() {
  Null n;
  List<Null> listNull;
  A a = new A();
  List<A> listA;

  testA(n); //                                                         //# 01: ok
  testA(a); //                                                         //# 02: ok
  testListA(listNull); //                                              //# 03: ok
  testListA(listA); //                                                 //# 04: ok

  testNull(n); //                                                      //# 05: ok
  testNull(a); //                                                      //# 06: ok
  testListNull(listNull); //                                           //# 07: ok
  testListNull(listA); //                                              //# 08: ok

  testReturnA(returnA); //                                             //# 09: ok
  testReturnA(returnNull); //                                          //# 10: ok

  testReturnNull(returnA); //                                          //# 11: ok
  testReturnNull(returnNull); //                                       //# 12: ok

  testTakeA(takeA); //                                                 //# 13: ok
  testTakeA(takeNull); //                                              //# 14: ok

  testTakeNull(takeA); //                                              //# 15: ok
  testTakeNull(takeNull); //                                           //# 16: ok
}
