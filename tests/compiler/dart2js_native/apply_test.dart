// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test should move to a language test once the apply method
// gets into the specification.

apply(Function function, ArgumentDescriptor args) {
  int argumentCount = 0;
  StringBuffer buffer = new StringBuffer();
  List arguments = [];

  if (args.positionalArguments != null) {
    argumentCount += args.positionalArguments.length;
    arguments.addAll(args.positionalArguments);
  }

  // Sort the named arguments to get the right selector name and
  // arguments order.
  if (args.namedArguments != null && !args.namedArguments.isEmpty()) {
    // Call new List.from to make sure we get a JavaScript array.
    List<String> namedArguments =
        new List<String>.from(args.namedArguments.getKeys());
    argumentCount += namedArguments.length;
    // We're sorting on strings, and the behavior is the same between
    // Dart string sort and JS String sort. To avoid needing the Dart
    // sort implementation, we use the JavaScript one instead.
    JS('void', '#.sort()', namedArguments);
    namedArguments.forEach((String name) {
      buffer.add('\$$name');
      arguments.add(args.namedArguments[name]);
    });
  }

  String selectorName = 'call\$$argumentCount$buffer';
  var jsFunction = JS('var', '#[#]', function, selectorName);
  if (jsFunction == null) {
    throw new NoSuchMethodError(function, selectorName, arguments);
  }
  // We bound 'this' to [function] because of how we compile
  // closures: escaped local variables are stored and accessed through
  // [function].
  return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
}

class ArgumentDescriptor {
  final List positionalArguments;
  final Map<String, Dynamic> namedArguments;

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

  // TODO(ngeoffray): Remove these calls. They are currently needed
  // because otherwise we would not generate the stubs. Once apply is
  // in the specification, we should change the compiler to emit stubs
  // for closures once it sees an 'apply' selector.
  c1();
  c2(1);
  c3(); c3(1);
  c4(); c4(a: 1);
  c5(); c5(a: 1); c5(b: 2); c5(a:1, b: 2);
  c6(); c6(a: 1); c6(b: 2); c6(a:1, b: 2);

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
  // TODO(ngeoffray): Should be throwsNSME with the new parameter
  // specification.
  Expect.equals('c3 1', apply(c3, new ArgumentDescriptor(null, {'a': 1})));

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
