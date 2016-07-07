dart_library.library('language/for_variable_capture_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_variable_capture_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_variable_capture_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_variable_capture_test.run = function(callback) {
    return dart.dcall(callback);
  };
  dart.fn(for_variable_capture_test.run, dynamicTodynamic());
  for_variable_capture_test.initializer = function() {
    let closure = null;
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); i < 3; i++) {
      i = i + 1;
      closure = fn;
    }
    expect$.Expect.equals(1, dart.dcall(closure));
  };
  dart.fn(for_variable_capture_test.initializer, VoidTodynamic());
  for_variable_capture_test.condition = function() {
    let closures = [];
    function check(callback) {
      closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let values = [];
    for (let i = 0; dart.test(dart.dsend(check(dart.fn(() => ++i, VoidToint())), '<', 8)); ++i) {
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7]), values);
    expect$.Expect.listEquals(JSArrayOfint().of([2, 4, 6, 8, 10]), closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.condition, VoidTodynamic());
  for_variable_capture_test.body = function() {
    let closures = [];
    for (let i = 0, j = 0; i < 3; i++) {
      j++;
      closures[dartx.add](dart.fn(() => i, VoidToint()));
      closures[dartx.add](dart.fn(() => j, VoidToint()));
    }
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 1, 2, 2, 3]), closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.body, VoidTodynamic());
  for_variable_capture_test.update = function() {
    let closures = [];
    function check(callback) {
      closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let values = [];
    for (let i = 0; i < 4; check(dart.fn(() => ++i, VoidToint()))) {
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3]), values);
    expect$.Expect.listEquals(JSArrayOfint().of([2, 3, 4, 5]), closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.update, VoidTodynamic());
  for_variable_capture_test.initializer_condition = function() {
    let values = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); dart.test(dart.dsend(for_variable_capture_test.run(dart.fn(() => ++i, VoidToint())), '<', 3));) {
      values[dartx.add](i);
      values[dartx.add](fn());
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 1, 2, 1]), values);
  };
  dart.fn(for_variable_capture_test.initializer_condition, VoidTodynamic());
  for_variable_capture_test.initializer_update = function() {
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let init_closure = null;
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); i < 4; update(dart.fn(() => ++i, VoidToint()))) {
      init_closure = fn;
      if (i == 0) {
        ++i;
      }
    }
    expect$.Expect.equals(1, dart.dcall(init_closure));
    expect$.Expect.listEquals(JSArrayOfint().of([3, 4, 5]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.equals(1, dart.dcall(init_closure));
  };
  dart.fn(for_variable_capture_test.initializer_update, VoidTodynamic());
  for_variable_capture_test.initializer_body = function() {
    let closures = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); i < 3; i++) {
      closures[dartx.add](dart.fn(() => i, VoidToint()));
      closures[dartx.add](fn);
      fn = dart.fn(() => i, VoidToint());
    }
    expect$.Expect.listEquals(JSArrayOfint().of([0, 0, 1, 0, 2, 1]), closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.initializer_body, VoidTodynamic());
  for_variable_capture_test.condition_update = function() {
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let values = [];
    for (let i = 0; dart.test(dart.dsend(check(dart.fn(() => i, VoidToint())), '<', 4)); update(dart.fn(() => ++i, VoidToint()))) {
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3]), values);
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3, 4]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 3, 4, 5]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([0, 2, 3, 4, 5]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.condition_update, VoidTodynamic());
  for_variable_capture_test.condition_body = function() {
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let body_closures = [];
    function do_body(callback) {
      body_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(do_body, dynamicTodynamic());
    for (let i = 0; dart.test(dart.dsend(check(dart.fn(() => i, VoidToint())), '<', 4)); ++i) {
      do_body(dart.fn(() => i, VoidToint()));
    }
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3, 4]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3]), body_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.condition_body, VoidTodynamic());
  for_variable_capture_test.initializer_condition_update = function() {
    let init = null;
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let values = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); dart.test(dart.dsend(check(dart.fn(() => ++i, VoidToint())), '<', 8)); update(dart.fn(() => ++i, VoidToint()))) {
      init = fn;
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7]), values);
    expect$.Expect.equals(1, dart.dcall(init));
    expect$.Expect.listEquals(JSArrayOfint().of([2, 4, 6, 8, 10]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([5, 7, 9, 11]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.initializer_condition_update, VoidTodynamic());
  for_variable_capture_test.initializer_condition_body = function() {
    let init = null;
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let body_closures = [];
    function do_body(callback) {
      body_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(do_body, dynamicTodynamic());
    let values = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); dart.test(dart.dsend(check(dart.fn(() => ++i, VoidToint())), '<', 8));) {
      init = fn;
      do_body(dart.fn(() => ++i, VoidToint()));
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([2, 4, 6, 8]), values);
    expect$.Expect.equals(2, dart.dcall(init));
    expect$.Expect.listEquals(JSArrayOfint().of([3, 5, 7, 9, 10]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([4, 6, 8, 10]), body_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.initializer_condition_body, VoidTodynamic());
  for_variable_capture_test.initializer_update_body = function() {
    let init = null;
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let body_closures = [];
    function do_body(callback) {
      body_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(do_body, dynamicTodynamic());
    let values = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); i < 8; update(dart.fn(() => ++i, VoidToint()))) {
      init = fn;
      do_body(dart.fn(() => ++i, VoidToint()));
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7]), values);
    expect$.Expect.equals(1, dart.dcall(init));
    expect$.Expect.listEquals(JSArrayOfint().of([4, 6, 8, 9]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 5, 7, 9]), body_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.initializer_update_body, VoidTodynamic());
  for_variable_capture_test.condition_update_body = function() {
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let body_closures = [];
    function do_body(callback) {
      body_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(do_body, dynamicTodynamic());
    let values = [];
    for (let i = 0; dart.test(dart.dsend(check(dart.fn(() => i, VoidToint())), '<', 8)); update(dart.fn(() => ++i, VoidToint()))) {
      do_body(dart.fn(() => ++i, VoidToint()));
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7]), values);
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7, 8]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([4, 6, 8, 9]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 5, 7, 9]), body_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 5, 7, 9, 9]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.condition_update_body, VoidTodynamic());
  for_variable_capture_test.initializer_condition_update_body = function() {
    let init = null;
    let cond_closures = [];
    function check(callback) {
      cond_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(check, dynamicTodynamic());
    let update_closures = [];
    function update(callback) {
      update_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(update, dynamicTodynamic());
    let body_closures = [];
    function do_body(callback) {
      body_closures[dartx.add](callback);
      return dart.dcall(callback);
    }
    dart.fn(do_body, dynamicTodynamic());
    let values = [];
    for (let i = 0, fn = dart.fn(() => i, VoidToint()); dart.test(dart.dsend(check(dart.fn(() => i, VoidToint())), '<', 8)); update(dart.fn(() => ++i, VoidToint()))) {
      init = fn;
      do_body(dart.fn(() => ++i, VoidToint()));
      values[dartx.add](i);
    }
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7]), values);
    expect$.Expect.equals(1, dart.dcall(init));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 3, 5, 7, 8]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([4, 6, 8, 9]), update_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 5, 7, 9]), body_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([2, 5, 7, 9, 9]), cond_closures[dartx.map](dart.dynamic)(for_variable_capture_test.run)[dartx.toList]());
  };
  dart.fn(for_variable_capture_test.initializer_condition_update_body, VoidTodynamic());
  for_variable_capture_test.main = function() {
    for_variable_capture_test.initializer();
    for_variable_capture_test.condition();
    for_variable_capture_test.update();
    for_variable_capture_test.body();
    for_variable_capture_test.initializer_condition();
    for_variable_capture_test.initializer_update();
    for_variable_capture_test.initializer_body();
    for_variable_capture_test.condition_update();
    for_variable_capture_test.condition_body();
    for_variable_capture_test.initializer_condition_update();
    for_variable_capture_test.initializer_condition_body();
    for_variable_capture_test.initializer_update_body();
    for_variable_capture_test.condition_update_body();
    for_variable_capture_test.initializer_condition_update_body();
  };
  dart.fn(for_variable_capture_test.main, VoidTodynamic());
  // Exports:
  exports.for_variable_capture_test = for_variable_capture_test;
});
