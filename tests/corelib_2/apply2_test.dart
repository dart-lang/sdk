// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

apply(Function function, List positional, Map<Symbol, dynamic> named) {
  return Function.apply(function, positional, named);
}

void throwsNSME(
    Function function, List positional, Map<Symbol, dynamic> named) {
  Expect.throwsNoSuchMethodError(() => apply(function, positional, named));
}

main() {
  var c1 = () => 'c1';
  var c2 = (a) => 'c2 $a';
  var c3 = ([a = 1]) => 'c3 $a';
  var c4 = ({a: 1}) => 'c4 $a';
  var c5 = ({a: 1, b: 2}) => 'c5 $a $b';
  var c6 = ({b: 1, a: 2}) => 'c6 $a $b';
  var c7 = (x, {b: 1, a: 2}) => 'c7 $x $a $b';
  var c8 = (x, y, [a = 2, b = 3]) => 'c8 $x $y $a $b';

  Expect.equals('c1', apply(c1, null, null));
  Expect.equals('c1', apply(c1, [], null));
  Expect.equals('c1', apply(c1, [], {}));
  Expect.equals('c1', apply(c1, null, {}));
  throwsNSME(c1, [1], null);
  throwsNSME(c1, [1], {#a: 2});
  throwsNSME(c1, null, {#a: 2});

  Expect.equals('c2 1', apply(c2, [1], null));
  Expect.equals('c2 1', apply(c2, [1], {}));
  throwsNSME(c2, null, null);
  throwsNSME(c2, [], null);
  throwsNSME(c2, null, {});
  throwsNSME(c2, null, {#a: 1});
  throwsNSME(c2, [2], {#a: 1});

  Expect.equals('c3 1', apply(c3, null, null));
  Expect.equals('c3 1', apply(c3, [], null));
  Expect.equals('c3 2', apply(c3, [2], {}));
  throwsNSME(c3, [1, 2], null);
  throwsNSME(c3, null, {#a: 1});

  Expect.equals('c4 1', apply(c4, [], null));
  Expect.equals('c4 2', apply(c4, [], {#a: 2}));
  Expect.equals('c4 1', apply(c4, null, null));
  Expect.equals('c4 1', apply(c4, [], {}));
  throwsNSME(c4, [1], {#a: 1});
  throwsNSME(c4, [1], {});
  throwsNSME(c4, [], {#a: 1, #b: 2});

  Expect.equals('c5 1 2', apply(c5, [], null));
  Expect.equals('c5 3 2', apply(c5, [], {#a: 3}));
  Expect.equals('c5 1 2', apply(c5, null, null));
  Expect.equals('c5 1 2', apply(c5, [], {}));
  Expect.equals('c5 3 4', apply(c5, [], {#a: 3, #b: 4}));
  Expect.equals('c5 4 3', apply(c5, [], {#b: 3, #a: 4}));
  Expect.equals('c5 1 3', apply(c5, [], {#b: 3}));
  throwsNSME(c5, [1], {#a: 1});
  throwsNSME(c5, [1], {});
  throwsNSME(c5, [], {#a: 1, #b: 2, #c: 3});

  Expect.equals('c6 2 1', apply(c6, [], null));
  Expect.equals('c6 3 1', apply(c6, [], {#a: 3}));
  Expect.equals('c6 2 1', apply(c6, null, null));
  Expect.equals('c6 2 1', apply(c6, [], {}));
  Expect.equals('c6 3 4', apply(c6, [], {#a: 3, #b: 4}));
  Expect.equals('c6 4 3', apply(c6, [], {#b: 3, #a: 4}));
  Expect.equals('c6 2 3', apply(c6, [], {#b: 3}));
  throwsNSME(c6, [1], {#a: 1});
  throwsNSME(c6, [1], {});
  throwsNSME(c6, [], {#a: 1, #b: 2, #c: 3});

  Expect.equals('c7 7 2 1', apply(c7, [7], null));
  Expect.equals('c7 7 3 1', apply(c7, [7], {#a: 3}));
  Expect.equals('c7 7 2 1', apply(c7, [7], {}));
  Expect.equals('c7 7 3 4', apply(c7, [7], {#a: 3, #b: 4}));
  Expect.equals('c7 7 4 3', apply(c7, [7], {#b: 3, #a: 4}));
  Expect.equals('c7 7 2 3', apply(c7, [7], {#b: 3}));
  throwsNSME(c7, [], {#a: 1});
  throwsNSME(c7, [], {});
  throwsNSME(c7, [7], {#a: 1, #b: 2, #c: 3});

  Expect.equals('c8 7 8 2 3', apply(c8, [7, 8], null));
  Expect.equals('c8 7 8 2 3', apply(c8, [7, 8], {}));
  Expect.equals('c8 7 8 3 3', apply(c8, [7, 8, 3], null));
  Expect.equals('c8 7 8 3 4', apply(c8, [7, 8, 3, 4], null));
  throwsNSME(c8, [], null);
  throwsNSME(c8, [], {});
  throwsNSME(c8, [1], null);
  throwsNSME(c8, [7, 8, 9, 10, 11], null);
}
