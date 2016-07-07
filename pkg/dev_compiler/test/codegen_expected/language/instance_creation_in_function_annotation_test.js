dart_library.library('language/instance_creation_in_function_annotation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instance_creation_in_function_annotation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instance_creation_in_function_annotation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instance_creation_in_function_annotation_test.C = class C extends core.Object {
    new(s) {
      this.s = s;
    }
  };
  dart.setSignature(instance_creation_in_function_annotation_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(instance_creation_in_function_annotation_test.C, [core.String])})
  });
  instance_creation_in_function_annotation_test.D = class D extends core.Object {
    new(c) {
      this.c = c;
    }
  };
  dart.setSignature(instance_creation_in_function_annotation_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(instance_creation_in_function_annotation_test.D, [instance_creation_in_function_annotation_test.C])})
  });
  instance_creation_in_function_annotation_test.f = function() {
  };
  dart.fn(instance_creation_in_function_annotation_test.f, VoidTodynamic());
  instance_creation_in_function_annotation_test.main = function() {
    let closureMirror = mirrors.ClosureMirror._check(mirrors.reflect(instance_creation_in_function_annotation_test.f));
    let metadata = closureMirror.function.metadata;
    expect$.Expect.equals(1, metadata[dartx.length]);
    expect$.Expect.equals(dart.dload(dart.dload(metadata[dartx.get](0).reflectee, 'c'), 's'), 'foo');
  };
  dart.fn(instance_creation_in_function_annotation_test.main, VoidTodynamic());
  // Exports:
  exports.instance_creation_in_function_annotation_test = instance_creation_in_function_annotation_test;
});
