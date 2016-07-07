dart_library.library('language/positional_parameters_type_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__positional_parameters_type_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const positional_parameters_type_test_none_multi = Object.create(null);
  let num__Tovoid = () => (num__Tovoid = dart.constFn(dart.functionType(dart.void, [core.num], [core.bool])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [num__Tovoid()])))();
  let numTovoid = () => (numTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num])))();
  let numAndboolTovoid = () => (numAndboolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num, core.bool])))();
  let num__Tovoid$ = () => (num__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [core.num], [core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  positional_parameters_type_test_none_multi.main = function() {
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
    function funNumOptBool(n, b) {
      if (b === void 0) b = true;
    }
    dart.fn(funNumOptBool, num__Tovoid$());
    ;
    function funNumOptBoolX(n, x) {
      if (x === void 0) x = true;
    }
    dart.fn(funNumOptBoolX, num__Tovoid$());
    ;
    anyFunction = funNum;
    anyFunction = funNumBool;
    anyFunction = funNumOptBool;
    anyFunction = funNumOptBoolX;
    acceptFunNumOptBool(funNumOptBool);
    acceptFunNumOptBool(funNumOptBoolX);
  };
  dart.fn(positional_parameters_type_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.positional_parameters_type_test_none_multi = positional_parameters_type_test_none_multi;
});
