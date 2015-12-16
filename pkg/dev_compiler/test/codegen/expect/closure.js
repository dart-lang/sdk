dart_library.library('closure', null, /* Imports */[
  "dart/_runtime",
  'dart/core',
  'dart/js'
], /* Lazy imports */[
], function(exports, dart, core, js) {
  'use strict';
  let dartx = dart.dartx;
  /** @typedef {function({i: (?number|undefined)}=)} */
  const Callback = dart.typedef('Callback', () => dart.functionType(dart.void, [], {i: core.int}));
  const Foo$ = dart.generic(function(T) {
    class Foo extends core.Object {
      /**
       * @param {?number} i
       * @param {?} v
       */
      Foo(i, v) {
        this.i = i;
        this.v = v;
        this.b = null;
        this.s = null;
      }
      /** @return {Foo} */
      static build() {
        return new (Foo$(T))(1, null);
      }
      /**
       * @param {?} a
       * @param {?} b
       */
      untyped_method(a, b) {}
      /** @param {?} t */
      pass(t) {
        dart.as(t, T);
        return t;
      }
      /**
       * @param {Foo} foo
       * @param {core.List} list
       * @param {?number} i
       * @param {?number} n
       * @param {?number} d
       * @param {?boolean} b
       * @param {string} s
       * @param {Array<?>} a
       * @param {Object<*, *>} o
       * @param {Function} f
       * @return {string}
       */
      typed_method(foo, list, i, n, d, b, s, a, o, f) {
        return '';
      }
      /**
       * @param {?} a
       * @param {?=} b
       * @param {?=} c
       */
      optional_params(a, b, c) {
        if (b === void 0) b = null;
        if (c === void 0) c = null;
      }
      /**
       * @param {?} a
       * @param {{b: (?|undefined), c: (?|undefined)}=} opts
       */
      static named_params(a, opts) {
        let b = opts && 'b' in opts ? opts.b : null;
        let c = opts && 'c' in opts ? opts.c : null;
      }
      nullary_method() {}
      /**
       * @param {function(?, ?=):?number} f
       * @param {function(?, {y: (string|undefined), z: (?|undefined)}=):?} g
       * @param {Callback} cb
       */
      function_params(f, g, cb) {
        dart.as(f, dart.functionType(core.int, [dart.dynamic], [dart.dynamic]));
        dart.as(g, dart.functionType(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic}));
        cb({i: this.i});
      }
      /** @return {string} */
      get prop() {
        return null;
      }
      /** @param {string} value */
      set prop(value) {}
      /** @return {string} */
      static get staticProp() {
        return null;
      }
      /** @param {string} value */
      static set staticProp(value) {}
    }
    dart.setSignature(Foo, {
      constructors: () => ({
        Foo: [Foo$(T), [core.int, T]],
        build: [Foo$(T), []]
      }),
      methods: () => ({
        untyped_method: [dart.dynamic, [dart.dynamic, dart.dynamic]],
        pass: [T, [T]],
        typed_method: [core.String, [Foo$(), core.List, core.int, core.num, core.double, core.bool, core.String, js.JsArray, js.JsObject, js.JsFunction]],
        optional_params: [dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic]],
        nullary_method: [dart.dynamic, []],
        function_params: [dart.dynamic, [dart.functionType(core.int, [dart.dynamic], [dart.dynamic]), dart.functionType(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic}), Callback]]
      }),
      statics: () => ({named_params: [dart.dynamic, [dart.dynamic], {b: dart.dynamic, c: dart.dynamic}]}),
      names: ['named_params']
    });
    return Foo;
  });
  let Foo = Foo$();
  /** @final {string} */
  Foo.some_static_constant = "abc";
  /** @final {string} */
  Foo.some_static_final = "abc";
  /** @type {string} */
  Foo.some_static_var = "abc";
  class Bar extends core.Object {}
  class Baz extends dart.mixin(Foo$(core.int), Bar) {
    /** @param {?number} i */
    Baz(i) {
      super.Foo(i, 123);
    }
  }
  dart.setSignature(Baz, {
    constructors: () => ({Baz: [Baz, [core.int]]})
  });
  /** @param {?} args */
  function main(args) {
  }
  dart.fn(main, dart.void, [dart.dynamic]);
  /** @final {string} */
  const some_top_level_constant = "abc";
  /** @final {string} */
  exports.some_top_level_final = "abc";
  /** @type {string} */
  exports.some_top_level_var = "abc";
  // Exports:
  exports.Callback = Callback;
  exports.Foo$ = Foo$;
  exports.Foo = Foo;
  exports.Bar = Bar;
  exports.Baz = Baz;
  exports.main = main;
  exports.some_top_level_constant = some_top_level_constant;
});
