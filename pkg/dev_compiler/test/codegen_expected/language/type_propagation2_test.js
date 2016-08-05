dart_library.library('language/type_propagation2_test', null, /* Imports */[
  'dart_sdk'
], function load__type_propagation2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_propagation2_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_propagation2_test.Bar = class Bar extends core.Object {
    noSuchMethod(e) {
      return null;
    }
  };
  type_propagation2_test.main = function() {
    let d = new type_propagation2_test.Bar();
    while (false) {
      let input = dart.fn(x => {
      }, dynamicTodynamic())(null);
      let p2 = dart.dsend(dart.dload(input, 'keys'), 'firstWhere', null);
      let a2 = dart.dsend(dart.dload(input, 'keys'), 'firstWhere', null);
      core.print(dart.equals(dart.dindex(input, a2), p2));
    }
  };
  dart.fn(type_propagation2_test.main, VoidTodynamic());
  // Exports:
  exports.type_propagation2_test = type_propagation2_test;
});
