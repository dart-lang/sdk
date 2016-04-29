export const closure = Object.create(null);
import { core, js, dart, dartx } from 'dart_sdk';
closure.generic_function = function(T) {
  return (items: core.List<T>, seed: T): core.List<T> => {
    let strings = items[dartx.map](core.String)(dart.fn((i: T): string => `${i}`, core.String, [T]))[dartx.toList]();
    return items;
  };
};
dart.fn(closure.generic_function, T => [core.List$(T), [core.List$(T), T]]);
closure.Callback = dart.typedef('Callback', () => dart.functionType(dart.void, [], {i: core.int}));
closure.Foo$ = dart.generic(T => {
  class Foo<T> extends core.Object {
    i: number;
    b: boolean;
    s: string;
    v: T;
    static some_static_constant: string;
    static some_static_final: string;
    static some_static_var: string;
    Foo(i: number, v: T) {
      this.i = i;
      this.v = v;
      this.b = null;
      this.s = null;
    }
    static build() {
      return new (closure.Foo$(T))(1, null);
    }
    untyped_method(a, b) {}
    pass(t: T) {
      dart.as(t, T);
      return t;
    }
    typed_method(foo: closure.Foo<any>, list: core.List<any>, i: number, n: number, d: number, b: boolean, s: string, a: any[], o: Object, f: Function) {
      return '';
    }
    optional_params(a, b = null, c: number = null) {}
    static named_params(a, {b = null, c = null}: {b?: any, c?: number} = {}) {}
    nullary_method() {}
    function_params(f: (x: any, y?: any) => number, g: (x: any, opts?: {y?: string, z?: any}) => any, cb: closure.Callback) {
      dart.as(f, dart.functionType(core.int, [dart.dynamic], [dart.dynamic]));
      dart.as(g, dart.functionType(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic}));
      cb({i: this.i});
    }
    run(a: core.List<any>, b: string, c: (d: string) => core.List<any>, e: (f: (g: any) => any) => core.List<number>, {h = null}: {h?: core.Map<core.Map<any, any>, core.Map<any, any>>} = {}) {
      dart.as(c, dart.functionType(core.List, [core.String]));
      dart.as(e, dart.functionType(core.List$(core.int), [dart.functionType(dart.dynamic, [dart.dynamic])]));
    }
    get prop() {
      return null;
    }
    set prop(value: string) {}
    static get staticProp() {
      return null;
    }
    static set staticProp(value: string) {}
  }
  dart.setSignature(Foo, {
    constructors: () => ({
      Foo: [closure.Foo$(T), [core.int, T]],
      build: [closure.Foo$(T), []]
    }),
    methods: () => ({
      untyped_method: [dart.dynamic, [dart.dynamic, dart.dynamic]],
      pass: [T, [T]],
      typed_method: [core.String, [closure.Foo, core.List, core.int, core.num, core.double, core.bool, core.String, js.JsArray, js.JsObject, js.JsFunction]],
      optional_params: [dart.dynamic, [dart.dynamic], [dart.dynamic, core.int]],
      nullary_method: [dart.dynamic, []],
      function_params: [dart.dynamic, [dart.functionType(core.int, [dart.dynamic], [dart.dynamic]), dart.functionType(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic}), closure.Callback]],
      run: [dart.dynamic, [core.List, core.String, dart.functionType(core.List, [core.String]), dart.functionType(core.List$(core.int), [dart.functionType(dart.dynamic, [dart.dynamic])])], {h: core.Map$(core.Map, core.Map)}]
    }),
    statics: () => ({named_params: [dart.dynamic, [dart.dynamic], {b: dart.dynamic, c: core.int}]}),
    names: ['named_params']
  });
  return Foo;
});
closure.Foo = closure.Foo$();
/** @final {string} */
closure.Foo.some_static_constant = "abc";
/** @final {string} */
closure.Foo.some_static_final = "abc";
/** @type {string} */
closure.Foo.some_static_var = "abc";
closure.Bar = class Bar extends core.Object {};
closure.Baz = class Baz extends dart.mixin(closure.Foo$(core.int), closure.Bar) {
  Baz(i: number) {
    super.Foo(i, 123);
  }
};
dart.setSignature(closure.Baz, {
  constructors: () => ({Baz: [closure.Baz, [core.int]]})
});
closure.main = function(args): void {
};
dart.fn(closure.main, dart.void, [dart.dynamic]);
/** @final {string} */
closure.some_top_level_constant = "abc";
/** @final {string} */
closure.some_top_level_final = "abc";
/** @type {string} */
closure.some_top_level_var = "abc";
