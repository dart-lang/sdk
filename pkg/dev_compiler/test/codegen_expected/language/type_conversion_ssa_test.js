dart_library.library('language/type_conversion_ssa_test', null, /* Imports */[
  'dart_sdk'
], function load__type_conversion_ssa_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_conversion_ssa_test = Object.create(null);
  let JSArrayOfSimpleSelectorSequence = () => (JSArrayOfSimpleSelectorSequence = dart.constFn(_interceptors.JSArray$(type_conversion_ssa_test.SimpleSelectorSequence)))();
  let JSArrayOfSelector = () => (JSArrayOfSelector = dart.constFn(_interceptors.JSArray$(type_conversion_ssa_test.Selector)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_conversion_ssa_test.expect = function(a, b) {
    if (!dart.equals(a, b)) dart.throw('Failed');
  };
  dart.fn(type_conversion_ssa_test.expect, dynamicAnddynamicTodynamic());
  dart.defineLazy(type_conversion_ssa_test, {
    get array() {
      return JSArrayOfObject().of([new type_conversion_ssa_test.SelectorGroup(JSArrayOfSelector().of([new type_conversion_ssa_test.Selector(JSArrayOfSimpleSelectorSequence().of([new type_conversion_ssa_test.SimpleSelectorSequence(new type_conversion_ssa_test.ClassSelector())])), new type_conversion_ssa_test.Selector(JSArrayOfSimpleSelectorSequence().of([new type_conversion_ssa_test.SimpleSelectorSequence(new type_conversion_ssa_test.ClassSelector())])), new type_conversion_ssa_test.Selector(JSArrayOfSimpleSelectorSequence().of([new type_conversion_ssa_test.SimpleSelectorSequence(new type_conversion_ssa_test.ClassSelector())]))])), new core.Object()]);
    },
    set array(_) {}
  });
  const _selectorGroup = Symbol('_selectorGroup');
  type_conversion_ssa_test.RuleSet = class RuleSet extends core.Object {
    new(selectorGroup) {
      this[_selectorGroup] = selectorGroup;
    }
    get selectorGroup() {
      return this[_selectorGroup];
    }
  };
  dart.setSignature(type_conversion_ssa_test.RuleSet, {
    constructors: () => ({new: dart.definiteFunctionType(type_conversion_ssa_test.RuleSet, [type_conversion_ssa_test.SelectorGroup])})
  });
  const _selectors = Symbol('_selectors');
  type_conversion_ssa_test.SelectorGroup = class SelectorGroup extends core.Object {
    new(selectors) {
      this[_selectors] = selectors;
    }
    get selectors() {
      return this[_selectors];
    }
  };
  dart.setSignature(type_conversion_ssa_test.SelectorGroup, {
    constructors: () => ({new: dart.definiteFunctionType(type_conversion_ssa_test.SelectorGroup, [core.List$(type_conversion_ssa_test.Selector)])})
  });
  const _simpleSelectorSequences = Symbol('_simpleSelectorSequences');
  type_conversion_ssa_test.Selector = class Selector extends core.Object {
    new(simpleSelectorSequences) {
      this[_simpleSelectorSequences] = simpleSelectorSequences;
    }
    get simpleSelectorSequences() {
      return this[_simpleSelectorSequences];
    }
  };
  dart.setSignature(type_conversion_ssa_test.Selector, {
    constructors: () => ({new: dart.definiteFunctionType(type_conversion_ssa_test.Selector, [core.List$(type_conversion_ssa_test.SimpleSelectorSequence)])})
  });
  const _selector = Symbol('_selector');
  type_conversion_ssa_test.SimpleSelectorSequence = class SimpleSelectorSequence extends core.Object {
    new(selector) {
      this[_selector] = selector;
    }
    get simpleSelector() {
      return this[_selector];
    }
  };
  dart.setSignature(type_conversion_ssa_test.SimpleSelectorSequence, {
    constructors: () => ({new: dart.definiteFunctionType(type_conversion_ssa_test.SimpleSelectorSequence, [type_conversion_ssa_test.SimpleSelector])})
  });
  type_conversion_ssa_test.SimpleSelector = class SimpleSelector extends core.Object {};
  type_conversion_ssa_test.ClassSelector = class ClassSelector extends type_conversion_ssa_test.SimpleSelector {};
  type_conversion_ssa_test.testSelectorGroups = function() {
    let ruleset = new type_conversion_ssa_test.RuleSet(type_conversion_ssa_test.SelectorGroup._check(type_conversion_ssa_test.array[dartx.get](0)));
    type_conversion_ssa_test.expect(ruleset.selectorGroup.selectors[dartx.length], 3);
    let groupSelector0 = ruleset.selectorGroup.selectors[dartx.get](0);
    let selector0 = groupSelector0.simpleSelectorSequences[dartx.get](0);
    let simpleSelector0 = selector0.simpleSelector;
    let groupSelector1 = ruleset.selectorGroup.selectors[dartx.get](1);
    let selector1 = groupSelector1.simpleSelectorSequences[dartx.get](0);
    let simpleSelector1 = selector1.simpleSelector;
    type_conversion_ssa_test.expect(type_conversion_ssa_test.ClassSelector.is(simpleSelector1), true);
    let groupSelector2 = ruleset.selectorGroup.selectors[dartx.get](2);
  };
  dart.fn(type_conversion_ssa_test.testSelectorGroups, VoidTovoid());
  type_conversion_ssa_test.main = function() {
    type_conversion_ssa_test.testSelectorGroups();
    new type_conversion_ssa_test.SimpleSelectorSequence(new type_conversion_ssa_test.SimpleSelector());
    new type_conversion_ssa_test.SelectorGroup(JSArrayOfSelector().of([]));
    new type_conversion_ssa_test.Selector(JSArrayOfSimpleSelectorSequence().of([]));
  };
  dart.fn(type_conversion_ssa_test.main, VoidTodynamic());
  // Exports:
  exports.type_conversion_ssa_test = type_conversion_ssa_test;
});
