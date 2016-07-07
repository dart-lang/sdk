dart_library.library('corelib/hidden_library2_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__hidden_library2_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const hidden_library2_test_01_multi = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hidden_library2_test_01_multi.main = function() {
    core.print(JSArrayOfString().of(['x'])[dartx.where](dart.fn(_ => {
      dart.throw('fisk');
      return true;
    }, StringTobool()))[dartx.toList]());
  };
  dart.fn(hidden_library2_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.hidden_library2_test_01_multi = hidden_library2_test_01_multi;
});
