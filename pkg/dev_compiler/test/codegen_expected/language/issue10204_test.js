dart_library.library('language/issue10204_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10204_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10204_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(issue10204_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10204_test.a = 2;
  issue10204_test.Tupe = class Tupe extends core.Object {
    new() {
    }
    get instructionType() {
      return issue10204_test.a == 2 ? this : new issue10204_test.A();
    }
    refine(a, b) {
      return dart.str`${a}${b}`;
    }
  };
  dart.setSignature(issue10204_test.Tupe, {
    constructors: () => ({new: dart.definiteFunctionType(issue10204_test.Tupe, [])}),
    methods: () => ({refine: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  issue10204_test.Node = class Node extends core.Object {
    new() {
      this.inputs = dart.map({a: dart.const(new issue10204_test.Tupe()), b: dart.const(new issue10204_test.Tupe())}, core.String, issue10204_test.Tupe);
      this.selector = null;
      this.isCallOnInterceptor = false;
    }
    getDartReceiver() {
      return dart.test(this.isCallOnInterceptor) ? this.inputs[dartx.get]("a") : this.inputs[dartx.get]("b");
    }
  };
  dart.setSignature(issue10204_test.Node, {
    methods: () => ({getDartReceiver: dart.definiteFunctionType(dart.dynamic, [])})
  });
  issue10204_test.A = class A extends core.Object {
    visitInvokeDynamicMethod(node) {
      let receiverType = dart.dload(dart.dsend(node, 'getDartReceiver'), 'instructionType');
      return dart.dsend(receiverType, 'refine', dart.dload(node, 'selector'), dart.dload(node, 'selector'));
    }
  };
  dart.setSignature(issue10204_test.A, {
    methods: () => ({visitInvokeDynamicMethod: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  issue10204_test.main = function() {
    expect$.Expect.equals('nullnull', JSArrayOfA().of([new issue10204_test.A()])[dartx.last].visitInvokeDynamicMethod(new issue10204_test.Node()));
  };
  dart.fn(issue10204_test.main, VoidTodynamic());
  // Exports:
  exports.issue10204_test = issue10204_test;
});
