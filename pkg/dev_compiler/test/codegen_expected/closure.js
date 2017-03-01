export const closure = Object.create(null);
import { core, js, dart, dartx } from 'dart_sdk';
let dynamic__Toint = () => (dynamic__Toint = dart.constFn(dart.functionType(core.int, [dart.dynamic], [dart.dynamic])))();
let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic})))();
let StringToList = () => (StringToList = dart.constFn(dart.functionType(core.List, [core.String])))();
let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
let FnToListOfint = () => (FnToListOfint = dart.constFn(dart.functionType(ListOfint(), [dynamicTodynamic()])))();
let MapOfMap$Map = () => (MapOfMap$Map = dart.constFn(core.Map$(core.Map, core.Map)))();
let Foo = () => (Foo = dart.constFn(closure.Foo$()))();
let ListOfTAndTToListOfT = () => (ListOfTAndTToListOfT = dart.constFn(dart.definiteFunctionType(T => [core.List$(T), [core.List$(T), T]])))();
let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
let VoidToNull = () => (VoidToNull = dart.constFn(dart.definiteFunctionType(core.Null, [])))();
closure.generic_function = function(T) {
  return (items: core.List<T>, seed: T): core.List<T> => {
    let strings = items[dartx.map](core.String)(dart.fn((i: T): string => dart.str`${i}`, dart.definiteFunctionType(core.String, [T])))[dartx.toList]();
    return items;
  };
};
dart.fn(closure.generic_function, ListOfTAndTToListOfT());
closure.Callback = dart.typedef('Callback', () => dart.functionType(dart.void, [], {i: core.int}));
closure.Foo$ = dart.generic(T => {
  let FooOfT = () => (FooOfT = dart.constFn(closure.Foo$(T)))();
  class Foo<T> extends core.Object {
    i: number;
    b: boolean;
    s: string;
    v: T;
    static some_static_constant: string;
    static some_static_final: string;
    static some_static_var: string;
    new(i: number, v: T) {
      this.i = i;
      this.v = v;
      this.b = null;
      this.s = null;
    }
    static build() {
      return new (FooOfT())(1, null);
    }
    untyped_method(a, b) {}
    pass(t: T) {
      T._check(t);
      return t;
    }
    typed_method(foo: closure.Foo<any>, list: core.List<any>, i: number, n: number, d: number, b: boolean, s: string, a: any[], o: Object, f: Function) {
      return '';
    }
    optional_params(a, b = null, c: number = null) {}
    static named_params(a, {b = null, c = null}: {b?: any, c?: number} = {}) {}
    nullary_method() {}
    function_params(f: (x: any, y?: any) => number, g: (x: any, opts?: {y?: string, z?: any}) => any, cb: closure.Callback) {
      cb({i: this.i});
    }
    run(a: core.List<any>, b: string, c: (d: string) => core.List<any>, e: (f: (g: any) => any) => core.List<number>, {h = null}: {h?: core.Map<core.Map<any, any>, core.Map<any, any>>} = {}) {}
    get prop() {
      return null;
    }
    set prop(value: string) {}
    static get staticProp() {
      return null;
    }
    static set staticProp(value: string) {}
  }
  dart.addTypeTests(Foo);
  dart.setSignature(Foo, {
    fields: () => ({
      i: core.int,
      b: core.bool,
      s: core.String,
      v: T
    }),
    getters: () => ({prop: dart.definiteFunctionType(core.String, [])}),
    setters: () => ({prop: dart.definiteFunctionType(dart.void, [core.String])}),
    methods: () => ({
      untyped_method: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      pass: dart.definiteFunctionType(T, [T]),
      typed_method: dart.definiteFunctionType(core.String, [closure.Foo, core.List, core.int, core.num, core.double, core.bool, core.String, js.JsArray, js.JsObject, js.JsFunction]),
      optional_params: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, core.int]),
      nullary_method: dart.definiteFunctionType(dart.dynamic, []),
      function_params: dart.definiteFunctionType(dart.dynamic, [dynamic__Toint(), dynamic__Todynamic(), closure.Callback]),
      run: dart.definiteFunctionType(dart.dynamic, [core.List, core.String, StringToList(), FnToListOfint()], {h: MapOfMap$Map()})
    }),
    statics: () => ({named_params: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {b: dart.dynamic, c: core.int})}),
    names: ['named_params']
  });
  return Foo;
});
closure.Foo = Foo();
/** @final {string} */
closure.Foo.some_static_constant = "abc";
/** @final {string} */
closure.Foo.some_static_final = "abc";
/** @type {string} */
closure.Foo.some_static_var = "abc";
closure.Bar = class Bar extends core.Object {};
closure.Baz = class Baz extends dart.mixin(closure.Foo$(core.int), closure.Bar) {
  new(i: number) {
    super.new(i, 123);
  }
};
dart.addSimpleTypeTests(closure.Baz);
closure.main = function(args): void {
};
dart.fn(closure.main, dynamicTovoid());
dart.defineLazy(closure, {
  get closure() {
    return dart.fn((): core.Null => {
      return;
    }, VoidToNull());
  },
  set closure(_) {}
});
/** @final {string} */
closure.some_top_level_constant = "abc";
/** @final {string} */
closure.some_top_level_final = "abc";
/** @type {string} */
closure.some_top_level_var = "abc";
dart.trackLibraries("closure", {"closure.dart": closure});
