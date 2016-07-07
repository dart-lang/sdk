dart_library.library('language/export_order_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__export_order_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const export_order_test = Object.create(null);
  const export_order_helper1 = Object.create(null);
  const export_order_helper2 = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  export_order_test.y = 38;
  dart.defineLazy(export_order_test, {
    get info() {
      return new export_order_helper2.Info();
    }
  });
  export_order_test.main = function() {
    expect$.Expect.equals(38, export_order_test.info.x);
    expect$.Expect.equals(38, export_order_test.y);
    expect$.Expect.equals(38, export_order_helper2.z);
  };
  dart.fn(export_order_test.main, VoidTovoid());
  export_order_helper1.y = export_order_test.y;
  dart.export(export_order_helper1, export_order_test, 'info');
  export_order_helper1.main = export_order_test.main;
  dart.copyProperties(export_order_helper2, {
    get z() {
      return 38;
    }
  });
  dart.export(export_order_helper1, export_order_helper2, 'z');
  export_order_helper2.Info = class Info extends core.Object {
    new() {
      this.x = export_order_test.y;
    }
  };
  // Exports:
  exports.export_order_test = export_order_test;
  exports.export_order_helper1 = export_order_helper1;
  exports.export_order_helper2 = export_order_helper2;
});
