dart_library.library('language/many_named_arguments_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__many_named_arguments_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const many_named_arguments_test = Object.create(null);
  let MapOfSymbol$dynamic = () => (MapOfSymbol$dynamic = dart.constFn(core.Map$(core.Symbol, dart.dynamic)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  many_named_arguments_test.Fisk = class Fisk extends core.Object {
    method(opts) {
      let a = opts && 'a' in opts ? opts.a : 'a';
      let b = opts && 'b' in opts ? opts.b : 'b';
      let c = opts && 'c' in opts ? opts.c : 'c';
      let d = opts && 'd' in opts ? opts.d : 'd';
      let e = opts && 'e' in opts ? opts.e : 'e';
      let f = opts && 'f' in opts ? opts.f : 'f';
      let g = opts && 'g' in opts ? opts.g : 'g';
      let h = opts && 'h' in opts ? opts.h : 'h';
      let i = opts && 'i' in opts ? opts.i : 'i';
      let j = opts && 'j' in opts ? opts.j : 'j';
      let k = opts && 'k' in opts ? opts.k : 'k';
      let l = opts && 'l' in opts ? opts.l : 'l';
      let m = opts && 'm' in opts ? opts.m : 'm';
      let n = opts && 'n' in opts ? opts.n : 'n';
      let o = opts && 'o' in opts ? opts.o : 'o';
      let p = opts && 'p' in opts ? opts.p : 'p';
      let q = opts && 'q' in opts ? opts.q : 'q';
      let r = opts && 'r' in opts ? opts.r : 'r';
      let s = opts && 's' in opts ? opts.s : 's';
      let t = opts && 't' in opts ? opts.t : 't';
      let u = opts && 'u' in opts ? opts.u : 'u';
      let v = opts && 'v' in opts ? opts.v : 'v';
      let w = opts && 'w' in opts ? opts.w : 'w';
      let x = opts && 'x' in opts ? opts.x : 'x';
      let y = opts && 'y' in opts ? opts.y : 'y';
      let z = opts && 'z' in opts ? opts.z : 'z';
      return dart.str`a: ${a}, ` + dart.str`b: ${b}, ` + dart.str`c: ${c}, ` + dart.str`d: ${d}, ` + dart.str`e: ${e}, ` + dart.str`f: ${f}, ` + dart.str`g: ${g}, ` + dart.str`h: ${h}, ` + dart.str`i: ${i}, ` + dart.str`j: ${j}, ` + dart.str`k: ${k}, ` + dart.str`l: ${l}, ` + dart.str`m: ${m}, ` + dart.str`n: ${n}, ` + dart.str`o: ${o}, ` + dart.str`p: ${p}, ` + dart.str`q: ${q}, ` + dart.str`r: ${r}, ` + dart.str`s: ${s}, ` + dart.str`t: ${t}, ` + dart.str`u: ${u}, ` + dart.str`v: ${v}, ` + dart.str`w: ${w}, ` + dart.str`x: ${x}, ` + dart.str`y: ${y}, ` + dart.str`z: ${z}`;
    }
  };
  dart.setSignature(many_named_arguments_test.Fisk, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic, c: dart.dynamic, d: dart.dynamic, e: dart.dynamic, f: dart.dynamic, g: dart.dynamic, h: dart.dynamic, i: dart.dynamic, j: dart.dynamic, k: dart.dynamic, l: dart.dynamic, m: dart.dynamic, n: dart.dynamic, o: dart.dynamic, p: dart.dynamic, q: dart.dynamic, r: dart.dynamic, s: dart.dynamic, t: dart.dynamic, u: dart.dynamic, v: dart.dynamic, w: dart.dynamic, x: dart.dynamic, y: dart.dynamic, z: dart.dynamic})})
  });
  let const$;
  many_named_arguments_test.main = function() {
    let method = dart.bind(new many_named_arguments_test.Fisk(), 'method');
    let namedArguments = core.Map.new();
    namedArguments[dartx.set](const$ || (const$ = dart.const(core.Symbol.new('a'))), 'a');
    expect$.Expect.stringEquals(many_named_arguments_test.EXPECTED_RESULT, core.String._check(core.Function.apply(method, [], MapOfSymbol$dynamic()._check(namedArguments))));
    expect$.Expect.stringEquals(many_named_arguments_test.EXPECTED_RESULT, core.String._check(new many_named_arguments_test.Fisk().method({a: 'a', b: 'b', c: 'c', d: 'd', e: 'e', f: 'f', g: 'g', h: 'h', i: 'i', j: 'j', k: 'k', l: 'l', m: 'm', n: 'n', o: 'o', p: 'p', q: 'q', r: 'r', s: 's', t: 't', u: 'u', v: 'v', w: 'w', x: 'x', y: 'y', z: 'z'})));
  };
  dart.fn(many_named_arguments_test.main, VoidTodynamic());
  many_named_arguments_test.EXPECTED_RESULT = 'a: a, ' + 'b: b, ' + 'c: c, ' + 'd: d, ' + 'e: e, ' + 'f: f, ' + 'g: g, ' + 'h: h, ' + 'i: i, ' + 'j: j, ' + 'k: k, ' + 'l: l, ' + 'm: m, ' + 'n: n, ' + 'o: o, ' + 'p: p, ' + 'q: q, ' + 'r: r, ' + 's: s, ' + 't: t, ' + 'u: u, ' + 'v: v, ' + 'w: w, ' + 'x: x, ' + 'y: y, ' + 'z: z';
  // Exports:
  exports.many_named_arguments_test = many_named_arguments_test;
});
