// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_closurization_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  foo() => "foo";
  bar([x]) => "bar-$x";
  gee({named}) => "gee-$named";

  // Methods that must be intercepted.

  // Tear-offs we will also get without mirrors.
  codeUnitAt(x) => "codeUnitAt-$x";
  toUpperCase() => "toUpperCase";
  // indexOf takes an optional argument in String.
  indexOf(x) => "indexOf-$x";
  // lastIndexOf matches signature from String.
  lastIndexOf(x, [y]) => "lastIndexOf-$x,$y";
  // splitMapJoin matches signature from String.
  splitMapJoin(x, {onMatch, onNonMatch}) =>
      "splitMapJoin-$x,$onMatch,$onNonMatch";
  // Same name as intercepted, but with named argument.
  trim({named}) => "trim-$named";

  // Tear-offs we will not call directly.
  endsWith(x) => "endsWith-$x";
  toLowerCase() => "toLowerCase";
  // matchAsPrefix matches signature from String.
  matchAsPrefix(x, [y = 0]) => "matchAsPrefix-$x,$y";
  // Matches signature from List
  toList({growable: true}) => "toList-$growable";
  // Same name as intercepted, but with named argument.
  toSet({named}) => "toSet-$named";
}

// The recursive call makes inlining difficult.
// The use of DateTime.now makes the result unpredictable.
confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) {
    return confuse(new DateTime.now().millisecondsSinceEpoch);
  }
  return x;
}

main() {
  var list = ["foo", new List(), new A()];

  getAMirror() => reflect(list[confuse(2)]);

  // Tear-off without mirrors.
  var f = confuse(getAMirror().reflectee.codeUnitAt);
  Expect.equals("codeUnitAt-42", f(42));
  f = confuse(getAMirror().reflectee.toUpperCase);
  Expect.equals("toUpperCase", f());
  f = confuse(getAMirror().reflectee.indexOf);
  Expect.equals("indexOf-499", f(499));
  f = confuse(getAMirror().reflectee.lastIndexOf);
  Expect.equals("lastIndexOf-FOO,BAR", f("FOO", "BAR"));
  f = confuse(getAMirror().reflectee.splitMapJoin);
  Expect.equals("splitMapJoin-1,2,3", f(1, onMatch: 2, onNonMatch: 3));
  f = confuse(getAMirror().reflectee.trim);
  Expect.equals("trim-true", f(named: true));

  // Now the same thing through mirrors.
  f = getAMirror().getField(#codeUnitAt).reflectee;
  Expect.equals("codeUnitAt-42", f(42));
  f = getAMirror().getField(#toUpperCase).reflectee;
  Expect.equals("toUpperCase", f());
  f = getAMirror().getField(#indexOf).reflectee;
  Expect.equals("indexOf-499", f(499));
  f = getAMirror().getField(#lastIndexOf).reflectee;
  Expect.equals("lastIndexOf-FOO,BAR", f("FOO", "BAR"));
  f = getAMirror().getField(#splitMapJoin).reflectee;
  Expect.equals("splitMapJoin-1,2,3", f(1, onMatch: 2, onNonMatch: 3));
  f = getAMirror().getField(#trim).reflectee;
  Expect.equals("trim-true", f(named: true));

  // Now the same thing through mirrors and mirror-invocation.
  f = getAMirror().getField(#codeUnitAt);
  Expect.equals("codeUnitAt-42", f.invoke(#call, [42], {}).reflectee);
  f = getAMirror().getField(#toUpperCase);
  Expect.equals("toUpperCase", f.invoke(#call, [], {}).reflectee);
  f = getAMirror().getField(#indexOf);
  Expect.equals("indexOf-499", f.invoke(#call, [499], {}).reflectee);
  f = getAMirror().getField(#lastIndexOf);
  Expect.equals(
      "lastIndexOf-FOO,BAR", f.invoke(#call, ["FOO", "BAR"]).reflectee);
  f = getAMirror().getField(#splitMapJoin);
  Expect.equals("splitMapJoin-1,2,3",
      f.invoke(#call, [1], {#onMatch: 2, #onNonMatch: 3}).reflectee);
  f = getAMirror().getField(#trim);
  Expect.equals("trim-true", f.invoke(#call, [], {#named: true}).reflectee);

  // Tear-offs only through mirrors. (No direct selector in the code).
  // --------

  f = getAMirror().getField(#endsWith).reflectee;
  Expect.equals("endsWith-42", f(42));
  f = getAMirror().getField(#toLowerCase).reflectee;
  Expect.equals("toLowerCase", f());
  f = getAMirror().getField(#indexOf).reflectee;
  Expect.equals("indexOf-499", f(499));
  f = getAMirror().getField(#matchAsPrefix).reflectee;
  Expect.equals("matchAsPrefix-FOO,BAR", f("FOO", "BAR"));
  f = getAMirror().getField(#toList).reflectee;
  Expect.equals("toList-1", f(growable: 1));
  f = getAMirror().getField(#toSet).reflectee;
  Expect.equals("toSet-true", f(named: true));

  f = getAMirror().getField(#endsWith);
  Expect.equals("endsWith-42", f.invoke(#call, [42], {}).reflectee);
  f = getAMirror().getField(#toLowerCase);
  Expect.equals("toLowerCase", f.invoke(#call, [], {}).reflectee);
  f = getAMirror().getField(#indexOf);
  Expect.equals("indexOf-499", f.invoke(#call, [499], {}).reflectee);
  f = getAMirror().getField(#matchAsPrefix);
  Expect.equals(
      "matchAsPrefix-FOO,BAR", f.invoke(#call, ["FOO", "BAR"]).reflectee);
  f = getAMirror().getField(#toList);
  Expect.equals("toList-1", f.invoke(#call, [], {#growable: 1}).reflectee);
  f = getAMirror().getField(#toSet);
  Expect.equals("toSet-true", f.invoke(#call, [], {#named: true}).reflectee);
}
