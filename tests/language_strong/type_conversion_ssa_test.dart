// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, that used to generate bad code in
// checked mode. The pattern that lead to an error was:
//
// t1 = GeneratedAtUseSite instruction
// t2 = check(t1)
// t3 = check(t2)
// t4 = use(t3)
// t5 = use(t3)
// t6 = use(t2)
//
// The SSA variable allocator used to allocate the same variable for
// t5 and t2, because of a bogus optimization with check instructions.

expect(a, b) {
  if (a != b) throw 'Failed';
}

var array = [
  new SelectorGroup([
    new Selector([new SimpleSelectorSequence(new ClassSelector())]),
    new Selector([new SimpleSelectorSequence(new ClassSelector())]),
    new Selector([new SimpleSelectorSequence(new ClassSelector())])
  ]),
  new Object()
];

class RuleSet {
  final SelectorGroup _selectorGroup;
  RuleSet(this._selectorGroup);
  SelectorGroup get selectorGroup => _selectorGroup;
}

class SelectorGroup {
  List<Selector> _selectors;
  SelectorGroup(this._selectors);
  List<Selector> get selectors => _selectors;
}

class Selector {
  final List<SimpleSelectorSequence> _simpleSelectorSequences;
  Selector(this._simpleSelectorSequences);
  List<SimpleSelectorSequence> get simpleSelectorSequences =>
      _simpleSelectorSequences;
}

class SimpleSelectorSequence {
  final SimpleSelector _selector;
  SimpleSelectorSequence(this._selector);
  get simpleSelector => _selector;
}

class SimpleSelector {}

class ClassSelector extends SimpleSelector {}

void testSelectorGroups() {
  // Fetch the rule set from an array to trick the type inferrer.
  var ruleset = new RuleSet(array[0]);
  expect(ruleset.selectorGroup.selectors.length, 3);

  var groupSelector0 = ruleset.selectorGroup.selectors[0];
  var selector0 = groupSelector0.simpleSelectorSequences[0];
  var simpleSelector0 = selector0.simpleSelector;

  var groupSelector1 = ruleset.selectorGroup.selectors[1];
  var selector1 = groupSelector1.simpleSelectorSequences[0];
  var simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  var groupSelector2 = ruleset.selectorGroup.selectors[2];
}

main() {
  testSelectorGroups();
  // Trick the type inferrer.
  new SimpleSelectorSequence(new SimpleSelector());
  new SelectorGroup([]);
  new Selector([]);
}
