dart_library.library('language/core_type_check_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__core_type_check_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const core_type_check_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  core_type_check_test.check = function(value, expectComparable, expectPattern) {
    expect$.Expect.equals(expectComparable, core.Comparable.is(value));
    expect$.Expect.equals(expectPattern, core.Pattern.is(value));
  };
  dart.fn(core_type_check_test.check, dynamicAnddynamicAnddynamicTodynamic());
  core_type_check_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(core_type_check_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(core_type_check_test.inscrutable, intToint());
  core_type_check_test.A = class A extends core.Object {
    compareTo(o) {
      return 0;
    }
  };
  core_type_check_test.A[dart.implements] = () => [core.Comparable];
  dart.setSignature(core_type_check_test.A, {
    methods: () => ({compareTo: dart.definiteFunctionType(core.int, [dart.dynamic])})
  });
  dart.defineExtensionMembers(core_type_check_test.A, ['compareTo']);
  core_type_check_test.B = class B extends core.Object {};
  core_type_check_test.C = class C extends core.Object {
    matchAsPrefix(s, start) {
      if (start === void 0) start = 0;
      return null;
    }
    allMatches(s, start) {
      if (start === void 0) start = 0;
      return null;
    }
  };
  core_type_check_test.C[dart.implements] = () => [core.Pattern];
  dart.setSignature(core_type_check_test.C, {
    methods: () => ({
      matchAsPrefix: dart.definiteFunctionType(core.Match, [core.String], [core.int]),
      allMatches: dart.definiteFunctionType(core.Iterable$(core.Match), [core.String], [core.int])
    })
  });
  dart.defineExtensionMembers(core_type_check_test.C, ['matchAsPrefix', 'allMatches']);
  core_type_check_test.D = class D extends core.Object {
    compareTo(o) {
      return 0;
    }
    matchAsPrefix(s, start) {
      if (start === void 0) start = 0;
      return null;
    }
    allMatches(s, start) {
      if (start === void 0) start = 0;
      return null;
    }
  };
  core_type_check_test.D[dart.implements] = () => [core.Pattern, core.Comparable];
  dart.setSignature(core_type_check_test.D, {
    methods: () => ({
      compareTo: dart.definiteFunctionType(core.int, [dart.dynamic]),
      matchAsPrefix: dart.definiteFunctionType(core.Match, [core.String], [core.int]),
      allMatches: dart.definiteFunctionType(core.Iterable$(core.Match), [core.String], [core.int])
    })
  });
  dart.defineExtensionMembers(core_type_check_test.D, ['compareTo', 'matchAsPrefix', 'allMatches']);
  core_type_check_test.main = function() {
    let things = JSArrayOfObject().of([[], 4, 4.2, 'foo', new core.Object(), new core_type_check_test.A(), new core_type_check_test.B(), new core_type_check_test.C(), new core_type_check_test.D()]);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(0)), false, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(1)), true, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(2)), true, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(3)), true, true);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(4)), false, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(5)), true, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(6)), false, false);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(7)), false, true);
    core_type_check_test.check(things[dartx.get](core_type_check_test.inscrutable(8)), true, true);
  };
  dart.fn(core_type_check_test.main, VoidTodynamic());
  // Exports:
  exports.core_type_check_test = core_type_check_test;
});
