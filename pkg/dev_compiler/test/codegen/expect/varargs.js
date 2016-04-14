dart_library.library('varargs', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const varargs = Object.create(null);
  varargs.varargsTest = function(x, ...others) {
    let args = [1, others];
    dart.dsend(x, 'call', ...args);
  };
  dart.fn(varargs.varargsTest);
  varargs.varargsTest2 = function(x, ...others) {
    let args = [1, others];
    dart.dsend(x, 'call', ...args);
  };
  dart.fn(varargs.varargsTest2);
  // Exports:
  exports.varargs = varargs;
});
