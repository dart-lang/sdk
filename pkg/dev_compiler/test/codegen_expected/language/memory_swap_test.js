dart_library.library('language/memory_swap_test', null, /* Imports */[
  'dart_sdk'
], function load__memory_swap_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const memory_swap_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  memory_swap_test.main = function() {
    for (let i = 0; i < 100000; i++) {
      memory_swap_test.spillingMethod(i, dart.fn(() => 0, VoidToint()));
    }
  };
  dart.fn(memory_swap_test.main, VoidTodynamic());
  memory_swap_test.spillingMethod = function(what, obfuscate) {
    let a = dart.dcall(obfuscate);
    let b = dart.dcall(obfuscate);
    let c = dart.dcall(obfuscate);
    let d = dart.dcall(obfuscate);
    let e = dart.dcall(obfuscate);
    let f = dart.dcall(obfuscate);
    let g = dart.dcall(obfuscate);
    let h = dart.dcall(obfuscate);
    let i = dart.dcall(obfuscate);
    let j = dart.dcall(obfuscate);
    let k = dart.dcall(obfuscate);
    let l = dart.dcall(obfuscate);
    let m = dart.dcall(obfuscate);
    let n = dart.dcall(obfuscate);
    let o = dart.dcall(obfuscate);
    let p = dart.dcall(obfuscate);
    let q = dart.dcall(obfuscate);
    let r = dart.dcall(obfuscate);
    let s = dart.dcall(obfuscate);
    let t = dart.dcall(obfuscate);
    let u = dart.dcall(obfuscate);
    let v = dart.dcall(obfuscate);
    while (dart.equals(what, 42)) {
      a = b;
      b = a;
      c = d;
      d = c;
      e = f;
      f = e;
      g = h;
      h = g;
      i = j;
      j = i;
      k = l;
      l = k;
      m = n;
      n = m;
      o = p;
      p = o;
      q = r;
      r = q;
      s = t;
      t = s;
      u = v;
      v = u;
      what = dart.dsend(what, '+', 1);
    }
    return dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(a, '+', b), '+', c), '+', d), '+', e), '+', f), '+', g), '+', h), '+', i), '+', j), '+', k), '+', l), '+', m), '+', n), '+', o), '+', p), '+', q), '+', r), '+', s), '+', t), '+', u), '+', v);
  };
  dart.fn(memory_swap_test.spillingMethod, dynamicAnddynamicTodynamic());
  // Exports:
  exports.memory_swap_test = memory_swap_test;
});
