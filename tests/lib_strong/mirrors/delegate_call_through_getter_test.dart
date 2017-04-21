// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_call_through_getter;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class FakeFunctionCall {
  call(x, y) => '1 $x $y';
}

class FakeFunctionNSM {
  noSuchMethod(msg) => msg.positionalArguments.join(', ');
}

class C {
  get fakeFunctionCall => new FakeFunctionCall();
  get fakeFunctionNSM => new FakeFunctionNSM();
  get closure => (x, y) => '2 $this $x $y';
  get closureOpt => (x, y, [z, w]) => '3 $this $x $y $z $w';
  get closureNamed => (x, y, {z, w}) => '4 $this $x $y $z $w';
  get notAClosure => 'Not a closure';
  noSuchMethod(msg) => 'DNU';

  toString() => 'C';
}

class Forwarder {
  noSuchMethod(msg) => reflect(new C()).delegate(msg);
}

main() {
  var f = new Forwarder();

  Expect.equals('1 5 6', f.fakeFunctionCall(5, 6));
  Expect.equals('7, 8', f.fakeFunctionNSM(7, 8));
  Expect.equals('2 C 9 10', f.closure(9, 10));
  Expect.equals('3 C 11 12 13 null', f.closureOpt(11, 12, 13));
  Expect.equals('4 C 14 15 null 16', f.closureNamed(14, 15, w: 16));
  Expect.equals('DNU', f.doesNotExist(17, 18));
  Expect.throws(() => f.closure('wrong arity'), (e) => e is NoSuchMethodError);
  Expect.throws(() => f.notAClosure(), (e) => e is NoSuchMethodError);
}
