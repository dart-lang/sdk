dart_library.library('language/closure7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure7_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure7_test.A = class A extends core.Object {
    foo() {
      return 499;
    }
    fooo() {
      return 4999;
    }
    bar(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let z = opts && 'z' in opts ? opts.z : 10;
      return dart.str`1 ${x} ${y} ${z}`;
    }
    gee(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 9;
      let z = opts && 'z' in opts ? opts.z : 11;
      return dart.str`2 ${x} ${y} ${z}`;
    }
    toto(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let z = opts && 'z' in opts ? opts.z : 10;
      return dart.str`3 ${x} ${y} ${z}`;
    }
    fisk(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let zz = opts && 'zz' in opts ? opts.zz : 10;
      return dart.str`4 ${x} ${y} ${zz}`;
    }
    titi(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let zz = opts && 'zz' in opts ? opts.zz : 77;
      return dart.str`5 ${x} ${y} ${zz}`;
    }
  };
  dart.setSignature(closure7_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      fooo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      gee: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      toto: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      fisk: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, zz: dart.dynamic}),
      titi: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, zz: dart.dynamic})
    })
  });
  closure7_test.B = class B extends core.Object {
    foo() {
      return 4990;
    }
    fooo() {
      return 49990;
    }
    bar(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let z = opts && 'z' in opts ? opts.z : 10;
      return dart.str`1B ${x} ${y} ${z}`;
    }
    gee(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 9;
      let z = opts && 'z' in opts ? opts.z : 11;
      return dart.str`2B ${x} ${y} ${z}`;
    }
    toto(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let z = opts && 'z' in opts ? opts.z : 10;
      return dart.str`3B ${x} ${y} ${z}`;
    }
    fisk(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let zz = opts && 'zz' in opts ? opts.zz : 10;
      return dart.str`4B ${x} ${y} ${zz}`;
    }
    titi(x, opts) {
      let y = opts && 'y' in opts ? opts.y : 8;
      let zz = opts && 'zz' in opts ? opts.zz : 77;
      return dart.str`5B ${x} ${y} ${zz}`;
    }
  };
  dart.setSignature(closure7_test.B, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      fooo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      gee: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      toto: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, z: dart.dynamic}),
      fisk: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, zz: dart.dynamic}),
      titi: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {y: dart.dynamic, zz: dart.dynamic})
    })
  });
  closure7_test.tearOffFoo = function(o) {
    return dart.dload(o, 'foo');
  };
  dart.fn(closure7_test.tearOffFoo, dynamicTodynamic());
  closure7_test.tearOffFooo = function(o) {
    return dart.dload(o, 'fooo');
  };
  dart.fn(closure7_test.tearOffFooo, dynamicTodynamic());
  closure7_test.tearOffBar = function(o) {
    return dart.dload(o, 'bar');
  };
  dart.fn(closure7_test.tearOffBar, dynamicTodynamic());
  closure7_test.tearOffGee = function(o) {
    return dart.dload(o, 'gee');
  };
  dart.fn(closure7_test.tearOffGee, dynamicTodynamic());
  closure7_test.tearOffToto = function(o) {
    return dart.dload(o, 'toto');
  };
  dart.fn(closure7_test.tearOffToto, dynamicTodynamic());
  closure7_test.tearOffFisk = function(o) {
    return dart.dload(o, 'fisk');
  };
  dart.fn(closure7_test.tearOffFisk, dynamicTodynamic());
  closure7_test.tearOffTiti = function(o) {
    return dart.dload(o, 'titi');
  };
  dart.fn(closure7_test.tearOffTiti, dynamicTodynamic());
  closure7_test.main = function() {
    let a = new closure7_test.A();
    let b = new closure7_test.B();
    expect$.Expect.equals(499, dart.dcall(closure7_test.tearOffFoo(a)));
    expect$.Expect.equals(4990, dart.dcall(closure7_test.tearOffFoo(b)));
    expect$.Expect.equals(4999, dart.dcall(closure7_test.tearOffFooo(a)));
    expect$.Expect.equals(49990, dart.dcall(closure7_test.tearOffFooo(b)));
    let barA = closure7_test.tearOffBar(a);
    let barB = closure7_test.tearOffBar(b);
    let geeA = closure7_test.tearOffGee(a);
    let geeB = closure7_test.tearOffGee(b);
    let totoA = closure7_test.tearOffToto(a);
    let totoB = closure7_test.tearOffToto(b);
    expect$.Expect.equals("1 33 8 10", dart.dcall(barA, 33));
    expect$.Expect.equals("1B 33 8 10", dart.dcall(barB, 33));
    expect$.Expect.equals("2 33 9 11", dart.dcall(geeA, 33));
    expect$.Expect.equals("2B 33 9 11", dart.dcall(geeB, 33));
    expect$.Expect.equals("3 33 8 10", dart.dcall(totoA, 33));
    expect$.Expect.equals("3B 33 8 10", dart.dcall(totoB, 33));
    expect$.Expect.equals("1 35 8 10", dart.dcall(barA, 35));
    expect$.Expect.equals("1B 35 8 10", dart.dcall(barB, 35));
    expect$.Expect.equals("2 35 9 11", dart.dcall(geeA, 35));
    expect$.Expect.equals("2B 35 9 11", dart.dcall(geeB, 35));
    expect$.Expect.equals("3 35 8 10", dart.dcall(totoA, 35));
    expect$.Expect.equals("3B 35 8 10", dart.dcall(totoB, 35));
    expect$.Expect.equals("1 35 8 77", dart.dcall(barA, 35, {z: 77}));
    expect$.Expect.equals("1B 35 8 77", dart.dcall(barB, 35, {z: 77}));
    expect$.Expect.equals("2 35 9 77", dart.dcall(geeA, 35, {z: 77}));
    expect$.Expect.equals("2B 35 9 77", dart.dcall(geeB, 35, {z: 77}));
    expect$.Expect.equals("3 35 8 77", dart.dcall(totoA, 35, {z: 77}));
    expect$.Expect.equals("3B 35 8 77", dart.dcall(totoB, 35, {z: 77}));
    expect$.Expect.equals("1 35 8 77", dart.dcall(barA, 35, {z: 77}));
    expect$.Expect.equals("1B 35 8 77", dart.dcall(barB, 35, {z: 77}));
    expect$.Expect.equals("2 35 9 77", dart.dcall(geeA, 35, {z: 77}));
    expect$.Expect.equals("2B 35 9 77", dart.dcall(geeB, 35, {z: 77}));
    expect$.Expect.equals("3 35 8 77", dart.dcall(totoA, 35, {z: 77}));
    expect$.Expect.equals("3B 35 8 77", dart.dcall(totoB, 35, {z: 77}));
    let fiskA = closure7_test.tearOffFisk(a);
    let fiskB = closure7_test.tearOffFisk(b);
    let titiA = closure7_test.tearOffTiti(a);
    let titiB = closure7_test.tearOffTiti(b);
    expect$.Expect.equals("4 311 8 987", dart.dcall(fiskA, 311, {zz: 987}));
    expect$.Expect.equals("4B 311 8 987", dart.dcall(fiskB, 311, {zz: 987}));
    expect$.Expect.equals("5 311 8 987", dart.dcall(titiA, 311, {zz: 987}));
    expect$.Expect.equals("5B 311 8 987", dart.dcall(titiB, 311, {zz: 987}));
    expect$.Expect.equals("4 311 765 987", dart.dcall(fiskA, 311, {y: 765, zz: 987}));
    expect$.Expect.equals("4B 311 765 987", dart.dcall(fiskB, 311, {y: 765, zz: 987}));
    expect$.Expect.equals("5 311 765 987", dart.dcall(titiA, 311, {y: 765, zz: 987}));
    expect$.Expect.equals("5B 311 765 987", dart.dcall(titiB, 311, {y: 765, zz: 987}));
  };
  dart.fn(closure7_test.main, VoidTodynamic());
  // Exports:
  exports.closure7_test = closure7_test;
});
