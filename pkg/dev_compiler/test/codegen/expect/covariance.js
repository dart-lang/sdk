var covariance = dart.defineLibrary(covariance, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  let _t = Symbol('_t');
  let Foo$ = dart.generic(function(T) {
    class Foo extends core.Object {
      Foo() {
        this[_t] = null;
      }
      add(t) {
        dart.as(t, T);
        this[_t] = t;
      }
      forEach(fn) {
        dart.as(fn, dart.functionType(dart.void, [T]));
        fn(this[_t]);
      }
    }
    dart.setSignature(Foo, {
      methods: () => ({
        add: [core.Object, [T]],
        forEach: [core.Object, [dart.functionType(dart.void, [T])]]
      })
    });
    return Foo;
  });
  let Foo = Foo$();
  class Bar extends Foo$(core.int) {
    Bar() {
      super.Foo();
    }
    add(x) {
      core.print(`Bar.add got ${x}`);
      super.add(x);
    }
  }
  dart.setSignature(Bar, {
    methods: () => ({add: [core.Object, [core.int]]})
  });
  function main() {
    let foo = new Bar();
    foo.add('hi');
  }
  dart.fn(main);
  // Exports:
  exports.Foo$ = Foo$;
  exports.Foo = Foo;
  exports.Bar = Bar;
  exports.main = main;
})(covariance, core);
