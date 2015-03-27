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
  // Function main: () → dynamic
  function main() {
    core.print(exports.exports);
    core.print(new Foo()._foo());
    core.print(_foo());
  }
  // Exports:
  exports.Foo = Foo;
  exports.main = main;
})(names || (names = {}));
