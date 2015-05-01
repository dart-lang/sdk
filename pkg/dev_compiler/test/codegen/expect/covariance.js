var covariance;
(function(exports) {
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
    return Foo;
  });
  let Foo = Foo$();
  class Bar extends Foo$(core.int) {
    add(x) {
      core.print(`Bar.add got ${x}`);
      super.add(x);
    }
  }
  // Function main: () → dynamic
  function main() {
    let foo = new Bar();
    foo.add('hi');
  }
  // Exports:
  exports.Foo$ = Foo$;
  exports.Foo = Foo;
  exports.Bar = Bar;
  exports.main = main;
})(covariance || (covariance = {}));
