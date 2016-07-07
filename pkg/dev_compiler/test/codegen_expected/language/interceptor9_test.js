dart_library.library('language/interceptor9_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__interceptor9_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const interceptor9_test = Object.create(null);
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  interceptor9_test.confuse = function(x, y) {
    if (y === void 0) y = null;
    return new core.DateTime.now().day == 42 ? y : x;
  };
  dart.fn(interceptor9_test.confuse, dynamic__Todynamic());
  interceptor9_test.boom = function() {
    let x = interceptor9_test.confuse(typed_data.Uint8List.new(22), "");
    expect$.Expect.isTrue(typed_data.Uint8List.is(x));
    dart.dsend(x, 'startsWith', "a");
    dart.dsend(x, 'endsWith', "u");
  };
  dart.fn(interceptor9_test.boom, VoidTodynamic());
  interceptor9_test.main = function() {
    try {
      let f = null;
      if (dart.test(interceptor9_test.confuse(true))) {
        f = interceptor9_test.boom;
      }
      dart.dcall(f);
    } catch (e) {
      if (expect$.ExpectException.is(e)) dart.throw(e);
    }

  };
  dart.fn(interceptor9_test.main, VoidTodynamic());
  // Exports:
  exports.interceptor9_test = interceptor9_test;
});
