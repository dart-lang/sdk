dart_library.library('language/named_parameters_type_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__named_parameters_type_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const named_parameters_type_test_none_multi = Object.create(null);
  let num__Tovoid = () => (num__Tovoid = dart.constFn(dart.functionType(dart.void, [core.num], {b: core.bool})))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [num__Tovoid()])))();
  let numTovoid = () => (numTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num])))();
  let numAndboolTovoid = () => (numAndboolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num, core.bool])))();
  let num__Tovoid$ = () => (num__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [core.num], {b: core.bool})))();
  let num__Tovoid$0 = () => (num__Tovoid$0 = dart.constFn(dart.definiteFunctionType(dart.void, [core.num], {x: core.bool})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_type_test_none_multi.main = function() {
    let anyFunction = null;
    function acceptFunNumOptBool(funNumOptBool) {
    }
    dart.fn(acceptFunNumOptBool, FnTovoid());
    ;
    function funNum(n) {
    }
    dart.fn(funNum, numTovoid());
    ;
    function funNumBool(n, b) {
    }
    dart.fn(funNumBool, numAndboolTovoid());
    ;
    function funNumOptBool(n, opts) {
      let b = opts && 'b' in opts ? opts.b : true;
    }
    dart.fn(funNumOptBool, num__Tovoid$());
    ;
    function funNumOptBoolX(n, opts) {
      let x = opts && 'x' in opts ? opts.x : true;
    }
    dart.fn(funNumOptBoolX, num__Tovoid$0());
    ;
    anyFunction = funNum;
    anyFunction = funNumBool;
    anyFunction = funNumOptBool;
    anyFunction = funNumOptBoolX;
    acceptFunNumOptBool(funNumOptBool);
  };
  dart.fn(named_parameters_type_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_type_test_none_multi = named_parameters_type_test_none_multi;
});
