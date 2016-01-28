dart_library.library('notnull', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function intAssignments() {
    let i = 0;
    i = i & 1;
    i = i | 1;
    i = i ^ 1;
    i = i >> 1;
    i = i << 1;
    i = i - 1;
    i = i % 1;
    i = i + 1;
    let t = i;
    t == null ? i = 1 : t;
    i = i * 1;
    i = (i / 1)[dartx.truncate]();
    i++;
    --i;
    core.print(i + 1);
    let j = 1;
    j = i < 10 ? 1 : 2;
    core.print(j + 1);
  }
  dart.fn(intAssignments, dart.void, []);
  function doubleAssignments() {
    let d = 0.0;
    d = d / 1;
    core.print(d + 1);
  }
  dart.fn(doubleAssignments, dart.void, []);
  function boolAssignments() {
    let b = true;
    b != b;
    core.print(b);
  }
  dart.fn(boolAssignments, dart.void, []);
  function increments() {
    let i = 1;
    core.print(++i);
    core.print(i++);
    core.print(--i);
    core.print(i--);
    let j = null;
    j = 1;
    core.print((j = dart.notNull(j) + 1));
    core.print((() => {
      let x = j;
      j = dart.notNull(x) + 1;
      return x;
    })());
    core.print((j = dart.notNull(j) - 1));
    core.print((() => {
      let x = j;
      j = dart.notNull(x) - 1;
      return x;
    })());
  }
  dart.fn(increments, dart.void, []);
  function conditionals(cond) {
    if (cond === void 0) cond = null;
    let nullable = null;
    nullable = 1;
    let nonNullable = 1;
    let a = dart.notNull(cond) ? nullable : nullable;
    let b = dart.notNull(cond) ? nullable : nonNullable;
    let c = dart.notNull(cond) ? nonNullable : nonNullable;
    let d = dart.notNull(cond) ? nonNullable : nullable;
    core.print(dart.notNull(a) + dart.notNull(b) + c + dart.notNull(d));
  }
  dart.fn(conditionals, dart.void, [], [core.bool]);
  function nullAwareOps() {
    let nullable = null;
    let nonNullable = 1;
    let a = (nullable != null ? nullable : nullable);
    let b = (nullable != null ? nullable : nonNullable);
    let c = nonNullable;
    let d = nonNullable;
    core.print(dart.notNull(a) + dart.notNull(b) + c + d);
    let s = "";
    core.print(dart.notNull(s[dartx.length]) + 1);
  }
  dart.fn(nullAwareOps, dart.void, []);
  function nullableLocals(param) {
    core.print(dart.notNull(param) + 1);
    let i = null;
    i = 1;
    core.print(dart.notNull(i) + 1);
    let j = 1;
    j = i == 1 ? 1 : null;
    core.print(dart.notNull(j) + 1);
  }
  dart.fn(nullableLocals, dart.void, [core.int]);
  function optParams(x, y) {
    if (x === void 0) x = null;
    if (y === void 0) y = 1;
    core.print(dart.notNull(x) + dart.notNull(y));
  }
  dart.fn(optParams, dart.void, [], [core.int, core.int]);
  function namedParams(opts) {
    let x = opts && 'x' in opts ? opts.x : null;
    let y = opts && 'y' in opts ? opts.y : 1;
    core.print(dart.notNull(x) + dart.notNull(y));
  }
  dart.fn(namedParams, dart.void, [], {x: core.int, y: core.int});
  function forLoops(length) {
    for (let i = 0; i < 10; i++) {
      core.print(i + 1);
    }
    for (let i = 0; i < dart.notNull(length()); i++) {
      core.print(i + 1);
    }
    for (let i = 0, n = length(); i < dart.notNull(n); i++) {
      core.print(i + 1);
    }
    for (let i = 0, n = dart.notNull(length()) + 0; i < n; i++) {
      core.print(i + 1);
    }
  }
  dart.fn(forLoops, dart.void, [dart.functionType(core.int, [])]);
  function nullableCycle() {
    let x = 1;
    let y = 2;
    let z = null;
    x = y;
    y = z;
    z = x;
    core.print(dart.notNull(x) + dart.notNull(y) + dart.notNull(z));
    let s = null;
    s = s;
    core.print(dart.notNull(s) + 1);
  }
  dart.fn(nullableCycle, dart.void, []);
  function nonNullableCycle() {
    let x = 1;
    let y = 2;
    let z = 3;
    x = y;
    y = z;
    z = x;
    core.print(x + y + z);
    let s = 1;
    s = s;
    core.print(s + 1);
  }
  dart.fn(nonNullableCycle, dart.void, []);
  class Foo extends core.Object {
    Foo() {
      this.intField = null;
      this.varField = null;
    }
    f(o) {
      core.print(1 + dart.notNull(dart.as(this.varField, core.num)) + 2);
      while (dart.notNull(dart.as(dart.dsend(this.varField, '<', 10), core.bool))) {
        this.varField = dart.dsend(this.varField, '+', 1);
      }
      while (dart.notNull(dart.as(dart.dsend(this.varField, '<', 10), core.bool)))
        this.varField = dart.dsend(this.varField, '+', 1);
      core.print(1 + dart.notNull(this.intField) + 2);
      while (dart.notNull(this.intField) < 10) {
        this.intField = dart.notNull(this.intField) + 1;
      }
      while (dart.notNull(this.intField) < 10)
        this.intField = dart.notNull(this.intField) + 1;
      core.print(1 + dart.notNull(o.intField) + 2);
      while (dart.notNull(o.intField) < 10) {
        o.intField = dart.notNull(o.intField) + 1;
      }
      while (dart.notNull(o.intField) < 10)
        o.intField = dart.notNull(o.intField) + 1;
    }
  }
  dart.setSignature(Foo, {
    methods: () => ({f: [dart.dynamic, [Foo]]})
  });
  function _foo() {
    return 1;
  }
  dart.fn(_foo, core.int, []);
  function calls() {
    let a = 1;
    let b = 1;
    b = dart.as(dart.dcall(dart.fn(x => x), a), core.int);
    core.print(dart.notNull(b) + 1);
    let c = _foo();
    core.print(dart.notNull(c) + 1);
  }
  dart.fn(calls);
  function localEscapes() {
    let a = 1;
    let f = dart.fn(x => a = dart.as(x, core.int));
    let b = 1;
    function g(x) {
      return b = dart.as(x, core.int);
    }
    dart.fn(g);
    dart.dcall(f, 1);
    g(1);
    core.print(dart.notNull(a) + dart.notNull(b));
  }
  dart.fn(localEscapes);
  function controlFlow() {
    for (let i = null, j = null;;) {
      i = j = 1;
      core.print(dart.notNull(i) + dart.notNull(j) + 1);
      break;
    }
    try {
      dart.throw(1);
    } catch (e) {
      core.print(dart.dsend(e, '+', 1));
    }

    try {
      dart.dsend(null, 'foo');
    } catch (e) {
      let trace = dart.stackTrace(e);
      core.print(`${typeof e == 'string' ? e : dart.toString(e)} at ${trace}`);
    }

  }
  dart.fn(controlFlow);
  function main() {
    intAssignments();
    doubleAssignments();
    boolAssignments();
    nullableLocals(1);
    optParams(1, 2);
    namedParams({x: 1, y: 2});
    forLoops(dart.fn(() => 10, core.int, []));
    increments();
    conditionals(true);
    calls();
    localEscapes();
    controlFlow();
    nullableCycle();
    nonNullableCycle();
  }
  dart.fn(main);
  // Exports:
  exports.intAssignments = intAssignments;
  exports.doubleAssignments = doubleAssignments;
  exports.boolAssignments = boolAssignments;
  exports.increments = increments;
  exports.conditionals = conditionals;
  exports.nullAwareOps = nullAwareOps;
  exports.nullableLocals = nullableLocals;
  exports.optParams = optParams;
  exports.namedParams = namedParams;
  exports.forLoops = forLoops;
  exports.nullableCycle = nullableCycle;
  exports.nonNullableCycle = nonNullableCycle;
  exports.Foo = Foo;
  exports.calls = calls;
  exports.localEscapes = localEscapes;
  exports.controlFlow = controlFlow;
  exports.main = main;
});
