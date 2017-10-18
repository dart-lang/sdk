define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const _root = Object.create(null);
  const unresolved_names = Object.create(_root);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
  unresolved_names.C = class C extends core.Object {};
  (unresolved_names.C.new = function() {
  }).prototype = unresolved_names.C.prototype;
  dart.addTypeTests(unresolved_names.C);
  unresolved_names.main = function() {
    dart.throw(Error("compile error: unresolved constructor: dynamic.<unnamed>"));
    dart.throw(Error("compile error: unresolved constructor: C.bar"));
    core.print(dart.throw(Error("compile error: unresolved identifier: baz")));
    core.print(dart.dload(unresolved_names.C, 'quux'));
  };
  dart.fn(unresolved_names.main, VoidTodynamic());
  dart.trackLibraries("unresolved_names", {
    "unresolved_names.dart": unresolved_names
  }, null);
  // Exports:
  return {
    unresolved_names: unresolved_names
  };
});
