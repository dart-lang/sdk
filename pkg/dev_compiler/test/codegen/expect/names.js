var names;
(function(exports) {
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
    ['caller*'](arguments$) {
      this.arguments = arguments$;
    }
    static ['callee*']() {
      return null;
    }
  }
  dart.defineNamedConstructor(Frame, 'caller*');
  // Function main: () → dynamic
  function main() {
    core.print(exports.exports);
    core.print(new Foo()._foo());
    core.print(_foo());
    core.print(new Frame['caller*'](new core.List.from([1, 2, 3])));
    let eval$ = Frame['callee*'];
    core.print(eval$);
  }
  // Exports:
  exports.Foo = Foo;
  exports.Frame = Frame;
  exports.main = main;
})(names || (names = {}));
