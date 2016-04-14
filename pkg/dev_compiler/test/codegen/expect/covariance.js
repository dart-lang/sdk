dart_library.library('covariance', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const covariance = Object.create(null);
  const _t = Symbol('_t');
  covariance.Foo$ = dart.generic(T => {
    class Foo extends core.Object {
      Foo() {
        this[_t] = null;
      }
      add(t) {
        dart.as(t, T);
        this[_t] = t;
      }
      forEach(fn) {
        dart.as(fn, dart.functionType(dart.void, [T]));
        fn(this[_t]);
      }
    }
    dart.setSignature(Foo, {
      methods: () => ({
        add: [dart.dynamic, [T]],
        forEach: [dart.dynamic, [dart.functionType(dart.void, [T])]]
      })
    });
    return Foo;
  });
  covariance.Foo = covariance.Foo$();
  covariance.Bar = class Bar extends covariance.Foo$(core.int) {
    Bar() {
      super.Foo();
    }
    add(x) {
      core.print(`Bar.add got ${x}`);
      super.add(x);
    }
  };
  dart.setSignature(covariance.Bar, {
    methods: () => ({add: [dart.dynamic, [core.int]]})
  });
  covariance.main = function() {
    let foo = new covariance.Bar();
    foo.add('hi');
  };
  dart.fn(covariance.main);
  // Exports:
  exports.covariance = covariance;
});
