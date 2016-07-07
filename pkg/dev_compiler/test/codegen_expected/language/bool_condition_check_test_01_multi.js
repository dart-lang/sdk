dart_library.library('language/bool_condition_check_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bool_condition_check_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bool_condition_check_test_01_multi = Object.create(null);
  let __ToString = () => (__ToString = dart.constFn(dart.definiteFunctionType(core.String, [], {a: core.bool, b: core.bool})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bool_condition_check_test_01_multi.check = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
    let a_string = dart.test(a) ? 'a' : '';
    let b_string = dart.test(b) ? 'b' : '';
    return dart.str`${a_string}${b_string}`;
  };
  dart.fn(bool_condition_check_test_01_multi.check, __ToString());
  bool_condition_check_test_01_multi.Class = class Class extends core.Object {
    new(opts) {
      let a = opts && 'a' in opts ? opts.a : false;
      let b = opts && 'b' in opts ? opts.b : true;
      this.field = bool_condition_check_test_01_multi.check({a: a, b: b});
    }
  };
  dart.setSignature(bool_condition_check_test_01_multi.Class, {
    constructors: () => ({new: dart.definiteFunctionType(bool_condition_check_test_01_multi.Class, [], {a: core.bool, b: core.bool})})
  });
  bool_condition_check_test_01_multi.main = function() {
    expect$.Expect.equals('', new bool_condition_check_test_01_multi.Class({a: null, b: null}).field);
  };
  dart.fn(bool_condition_check_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.bool_condition_check_test_01_multi = bool_condition_check_test_01_multi;
});
