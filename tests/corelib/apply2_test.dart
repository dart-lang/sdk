// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

apply(Function function, ArgumentDescriptor args) {
  return Function.apply(
      function, args.positionalArguments, args.namedArguments);
}

class ArgumentDescriptor {
  final List positionalArguments;
  final Map<String, dynamic> namedArguments;

  ArgumentDescriptor(this.positionalArguments, this.namedArguments);
}

void throwsNSME(function) {
  Expect.throws(function, (e) => e is NoSuchMethodError);
}

main() {
  var c1 = () => 'c1';
  var c2 = (a) => 'c2 $a';
  var c3 = ([a = 1]) => 'c3 $a';
  var c4 = ({a: 1}) => 'c4 $a';
  var c5 = ({a: 1, b: 2}) => 'c5 $a $b';
  var c6 = ({b: 1, a: 2}) => 'c6 $a $b';

  Expect.equals('c1', apply(c1, new ArgumentDescriptor(null, null)));
  Expect.equals('c1', apply(c1, new ArgumentDescriptor([], null)));
  Expect.equals('c1', apply(c1, new ArgumentDescriptor([], {})));
  Expect.equals('c1', apply(c1, new ArgumentDescriptor(null, {})));
  throwsNSME(() => apply(c1, new ArgumentDescriptor([1], null)));
  throwsNSME(() => apply(c1, new ArgumentDescriptor([1], {'a': 2})));
  throwsNSME(() => apply(c1, new ArgumentDescriptor(null, {'a': 2})));

  Expect.equals('c2 1', apply(c2, new ArgumentDescriptor([1], null)));
  Expect.equals('c2 1', apply(c2, new ArgumentDescriptor([1], {})));
  throwsNSME(() => apply(c2, new ArgumentDescriptor(null, null)));
  throwsNSME(() => apply(c2, new ArgumentDescriptor([], null)));
  throwsNSME(() => apply(c2, new ArgumentDescriptor(null, {})));
  throwsNSME(() => apply(c2, new ArgumentDescriptor(null, {'a': 1})));

  Expect.equals('c3 1', apply(c3, new ArgumentDescriptor([], null)));
  Expect.equals('c3 2', apply(c3, new ArgumentDescriptor([2], {})));
  throwsNSME(() => apply(c3, new ArgumentDescriptor([1, 2], null)));
  throwsNSME(() => apply(c3, new ArgumentDescriptor(null, {'a': 1})));

  Expect.equals('c4 1', apply(c4, new ArgumentDescriptor([], null)));
  Expect.equals('c4 2', apply(c4, new ArgumentDescriptor([], {'a': 2})));
  Expect.equals('c4 1', apply(c4, new ArgumentDescriptor(null, null)));
  Expect.equals('c4 1', apply(c4, new ArgumentDescriptor([], {})));
  throwsNSME(() => apply(c4, new ArgumentDescriptor([1], {'a': 1})));
  throwsNSME(() => apply(c4, new ArgumentDescriptor([1], {})));
  throwsNSME(() => apply(c4, new ArgumentDescriptor([], {'a': 1, 'b': 2})));

  Expect.equals('c5 1 2', apply(c5, new ArgumentDescriptor([], null)));
  Expect.equals('c5 3 2', apply(c5, new ArgumentDescriptor([], {'a': 3})));
  Expect.equals('c5 1 2', apply(c5, new ArgumentDescriptor(null, null)));
  Expect.equals('c5 1 2', apply(c5, new ArgumentDescriptor([], {})));
  Expect.equals('c5 3 4',
      apply(c5, new ArgumentDescriptor([], {'a': 3, 'b': 4})));
  Expect.equals('c5 4 3',
      apply(c5, new ArgumentDescriptor([], {'b': 3, 'a': 4})));
  Expect.equals('c5 1 3',
      apply(c5, new ArgumentDescriptor([], {'b': 3})));
  throwsNSME(() => apply(c5, new ArgumentDescriptor([1], {'a': 1})));
  throwsNSME(() => apply(c5, new ArgumentDescriptor([1], {})));
  throwsNSME(() =>
      apply(c5, new ArgumentDescriptor([], {'a': 1, 'b': 2, 'c': 3})));

  Expect.equals('c6 2 1', apply(c6, new ArgumentDescriptor([], null)));
  Expect.equals('c6 3 1', apply(c6, new ArgumentDescriptor([], {'a': 3})));
  Expect.equals('c6 2 1', apply(c6, new ArgumentDescriptor(null, null)));
  Expect.equals('c6 2 1', apply(c6, new ArgumentDescriptor([], {})));
  Expect.equals('c6 3 4',
      apply(c6, new ArgumentDescriptor([], {'a': 3, 'b': 4})));
  Expect.equals('c6 4 3',
      apply(c6, new ArgumentDescriptor([], {'b': 3, 'a': 4})));
  Expect.equals('c6 2 3',
      apply(c6, new ArgumentDescriptor([], {'b': 3})));
  throwsNSME(() => apply(c6, new ArgumentDescriptor([1], {'a': 1})));
  throwsNSME(() => apply(c6, new ArgumentDescriptor([1], {})));
  throwsNSME(() =>
      apply(c6, new ArgumentDescriptor([], {'a': 1, 'b': 2, 'c': 3})));
}
