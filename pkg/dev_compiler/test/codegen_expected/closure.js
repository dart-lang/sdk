export const closure = Object.create(null);
import { core, js, dart, dartx } from 'dart_sdk';
const $toList = dartx.toList;
const $map = dartx.map;
let dynamic__Toint = () => (dynamic__Toint = dart.constFn(dart.fnTypeFuzzy(core.int, [dart.dynamic], [dart.dynamic])))();
let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.fnTypeFuzzy(dart.dynamic, [dart.dynamic], {y: core.String, z: dart.dynamic})))();
let StringToList = () => (StringToList = dart.constFn(dart.fnTypeFuzzy(core.List, [core.String])))();
let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.fnTypeFuzzy(dart.dynamic, [dart.dynamic])))();
let FnToListOfint = () => (FnToListOfint = dart.constFn(dart.fnTypeFuzzy(ListOfint(), [dynamicTodynamic()])))();
let MapOfMap$Map = () => (MapOfMap$Map = dart.constFn(core.Map$(core.Map, core.Map)))();
let Foo = () => (Foo = dart.constFn(closure.Foo$()))();
let ListOfTAndTToListOfT = () => (ListOfTAndTToListOfT = dart.constFn(dart.gFnType(T => [core.List$(T), [core.List$(T), T]])))();
let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic])))();
let VoidToNull = () => (VoidToNull = dart.constFn(dart.fnType(core.Null, [])))();
closure.generic_function = function(T) {
  return (items: core.List<T> = null, seed: T = null): core.List<T> => {
    let strings = items[$map](core.String)(dart.fn((i: T = null): string => dart.str`${i}`, dart.fnType(core.String, [T])))[$toList]();
    return items;
  };
};
dart.fn(closure.generic_function, ListOfTAndTToListOfT());
closure.Callback = dart.typedef('Callback', () => dart.fnTypeFuzzy(dart.void, [], {i: core.int}));
const _is_Foo_default = Symbol('_is_Foo_default');
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
    get i() {
      return this[i$];
    }
    set i(value) {
      super.i = value;
    }
    get b() {
      return this[b];
    }
    set b(value) {
      this[b] = value;
    }
    get s() {
      return this[s];
    }
    set s(value) {
      this[s] = value;
    }
    get v() {
      return this[v$];
    }
    set v(value) {
      this[v$] = T._check(value);
    }
    static build() {
      return new (FooOfT()).new(1, null);
    }
    untyped_method(a = null, b = null) {}
    pass(t: T = null) {
      T._check(t);
      return t;
    }
    typed_method(foo: closure.Foo<any> = null, list: core.List<any> = null, i: number = null, n: number = null, d: number = null, b: boolean = null, s: string = null, a: any[] = null, o: Object = null, f: Function = null) {
      return '';
    }
    optional_params(a = null, b = null, c: number = null) {}
    static named_params(a = null, {b = null, c = null}: {b?: any, c?: number} = {}) {}
    nullary_method() {}
    function_params(f: (x: any, y?: any) => number = null, g: (x: any, opts?: {y?: string, z?: any}) => any = null, cb: closure.Callback = null) {
      cb({i: this.i});
    }
    run(a: core.List<any> = null, b: string = null, c: (d: string) => core.List<any> = null, e: (f: (g: any) => any) => core.List<number> = null, {h = null}: {h?: core.Map<core.Map<any, any>, core.Map<any, any>>} = {}) {}
    get prop() {
      return null;
    }
    set prop(value: string = null) {}
    static get staticProp() {
      return null;
    }
    static set staticProp(value: string = null) {}
  }
  (Foo.new = function(i: number = null, v: T = null) {
    this[i$] = i;
    this[v$] = v;
    this[b] = null;
    this[s] = null;
  }).prototype = Foo.prototype;
  dart.addTypeTests(Foo);
  Foo.prototype[_is_Foo_default] = true;
  const i$ = Symbol("Foo.i");
  const b = Symbol("Foo.b");
  const s = Symbol("Foo.s");
  const v$ = Symbol("Foo.v");
  dart.setSignature(Foo, {
    fields: () => ({
      i: dart.finalFieldType(core.int),
      b: dart.fieldType(core.bool),
      s: dart.fieldType(core.String),
      v: dart.fieldType(T)
    }),
    getters: () => ({prop: dart.fnType(core.String, [])}),
    setters: () => ({prop: dart.fnType(dart.void, [core.String])}),
    methods: () => ({
      untyped_method: dart.fnType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      pass: dart.fnType(T, [core.Object]),
      typed_method: dart.fnType(core.String, [closure.Foo, core.List, core.int, core.num, core.double, core.bool, core.String, js.JsArray, js.JsObject, js.JsFunction]),
      optional_params: dart.fnType(dart.dynamic, [dart.dynamic], [dart.dynamic, core.int]),
      nullary_method: dart.fnType(dart.dynamic, []),
      function_params: dart.fnType(dart.dynamic, [dynamic__Toint(), dynamic__Todynamic(), closure.Callback]),
      run: dart.fnType(dart.dynamic, [core.List, core.String, StringToList(), FnToListOfint()], {h: MapOfMap$Map()})
    }),
    statics: () => ({named_params: dart.fnType(dart.dynamic, [dart.dynamic], {b: dart.dynamic, c: core.int})}),
    names: ['named_params']
  });
  return Foo;
});
closure.Foo = Foo();
dart.defineLazy(closure.Foo, {
  get some_static_constant() {
    return "abc";
  },
  get some_static_final() {
    return "abc";
  },
  get some_static_var() {
    return "abc";
  },
  set some_static_var(_) {}
});
dart.addTypeTests(closure.Foo, _is_Foo_default);
closure.Bar = class Bar extends core.Object {};
(closure.Bar.new = function() {
}).prototype = closure.Bar.prototype;
dart.addTypeTests(closure.Bar);
closure.Baz = class Baz extends dart.mixin(closure.Foo$(core.int), closure.Bar) {};
(closure.Baz.new = function(i: number = null) {
  closure.Baz.__proto__.new.call(this, i, 123);
}).prototype = closure.Baz.prototype;
dart.addTypeTests(closure.Baz);
closure.main = function(args = null): void {
};
dart.fn(closure.main, dynamicTovoid());
dart.defineLazy(closure, {
  get closure() {
    return dart.fn((): core.Null => {
      return;
    }, VoidToNull());
  },
  set closure(_) {},
  get some_top_level_constant() {
    return "abc";
  },
  get some_top_level_final() {
    return "abc";
  },
  get some_top_level_var() {
    return "abc";
  },
  set some_top_level_var(_) {}
});
dart.trackLibraries("closure", {
  "closure.dart": closure
}, null);
