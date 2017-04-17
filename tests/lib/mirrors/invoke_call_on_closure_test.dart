// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_call_on_closure;

@MirrorsUsed(targets: "test.invoke_call_on_closure")
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
  tearOff(x, y) => '22 $this $x $y';
  tearOffOpt(x, y, [z, w]) => '33 $this $x $y $z $w';
  tearOffNamed(x, y, {z, w}) => '44 $this $x $y $z $w';

  noSuchMethod(msg) => 'DNU';

  toString() => 'C';
}

main() {
  var c = new C();
  InstanceMirror im;

  im = reflect(c.fakeFunctionCall);
  Expect.equals('1 5 6', im.invoke(#call, [5, 6]).reflectee);

  im = reflect(c.fakeFunctionNSM);
  Expect.equals('7, 8', im.invoke(#call, [7, 8]).reflectee);

  im = reflect(c.closure);
  Expect.equals('2 C 9 10', im.invoke(#call, [9, 10]).reflectee);

  im = reflect(c.closureOpt);
  Expect.equals('3 C 11 12 13 null', im.invoke(#call, [11, 12, 13]).reflectee);

  im = reflect(c.closureNamed);
  Expect.equals(
      '4 C 14 15 null 16', im.invoke(#call, [14, 15], {#w: 16}).reflectee);

  im = reflect(c.tearOff);
  Expect.equals('22 C 9 10', im.invoke(#call, [9, 10]).reflectee);

  im = reflect(c.tearOffOpt);
  Expect.equals('33 C 11 12 13 null', im.invoke(#call, [11, 12, 13]).reflectee);

  im = reflect(c.tearOffNamed);
  Expect.equals(
      '44 C 14 15 null 16', im.invoke(#call, [14, 15], {#w: 16}).reflectee);
}
