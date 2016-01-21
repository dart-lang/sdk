dart_library.library('varargs', null, /* Imports */[
  'dart/_runtime'
], /* Lazy imports */[
], function(exports, dart) {
  'use strict';
  let dartx = dart.dartx;
  function varargsTest(x, ...others) {
    let args = [1, others];
    dart.dsend(x, 'call', ...args);
  }
  dart.fn(varargsTest);
  function varargsTest2(x, ...others) {
    let args = [1, others];
    dart.dsend(x, 'call', ...args);
  }
  dart.fn(varargsTest2);
  // Exports:
  exports.varargsTest = varargsTest;
  exports.varargsTest2 = varargsTest2;
});
