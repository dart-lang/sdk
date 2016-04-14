dart_library.library('names', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const names = Object.create(null);
  names.exports = 42;
  const _foo = Symbol('_foo');
  names.Foo = class Foo extends core.Object {
    [_foo]() {
      return 123;
    }
  };
  dart.setSignature(names.Foo, {
    methods: () => ({[_foo]: [dart.dynamic, []]})
  });
  names._foo = function() {
    return 456;
  };
  dart.fn(names._foo);
  names.Frame = class Frame extends core.Object {
    caller(arguments$) {
      this.arguments = arguments$;
    }
    static callee() {
      return null;
    }
  };
  dart.defineNamedConstructor(names.Frame, 'caller');
  dart.setSignature(names.Frame, {
    constructors: () => ({caller: [names.Frame, [core.List]]}),
    statics: () => ({callee: [dart.dynamic, []]}),
    names: ['callee']
  });
  names.Frame2 = class Frame2 extends core.Object {};
  dart.defineLazy(names.Frame2, {
    get caller() {
      return 100;
    },
    set caller(_) {},
    get arguments() {
      return 200;
    },
    set arguments(_) {}
  });
  names.main = function() {
    core.print(names.exports);
    core.print(new names.Foo()[_foo]());
    core.print(names._foo());
    core.print(new names.Frame.caller(dart.list([1, 2, 3], core.int)));
    let eval$ = names.Frame.callee;
    core.print(eval$);
    core.print(dart.notNull(names.Frame2.caller) + dart.notNull(names.Frame2.arguments));
  };
  dart.fn(names.main);
  // Exports:
  exports.names = names;
});
