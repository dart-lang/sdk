dart_library.library('language/named_parameters_aggregated_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__named_parameters_aggregated_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const named_parameters_aggregated_test_none_multi = Object.create(null);
  let TypeTester = () => (TypeTester = dart.constFn(named_parameters_aggregated_test_none_multi.TypeTester$()))();
  let TypeTesterOfCallback = () => (TypeTesterOfCallback = dart.constFn(named_parameters_aggregated_test_none_multi.TypeTester$(named_parameters_aggregated_test_none_multi.Callback)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_aggregated_test_none_multi.TypeTester$ = dart.generic(T => {
    class TypeTester extends core.Object {}
    dart.addTypeTests(TypeTester);
    return TypeTester;
  });
  named_parameters_aggregated_test_none_multi.TypeTester = TypeTester();
  named_parameters_aggregated_test_none_multi.Callback = dart.typedef('Callback', () => dart.functionType(dart.void, [], [core.String]));
  const _handler = Symbol('_handler');
  named_parameters_aggregated_test_none_multi.NamedParametersAggregatedTests = class NamedParametersAggregatedTests extends core.Object {
    new() {
      this[_handler] = null;
    }
    static F31(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    static f_missing_comma(a) {
      return core.int._check(a);
    }
    InstallCallback(cb) {
      this[_handler] = cb;
    }
  };
  dart.setSignature(named_parameters_aggregated_test_none_multi.NamedParametersAggregatedTests, {
    methods: () => ({InstallCallback: dart.definiteFunctionType(dart.void, [dart.functionType(dart.void, [], {msg: core.String})])}),
    statics: () => ({
      F31: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int}),
      f_missing_comma: dart.definiteFunctionType(core.int, [dart.dynamic])
    }),
    names: ['F31', 'f_missing_comma']
  });
  named_parameters_aggregated_test_none_multi.main = function() {
    named_parameters_aggregated_test_none_multi.NamedParametersAggregatedTests.f_missing_comma(10);
    named_parameters_aggregated_test_none_multi.NamedParametersAggregatedTests.F31(10, {b: 25});
    new (TypeTesterOfCallback())();
    new named_parameters_aggregated_test_none_multi.NamedParametersAggregatedTests().InstallCallback(null);
  };
  dart.fn(named_parameters_aggregated_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_aggregated_test_none_multi = named_parameters_aggregated_test_none_multi;
});
