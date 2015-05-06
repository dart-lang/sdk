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
  // Function _foo: () → dynamic
  function _foo() {
    return 456;
  }
  class Frame extends core.Object {
    caller(arguments$) {
      this.arguments = arguments$;
    }
    static callee() {
      return null;
    }
  }
  dart.defineNamedConstructor(Frame, 'caller');
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
  // Function main: () → dynamic
  function main() {
    core.print(exports.exports);
    core.print(new Foo()[_foo$]());
    core.print(_foo());
    core.print(new Frame.caller([1, 2, 3]));
    let eval$ = dart.bind(Frame, 'callee');
    core.print(eval$);
    core.print(dart.notNull(Frame2.caller) + dart.notNull(Frame2.arguments));
  }
  // Exports:
  exports.Foo = Foo;
  exports.Frame = Frame;
  exports.Frame2 = Frame2;
  exports.main = main;
})(names, core);
