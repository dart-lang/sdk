dart_library.library('corelib/throw_half_surrogate_pair_test_02_multi', null, /* Imports */[
  'dart_sdk'
], function load__throw_half_surrogate_pair_test_02_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const throw_half_surrogate_pair_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw_half_surrogate_pair_test_02_multi.main = function() {
    let trebleClef = "𝄞";
    if (trebleClef[dartx.length] != 2) dart.throw("String should be a surrogate pair");
    dart.throw(trebleClef[dartx.get](1));
  };
  dart.fn(throw_half_surrogate_pair_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.throw_half_surrogate_pair_test_02_multi = throw_half_surrogate_pair_test_02_multi;
});
