dart_library.library('language/call_constructor_on_unresolvable_class_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__call_constructor_on_unresolvable_class_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const call_constructor_on_unresolvable_class_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_constructor_on_unresolvable_class_test_none_multi.never = function() {
    let r = math.Random.new();
    let r1 = r.nextInt(1000);
    let r2 = r.nextInt(1000);
    let r3 = r.nextInt(1000);
    return dart.notNull(r1) > dart.notNull(r3) && dart.notNull(r2) > dart.notNull(r3) && dart.notNull(r3) > dart.notNull(r1) + dart.notNull(r2);
  };
  dart.fn(call_constructor_on_unresolvable_class_test_none_multi.never, VoidTodynamic());
  call_constructor_on_unresolvable_class_test_none_multi.main = function() {
    if (dart.test(call_constructor_on_unresolvable_class_test_none_multi.never())) {
    }
  };
  dart.fn(call_constructor_on_unresolvable_class_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.call_constructor_on_unresolvable_class_test_none_multi = call_constructor_on_unresolvable_class_test_none_multi;
});
