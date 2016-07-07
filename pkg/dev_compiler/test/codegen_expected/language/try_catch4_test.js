dart_library.library('language/try_catch4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch4_test.a = null;
  try_catch4_test.foo1 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        return;
      } finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo1, VoidTodynamic());
  try_catch4_test.doThrow = function() {
    dart.throw(2);
  };
  dart.fn(try_catch4_test.doThrow, VoidTodynamic());
  try_catch4_test.foo2 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        try_catch4_test.doThrow();
        return;
      } catch (e) {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }

    }
  };
  dart.fn(try_catch4_test.foo2, VoidTodynamic());
  try_catch4_test.foo3 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.doThrow();
      } catch (e) {
        try_catch4_test.a = 8;
        entered = true;
        return;
      }
 finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo3, VoidTodynamic());
  try_catch4_test.foo4 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        break;
      } finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo4, VoidTodynamic());
  try_catch4_test.foo5 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        try_catch4_test.doThrow();
        break;
      } catch (e) {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }

    }
  };
  dart.fn(try_catch4_test.foo5, VoidTodynamic());
  try_catch4_test.foo6 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.doThrow();
      } catch (e) {
        try_catch4_test.a = 8;
        entered = true;
        break;
      }
 finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo6, VoidTodynamic());
  try_catch4_test.foo7 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        continue;
      } finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo7, VoidTodynamic());
  try_catch4_test.foo8 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.a = 8;
        try_catch4_test.doThrow();
        continue;
      } catch (e) {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }

    }
  };
  dart.fn(try_catch4_test.foo8, VoidTodynamic());
  try_catch4_test.foo9 = function() {
    let b = false;
    let entered = false;
    while (true) {
      if (entered) return b;
      b = dart.equals(8, try_catch4_test.a);
      try {
        try_catch4_test.doThrow();
      } catch (e) {
        try_catch4_test.a = 8;
        entered = true;
        continue;
      }
 finally {
        b = dart.equals(8, try_catch4_test.a);
        entered = true;
        continue;
      }
    }
  };
  dart.fn(try_catch4_test.foo9, VoidTodynamic());
  try_catch4_test.main_test = function() {
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo1());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo2());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo3());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo4());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo5());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo6());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo7());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo8());
    try_catch4_test.a = 0;
    expect$.Expect.isTrue(try_catch4_test.foo9());
  };
  dart.fn(try_catch4_test.main_test, VoidTodynamic());
  try_catch4_test.main = function() {
    for (let i = 0; i < 20; i++) {
      try_catch4_test.main_test();
    }
  };
  dart.fn(try_catch4_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch4_test = try_catch4_test;
});
