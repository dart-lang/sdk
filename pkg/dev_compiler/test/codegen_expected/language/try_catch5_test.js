dart_library.library('language/try_catch5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch5_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch5_test.a = null;
  try_catch5_test.foo1 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch5_test.a);
      try {
        try {
          try_catch5_test.a = 8;
          return;
        } finally {
          b = dart.equals(8, try_catch5_test.a);
          entered = true;
          continue;
        }
      } finally {
        continue;
      }
    }
  };
  dart.fn(try_catch5_test.foo1, VoidTodynamic());
  try_catch5_test.main = function() {
    for (let i = 0; i < 20; i++) {
      try_catch5_test.a = 0;
      expect$.Expect.isTrue(try_catch5_test.foo1());
    }
  };
  dart.fn(try_catch5_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch5_test = try_catch5_test;
});
