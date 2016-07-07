dart_library.library('language/class_syntax2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__class_syntax2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const class_syntax2_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  class_syntax2_test.main = function() {
    let c = new class_syntax2_test.Cool(true);
    expect$.Expect.stringEquals('{}', dart.str`${c.thing}`);
    c = new class_syntax2_test.Cool(false);
    expect$.Expect.stringEquals('[]', dart.str`${c.thing}`);
    c = new class_syntax2_test.Cool.alt(true);
    expect$.Expect.stringEquals('{}', dart.str`${c.thing}`);
    c = new class_syntax2_test.Cool.alt(false);
    expect$.Expect.stringEquals('[]', dart.str`${c.thing}`);
  };
  dart.fn(class_syntax2_test.main, VoidTovoid());
  class_syntax2_test.Cool = class Cool extends core.Object {
    new(option) {
      this.thing = dart.test(option) ? dart.map({}, core.String, core.String) : JSArrayOfString().of([]);
    }
    alt(option) {
      this.thing = !dart.test(option) ? JSArrayOfString().of([]) : dart.map({}, core.String, core.String);
    }
  };
  dart.defineNamedConstructor(class_syntax2_test.Cool, 'alt');
  dart.setSignature(class_syntax2_test.Cool, {
    constructors: () => ({
      new: dart.definiteFunctionType(class_syntax2_test.Cool, [core.bool]),
      alt: dart.definiteFunctionType(class_syntax2_test.Cool, [core.bool])
    })
  });
  // Exports:
  exports.class_syntax2_test = class_syntax2_test;
});
