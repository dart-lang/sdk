dart_library.library('language/getter_setter_order_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_setter_order_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_setter_order_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getter_setter_order_test.trace = null;
  getter_setter_order_test.X = class X extends core.Object {
    get b() {
      dart.dsend(getter_setter_order_test.trace, 'add', 'get b');
      return new getter_setter_order_test.X();
    }
    set c(value) {
      dart.dsend(getter_setter_order_test.trace, 'add', 'set c');
    }
    toString() {
      dart.dsend(getter_setter_order_test.trace, 'add', 'toString');
      return 'X';
    }
    get c() {
      dart.dsend(getter_setter_order_test.trace, 'add', 'get c');
      return 42;
    }
    get d() {
      dart.dsend(getter_setter_order_test.trace, 'add', 'get d');
      return new getter_setter_order_test.X();
    }
    get(index) {
      dart.dsend(getter_setter_order_test.trace, 'add', 'index');
      return 42;
    }
    set(index, value) {
      dart.dsend(getter_setter_order_test.trace, 'add', 'indexSet');
      return value;
    }
  };
  dart.setSignature(getter_setter_order_test.X, {
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
    })
  });
  getter_setter_order_test.main = function() {
    let x = new getter_setter_order_test.X();
    getter_setter_order_test.trace = [];
    dart.dput(x.b, 'c', dart.str`${x}`);
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'toString', 'set c']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o = x.b;
    dart.dput(o, 'c', dart.dsend(dart.dload(o, 'c'), '+', dart.hashCode(dart.str`${x}`)));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get c', 'toString', 'set c']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o$ = x.b;
    dart.dput(o$, 'c', dart.dsend(dart.dload(o$, 'c'), '+', 1));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get c', 'set c']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    dart.dsetindex(dart.dload(x.b, 'd'), 42, dart.str`${x}`);
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'toString', 'indexSet']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o$0 = dart.dload(x.b, 'd'), i = 42;
    dart.dsetindex(o$0, i, dart.dsend(dart.dindex(o$0, i), '+', dart.hashCode(dart.str`${x}`)));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'index', 'toString', 'indexSet']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o$1 = dart.dload(x.b, 'd'), i$ = 42;
    dart.dsetindex(o$1, i$, dart.dsend(dart.dindex(o$1, i$), '+', 1));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'index', 'indexSet']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o$2 = dart.dload(x.b, 'd'), i$0 = 42;
    dart.dsetindex(o$2, i$0, dart.dsend(dart.dindex(o$2, i$0), '+', 1));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'index', 'indexSet']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    let o$3 = dart.dload(x.b, 'd'), i$1 = x.c;
    dart.dsetindex(o$3, i$1, dart.dsend(dart.dindex(o$3, i$1), '*', dart.hashCode(dart.str`${x}`)));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'get c', 'index', 'toString', 'indexSet']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    dart.dput(x.b, 'c', dart.dput(x.d, 'c', dart.str`${x}`));
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'toString', 'set c', 'set c']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    dart.dput(x.b, 'c', (() => {
      let o = x.d, i = 42;
      return dart.dsetindex(o, i, dart.dsend(dart.dindex(o, i), '*', dart.hashCode(dart.str`${x}`)));
    })());
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'index', 'toString', 'indexSet', 'set c']), core.List._check(getter_setter_order_test.trace));
    getter_setter_order_test.trace = [];
    dart.dput(x.b, 'c', (() => {
      let o = x.d;
      return dart.dput(o, 'c', dart.dsend(dart.dload(o, 'c'), '+', 1));
    })());
    expect$.Expect.listEquals(JSArrayOfString().of(['get b', 'get d', 'get c', 'set c', 'set c']), core.List._check(getter_setter_order_test.trace));
  };
  dart.fn(getter_setter_order_test.main, VoidTodynamic());
  // Exports:
  exports.getter_setter_order_test = getter_setter_order_test;
});
