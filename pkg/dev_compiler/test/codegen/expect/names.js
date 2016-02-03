dart_library.library('names', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  exports.exports = 42;
  const _foo$ = Symbol('_foo');
  class Foo extends core.Object {
    [_foo$]() {
      return 123;
    }
  }
  dart.setSignature(Foo, {
    methods: () => ({[_foo$]: [dart.dynamic, []]})
  });
  function _foo() {
    return 456;
  }
  dart.fn(_foo);
  class Frame extends core.Object {
    [dartx.caller](arguments$) {
      this.arguments = arguments$;
    }
    static [dartx.callee]() {
      return null;
    }
  }
  dart.defineNamedConstructor(Frame, dartx.caller);
  dart.setSignature(Frame, {
    constructors: () => ({[dartx.caller]: [Frame, [core.List]]}),
    statics: () => ({[dartx.callee]: [dart.dynamic, []]}),
    names: [dartx.callee]
  });
  class Frame2 extends core.Object {}
  dart.defineLazyProperties(Frame2, {
    get [dartx.caller]() {
      return 100;
    },
    set [dartx.caller](_) {},
    get [dartx.arguments]() {
      return 200;
    },
    set [dartx.arguments](_) {}
  });
  function main() {
    core.print(exports.exports);
    core.print(new Foo()[_foo$]());
    core.print(_foo());
    core.print(new Frame[dartx.caller]([1, 2, 3]));
    let eval$ = Frame[dartx.callee];
    core.print(eval$);
    core.print(dart.notNull(Frame2[dartx.caller]) + dart.notNull(Frame2[dartx.arguments]));
  }
  dart.fn(main);
  dart.defineExtensionNames([
    "caller",
    "callee",
    "arguments"
  ]);
  // Exports:
  exports.Foo = Foo;
  exports.Frame = Frame;
  exports.Frame2 = Frame2;
  exports.main = main;
});
