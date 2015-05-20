var names = dart.defineLibrary(names, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  exports.exports = 42;
  let _foo$ = Symbol('_foo');
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
    caller(arguments$) {
      this.arguments = arguments$;
    }
    static callee() {
      return null;
    }
  }
  dart.defineNamedConstructor(Frame, 'caller');
  dart.setSignature(Frame, {
    statics: () => ({callee: [dart.dynamic, []]}),
    names: ['callee']
  });
  class Frame2 extends core.Object {}
  dart.defineLazyProperties(Frame2, {
    get caller() {
      return 100;
    },
    set caller(_) {},
    get arguments() {
      return 200;
    },
    set arguments(_) {}
  });
  function main() {
    core.print(exports.exports);
    core.print(new Foo()[_foo$]());
    core.print(_foo());
    core.print(new Frame.caller([1, 2, 3]));
    let eval$ = Frame.callee;
    core.print(eval$);
    core.print(dart.notNull(Frame2.caller) + dart.notNull(Frame2.arguments));
  }
  dart.fn(main);
  // Exports:
  exports.Foo = Foo;
  exports.Frame = Frame;
  exports.Frame2 = Frame2;
  exports.main = main;
})(names, core);
